# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'

enable :method_override
get %r{/memos/?} do
  if File.exist?('file_infos.txt')
    @files = IO.readlines('file_infos.txt')
  else
    file = File.new('file_infos.txt', 'w')
    file.close
  end
  erb :memos
end

get '/memos/new' do
  erb :new
end

post '/memos/create' do
  @title = params[:title]
  @content = params[:content]
  @id = File.read('file_infos.txt').count("\n")
  files = File.open('file_infos.txt', 'a')
  files.puts("#{@id},#{@title}")
  files.close
  current_dir = Dir.pwd
  new_file = File.new("#{current_dir}/data/#{@id}", 'w')
  new_file.puts(@content)
  new_file.close
  redirect "http://localhost:4567/memos/show/#{@id}"
end

patch '/memos/update/:id' do
  @title = params[:title]
  @content = params[:content]
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
  file = File.open("#{current_dir}/data/#{@id}", 'w')
  file.puts(@content)
  file.close
  redirect "http://localhost:4567/memos/show/#{@id}"
end

get '/memos/show/*' do
  current_dir = Dir.pwd
  @id, @title = *fetch_id_and_title('show')
  @content = File.read("#{current_dir}/data/#{@id}")
  erb :show
end

get '/memos/edit/*' do
  current_dir = Dir.pwd
  @id, @title = *fetch_id_and_title('edit')
  @content = File.read("#{current_dir}/data/#{@id}")
  erb :edit
end

delete '/memos/delete/:id' do
  current_dir = Dir.pwd
  file_infos = IO.readlines('file_infos.txt')
  @id, @title = *fetch_id_and_title('delete')
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

def fetch_id_and_title(order)
  id = request.url.gsub("http://localhost:4567/memos/#{order}/", '')
  file_infos = IO.readlines('file_infos.txt')
  file_infos.each do |file_info|
    info_id, info_title = file_info.split(',')
    return [info_id, info_title] if info_id == id
  end
end

def replace_line(file_name, line_num, new_line)
  lines = IO.readlines(file_name)
  lines[line_num] = new_line
  file = File.open(file_name, 'w')
  file.puts(lines.join)
  file.close
end
