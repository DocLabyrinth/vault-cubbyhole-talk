require 'semantic_logger'
require 'vault'

class VaultConnector
  def initialize(address, logger, token)
    vault_address = address || Global.settings[:vault][:url] || ENV['VAULT_URL']
    @logger = logger
    @token = token
    puts "tok: #{@token}"

    @logger.info("Using vault server at address: #{vault_address}")
    @vault_address = vault_address
  end

  # Requests an access token for a given role. By using Vault's
  # response-wrapping feature, the token is not returned directly
  # but stored in the cubbyhole secret back-end. A single-use token
  # with a short TTL is returned which can later be used to retrieve
  # the real token.
  #
  # @param for_role [String] The role to create the access token for
  # @param temp_token_ttl [String] The temp token's time to live (e.g. 30s, 2m, 1h)
  # @param perm_token_opts [String] Additional options to pass to Vault when creating the access token
  # @return [String] The temporary single-use token which allows access to the real token
  def get_temp_token(for_role, temp_token_ttl = "2m", perm_token_opts = {})
    perm_token_opts = perm_token_opts.merge({
      ttl: "10m",
      renewable: false
    })

    @logger.info(
      "Attempting to create token for role: #{for_role} - #{perm_token_opts.inspect}"
    )

    vault = Vault::Client.new(
      address: @vault_address,
      token: @token
    )

    response = vault.post(
      "/v1/auth/token/create/#{for_role}",
      perm_token_opts.to_json,
      {"X-Vault-Wrap-TTL" => temp_token_ttl}
    )

    token = response[:wrap_info][:token]

    @logger.info("Successfully created temp token with TTL: #{temp_token_ttl}")

    token
  end

  # Retrieves a permanent access token previously created and wrapped
  # by the get_temp_token function
  #
  # @param temp_token [String] A temporary token returned from get_temp_token
  # @return [String] The permanent token which can be used to authenticate with vault
  def fetch_perm_token(temp_token)
    # grab the original create-token response from the cubbyhole
    # using the supplied single-use token
    vault = Vault::Client.new(
      address: @vault_address,
      token: temp_token
    )
    wrapped_response = vault.get("/v1/cubbyhole/response")

    response = JSON.parse(wrapped_response[:data][:response])
    response["auth"]["client_token"]
  end
end
