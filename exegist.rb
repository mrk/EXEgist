require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-types'
#require 'rack-flash'

# enable sessions (for login/cookies)
enable :sessions
#use Rack::Flash

# helpers can be called inside any of the main methods
helpers do

  # Check to see if a user is logged in
  def logged_in?
    #if request.cookies['userid']
    if session["current_user"]
      true
    else
      false
    end
  end

  # Add this to the top of a route to make it accessible only to logged in users
  def authorize!
    redirect '/login' unless logged_in?
  end

  # # Get the logged in user's ID
  # def get_userid
  #   request.cookies['userid']
  # end

  # # Set the logged in user's ID (logging them in)
  # def set_userid(id)
  #   response.set_cookie('userid', id)
  # end

end

# sets up DB
configure :development do
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/exegist.db")
end


class User
  include DataMapper::Resource
  
  property :id,         Serial
  property :username,   String, :required => true, :unique => true
  property :email,      String, :required => true, :unique => true, :format => :email_address
  
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
  property :username,   String
  property :comment,    Text
  property :created_at, DateTime

end

class Paper
  include DataMapper::Resource
  
  property :id,         Serial
  property :body,       Text
  
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

get '/login' do
  @title = "Log in to EXEgist"
  erb :login
end

get '/papers/new' do
  erb :newpaper
end

post '/papers/new' do
  @newpaper = Paper.new(:body => params[:body])
  if @newpaper.save
    redirect '/papers/' + @newpaper.id.to_s
  else
    "sorry, did not save"
  end
end

get '/papers/:id' do
  @paper = Paper.get(params[:id])
  @paperArray = @paper.body.split('.')
  session["current_paper"] = @paper.id.to_s
  authorize!
  
  erb :paper
end

post '/login' do
  @user = User.new(params[:user])
  if @user.save
    session["current_user"] = @user.username
    redirect '/papers/' + session["current_paper"]
  else
    redirect '/'
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