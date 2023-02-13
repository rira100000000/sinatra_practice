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
    CSV.foreach("#{data_dir}/memos.csv") do |row|
      @memos << [row[0], row[1]]
    end
  else
    file = File.new("#{data_dir}/memos.csv", 'w')
    file.close
  end
  erb :memos
end

get '/' do
  @page_title = 'メモ一覧'
  redirect redirect 'http://localhost:4567/memos'
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
  memos = File.open("#{data_dir}/memos.csv", 'a')
  memos.puts("#{id},#{title},#{content}")
  memos.close
  max_id_file = File.open("#{data_dir}/max_id.txt", 'w')
  max_id_file.puts(id)
  max_id_file.close
  redirect "http://localhost:4567/memos/#{id}/show"
end

patch '/memos/:id/update' do
  @title = protect_xss(params[:title])
  @content = protect_xss(params[:content])
  @id = params[:id]
  current_dir = Dir.pwd
  file_infos = IO.readlines('memos.csv')
  file_infos.each_with_index do |file_info, index|
    info_id, _info_title = file_info.split(',')
    if info_id == @id
      replace_line("#{current_dir}/memos.csv", index, "#{@id},#{@title}\n")
      break
    end
  end
  file = File.open("#{current_dir}/data/#{@id}.txt", 'w')
  file.puts(@content)
  file.close
  redirect "http://localhost:4567/memos/#{@id}/show"
end

get '/memos/:id/show' do
  @id, @title, @content = *fetch_title_and_content
  @page_title = @title
  erb :show
end

get '/memos/:id/edit' do
  current_dir = Dir.pwd
  @id, @title = *fetch_id_and_title
  @page_title = "#{@title}-編集"
  @content = File.read("#{current_dir}/data/#{@id}.txt")
  erb :edit
end

delete '/memos/:id/delete' do
  current_dir = Dir.pwd
  file_infos = IO.readlines('memos.csv')
  @id, @title = *fetch_id_and_title
  file_infos.each_with_index do |file_info, index|
    info_id, info_title = file_info.split(',')
    if info_id == @id
      info_title.gsub!("\n", '')
      replace_line("#{current_dir}/memos.csv", index, "#{info_id},#{info_title},true\n")
      break
    end
    next
  end
  redirect 'http://localhost:4567/memos'
end

not_found do
  @page_title = '404 お探しのページは存在しません'
  '404 お探しのページは存在しません'
end

def fetch_title_and_content
  data_dir = "#{Dir.pwd}/data"
  id = request.url.match("(?<=memos\/).*(?=\/)")[0]
  CSV.foreach("#{data_dir}/memos.csv") do |memo|
    return memo if memo[0] == id
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
