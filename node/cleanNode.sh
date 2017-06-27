#!/bin/bash

# 停止相关服务进程
systemctl stop kubelet kube-proxy docker flanneld
# 删除 kubelet 工作目录
rm -rf /var/lib/kubelet
# 删除 docker 工作目录
rm -rf /var/lib/docker
# 删除 flanneld 写入的网络配置文件
rm -rf /var/run/flannel/
# 删除 docker 的一些运行文件
rm -rf /var/run/docker/
# 删除 systemd unit 文件
rm -rf /lib/systemd/system/{kubelet,docker,flanneld}.service
# 删除程序文件
rm -rf /usr/bin/{kubectl,kubelet,kube-proxy,docker*,flanneld}
# 删除证书文件
rm -rf /etc/kubernetes


iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat


ip link del flannel.1
ip link del docker0