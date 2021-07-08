require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def get_db
  db = SQLite3::Database.new 'barbershop.db'
  db.results_as_hash = true
  return db
end

def save_form_data_to_database
  db = get_db
  db.execute 'INSERT INTO Users (username, phone, datestamp, barber, color)
  VALUES (?, ?, ?, ?, ?)', [@username, @phone, @datetime, @barber, @color]
  db.close
end

def c_users
  db = get_db
  db.execute 'CREATE TABLE IF NOT EXISTS "Users"
    (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "username" TEXT,
      "phone" TEXT,
      "datestamp" TEXT,
      "barber" TEXT,
      "color" TEXT
    )'
    db.close
end

def c_barbers
  db = get_db
  db.execute 'CREATE TABLE IF NOT EXISTS "Barbers"
    (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "barber" TEXT
    )'
  # db.execute 'insert into Barbers (barber) Select "Walter White"   Where not exists(select barber from Barbers where barber="Walter White")'
  # db.execute 'insert into Barbers (barber) Select "Jessie Pinkman" Where not exists(select barber from Barbers where barber="Jessie Pinkman")'
  # db.execute 'insert into Barbers (barber) Select "Gus Fring"      Where not exists(select barber from Barbers where barber="Gus Fring")'

  db.close
end

def is_barber_exists? db, name
  db.execute('select * from Barbers where barber=?', [name]).length > 0
end

def seed_db db, barbers
  barbers.each do |barber|
    if !is_barber_exists? db, barber
      db.execute 'insert into Barbers (barber) values (?)', [barber]
    end
  end
end

before do
  db = get_db
  @barbers =  db.execute 'select * from Barbers'
end
configure do
  db = get_db
  enable :sessions

  c_users
  c_barbers

  seed_db db, ['Walter White', 'Jessie Pinkman', 'Gus Fring', 'Danylko Gigi',]
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
  @username=params[:name]
  @phone=params[:phone]
  @datetime=params[:date]
  @barber=params[:barber]
  @color=params[:color]

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
  file.puts("Ім'я клієнта: #{@username}, номер телефону: #{@phone}, Ваш перукар #{@barber}, колір волосся #{@color}, дата візиту: #{@datetime}!")
  file.close

  save_form_data_to_database
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

get '/showusers' do
  
db = get_db
@results =  db.execute 'select * from Users order by id desc'

erb :showusers
end