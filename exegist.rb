require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'

get '/' do
  @title = "Welcome to EXEgist"
  erb :welcome :layout => false
end

get '/joyce' do
  @title="Joyce"
  erb :standard 
end

get '/paper2' do
  erb :standard
end

get '/paper3' do
  erb :standard
end


#GREG'S WAY OF PARSING THE SENTENCES SERVER SIDE
#<% for sentence in @mything.split(".") %><span class="aSentence"><%= sentence %></span><% end %>