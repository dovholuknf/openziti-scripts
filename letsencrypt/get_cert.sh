your_email="clint@openziti.org"
wildcard_url="clint.demo.openziti.org"
sudo docker run -it --rm --name certbot \
  -v "/data/docker/letsencrypt:/etc/letsencrypt" \
certbot/certbot certonly -d "*.${wildcard_url}" \
--manual \
--preferred-challenges dns \
--email "${your_email}" \
--agree-tos
