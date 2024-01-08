use python to start a server:
* cd to this folder
* `python3 -m http.server 9000`
* open your browser to http://localhost:9000
* make sure your IdP (keycloak?) has
    * valid redirect url: http://localhost:9000/*
	* web origin: http://localhost:9000 or *
* 