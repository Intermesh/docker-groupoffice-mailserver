#!/bin/bash
set -e
docker login
docker buildx build --push --platform linux/amd64,linux/arm64 --no-cache . -t intermesh/groupoffice-mailserver:latest

#docker push intermesh/groupoffice-mailserver:latest
