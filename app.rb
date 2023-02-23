# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'csv'
require 'pg'

set :strict_paths, false

DB_NAME = 'sinatra_practice'
HOST = 'localhost'
USER = 'postgres'
PASSWORD = 'postgres'
PORT = 5432

before do
  @db_connect = PG::Connection.new(host: HOST, port: PORT, dbname: DB_NAME, user: USER, password: PASSWORD)
  @db_connect.set_client_encoding('UTF8')
  if table_exists?(@db_connect, DB_NAME)
    @db_connect.exec("CREATE TABLE memos (
      id serial primary key,
      title varchar(255),
      content text
    );")
  end
end

get '/memos' do
  @result = @db_connect.exec('SELECT id, title FROM memos')
  @result.field_name_type = :symbol

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
  title = protect_xss(params[:title])
  content = protect_xss(params[:content])
  @db_connect.exec_params('INSERT INTO memos(title, content) VALUES($1, $2)', [title, content])
  result = @db_connect.exec('SELECT MAX(id) FROM memos')
  result.field_name_type = :symbol

  redirect "/memos/#{result[0][:max]}"
end

patch '/memos/:id' do
  id = params[:id].to_i
  title = protect_xss(params[:title])
  content = protect_xss(params[:content])

  @db_connect.exec_params('UPDATE memos SET title = $1, content = $2 WHERE id = $3', [title, content, id])

  redirect "/memos/#{id}"
end

get '/memos/:id' do
  result = @db_connect.exec("SELECT * FROM memos WHERE id =#{params[:id]};")
  result.field_name_type = :symbol
  @memo = result[0]

  @page_title = @memo[:title]
  erb :show
end

get '/memos/:id/edit' do
  result = @db_connect.exec("SELECT * FROM memos WHERE id =#{params[:id]};")
  result.field_name_type = :symbol
  @memo = result[0]

  @page_title = "#{@memo[:title]}-編集"
  erb :edit
end

delete '/memos/:id' do
  @db_connect.exec("DELETE FROM memos WHERE id =#{params[:id]};")

  redirect '/memos'
end

not_found do
  @page_title = '404 お探しのページは存在しません'
  '404 お探しのページは存在しません'
end

def protect_xss(text)
  Rack::Utils.escape_html(text)
end

def table_exists?(db_connect, table_name)
  result = db_connect.exec("SELECT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_name = '#{table_name}'
    );")
  result.field_name_type = :symbol
  result[0][:exists] == 't'
end
