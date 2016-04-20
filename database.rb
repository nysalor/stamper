ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  database: 'stamper',
  username: ENV['RAILS_DB_USER'],
  password: ENV['RAILS_DB_PASSWORD']
)
