#清理kubernetes
systemctl stop kube-apiserver kube-controller-manager kube-scheduler
rm -rf /var/run/kubernetes
rm -rf /lib/systemd/system/{kube-apiserver,kube-controller-manager,kube-scheduler}.service
rm -rf /usr/bin/{kube-apiserver,kube-controller-manager,kube-scheduler}
rm -rf /etc/kubernetes/ssl
rm -rf /etc/kubernetes
rm -rf ~/.kube
#清理etcd
systemctl stop etcd
rm -rf /var/lib/etcd
rm -rf /lib/systemd/system/etcd.service
rm -rf /usr/bin/etcd
#清理flannel
systemctl stop flanneld
rm -rf /var/run/flannel/
rm -rf /usr/bin/flanneld
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat
ip link del flannel.1