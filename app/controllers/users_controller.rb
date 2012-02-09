require 'gmail_xoauth'
require 'nokogiri'

class UsersController < ApplicationController
  
  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      redirect_to @user, :notice => "Successfully created user."
    else
      render :new
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      redirect_to @user, :notice  => "Successfully updated user."
    else
      render :edit
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to users_url, :notice => "Successfully destroyed user."
  end

  def new_gmail_session
    consumer = get_consumer
    @user = User.find(params[:id])
    next_url = "http://localhost:3000/users/#{params[:id]}/create_gmail_session"
    scope = "https://mail.google.com/ https://www.google.com/m8/feeds/"
    puts "scope: #{scope}"
    request_token = consumer.get_request_token( {:oauth_callback => next_url}, {:scope => scope} )
    session[:oauth_secret] = request_token.secret
    redirect_to request_token.authorize_url
  end

  def create_gmail_session
    @user = User.find(params[:id])
    request_token = OAuth::RequestToken.new(get_consumer, params[:oauth_token], session[:oauth_secret])
    session[:oauth_secret] = nil
    access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    @user.oauth_token  =  access_token.token
    @user.oauth_secret =  access_token.secret
    xml = Nokogiri.XML(access_token.get("https://www.google.com/m8/feeds/contacts/default/full/").body)
    @user.email = xml.at_css('id').content
    puts "#{@user.email}"
    @user.save
    redirect_to :action => :gmail
  end

  def destroy_gmail_session
    reset_session
    flash[:notice] = "You have been logged out"
    redirect_to :action => 'new'
  end

  def gmail
    @user = User.find(params[:id])
    imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
    imap.authenticate('XOAUTH', @user.email,
                      :consumer_key => "hobstr.com",
                      :consumer_secret => "Ex46_y1b_oELupr5pSge9SNq",
                      :token => @user.oauth_token,
                      :token_secret => @user.oauth_secret
                      )
    @user.inbox_size = imap.status('INBOX', ['MESSAGES'])['MESSAGES']
    @user.save
    imap.examine('INBOX')
    flash[:notice] = imap.fetch(1..10, "BODY[HEADER.FIELDS (SUBJECT)]")
    render :show
  end

private
 
  def get_consumer
    require 'oauth/consumer'
    consumer = OAuth::Consumer.new("hobstr.com", "Ex46_y1b_oELupr5pSge9SNq",
                                   {
                                     :site => "https://www.google.com/",
                                     :request_token_path => "/accounts/OAuthGetRequestToken",
                                     :access_token_path => "/accounts/OAuthGetAccessToken",
                                     :authorize_path=> "/accounts/OAuthAuthorizeToken"})                                                                       
  end

end
