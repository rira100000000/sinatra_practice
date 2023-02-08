# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'

enable :method_override
get %r{/memos/?} do
  @page_title = 'メモ一覧'
  if File.exist?('file_infos.txt')
    @files = IO.readlines('file_infos.txt')
  else
    file = File.new('file_infos.txt', 'w')
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
  @title = protect_xss(params[:title])
  @content = protect_xss(params[:content])
  @id = File.read('file_infos.txt').count("\n")
  files = File.open('file_infos.txt', 'a')
  files.puts("#{@id},#{@title}")
  files.close
  current_dir = Dir.pwd
  new_file = File.new("#{current_dir}/data/#{@id}.txt", 'w')
  new_file.puts(@content)
  new_file.close
  redirect "http://localhost:4567/memos/#{@id}/show"
end

patch '/memos/:id/update' do
  @title = protect_xss(params[:title])
  @content = protect_xss(params[:content])
  @id = params[:id]
  current_dir = Dir.pwd
  file_infos = IO.readlines('file_infos.txt')
  file_infos.each_with_index do |file_info, index|
    info_id, _info_title = file_info.split(',')
    if info_id == @id
      replace_line("#{current_dir}/file_infos.txt", index, "#{@id},#{@title}\n")
      break
    end
  end
  file = File.open("#{current_dir}/data/#{@id}.txt", 'w')
  file.puts(@content)
  file.close
  redirect "http://localhost:4567/memos/#{@id}/show"
end

get '/memos/:id/show' do
  current_dir = Dir.pwd
  @id, @title = *fetch_id_and_title
  @page_title = @title
  @content = File.read("#{current_dir}/data/#{@id}.txt")
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
  file_infos = IO.readlines('file_infos.txt')
  @id, @title = *fetch_id_and_title
  file_infos.each_with_index do |file_info, index|
    info_id, info_title = file_info.split(',')
    if info_id == @id
      info_title.gsub!("\n", '')
      replace_line("#{current_dir}/file_infos.txt", index, "#{info_id},#{info_title},true\n")
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

def fetch_id_and_title
  id = request.url.match("(?<=memos\/).*(?=\/)")
  file_infos = IO.readlines('file_infos.txt')
  file_infos.each do |file_info|
    info_id, info_title = file_info.split(',')
    return [info_id, info_title] if info_id == id.to_s
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
