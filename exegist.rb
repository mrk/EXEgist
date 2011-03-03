require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-types'


#NOTE ON COMMENTS
#if we say that a comment is a child of another comment, that may solve our subcomments issue.

configure :development do
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/exegist.db")
end

helpers do
  
  # Check to see if a user is logged in
  def logged_in?
    if request.cookies['userid']
      true
    else
      false
    end
  end

  # Add this to the top of a route to make it accessible only to logged in users
  def authorize!
    redirect '/' unless logged_in?
  end

  # Get the logged in user's ID
  def get_userid
    request.cookies['userid']
  end

  # Set the logged in user's ID (logging them in)
  def set_userid(id)
    response.set_cookie('userid', id)
  end

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
  
  attr_accessor :password_confirmation
  validates_confirmation_of :password
  
  has n, :comments
end

class Comment                         # classes map to tables
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


# Show a login form or log the user out
get '/login/?' do
  unless logged_in?
    erb :login
  else
    flash[:notice] = 'You have been logged out.'
    response.delete_cookie('userid')
    redirect '/'
  end
end


post '/login/?' do
  user = User.first(:username => params[:username])
  if user
    if user.password == params[:password]
      set_userid(user.id)
      flash[:notice] = 'You are now logged in.'
      redirect '/'
    else
      flash[:notice] = 'Incorrect password.'
      redirect '/login'
    end
  else
    flash[:notice] = 'Incorrect username.'
    redirect '/login'
  end
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
  erb :paper
end

get '/wallace' do
  @title="E Unibus Plurum"
  mypage = "wallace"  
  erb :wallace 
end

get '/paper' do
  @title="(sava class paper)"
  mypage = "paper"
  erb :paper 
end

get '/fanfic' do
  @title="(fanfic name)"
  mypage = "fanfic"
  erb :fanfic
end


get '/register' do
  @title = "EXEgist User Registration"
  erb :register
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