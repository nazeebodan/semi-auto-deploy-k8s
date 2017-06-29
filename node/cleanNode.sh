#!/bin/bash
echo "***************begin to clean node's config ****************"
systemctl stop kubelet kube-proxy docker flanneld
rm -rf /var/lib/kubelet
rm -rf /var/lib/docker
rm -rf /var/run/flannel/
rm -rf /var/run/docker/
rm -rf /usr/lib/systemd/system/{kubelet,docker,flanneld}.service
rm -rf /usr/bin/{kubectl,kubelet,kube-proxy,docker*,flanneld}
rm -rf /etc/kubernetes
rm -rf ~/.kube
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat
ip link del flannel.1
ip link del docker0
echo "***************clean node's config finished!****************"