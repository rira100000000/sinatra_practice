# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'csv'

set :strict_paths, false

DATA_DIR = File.join(Dir.pwd, 'data')
CSV_PATH = File.join(DATA_DIR, 'memos.csv')
MAX_ID_PATH = File.join(DATA_DIR, 'max_id.txt')

before do
  Dir.mkdir(DATA_DIR) unless Dir.exist?(DATA_DIR)
  prepare_max_id_file
  prepare_data_file
end

get '/memos' do
  @memos = []
  CSV.open(CSV_PATH, headers: true, header_converters: :symbol) do |csv|
    csv.each do |memo|
      @memos << { id: memo[:id], title: memo[:title] }
    end
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
  id = File.read(MAX_ID_PATH).to_i + 1
  title = protect_xss(params[:title])
  content = protect_xss(params[:content])

  CSV.open(CSV_PATH, 'a', quote_char: '"') { |csv| csv << [id, title, content] }
  File.open(MAX_ID_PATH, 'w') { |file| file << id }

  redirect "/memos/#{id}"
end

patch '/memos/:id' do
  id = params[:id].to_i
  title = protect_xss(params[:title])
  content = protect_xss(params[:content])

  table = CSV.table(CSV_PATH)
  index = table.find_index { |row| row[:id] == id }
  table[index] = [id.to_s, title, content]

  CSV.open(CSV_PATH, 'w') do |memo|
    memo << table.headers
    table.each do |row|
      memo << row
    end
  end

  redirect "/memos/#{id}"
end

get '/memos/:id' do
  @memo = fetch_memo(params[:id])

  @page_title = @memo[:title]
  erb :show
end

get '/memos/:id/edit' do
  @memo = fetch_memo(params[:id])

  @page_title = "#{@memo[:title]}-編集"
  erb :edit
end

delete '/memos/:id' do
  fetched_memo = fetch_memo(params[:id])
  table = CSV.table(CSV_PATH).delete_if { |row| row[:id].to_i == fetched_memo[:id].to_i }

  CSV.open(CSV_PATH, 'w') do |memo|
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
  CSV.open(CSV_PATH, headers: true, header_converters: :symbol) do |csv|
    csv.find do |memo|
      memo[:id] == id
    end
  end
end

def protect_xss(text)
  Rack::Utils.escape_html(text)
end

def prepare_max_id_file
  return if File.exist?(MAX_ID_PATH)

  File.open(MAX_ID_PATH, 'w') { |file| file.puts(0) }
end

def prepare_data_file
  return if File.exist?(CSV_PATH)

  CSV.open(CSV_PATH, 'w') { |csv| csv << %w[id title content] }
end
