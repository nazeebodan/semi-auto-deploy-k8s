#!/bin/bash

#env
baseDir="$1"
nodesName=192.168.0.157

kubectl get node

#ssh kube-node2  tar -zxvf ${baseDir}/deploy/efk/efkdir.tgz && sh ${baseDir}/deploy/efk/imgsload.sh

ssh kube-node2 sh ${baseDir}/deploy/efk/imgsload.sh


cd ${baseDir}/deploy/efk
kubectl label nodes ${nodesName} beta.kubernetes.io/fluentd-ds-ready=true
kubectl create -f .
for i in {1..10}
do
   echo -ne  "===>\b"
   sleep 0.5
done
echo ""
kubectl get pods -n kube-system|grep -E 'elasticsearch|fluentd|kibana'
sleep 2
kubectl get service -n kube-system|grep -E 'elasticsearch|kibana'


#kubectl logs kibana-logging-3757371098-cldln -n kube-system -f