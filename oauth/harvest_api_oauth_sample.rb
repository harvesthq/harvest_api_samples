#!/usr/bin/env ruby

# This requires the sinatra and httparty gems to work
# In your terminal: gem install sinatra httparty

# To run: ruby harvest_api_oauth_sample.rb

# This sample emulates the typical Authorization Code flow for server-side authorization

# You'll need to change these to match the app you registered at https://platform.harvestapp.com/oauth2_clients
# Running this locally? Make sure you use http://localhost:4567/oauth_redirect for the redirect URL

CLIENT_ID = "su4qX/igjUPcEdYMS/Ialg=="
CLIENT_SECRET = "q8wtCmG0Tz54R7CzditlWSEVJnIG44zQbZxHeL0OD/xbjxExuh2vWBYAWcvCXUCK2J6D4ANvFRIl5sBr0iUB5A=="

# And the rest should now work

begin
  require 'rubygems'
  require 'sinatra'
  require 'httparty'
rescue LoadError => e
  puts "\nYou need to install some gems!"
  puts "gem install sinatra httparty\n\n"
  puts "---- ORIGINAL ERROR ----"
  puts e
  exit
end

REDIRECT_URI = "http://localhost:4567/oauth_redirect"
HARVEST_HOST = "https://api.harvestapp.com"

get '/' do
  erb :index
end

get '/redirect_to_harvest' do
  redirect "#{HARVEST_HOST}/oauth2/authorize?client_id=#{CLIENT_ID}&redirect_uri=#{REDIRECT_URI}&state=optional-csrf-token&response_type=code"
end

get '/oauth_redirect' do
  options = {
    body: {
      code: params[:code],
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      redirect_uri: REDIRECT_URI,
      grant_type: "authorization_code"
    },
    headers: {
      "Content-Type" => "application/x-www-form-urlencoded",
      "Accept" => "application/json"
    }
  }

  @data = HTTParty.post("#{HARVEST_HOST}/oauth2/token", options)
  write_tokens @data['access_token'], @data['refresh_token']

  erb :response
end

get '/authenticated' do
  redirect to('/') unless tokens['access_token']

  options = {
    body: {
      access_token: tokens['access_token']
    },
    headers: {
      "Accept" => "application/json"
    }
  }

  @data = HTTParty.get("#{HARVEST_HOST}/account/who_am_i", options)

  erb :authenticated
end

get '/refresh' do
  options = {
    body: {
      refresh_token: tokens['refresh_token'],
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      grant_type: "refresh_token"
    },
    headers: {
      "Content-Type" => "application/x-www-form-urlencoded",
      "Accept" => "application/json"
    }
  }

  @data = HTTParty.post("#{HARVEST_HOST}/oauth2/token", options)
  write_tokens @data['access_token'], @data['refresh_token']

  erb :response
end

template :layout do
  "<html>
    <head>
      <title>OAuth</title>
    </head>
    <body>
      <h1>OAuth Demo</h1>
      <%= yield %>
    </body>
  </html>"
end

template :index do
  "<a href='/redirect_to_harvest'>Authorize this application to access your Harvest account</a>"
end

template :response do
  "
    <% unless @data['error'] %>
    <h2>Response data</h2>
    <ul>
      <li>Access token: <%= @data['access_token'] %></li>
      <li>Refresh token: <%= @data['refresh_token'] %></li>
    </ul>

    <a href='/authenticated'>See an authenticated call</a>
    <% else %>
    <h2><%= @data['error'] %>: <%= @data['error_description'] %></h2>
    <% end %>
  "
end

template :authenticated do
  "
    <p>Hello! Your Harvest company is called <strong><%= @data['company']['name'] %></strong></p>
    <p>You are <strong><%= @data['user']['first_name'] %> <%= @data['user']['last_name'] %></strong></p>
    <p>This is your avatar: <br><img src='<%= @data['user']['avatar_url'] %>'></p>
    <hr>
    <p><a href='/refresh'>Refresh the token</a> or <a href='/'>go back to the main page</a></p>
  "
end

def tokens
  YAML.load File.read('oauth_tokens.yml')
end

def write_tokens(access_token, refresh_token)
  output = {
    'access_token' => access_token,
    'refresh_token' => refresh_token
  }

  File.open("oauth_tokens.yml", "w") { |file| file.write(YAML.dump(output))  }
end
