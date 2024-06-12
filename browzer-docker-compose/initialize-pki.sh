mkdir -p ${DOCKER_DIR}

openssl req \
  -x509 \
  -newkey rsa:4096 \
  -sha256 \
  -days 3650 \
  -nodes \
  -keyout ${DOCKER_DIR}/${WILDCARD_DNS}.root.key \
  -out ${DOCKER_DIR}/${WILDCARD_DNS}.root.crt \
  -subj "/CN=${WILDCARD_DNS}.root.ca"

openssl req \
  -newkey rsa:4096 \
  -nodes \
  -keyout ${DOCKER_DIR}/${WILDCARD_DNS}.server.key \
  -out ${DOCKER_DIR}/${WILDCARD_DNS}.server.csr \
  -subj "/CN=*.${WILDCARD_DNS}"

cat > ${DOCKER_DIR}/${WILDCARD_DNS}.server.csrconf <<HERE
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[ req_distinguished_name ]
CN = *.${WILDCARD_DNS}

[ v3_altnames ]
subjectAltName = @alt_names
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:false, pathlen:0
keyUsage = critical, digitalSignature, keyCertSign

[ alt_names ]
DNS.1 = *.${WILDCARD_DNS}
DNS.2 = ${WILDCARD_DNS}
HERE

openssl x509 \
  -req \
  -in ${DOCKER_DIR}/${WILDCARD_DNS}.server.csr \
  -CA ${DOCKER_DIR}/${WILDCARD_DNS}.root.crt \
  -CAkey ${DOCKER_DIR}/${WILDCARD_DNS}.root.key \
  -out ${DOCKER_DIR}/${WILDCARD_DNS}.server.crt \
  -days 365 \
  -sha256 \
  -extfile ${DOCKER_DIR}/${WILDCARD_DNS}.server.csrconf \
  -extensions v3_altnames

cp ${DOCKER_DIR}/${WILDCARD_DNS}.server.crt ${DOCKER_DIR}/${WILDCARD_DNS}.server.crt.2171
cp ${DOCKER_DIR}/${WILDCARD_DNS}.server.key ${DOCKER_DIR}/${WILDCARD_DNS}.server.key.2171
sudo chown 2171:2171 ${DOCKER_DIR}/${WILDCARD_DNS}.server*2171

echo " ---- PKI COMPLETE ---- "
echo " "
echo " add this file to your OS or browser trust store:"
echo "   - ${DOCKER_DIR}/${WILDCARD_DNS}.root.crt"
echo " "
echo " ---- PKI COMPLETE ---- "

