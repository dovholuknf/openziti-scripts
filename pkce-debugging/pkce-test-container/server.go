package main

import (
	"fmt"
	"html/template"
	"net/http"
	"os"
)

type PageVariables struct {
	Host string
	Path string
	AuthURL string
	TokenURL string
	ClientID string
}

func main() {
	port := getEnv("PORT", "8080")
	authURL := getEnv("AUTH_URL", "http://example.com/auth")
	tokenURL := getEnv("TOKEN_URL", "http://example.com/token")
	clientID := getEnv("CLIENT_ID", "your_client_id")

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		pageVariables := PageVariables{
			Host: r.Host,
			Path: r.URL.Path,
			AuthURL: authURL,
			TokenURL: tokenURL,
			ClientID: clientID,
		}

		tmpl, err := template.ParseFiles("index.html")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		err = tmpl.Execute(w, pageVariables)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	})

	fmt.Printf("Server listening on port %s...\n", port)
	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		fmt.Println(err)
	}
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
