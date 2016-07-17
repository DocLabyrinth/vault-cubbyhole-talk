require 'bundler/setup'
require 'alphanumeric_random'
require_relative 'init'
require_relative 'vault_connector'

temp_token_filename = AlphanumericRandom.generate(length: 64)

REDIS.rpush(Global.settings[:redis][:queue], temp_token_filename)
LOGGER.info("Sent a request for credentials using filename: #{temp_token_filename}")

vault_connector = VaultConnector.new

attempt = 0
perm_token = nil

begin
  temp_token = File.read("#{Global.settings[:temp_token_path]}/#{temp_token_filename}")
  LOGGER.info("temp: #{temp_token}")
  perm_token = vault_connector.fetch_perm_token(temp_token)
  LOGGER.info("Fetched permanent token from cubbyhole successfully")
  LOGGER.info("perm: #{perm_token}")
rescue Errno::ENOENT
  attempt += 1
  LOGGER.info("Temp token not available yet, waiting #{attempt * 0.5} seconds")
  sleep attempt * 0.5
  retry
end

vault_client = Vault::Client.new(
  address: Global.settings[:vault][:url],
  token: perm_token
)

puts "got these secrets back:"
puts vault_client.get("/v1/secret/my-test-app/secrets")[:data].to_yaml
