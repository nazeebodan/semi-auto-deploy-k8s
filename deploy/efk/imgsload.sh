#!/bin/bash

docker load < efkdir/elasticsearch.tar
docker load < efkdir/fluentd-elasticsearch.tar
docker load < efkdir/kibana.tar

docker images | grep -E 'elasticsearch|fluentd|kibana'