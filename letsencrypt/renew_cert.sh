#!/bin/bash

docker run -it --rm \
  -v "/etc/letsencrypt:/etc/letsencrypt" \
  -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
  -v "$1:/root/.aws/credentials:ro" \
  certbot/dns-route53 renew --dns-route53

