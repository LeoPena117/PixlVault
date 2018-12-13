require 'sinatra'
require_relative "user.rb"

enable :sessions

set :session_secret, 'super secret'

get "/login" do
	erb :"authentication/loginpage"
end


post "/process_login" do
	email = params[:email]
	password = params[:password]

	user = User.first(email: email.downcase)

	if(user && user.login(password))
		session[:user_id] = user.id
		redirect "/"
	else
		erb :"authentication/invalid_login"
	end
end

get "/logout" do
	session[:user_id] = nil
	redirect "/"
end

get "/sign_up" do
	if current_user.nil?
		erb :"authentication/sign_up"
	else
		erb :home
	end
end


post "/register" do
	email = params[:email]
	password = params[:password]
	username = params[:username]
	passwordconf = params[:passwordconf]
	bio = params[:bio]

	if (!(email.nil?&&password.nil?&&bio.nil?&&username.nil?)&&(password==passwordconf))
		u = User.new
		u.email = email.downcase
		u.password =  password
		u.username = username
		u.bio = bio
		u.save

		session[:user_id] = u.id
		erb :home
	else
		flash[:error]="Incorrect fields"
		erb :"authentication/sign_up"
	end
end

#This method will return the user object of the currently signed in user
#Returns nil if not signed in
def current_user
	if(session[:user_id])
		@u ||= User.first(id: session[:user_id])
		return @u
	else
		return nil
	end
end

#if the user is not signed in, will redirect to login page
def authenticate!
	if !current_user
		redirect "/login"
	end
end