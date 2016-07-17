require_relative 'init'
require_relative 'vault_connector'

LOGGER.info("Using #{Global.environment} environment")

vault = VaultConnector.new

loop do
  sleep 1
  filename = REDIS.lpop(Global.settings[:redis][:queue])
  next unless filename

  LOGGER.info("Got a credential request message: #{filename}")
  temp_token = vault.get_temp_token("application")

  out_path = "#{Global.settings[:temp_token_path]}/#{filename}"
  File.open(out_path, "w") do |f|
    f.write(temp_token)
  end

  LOGGER.info("Wrote a temp token to file: #{out_path}")
end
