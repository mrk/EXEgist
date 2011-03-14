require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-types'
#require 'rack-flash'

module Sinatra::Partials
  def partial(template, *args)
    template_array = template.to_s.split('/')
    template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
    options = args.last.is_a?(Hash) ? args.pop : {}
    options.merge!(:layout => false)
    if collection = options.delete(:collection) then
      collection.inject([]) do |buffer, member|
        buffer << erb(:"#{template}", options.merge(:layout =>
        false, :locals => {template_array[-1].to_sym => member}))
      end.join("\n")
    else
      erb(:"#{template}", options)
    end
  end
end

helpers Sinatra::Partials

# enable sessions (for login/cookies)
enable :sessions
#use Rack::Flash

class String
  def monkeyparse
    # ary = self.split(/([^\.\?\!]+[\.\?\!])/)
    ary = self.gsub(/\n/,"</p><p>").split(/([^\.\?\!]+[\.\?\!])/)
    ary.delete("")
    sentences = Array.new
    str = ""
    for i in 0..ary.size-1
      next if ary[i].size == 0 || ary[i] =~ /^\s*$/
      str << ary[i]
      next if str =~ /Mr|Mrs|Ms|Dr|Mt|St\.$/
      if (i < ary.size-1)
        next if ary[i] =~ /[A-Z]\.$/
        next if ary[i+1] =~ /^\s*[a-z]/
      end
      if ary[i+1] =~ /^\"/
        str << '"'
        ary[i+1].sub!(/^\"/,"")
      elsif ary[i+1] =~ /^\)/
        str << ')'
        ary[i+1].sub!(/^\)/,"")
      end
      sentences << str.sub(/^\s+/,"")
      str = ""
    end
    sentences
  end
end

# helpers can be called inside any of the main methods
helpers do  

  # Check to see if a user is logged in
  def logged_in?
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
  #DataMapper.setup(:default, "mysql://#{Dir.pwd}/exegist")
  #SQL ISSUE, NEED HELP
end

configure :production do
  DataMapper::setup(:default, ENV['DATABASE_URL'])
end


class User
  include DataMapper::Resource
  
  property :id,         Serial
  property :username,   String, :required => true, :unique => true
  
  has n, :comments #how to pull this off...add comment_id?
end

class Comment
  # replace all instances of TestComment w Comment
  include DataMapper::Resource
  
  #belongs_to :paper
  #belongs_to :user
  
  property :id,           Serial
  property :user_id,      String
  # property :comment,      Text   #replaced with:
  property :body,         Text # 
  property :sentence_id,  Integer
  property :paper_id,     Integer
  property :created_at,   DateTime
  # the following two properties replace :paper_id
  property :parent_type,  String
  property :parent_id,    Integer
  
  #A COMMENT CAN HAVE COMMENTS
  
  #belongs_to, :user, 
  #belongs_to, :paper, 
  #belongs_to, :parent_id
  
  # finds a comment's parent, regardless of type
  def parent
    Kernel.const_get(parent_type).get(parent_id)
  end
  
  # specifies whether a comment is primary (top-level) or not
  def primary?
    if self.parent_type = "Paper"
      true
    else
      false
    end
  end
  
  # # also defined for the Paper class
  #  def comments
  #    Comment.all(
  #      :parent_type => "Comment",
  #      :parent_id => self.id
  #    )
  #  end

  # --GREG'S EXAMPLE CODE--
    # @parent = Paper.get(params[:paper_id])
    #   @parent = Comment.get(params[:comment_id])
    #   Comment.create :parent_id => @parent.id, :parent_type => @parent.class.to_s
  
end

class Paper
  include DataMapper::Resource
  
  property :id,         Serial
  property :body,       Text
  property :title,      String
  property :author,     String
  
  # also defined for the Comment class
  def comments
    Comment.all(
      :parent_type => "Paper",
      :parent_id => id
    )
  end
  
end


configure :development do
  #DataMapper .auto_upgrade!
  DataMapper .auto_migrate!
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
  @newpaper = Paper.new(:title => params[:title], :author => params[:author], :body => params[:body])
  if @newpaper.save
    redirect '/papers/' + @newpaper.id.to_s
  else
    "sorry, did not save"
  end
end

get '/papers/:id' do
  @paper = Paper.get(params[:id]) # notify david in case of change
  @paperArray = @paper.body.monkeyparse
  @all_comments = Comment.all(:paper_id => @paper.id)
  #for commentArray in @all_comments
   # @commentGet = @all_comments.get(params[:id])
  #  @commentSentenceSplit = commentArray.body.split('.')
  #end
  
  ###
  #@commentArray = c.body.split for c in @allcomments
  ###
  
  # @all_comments = Comment.all(:paper_id => @paper.id) # <-- old way
  session["current_paper"] = @paper.id.to_s
  authorize!  
  erb :paper
end

post '/login' do
  @user = User.first_or_create(:username => params[:username])
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

get '/newcomment/:sentence_id&parent_type=:parent_type&parent_id=:parent_id' do
  # replaces @paperpage
  #@myparent = params[:parent_id]
  #@myparenttype = params[:parent_type]
  erb :comment, :layout => false
end

post '/receivedcomment' do
  @comment = Comment.new(:user_id =>params[:username],:paper_id =>params[:paper_id], :body =>params[:comment], :sentence_id =>params[:sentence_id], :parent_id => params[:parent_id], :parent_type => params[:parent_type])
  
  @commentArray = @comment.body.monkeyparse
  @newbody = ''
  #GIVE EACH SENTENCE AN ID
  @theparentid = Comment.last.id.to_i + 1
  @commentArray.each_with_index do |sentence, index|
    @newbody = @newbody + '<a href="#" class="clickable" id="' + index.to_s + '" name="' + @theparentid.to_s + '" title="Comment">' + sentence + '</a>' 
  end  
  @comment.body = @newbody
  
  #@comment.paper_id = params[]
  #@comment.parent_id = 
  #@comment.parent_type = 
  #:username =>params[:username], :paper_id => params[:paper_id]
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
  @mycomments = Comment.all(:order => [:created_at.desc])
  
  erb :showcomtest, :layout => false
end

#TEST FOR SEEING ALL THE PAPERS
get '/showpapertest' do
  @mypaper = Paper.all
  erb :showpapertest
end

#GREG'S WAY OF PARSING THE SENTENCES SERVER SIDE
# also add:   - generate sequential unique ids
#             - put each one in a db
#             -- each entry associated with 
#             - each span given a set of classes, eg. <span class
#<% for sentence in @mything.split(".") %><span class="aSentence"><%= sentence %></span><% end %>