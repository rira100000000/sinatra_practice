# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'csv'

enable :method_override
get %r{/memos/?} do
  @page_title = 'メモ一覧'
  data_dir = "#{Dir.pwd}/data"
  Dir.mkdir(data_dir) unless Dir.exist?(data_dir)
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
  @page_title = 'メモ一覧'
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
  fetched_memo = fetch_memo
  @id = fetched_memo['id']
  @title = fetched_memo['title']
  @content = fetched_memo['content']
  @page_title = @title
  erb :show
end

get '/memos/:id/edit' do
  fetched_memo = fetch_memo
  @id = fetched_memo['id']
  @title = fetched_memo['title']
  @content = fetched_memo['content']
  @page_title = "#{@title}-編集"
  erb :edit
end

delete '/memos/:id/delete' do
  data_dir = "#{Dir.pwd}/data"
  fetched_memo = fetch_memo
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

def fetch_memo
  data_dir = "#{Dir.pwd}/data"
  id = request.url.match("(?<=memos\/).*(?=\/)")[0]
  CSV.foreach("#{data_dir}/memos.csv", headers: true) do |memo|
    return memo if memo['id'] == id
  end
end

def replace_line(file_name, line_num, new_line)
  lines = IO.readlines(file_name)
  lines[line_num] = new_line
  file = File.open(file_name, 'w')
  file.puts(lines.join)
  file.close
end

def protect_xss(text)
  Rack::Utils.escape_html(text)
end
