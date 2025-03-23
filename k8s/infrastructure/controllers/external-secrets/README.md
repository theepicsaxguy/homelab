curl -s <https://letsencrypt.org/certs/isrgrootx1.pem> -o isrgrootx1.pem

kubectl create secret generic letsencrypt-ca \
 --from-file=ca.crt=isrgrootx1.pem \
 -n external-secrets --dry-run=client -o yaml | kubectl apply -f -
