docker run --rm --name haproxy-sni --net=host \
    -v $(pwd)/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
    haproxy:latest

