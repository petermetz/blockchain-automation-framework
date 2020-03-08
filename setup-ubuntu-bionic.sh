#!/bin/bash

set -x
# microk8s.helm delete --purge flux-local

rm -rf ../vault/*

export VAULT_ADDR='http://10.0.0.2:8200' ;

vault server -config=../config.hcl -log-level=debug &
VAULT_PID=$!
echo "VAULT PID: ${VAULT_PID}"
sleep 2
vault operator init -key-shares=1 -key-threshold=1 -format=json > ./build/vault-init-output.json

VAULT_ROOT_TOKEN="$(cat ./build/vault-init-output.json | jq .root_token --raw-output)"
echo "VAULT_ROOT_TOKEN => $VAULT_ROOT_TOKEN"
sed -i "s/root_token: \".*\"/root_token: \"$VAULT_ROOT_TOKEN\"/g" build/network.yaml

VAULT_UNSEAL_KEY_B64="$(cat ./build/vault-init-output.json | jq .unseal_keys_b64[0] --raw-output)"
echo "VAULT_UNSEAL_KEY_B64 => $VAULT_UNSEAL_KEY_B64"

export VAULT_TOKEN=$VAULT_ROOT_TOKEN;
vault operator unseal $VAULT_UNSEAL_KEY_B64
vault secrets enable -version=1 -path=secret kv

microk8s.reset --destroy-storage
microk8s.status --wait-ready
microk8s.enable rbac
microk8s.status --wait-ready
microk8s.enable dns
microk8s.status --wait-ready
microk8s.enable storage
microk8s.status --wait-ready
microk8s.enable helm
microk8s.status --wait-ready

microk8s.kubectl delete clusterrolebinding flux-local
microk8s.kubectl delete clusterrole flux-local

docker run -v $(pwd):/home/blockchain-automation-framework/ hyperledgerlabs/baf-build || kill $VAULT_PID