#!/bin/bash

#env
baseDir="$1"

cd ${baseDir}/deploy/dns
kubectl create -f .