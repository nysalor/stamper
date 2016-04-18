if development?
  require 'sinatra/reloader'
end

require "sinatra/json"

ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  database: 'stamper',
  user: ENV['RAILS_DB_USER'],
  password: ENV['RAILS_DB_PASSWORD']
)

class Stamp < ActiveRecord::Base
end

class User < ActiveRecord::Base
end

before do
  @current_user = User.where(token: params[:token])
end

get '/' do
end

post '/users' do
  if (params[:name] != nil) && (params[:name].length > 0)
    @current_user = User.create name: params[:name]
  end
  json {}
end

helpers do
  def logged_in?
    @current_user != nil
  end

  def shorten(str, max = 20)
    if str.length > max
      "#{str[0..max.to_i]}..."
    else
      str
    end
  end

  def timefmt(time)
    if time
      time.strftime("%Y-%m-%d %H:%M:%S")
    else
      ''
    end
  end
end
