#!/usr/bin/env bash

eval $(minikube docker-env --shell bash) \
    && ./scripts/build_elm.sh \
    && faas-cli remove elm-openfaas-example -g http://$(minikube ip):31112 \
    && sleep 1 && faas-cli build -f elm-openfaas-example.yml \
    && sleep 1 && faas-cli deploy -f elm-openfaas-example.yml \
    && sleep 2 && kubectl scale --current-replicas=1 --replicas=0 deployment/elm-openfaas-example \
    && sleep 3 && ./scripts/patch_local_deployment.sh \
    && sleep 5 && kubectl scale --current-replicas=0 --replicas=1 deployment/elm-openfaas-example
