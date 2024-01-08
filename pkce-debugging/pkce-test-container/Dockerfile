FROM golang:1.17

WORKDIR /app

COPY index.html server.go /app/

RUN go build server.go

EXPOSE 8080

CMD ["./server"]
