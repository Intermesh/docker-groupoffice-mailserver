#!/bin/bash
set -e
docker login

docker pull debian:bookworm-slim

docker buildx build --push --platform linux/amd64,linux/arm64 --no-cache . -t intermesh/groupoffice-mailserver:latest -t intermesh/groupoffice-mailserver:6.8

#docker push intermesh/groupoffice-mailserver:latest
