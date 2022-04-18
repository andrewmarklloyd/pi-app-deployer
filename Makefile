.PHONY: build test

build:
	GOARCH=arm64 GOARM=5 go build -o bin/pi-app-deployer-server server/*
	GOOS=linux GOARCH=arm GOARM=5 go build -o bin/pi-app-deployer-agent agent/main.go

test:
	go test -v ./...

test-integration:
	GOOS=linux GOARCH=amd64 GOARM=5 go build -o pi-app-deployer-agent agent/main.go
	sudo -E ./test/test-integration.sh

deploy-dev: build
	scp pi-app-deployer-agent pi@${IP}:dev-pi-app-deployer-agent

clean:
	rm -rf bin/
