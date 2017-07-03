#!/bin/bash
echo "***************begin to clean master's config ****************"
echo "step:------> stop kube-apiserver kube-controller-manager kube-scheduler service "
sleep 1
systemctl stop kube-apiserver kube-controller-manager kube-scheduler
echo "step:------> remove kube-apiserver,kube-controller-manager,kube-scheduler config "
sleep 1
rm -rf /var/run/kubernetes
rm -rf /lib/systemd/system/{kube-apiserver,kube-controller-manager,kube-scheduler}.service
rm -rf /usr/bin/{kube-apiserver,kube-controller-manager,kube-scheduler}
echo "step:------> remove kubernetes .kube .ssh directory"
sleep 1
rm -rf /etc/kubernetes/ssl
rm -rf /etc/kubernetes
rm -rf ~/.kube
echo "step:------> stop and remove etcd service&&config "
sleep 1
systemctl stop etcd
rm -rf /var/lib/etcd
rm -rf /usr/lib/systemd/system/etcd.service
rm -rf /usr/bin/etcd
echo "step:------> stop and remove flannel service&&config "
sleep 1
systemctl stop flanneld
rm -rf /var/run/flannel/
rm -rf /usr/bin/flanneld
echo "step:------> clean network config"
sleep 1
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat
ip link del flannel.1
echo "***************clean master's config finished!****************"