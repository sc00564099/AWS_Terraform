#!/bin/bash -e

make backend-support.infra
make base.infra
make apps
make docker
make news.infra

