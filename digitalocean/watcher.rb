require 'yaml'
require 'json'
require 'semantic_logger'
require 'droplet_kit'
require 'faraday'

require_relative 'vault_connector'

this_dir = File.expand_path(File.dirname(__FILE__))

SemanticLogger.default_level = :debug
SemanticLogger.add_appender(io: $stdout, level: :trace, formatter: :color)

LOG = SemanticLogger['Watcher']
CONFIG = YAML.load_file(File.join(this_dir, 'config.yml'))
DO_CLIENT = DropletKit::Client.new(access_token: CONFIG['digitalocean']['token'])

vault_addr = CONFIG.fetch('vault', {}).fetch('address', nil) || ENV['VAULT_ADDR'] || 'http://127.0.0.1:8200'
VAULT = VaultConnector.new(vault_addr, LOG, CONFIG['vault']['watcher_token'])

tag2policy = {
  'web': 'application'
}

sent_to_ids = Set.new()

loop_delay = 5
app_port = 4567

loop do
  begin
    sleep loop_delay

    begin
      droplet_infos = DO_CLIENT.droplets.all.map do |droplet|
        {
          id: droplet.id,
          ip: droplet.private_ip,
          tags: droplet.tags,
        }
      end

      droplet_infos.each{|d| p d}

      # some mock output for testing locally
      # droplet_infos = [
      #   {
      #     id: '123213',
      #     ip: '127.0.0.1',
      #     tags: ['web']
      #   }
      # ]
    rescue Faraday::ClientError => e
      LOG.error('Droplet info request failed', class: e.class, message: e.message)
      next
    end

    droplet_infos
      .reject{ |info| info[:tags].empty? || sent_to_ids.include?(info[:id]) }
      .each do |info|
        # Vault tokens can only have one assigned role policy, for simplicity go
        # with the first one which maps to a policy
        policy = info[:tags].map{ |tag| tag2policy[tag.to_sym] }.compact.first
        LOG.info("New droplet found", info)

        temp_token = VAULT.get_temp_token(policy)
        LOG.debug("Created temp token", info)

        post_url = "http://#{info[:ip]}:#{app_port}/"

        LOG.debug("Posting token to droplet endpoint", url: post_url)

        conn = Faraday.new(:url => post_url)

        begin
          response = conn.post(post_url) do |req|
            req.url '/put-token'
            req.headers['Content-Type'] = 'application/json'
            req.body = {temp_token: temp_token}.to_json
            req.options[:timeout] = 5           # open/read timeout in seconds
            req.options[:open_timeout] = 2      # connection open timeout in seconds
          end
        rescue Faraday::ClientError => e
          LOG.error('Droplet token request failed', class: e.class, message: e.message)
          next
        end

        if !response.success?
          LOG.error("Token post request failed", status: response.status)
          next
        end

        LOG.info("Successfully sent token to droplet", id: info[:id])
        sent_to_ids.add(info[:id])
      end
  rescue RuntimeError => e
    LOG.error('Uncaught error', class: e.class, message: e.message)
    puts e.backtrace.join("\n")
  end
end
