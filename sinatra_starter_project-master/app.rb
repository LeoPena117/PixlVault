require "sinatra"
require 'sinatra/flash'
require 'fileutils'
require "mini_magick"

require_relative "authentication.rb"

#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil

if User.all(administrator: true).count == 0
	u = User.new
	u.email = "admin@admin.com"
	u.password = "admin"
	u.administrator = true
	u.save
end

get "/" do
  erb :home
end

get "/upload" do
  erb :form
end

post '/save_image' do

  @filename = params[:file][:filename]
  file = params[:file][:tempfile]



  current_user.profiletype = File.extname(params[:file][:filename])

  File.open("./public/#{current_user.id}/#{@filename}", 'wb') do |f|
    f.write(file.read)
    image = MiniMagick::Image.open(f)
    image.format "png"
    image.write "PROFILEPIC.png"
  end

  erb :show_image
end

get "/dashboard" do
	authenticate!
  @user = User.first(:id => current_user.id)
	erb :dashboard
end

get "/browse" do
  authenticate!
  @users = User.all
  erb :browse
end

get "/user" do
  authenticate!
  @user = User.first(:id => params[:Id])
  erb :dashboard
end

get "/settings" do
  authenticate!
  @user = User.first(:id => current_user.id)
  if(current_user.profiletype.nil?)
    erb :settings
  else
    @filename =  File.open("./public/#{current_user.id}/PROFILEPIC.#{current_user.profiletype}")
    erb :settings
  end
end

get "/upgrade" do
	authenticate!
	erb :upgrade
end

post "/changeBio" do

  @user = User.first(:id => current_user.id)
  @user.bio = params[:bio]
  @user.save
  erb :settings

end

post "/changeInsta" do

  @user = User.first(:id => current_user.id)
  @user.instagram = params[:insta]
  @user.save
  erb :settings

end

post '/charge' do
	authenticate!
  # Amount in cents
  @amount = 500

  customer = Stripe::Customer.create(
    :email => 'customer@example.com',
    :source  => params[:stripeToken]
  )

  charge = Stripe::Charge.create(
    :amount      => @amount,
    :description => 'Sinatra Charge',
    :currency    => 'usd',
    :customer    => customer.id
  )
  current_user.pro = true
  current_user.save
  erb :charge
end
