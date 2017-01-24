#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VAULT_CMD="docker-compose exec vault vault"
VAULT_ADDR="http://localhost:8200"

# register all the policies using the Vault CLI tool
# from within the container
for x in $(ls "$CURRENT_DIR/vault/policies/")
do
  $VAULT_CMD policy-write -address=$VAULT_ADDR $(echo $x|sed -e 's/\.hcl//') /policies/$x
done

# setup a role for the token vendor to use
$VAULT_CMD write -address=$VAULT_ADDR auth/token/roles/application allowed_policies=application

# put some stuff in the store for the application to read
$VAULT_CMD write -address=$VAULT_ADDR secret/my-test-app/secrets test1="I am a secret" test2="I am also a secret"

echo "Pass this token to the token-vendor:"
$VAULT_CMD token-create -address=$VAULT_ADDR -policy="token-vendor" |head -n 3 |tail -n 1
