# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'csv'

set :strict_paths, false

before do
  data_dir = File.join(Dir.pwd, 'data')
  @csv_path = File.join(data_dir, 'memos.csv')
  @max_id_path = File.join(data_dir, 'max_id.txt')

  Dir.mkdir(data_dir) unless Dir.exist?(data_dir)
  prepare_max_id_file(@max_id_path)
  prepare_data_file(@csv_path)
end

get '/memos' do
  @memos = []
  CSV.foreach(@csv_path, headers: true) do |memo|
    @memos << { id: memo['id'], title: memo['title'] }
  end

  @page_title = 'メモ一覧'
  erb :memos
end

get '/' do
  redirect '/memos'
end

get '/memos/new' do
  @page_title = '新規作成'
  erb :new
end

post '/memos' do
  id = File.read(@max_id_path).to_i + 1
  title = protect_xss(params[:title])
  content = protect_xss(params[:content])
  
  CSV.open(@csv_path, 'a', quote_char: '"') { |csv| csv << [id, title, content] }
  File.open(@max_id_path, 'w') { |file| file << id }

  redirect "/memos/#{id}"
end

patch '/memos/:id' do
  id = params[:id].to_i
  title = protect_xss(params[:title])
  content = protect_xss(params[:content])

  table = CSV.table(@csv_path)
  index = table.each_with_index do |row, i|
    break i if row[:id] == id
  end
  table[index] = [id.to_s, title, content]

  CSV.open(@csv_path, 'w') do |memo|
    memo << table.headers
    table.each do |row|
      memo << row
    end
  end

  redirect "/memos/#{id}"
end

get '/memos/:id' do
  @memo = fetch_memo(params[:id], @csv_path)
  
  @page_title = @memo['title']
  erb :show
end

get '/memos/:id/edit' do
  @memo = fetch_memo(params[:id], @csv_path)
  
  @page_title = "#{@memo['title']}-編集"
  erb :edit
end

delete '/memos/:id' do
  fetched_memo = fetch_memo(params[:id], @csv_path)
  table = CSV.table(@csv_path).delete_if { |row| row[:id].to_i == fetched_memo['id'].to_i }

  CSV.open(@csv_path, 'w') do |memo|
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

def fetch_memo(id, csv_path)
  CSV.foreach(csv_path, headers: true) do |memo|
    return memo if memo['id'] == id
  end
end

def protect_xss(text)
  Rack::Utils.escape_html(text)
end

def prepare_max_id_file(max_id_path)
  return if File.exist?(max_id_path)

  File.open(max_id_path, 'w') { |file| file.puts(0) }
end

def prepare_data_file(csv_path)
  return if File.exist?(csv_path)

  CSV.open(csv_path, 'w') { |csv| csv << %w[id title content] }
end
