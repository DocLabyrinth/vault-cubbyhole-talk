require 'bundler/setup'
require 'redis'
require 'vault'
require 'global'
require 'logger'

LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::INFO

Global.configure do |config|
  config.environment = ENV['TOKEN_VENDOR_ENV'] || "development"
  config.config_directory = "config"
end

LOGGER.info("Connecting to Redis: #{Global.settings[:redis].inspect}")

REDIS = Redis.new(
  :host => Global.settings[:redis][:host],
  :port => Global.settings[:redis][:port],
  :db => Global.settings[:redis][:db],
  :connect_timeout => 1,
  :read_timeout    => Global.settings[:redis][:timeout],
  :write_timeout   => 1
)
