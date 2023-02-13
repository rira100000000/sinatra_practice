# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'csv'

set :strict_paths, false
enable :method_override

get '/memos' do
  @page_title = 'メモ一覧'
  data_dir = "#{Dir.pwd}/data"
  Dir.mkdir(data_dir) unless Dir.exist?(data_dir)
  prepare_max_id_file(data_dir)
  if File.exist?("#{data_dir}/memos.csv")
    @memos = []
    CSV.foreach("#{data_dir}/memos.csv", headers: true) do |memo|
      @memos << [memo[0], memo[1]]
    end
  else
    file = File.new("#{data_dir}/memos.csv", 'w')
    file.puts('"id","title","content"')
    file.close
  end
  erb :memos
end

get '/' do
  redirect redirect '/memos'
end

get '/memos/new' do
  @page_title = '新規作成'
  erb :new
end

post '/memos/create' do
  data_dir = "#{Dir.pwd}/data"
  title = protect_xss(params[:title])
  content = protect_xss(params[:content])
  id = File.read("#{data_dir}/max_id.txt").to_i + 1
  memos = CSV.open("#{data_dir}/memos.csv", 'a', quote_char: '"')
  memos << [id, title, content]
  memos.close
  max_id_file = File.open("#{data_dir}/max_id.txt", 'w')
  max_id_file.puts(id)
  max_id_file.close
  redirect "/memos/#{id}/show"
end

patch '/memos/:id/update' do
  data_dir = "#{Dir.pwd}/data"
  title = protect_xss(params[:title])
  content = protect_xss(params[:content])
  id = protect_xss(params[:id]).to_i
  table = CSV.table("#{data_dir}/memos.csv")
  index = table.each_with_index do |row, i|
    break i if row[:id] == id
  end
  table[index] = [id.to_s, title.to_s, content.to_s]

  CSV.open("#{data_dir}/memos.csv", 'w') do |memo|
    memo << table.headers
    table.each do |row|
      memo << row
    end
  end
  redirect "/memos/#{id}/show"
end

get '/memos/:id/show' do
  fetched_memo = fetch_memo(params[:id])
  @id = fetched_memo['id']
  @title = fetched_memo['title']
  @content = fetched_memo['content']
  @page_title = @title
  erb :show
end

get '/memos/:id/edit' do
  fetched_memo = fetch_memo(params[:id])
  @id = fetched_memo['id']
  @title = fetched_memo['title']
  @content = fetched_memo['content']
  @page_title = "#{@title}-編集"
  erb :edit
end

delete '/memos/:id/delete' do
  data_dir = "#{Dir.pwd}/data"
  fetched_memo = fetch_memo(params[:id])
  id = fetched_memo['id']
  table = CSV.table("#{data_dir}/memos.csv").delete_if { |row| row[:id].to_i == id.to_i }

  CSV.open("#{data_dir}/memos.csv", 'w') do |memo|
    memo << table.headers
    table.each do |row|
      memo << row
    end
  end
  redirect '/memos'
end

not_found do
  @page_title = '404 お探しのページは存在しません'
  '404 お探しのページは存在しません'
end

def fetch_memo(id)
  data_dir = "#{Dir.pwd}/data"
  CSV.foreach("#{data_dir}/memos.csv", headers: true) do |memo|
    return memo if memo['id'] == id
  end
end

def protect_xss(text)
  Rack::Utils.escape_html(text)
end

def prepare_max_id_file(data_dir)
  return if File.exist?("#{data_dir}/max_id.txt")

  max_id_file = File.open("#{data_dir}/max_id.txt", 'w')
  max_id_file.puts(0)
  max_id_file.close
end
