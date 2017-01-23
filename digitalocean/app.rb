require 'sinatra'
require 'json'
require 'yaml'
require_relative './vault_connector'

token = nil

this_dir = File.expand_path(File.dirname(__FILE__))

CONFIG = YAML.load_file(File.join(this_dir, 'config.yml'))
vault_addr = CONFIG.fetch('vault', {}).fetch('address', nil) || ENV['VAULT_ADDR'] || 'http://127.0.0.1:8200'
VAULT = VaultConnector.new(vault_addr, Logger.new(STDOUT), CONFIG['vault']['watcher_token'])

ALLOWED_SOURCE_IPS = ENV
  .fetch('ALLOWED_SOURCE_IPS', '127.0.0.1')
  .split(',')
  .map{|ip| ip.strip}

get '/' do
  halt 503 unless token
  'Put this in your pipe & smoke it!'
end

post '/put-token' do
  halt 403 unless ALLOWED_SOURCE_IPS.include?(request.ip)
  data = JSON.parse(request.body.read)
  token = VAULT.fetch_perm_token(data['temp_token'])
end
