#!/bin/sh

set -e

if [ $(kind get clusters | wc -l) -eq 0 ]; then
  echo no cluster;
  cd kind && sh run-cluster.sh && cd -
  rm -f terraform/*.tfstate*
fi

if kubectl config current-context | grep -e "^kind"; then
  echo "already using kind cluster"
else
  echo "please point kubectl to right cluster"
  exit 1
fi

kubectl apply -f k8s

echo ""
echo "sleeping for 15s to let kubernetes settle"
sleep 15

cd terraform && sh run-terraform.sh && cd -

skaffold run

sleep 2
kubectl logs -l app=vault-kubernetes-auth -f