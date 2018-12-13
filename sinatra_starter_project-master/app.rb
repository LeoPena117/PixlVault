require "sinatra"
require 'sinatra/flash'
require 'fileutils'
require "stripe"

require_relative "authentication.rb"

#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil

if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

set :publishable_key, "pk_test_TJtBcrtqDRs8zsDRTw78iokb"
set :secret_key, "sk_test_6flurgcdvMeg2XNsyaJ843Sc"

Stripe.api_key = settings.secret_key


class Image
  include DataMapper::Resource

  property :id, Serial
  property :title, String
    property :description, String
    property :name, String
    property :price, Float, :default => 5
    property :user, Integer
end

DataMapper.finalize
User.auto_upgrade!
Image.auto_upgrade!


if User.all(administrator: true).count == 0
	u = User.new
	u.email = "admin@admin.com"
	u.password = "admin"
  u.level = 4
	u.administrator = true
	u.save
end

get "/" do
  erb :home
end

get "/upload" do
  erb :form
end

post '/upload' do
  @filename = params[:file][:filename]
  file = params[:file][:tempfile]

 filepath = "./public/"+current_user.id.to_s

  FileUtils.mkdir_p filepath

  File.open("./public/#{current_user.id}/#{@filename}", 'wb') do |f|
    f.write(file.read)
  end

  i = Image.new
  i.title = params["title"]
  i.description = params["desc"]
  i.name = @filename
  if(params["price"].to_i)
    i.price = params["price"]
  end
  i.user = current_user.id
  i.save

  @user = current_user

  erb :show_image
end

get "/dashboard" do
	authenticate!
  @user = User.first(:id => current_user.id)
  @images = @images = Image.all(:user => current_user.id)
	erb :dashboard
end

get "/browse" do
  authenticate!
  @users = User.all(:order => [:level.desc])
  erb :browse
end

get "/user" do
  authenticate!
  @user = User.first(:id => params[:Id])
  @images = Image.all(:user => params[:Id])
  erb :dashboard
end

get "/settings" do
  authenticate!
  filepath = "./public/"+current_user.id.to_s

  FileUtils.mkdir_p filepath
  @user = User.first(:id => current_user.id)
  erb :settings
end

get "/plans" do
	authenticate!
	erb :plans
end

post "/changeBio" do

  @user = User.first(:id => current_user.id)
  @user.bio = params[:bio]
  @user.save
  erb :settings

end

get "/delete" do
  authenticate!
  i = Image.first(:id => params[:pictureId].to_i)
  i.destroy
  @user = User.first(:id => current_user.id)
  @images = @images = Image.all(:user => current_user.id)
  erb :dashboard
end

get "/buy" do
  @photo = Image.first(:id => params[:pictureId].to_i)
  erb :pay
end
get "/browse" do
	authenticate!
	erb :browse
end

post '/buy' do
	authenticate!
  # Amount in cents
  @image = Image.first(:id => params[:photo])
  @amount = @image.price*100

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
  @user = User.first(:id => @image.user.to_s)
  @user.balance += @image.price/1.2
  @user.save
  @filename = @image.name
  erb :show_image
end

get '/upgrade' do 
  authenticate!
  @u = User.first(:id => current_user.id)
  @plan = params[:plan]
  if params[:plan]=="pro"
    @amount = 15
  elsif params[:plan]=="gold"
    @amount = 29
  end

    erb :upgradepay
end

post '/upgrade' do
  authenticate!
  # Amount in cents
  user = current_user
  if params[:plan]=="pro"
    @amount = 1500
  elsif params[:plan]=="gold"
    @amount = 2900
  end

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

  if params[:plan]=="pro"
    current_user.level = 2
  elsif params[:plan]=="gold"
    current_user.level = 3
  end
    
  current_user.save
  erb :home
end
