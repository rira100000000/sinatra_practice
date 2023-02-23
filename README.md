# sinatra_practice
[Sinatra を使ってWebアプリケーションの基本を理解する \| FBC](https://bootcamp.fjord.jp/practices/157)の提出課題です。<br>
sinatraを使って簡単なメモアプリを作成しました。

# 必要なgem
* gem 'sinatra'
* gem 'sinatra-contrib'
* gem 'webrick'
* gem 'pg'

# 使い方
```bash
git clone -b sinatra_practice https://github.com/rira100000000/sinatra_practice_db.git
cd <cloneしたディレクトリ>
bundle install
bundle exec ruby app.rb
```

# Note
作成したメモのデータはdataディレクトリ配下にmemos.csvとして保存されます。<br>
`bundle exec ruby app.rb`実行後、ブラウザから`http://localhost:4567`にアクセスしてください。

# 作成者
rira100000000
