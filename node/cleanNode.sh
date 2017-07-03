#!/bin/bash
echo "***************begin to clean node's config ****************"
echo "step:------> stop kubelet kube-proxy docker flanneld service "
sleep 1
systemctl stop kubelet kube-proxy docker flanneld
echo "step:------> remove kubelet kube-proxy docker flannel config "
sleep 1
rm -rf /var/lib/kubelet
rm -rf /var/lib/docker
rm -rf /var/run/flannel/
rm -rf /var/run/docker/
rm -rf /usr/lib/systemd/system/{kubelet,docker,flanneld}.service
rm -rf /usr/bin/{kubectl,kubelet,kube-proxy,docker*,flanneld}
echo "step:------> remove kubernetes .kube .ssh directory"
sleep 1
rm -rf /etc/kubernetes
rm -rf ~/.kube
rm -rf ~/.ssh/
echo "step:------> clean network config"
sleep 1
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat
ip link del flannel.1
ip link del docker0
echo "***************clean node's config finished!****************"