require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'

configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/secure/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
  erb 'Can you handle a <a href="/secure/place">secret</a>?'
end

get '/login/form' do
  erb :login_form
end

get '/visit' do
  erb :visit
end

get '/contacts' do
  erb :contacts
end

get '/about' do
  erb :about
end

post '/visit' do
  params[:name]
  params[:phone]
  params[:date]
  params[:barber]

  hh = { 
  :name => 'Введіть ім\'я',
  :phone => 'Введіть телефон',
  :date => 'Введіть дату та час'
  }
# для уожної пари ключ-знгачення
  hh.each do |key, value|
    if params[key] == ''
      @error = hh[key]
    return erb :visit
  end
  end
@message = "Вітаю, Ви, #{params[:name]}, записалися! Дата візиту - #{params[:date]}"
  file = File.open './public/visit.txt', "a+"
  file.puts("Ім'я клієнта: #{params[:name]}, номер телефону: #{params[:phone]} Ваш перукар #{params[:barber]}, дата візиту: #{params[:date]}")
  file.close
  erb :visit
end

post '/contacts' do
  params[:message]
  params[:email]
  c_file = File.open './public/contacts.txt', 'a+'
  c_file.puts("Email: #{params[:email]}, текст файлу:\n#{params[:message]} \n")
  c_file.close
  erb :contacts
end

post '/login/attempt' do
  if params['username'] == 'admin'
  session[:identity] = params['username']
  where_user_came_from = session[:previous_url] || '/'
  redirect to where_user_came_from
  else
  session.delete(:identity)
  erb "<div class='alert alert-message'>Login isn't correct, go away!</div>"
  end
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb 'This is a secret place that only <%=session[:identity]%> has access to!'
end
