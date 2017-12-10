#!/usr/bin/env sh

cat <<EOF | kubectl patch deployment elm-openfaas-example --type merge --patch "
spec:
  template:
    spec:
      containers:
      - name: elm-openfaas-example
        image: elm-openfaas-example
        imagePullPolicy: Never
"
EOF
