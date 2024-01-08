exitWithError() {
    echo -e "Error: $1"
    exit 1
}

if [ "$#" -lt 2 ]; then
    exitWithError "Two parameters are required. \
    \n       The first parameter should be the email you want to be notified when the cert is expiring \
    \n       The second is the domain you want a wildcard cert for\n"
fi

your_email=$1
wildcard_url=$2

sudo docker run -it --rm --name certbot \
  -v "/data/docker/letsencrypt:/etc/letsencrypt" \
  -v "$1:/root/.aws/credentials:ro" \
  certbot/certbot certonly -d "*.${wildcard_url}" \
  --manual \
  --preferred-challenges dns \
  --email "${your_email}" \
  --agree-tos
