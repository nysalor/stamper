require 'sinatra'
require 'active_record'
require 'sinatra/activerecord'
require 'mysql2'
require 'sinatra/json'
require './database.rb'

require 'sinatra/reloader' if development?

class Stamp < ActiveRecord::Base
  def self.list(year = Time.now.year, month = Time.now.month)
    start_time = Time.local(year, month, 1)
    end_time = Time.local(year, month == 12 ? 1 : month + 1, 1)
    stamps = []
    of_range(start_time, end_time).order(:stamp_at).each do |stamp|
      if stamp.action == 'in'
        unless stamps[stamp.stamp_at.mday]
          stamps[stamp.stamp_at.mday] = { in: stamp.stamp_at }
        end
      elsif stamp.action == 'out'
        stamps[stamp.stamp_at.mday] ||= {}
        stamps[stamp.stamp_at.mday][:out] = stamp.stamp_at
      end
    end
    stamps
  end

  def self.of_range(start_time, end_time)
    where('stamp_at > ? and stamp_at < ?', start_time, end_time)
  end
end

class User < ActiveRecord::Base
end

before do
  @current_user = User.where(token: params[:token], secret: params[:secret]).first
end

get '/' do
  succeed
end

post '/users' do
  unless @current_user
    if (params[:name] != nil) && (params[:name].length > 0)
      if User.where(name: params[:name]).empty?
        @current_user = User.new name: params[:name]
        @current_user.token = SecureRandom.urlsafe_base64
        @current_user.secret = SecureRandom.urlsafe_base64(32)
        if @current_user.save
          json({
                 success: true,
                 user: {
                   id: @current_user.id,
                   name: @current_user.name,
                   token: @current_user.token,
                   secret: @current_user.secret
                 }
               })
        else
          failed
        end
      else
        json({
               success: false,
               message: "name: `#{params[:name]}` has already taken."
             })
      end
    else
      failed
    end
  end
end

post '/in' do
  if @current_user
    @stamp = Stamp.new user_id: @current_user.id, action: 'in', stamp_at: Time.now
    if @stamp.save
      succeed
    else
      failed
    end
  else
    failed
  end
end

post '/out' do
  if @current_user
    @stamp = Stamp.new user_id: @current_user.id, action: 'out', stamp_at: Time.now
    if @stamp.save
      succeed
    else
      failed
    end
  else
    failed
  end
end

get '/csv/:year/:month' do
  if @current_user
    json({
           csv: Stamp.where(user_id: @current_user.id).list(params[:year].to_i, params[:month].to_i).map.with_index { |stamp, idx|
             if idx > 0
               date = [params[:year], params[:month], idx].join('/')
               if stamp
                 [date, timefmt(stamp[:in]), timefmt(stamp[:out])].join(',')
               else
                 [date, '', ''].join(',')
               end
             else
               nil
             end
           }.compact
         })
  else
    failed
  end
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
      time.localtime.strftime("%H:%M")
    else
      ''
    end
  end

  def succeed
    json({ success: true })
  end

  def failed
    json({ success: false })
  end
end
