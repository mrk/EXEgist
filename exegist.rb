require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'

configure :development do
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/exegist.db")
end

get '/' do
  @title = "Welcome to EXEgist"
  erb :welcome :layout => false
end

get '/paper/:id' do
  @title="Joyce"
  erb :standard 
end


#GREG'S WAY OF PARSING THE SENTENCES SERVER SIDE
#<% for sentence in @mything.split(".") %><span class="aSentence"><%= sentence %></span><% end %>