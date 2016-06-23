require 'rubygems'

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
      time = stamp.stamp_at
      time.localtime
      if stamp.action == 'in'
        unless stamps[time.mday]
          stamps[time.mday] = { in: time }
        end
      elsif stamp.action == 'out'
        stamps[time.mday] ||= {}
        stamps[time.mday][:out] = time
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
  if params[:token] && params[:secret]
    @current_user = User.where(token: params[:token], secret: Digest::MD5.hexdigest(params[:secret])).first
  end
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
        @secret = SecureRandom.urlsafe_base64(32)
        @current_user.secret = Digest::MD5.hexdigest(@secret)

        if @current_user.save
          json({
                 success: true,
                 user: {
                   id: @current_user.id,
                   name: @current_user.name,
                   token: @current_user.token,
                   secret: @secret
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
    @stamp.stamp_at = assigned_time if assigned_time
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
    @stamp.stamp_at = assigned_time if assigned_time
    if @stamp.save
      succeed
    else
      failed
    end
  else
    failed
  end
end

get '/csv' do
  if @current_user
    json({
           csv: csv
         })
  else
    failed
  end
end

get '/csv/:year/:month' do
  if @current_user
    json({
           csv: csv(params[:year], params[:month])
         })
  else
    failed
  end
end

get '/timecount' do
  if @current_user
    json timecount
  else
    failed
  end
end

get '/timecount/:year/:month' do
  if @current_user
    json timecount(params[:year], params[:month])
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

  def assigned_time
    if params[:time]
      Time.parse params[:time]
    else
      nil
    end
  end

  def stamps(year, month)
    Stamp.where(user_id: @current_user.id).list(year, month.to_i)
  end

  def csv(year = Time.now.year, month = Time.now.month)
    stamps(year, month).map.with_index { |stamp, idx|
      if idx > 0
        date = [year, month, idx].join('/')
        if stamp
          [date, timefmt(stamp[:in]), timefmt(stamp[:out])].join(',')
        else
          [date, '', ''].join(',')
        end
      else
        nil
      end
    }.compact
  end

  def timecount(year = Time.now.year, month = Time.now.month)
    day_count = 0
    count_sec = stamps(year, month).map.with_index { |stamp, idx|
      if idx > 0
        if stamp && stamp[:out] && stamp[:in]
          day_count += 1
          stamp[:out] - stamp[:in]
        else
          0
        end
      else
        nil
      end
    }.compact.sum

    (hour, sec) = count_sec.divmod(3600)

    {
      timecount: "#{hour}:#{sec.quo(60).floor.to_s.rjust(2, '0')}",
      daycount: day_count
    }
  end
  
  def succeed
    json({ success: true })
  end

  def failed
    json({ success: false })
  end
end
