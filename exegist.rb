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

get '/wallace' do
  @title="E Unibus Plurum"
  erb :wallace 
end

get '/paper' do
  @title="(sava class paper)"
  erb :paper 
end

get '/fanfic' do
  @title="(fanfic name)"
  erb :fanfic 
end




#GREG'S WAY OF PARSING THE SENTENCES SERVER SIDE
# also add:   - generate sequential unique ids
#             - put each one in a db
#             -- each entry associated with 
#             - each span given a set of classes, eg. <span class
#<% for sentence in @mything.split(".") %><span class="aSentence"><%= sentence %></span><% end %>