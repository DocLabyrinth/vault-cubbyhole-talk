# Digital Ocean Vault Example

This is some hastily tapped out example code to accompany a talk I gave on
using Hashicorp Vault on DigitalOcean. Unfortunately I wasn't able to completely
finish the example but the scripts here may still be useful as a rough outline
of the approach.

If you want to try this out locally, it should work if you spin up Vault using
the docker-compose.yml file in the root of this repo then follow these steps:

* in this folder, copy config.yml.example to config.yml and replace 'XXX' with a valid digitalocean token with read permissions
* run ./register-policies.sh in the root of this repo, it will set up the Vault policies and give you a token to put in the watcher_token key of config.yml
* run watcher.rb
* start a new digitalocean droplet

watcher.rb looks for the private ip of new droplets which start up (always avoid
having things internet-facing unless they need to be :P) and will request a temp
token from Vault and try to push it to the instance using an HTTP request. Here
is where the example is incomplete: a locally running watcher.rb can't connect
to a droplet's private ip :( In reality, watcher.rb, the sinatra app and Vault
would all be running on digitalocean and would be able to reach each other via
private ip addresses. I sadly didn't have time to get it working, but if you
manage it, let me know :)

#### In this folder:

* [watcher.rb](watcher.rb) - A script which watches for new droplets and uses the the 'pushing' approach to distributing tokens [described in Vault's docs](https://www.hashicorp.com/blog/vault-cubbyhole-principles.html)
* [app.rb](app.rb) - A sinatra app with an endpoint which expects a request which allows a Vault temporary token to be pushed to it
* [vault_connector.rb](vault_connector.rb) - some functions to handle fetching tokens and wrapping responses from Vault
