ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  database: ENV['STAMPER_DB_NAME'] || 'stamper',
  host: ENV['STAMPER_DB_HOST'] || 'localhost',
  username: ENV['STAMPER_DB_USER'],
  password: ENV['STAMPER_DB_PASSWORD']
)
