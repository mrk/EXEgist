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

end

# sets up DB
configure :development do
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/exegist.db")
  # A MySQL connection:
  #DataMapper.setup(:default, 'mysql://localhost/the_database_name')
end


class User
  include DataMapper::Resource
  
  property :id,         Serial
  property :username,   String, :required => true, :unique => true
  
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
  
  property :id,           Serial
  # property :username,     String
  property :comment,      Text
  property :sentence_id,  Integer
  property :paper_id,     Integer
  property :created_at,   DateTime
  
  # belongs_to :user 
  
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
  session["current_user"] = nil
  @title = "Log in to EXEgist"
  @login = true
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
  @all_comments = TestComment.all(:paper_id => @paper)
  # append <span class="comment">@all_comments.comment</span> where @all_comments.sentence_id == the "id" attribute of .sentence %>	
  # in jQuery, just add the star when you see it the span.
  session["current_paper"] = @paper.id.to_s
  authorize!  
  erb :paper
end

post '/login' do
  @user = User.first_or_create(:username => params[:user])
  session["current_user"] = @user.username
  redirect '/papers/' + session["current_paper"]
  # if @user
  #     session["current_user"] = @user.username
  #     redirect '/papers/' + session["current_paper"]
  # else            
  #     @user = User.new(params[:user])
  #     if @user.save
  #       session["current_user"] = @user.username
  #       redirect '/papers/' + session["current_paper"]
  #     else
  #       redirect '/login'
  #     end
  # end
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

get '/newcomment/:sentence_id&paper_id=:paper_id' do
  @paperpage = params[:paper_id]
  erb :comment, :layout => false
end

post '/receivedcomment' do
  @comment = TestComment.new(:comment =>params[:thecomment], :sentence_id =>params[:sentence_id], :paper_id => params[:paper_id])
  @comment.save
  #  redirect("/fanfic")
  #else
  #end
end

# get '/*' do
#   redirect '/papers/' + session["current_paper"]
# end

#TEST FOR ADDING COMMENTS
get '/showcomtest' do
  @mycomments = TestComment.all(:order => [:created_at.desc])
  erb :showcomtest, :layout => false
end



#GREG'S WAY OF PARSING THE SENTENCES SERVER SIDE
# also add:   - generate sequential unique ids
#             - put each one in a db
#             -- each entry associated with 
#             - each span given a set of classes, eg. <span class
#<% for sentence in @mything.split(".") %><span class="aSentence"><%= sentence %></span><% end %>