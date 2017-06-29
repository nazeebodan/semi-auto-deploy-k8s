#!/bin/bash

docker load < dockerdir/k8s-dns-dnsmasq-nanny-amd64.tar
docker load < dockerdir/k8s-dns-kube-dns-amd64.tar
docker load < dockerdir/k8s-dns-sidecar-amd64.tar
docker load < dockerdir/pause-amd64.tar
docker load < dockerdir/pod-infrastructure.tar
docker images