#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# register all the policies using the Vault CLI tool
# from within the container
for x in $(ls "$CURRENT_DIR/vault/policies/")
do
  docker-compose exec vault vault policy-write $(echo $x|sed -e 's/\.hcl//') /policies/$x
done

# setup a role for the token vendor to use
docker-compose exec vault vault write auth/token/roles/application allowed_policies=application

# put some stuff in the store for the application to read
docker-compose exec vault vault write secret/my-test-app/secrets test1="I am a secret" test2="I am also a secret"

echo "Pass this token to the token-vendor:"
docker-compose exec vault vault token-create -policy="token-vendor" |head -n 3 |tail -n 1
