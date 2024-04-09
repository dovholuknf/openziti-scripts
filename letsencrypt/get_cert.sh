exitWithError() {
    echo -e "Error: $1"
    exit 1
}

if [ "$#" -lt 2 ]; then
    exitWithError "Three parameters are required. \
    \n       The first parameter should be the email you want to be notified when the cert is expiring \
    \n       The second is the domain you want a wildcard cert for \
    \n       The third is the location of your aws creds\n"
fi

your_email=$1
wildcard_url=$2

sudo docker run -it --rm --name certbot \
  -v "/data/docker/letsencrypt:/etc/letsencrypt" \
  -v "$3:/root/.aws/credentials:ro" \
  certbot/certbot certonly -d "*.${wildcard_url}" \
  --manual \
  --preferred-challenges dns \
  --email "${your_email}" \
  --agree-tos

your_email=clint@openziti.org
local_dir=/data/docker/letsencrypt
aws_creds=/home/ubuntu/.aws/credentials

docker run -it --rm --name certbot \
    -v "${aws_creds}:/root/.aws/credentials:ro" \
    -v "${local_dir}/letsencrypt:/etc/letsencrypt" \
    certbot/dns-route53 certonly \
    -d "*.${wildcard_url}" \
    -m "${your_email}" \
    --dns-route53 \
    --non-interactive \
    --agree-tos \
    --server https://acme-v02.api.letsencrypt.org/directory
