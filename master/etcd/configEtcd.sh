#!/bin/bash

#######Begin########

##check last command is OK or not.
check_ok() {
        if [ $? != 0 ]
                then
                echo "Error, Check the error log."
                exit 1
        fi
}

##some env
baseDir="/softdb"
ETC_NAME=etcd-`hostname`
NODE_IP=`ifconfig eth0|sed -n '2p'|awk '{print $2}'|cut -c 1-20`
mkdir -p /var/lib/etcd

	echo "step:------> config etcd "
	sleep 1
	
	if [ ! -f "$baseDir/master/etcd/etcd-v3.1.9-linux-amd64.tar.gz" ]; then
	        wget https://github.com/coreos/etcd/releases/download/v3.1.9/etcd-v3.1.9-linux-amd64.tar.gz
			check_ok
			tar -zxf etcd-v3.1.9-linux-amd64.tar.gz
			mv etcd-v3.1.9-linux-amd64/etcd* /usr/bin/
			chown root.root /usr/bin/etc*
			rm -rf etcd-v3.1.9-linux-amd64
	fi
	
cat > etcd.service <<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos
[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
ExecStart=/usr/bin/etcd \\
--name=${ETC_NAME} \\
--cert-file=/etc/kubernetes/ssl/kubernetes.pem \\
--key-file=/etc/kubernetes/ssl/kubernetes-key.pem \\
--peer-cert-file=/etc/kubernetes/ssl/kubernetes.pem \\
--peer-key-file=/etc/kubernetes/ssl/kubernetes-key.pem \\
--trusted-ca-file=/etc/kubernetes/ssl/ca.pem \\
--peer-trusted-ca-file=/etc/kubernetes/ssl/ca.pem \\
--initial-advertise-peer-urls=https://${NODE_IP}:2380 \\
--listen-peer-urls=https://${NODE_IP}:2380 \\
--listen-client-urls=https://${NODE_IP}:2379,https://127.0.0.1:2379,http://127.0.0.1:2379 \\
--advertise-client-urls=https://${NODE_IP}:2379 \\
--initial-cluster-token=etcd-cluster-0 \\
--initial-cluster=${ETC_NAME}=https://`hostname`:2380 \\
--initial-cluster-state=new \\
--data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF
	
	echo "step:------> config etcd completed."
	sleep 1
	
	echo "step:------> ectd startup  "
	sleep 1
	rm -rf /lib/systemd/system/etcd.service
	sleep 1
	mv etcd.service /lib/systemd/system/
	systemctl daemon-reload
	systemctl enable etcd
	systemctl restart etcd
	check_ok
	
	echo "step:------> ectd startup completed. "
	sleep 1
	
	echo "step:------> check etcd "
	sleep 1
	etcdctl --ca-file=/etc/kubernetes/ssl/ca.pem --cert-file=/etc/kubernetes/ssl/kubernetes.pem --key-file=/etc/kubernetes/ssl/kubernetes-key.pem cluster-health
	echo "step:------> check etcd completed"
	sleep 1
	
	echo "step:------> config etcd network "
	sleep 1
	check_ok
	etcdctl mkdir /kube-centos/network
	etcdctl mk /kube-centos/network/config "{ \"Network\": \"172.30.0.0/16\", \"SubnetLen\": 24, \"Backend\": { \"Type\": \"vxlan\" } }"
	echo "step:------> config etcd network completed."
	sleep 1	

