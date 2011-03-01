require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'dm-validations'


#NOTE ON COMMENTS
#if we say that a comment is a child of another comment, that may solve our subcomments issue.

configure :development do
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/exegist.db")
end

# mark's first pass at defining our model
class User
  include DataMapper::Resource
  
  property :id,         Serial
  property :username,   String, :required => true, :unique => true, 
    :messages => {
      :presence => "Please specify a username.",
      :is_unique => "That name is already being used.",
      }
  property :email,      String, :required => true, :unique => true, :format => :email_address,
    :messages => {
      :presence => "Please specify an email address.",
      :is_unique => "That email address is already registered.",
      :format => "Please provide a valid email address."
      }
  property :password,   String 
  property :created_at, DateTime
  
  has n, :comments
end

class Comment                            # classes map to tables
  include DataMapper::Resource
  
  property :id,           Serial      # properties map to fields
  property :text,         Text
  property :level,        Integer
  property :in_doc,       String
  property :in_sentence,  String
  property :created_at,   DateTime
  #property :child_of, 
  
  belongs_to :user 
end

class TestComment
  include DataMapper::Resource
  
  property :id,         Serial
  property :comment,    Text
  property :created_at, DateTime

end


configure :development do
  DataMapper .auto_upgrade!
end
  
before do
  headers "Content-Type" => "text/html; charset=utf-8"
end

get '/' do
  @title = "Welcome to EXEgist"
  erb :welcome
end

get '/register' do
  @title = "EXEgist User Registration"
  erb :register
end

post '/newuser' do
  @user         = User.new(params[:user])
  if @user.save
    redirect("/")
  else
    redirect('/')
  end
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

get '/newcomment' do
  erb :comment, :layout => false
end

post '/postcomment' do
  @comment = TestComment.new(params[:thecomment])
  @comment.save
  #  redirect("/fanfic")
  #else
  #end
end






#GREG'S WAY OF PARSING THE SENTENCES SERVER SIDE
# also add:   - generate sequential unique ids
#             - put each one in a db
#             -- each entry associated with 
#             - each span given a set of classes, eg. <span class
#<% for sentence in @mything.split(".") %><span class="aSentence"><%= sentence %></span><% end %>