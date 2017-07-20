#!/bin/bash


#env
baseDir="$1"

cd ${baseDir}/deploy/dashboard
kubectl create -f . 