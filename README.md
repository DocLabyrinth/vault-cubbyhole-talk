# Vault Cubbyhole Example

This repo shows a quick and dirty example of how to use the Cubbyhole secret storage
backend and its associated features provided by [Hashicorp Vault](https://www.vaultproject.io).
The code accompanies a tech talk (further info hopefully coming soon) which
proposes using the security properties of [AWS IAM](https://aws.amazon.com/iam/)
to limit access to an [SQS queue](https://aws.amazon.com/sqs/) and an
[S3 bucket](https://aws.amazon.com/s3/) to a set of instances which share a
given role (and therefore the need for a specific set of secret materials).

This example is intended to be a very rough illustration of the concept to be run
without needing any AWS resources. Redis is used in place of SQS and local files
are used in place of S3 storage.

## Requirements

* docker
* docker-compose
* ruby >= 2.0
* bundler

## Setup

Vault complains if Consul isn't immediately available so bring it up first then
bring up the other services.

```bash
docker-compose up consul
docker-compose up vault redis
./register-policies.sh
```

then within the token-vendor/ directory:

```bash
bundle install
```

## Testing Vault

[token_vendor.rb](token-vendor/token_vendor.rb) is a script which loops and polls
the queue defined [in the config](config/settings.yml). It is an extremely minimal
and rough implementation of the coprocess technique described in Hashicorp's
[cubbyhole auth principles blog post](https://www.hashicorp.com/blog/vault-cubbyhole-principles.html)
The process expects a message which contains a long random alphanumeric string.
When it receives a message, it makes a request to create an access token with
permissions to access to the required secrets.  
[Vault's response wrapping](https://www.vaultproject.io/docs/concepts/response-wrapping.html)
is used to return a temporary single-use token which can be used to retrieve the real
token later on. The script writes the single-use token to a file named after
the long alphanumeric string in the directory specified in the config.

[test_app.rb](token-vendor/test-app.rb) simulates how part of an application's
startup process might look when using this technique. It writes a message with a
long and random alphanumeric string to the queue and then waits for a file with
that name to appear. Once the file appears, the script uses its contents (the
single-use token returned by token_vendor.rb) to retrieve its permanent access
token. It can then pull the secrets it needs from Vault.
