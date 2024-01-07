#!/bin/bash

docker run -it --rm \
  -v "/data/docker/letsencrypt:/etc/letsencrypt" \
  -v "$1:/root/.aws/credentials:ro" \
  certbot/dns-route53 renew --dns-route53

