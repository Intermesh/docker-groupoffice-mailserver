#!/bin/bash
set -e
docker build --no-cache . -t intermesh/groupoffice-mailserver:latest
docker login
docker push intermesh/groupoffice-mailserver:latest
