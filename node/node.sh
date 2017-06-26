#!/bin/bash

#######Begin########
echo "=====================>begin to install k8s-node<======================"
sleep 1

##check last command is OK or not.
check_ok() {
        if [ $? != 0 ]
                then
                echo "Error, Check the error log."
                exit 1
        fi
}

baseDir="/softdb/semi-auto-deploy-k8s"
k8s_version="v1.6.2"
k8s_file="kubernetes-server-linux-amd64.tar.gz"
flannel_version="v0.7.1"
flannel_file="flannel-v0.7.1-linux-amd64.tar.gz"
DOCKER_FILE="docker-17.05.0-ce.tgz"
serviceDir="/usr/lib/systemd/system"
MASTER_NAME="sure-node1"
MASTER_IP="172.18.78.48"
NODE_NAME=`hostname`
NODE_IP=`ifconfig eth0|sed -n '2p'|awk '{print $2}'|cut -c 1-20`
KUBE_APISERVER="https://${MASTER_IP}:6443"

mkdir -p /etc/kubernetes/

closeSelinux(){
    echo "step:------> close selinux config"
	sleep 1
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    selinux_s=`getenforce`
    if [ $selinux_s == "enforcing" ]
        then
        setenforce 0
    fi
	check_ok
	echo "step:------> close selinux config completed."
	sleep 1
}

closeIptables(){
	echo "step:------> stop iptables "
	sleep 1
        iptables-save > /etc/sysconfig/iptables_`date +%s`
        iptables -F
        systemctl stop iptables
	echo "step:------> stop iptables completed."
	sleep 1
}

doSomeOsConfig(){
	closeSelinux
	closeIptables
	
	mkdir -p /etc/kubernetes/ssl /var/lib/kublet /var/lib/kube-proxy
	
	cd /etc/kubernetes/ssl
	echo "step:------> copy k8s.pem,ca.pem,token.csv from k8s-master,You should input masterhost's passwd"
	sleep 1
	scp ${MASTER_IP}:/etc/kubernetes/ssl/{ca.pem,kubernetes.pem,kubernetes-key.pem,token.csv} .
	echo "step:------> copy k8s.pem,ca.pem,token.csv from k8s-master complted"
	sleep 1
	
	cd /etc/kubernetes
	echo "step:------> copy *.kubeconfig,You should input masterhost's passwd"
	sleep 1
	scp ${MASTER_IP}:/etc/kubernetes/*.kubeconfig .
	echo "step:------> copy *.kubeconfig completed."
	sleep 1
	
}

createK8scomponents(){
	cd ${baseDir}/master/k8s
    if [ ! -f "${baseDir}/master/k8s/${k8s_file}" ]; then
        #echo "${k8s_file} is not exist!"
        #exit 0
		echo "${k8s_file} is not exist! Now,We will get it first!"
		echo "step:------> wget ${k8s_file}"
		wget https://github.com/kubernetes/kubernetes/releases/download/${k8s_version}/kubernetes.tar.gz
		check_ok
		echo "step:------> wget ${k8s_file} completed."
    fi
	echo "step:------> unzip k8s-package"
	sleep 1
	cd ${baseDir}/master/k8s
    tar -zxf ${k8s_file}
    cd kubernetes
	echo "step:------> unzip k8s-package comleted."
	sleep 1
	echo "step:------> copy kube-node components to /usr/bin"
	sleep 1
    cp -r server/bin/{kubelet,kube-proxy,kubectl} /usr/bin/
    chmod 755 /usr/bin/kube*
	check_ok
	echo "step:------> copy kube-node components to /usr/bin completed."
	sleep 1
	cd ..
	rm -rf kubernetes
}

configFlannel(){
	echo "step:------> config flannel "
	sleep 1
	mkdir -p ${baseDir}/master/flannel/flannel
	cd ${baseDir}/master/flannel
	
	if [ ! -f "${baseDir}/master/flannel/${flannel_file}" ]; then
	    wget https://github.com/coreos/flannel/releases/download/${flannel_version}/${flannel_file}
		check_ok
	fi
	
	tar -zxf ${flannel_file} -C flannel 
	cp flannel/{flanneld,mk-docker-opts.sh} /usr/bin
	
	cat > ${baseDir}/master/flannel/flanneld.service <<EOF
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service
[Service]
Type=notify
ExecStart=/usr/bin/flanneld \\
-etcd-cafile=/etc/kubernetes/ssl/ca.pem \\
-etcd-certfile=/etc/kubernetes/ssl/kubernetes.pem \\
-etcd-keyfile=/etc/kubernetes/ssl/kubernetes-key.pem \\
-etcd-endpoints=https://${MASTER_NAME}:2379 \\
-etcd-prefix=/kube-centos/network \\
-iface=eth0
ExecStartPost=/usr/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
Restart=on-failure
[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF
	
	echo "step:------> config flannel completed."
	sleep 1
	
	echo "step:------> flannel startup  "
	sleep 1
	rm -rf ${serviceDir}/flanneld.service
	mv ${baseDir}/master/flannel/flanneld.service ${serviceDir}
	
	systemctl daemon-reload
	systemctl enable flanneld
	systemctl restart flanneld
	check_ok
	
	echo "step:------> flannel startup completed. "
	sleep 1
}

configDocker(){

	echo "step:------> remove old docker version"
	sleep 1
	yum remove docker docker-common container-selinux docker-selinux docker-engine
	check_ok
	echo "step:------> remove old docker version completed."
	sleep 1
	
	echo "step:------> deploy docker binary install package"
	sleep 1
	cd ${baseDir}/docker
	if [ ! -f "$baseDir/docker/docker-17.05.0-ce.tgz" ]; then
		wget https://get.docker.com/builds/Linux/x86_64/${DOCKER_FILE}
		check_ok
	fi
	tar -zxf ${DOCKER_FILE}
	cp docker/docker* /usr/bin
	cp docker/completion/bash/docker /etc/bash_completion.d/
	echo "step:------> deploy docker binary install package completed."
	sleep 1
	
	echo "step:------> config docker config"
	sleep 1
	cat > ${baseDir}/docker/docker.service <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.io
[Service]
Environment="PATH=/usr/bin:/bin:/usr/sbin"
EnvironmentFile=-/run/flannel/docker
ExecStart=/usr/bin/dockerd --log-level=error $DOCKER_NETWORK_OPTIONS
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure
RestartSec=5
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Delegate=yes
KillMode=process
[Install]
WantedBy=multi-user.target
EOF
	
	iptables -P FORWARD ACCEPT
	mkdir -p /etc/docker
	cat > /etc/docker/daemon.json <<EOF
	{
		"registry-mirrors": ["https://docker.mirrors.ustc.edu.cn", "hub-mirror.c.163.com"],"max-concurrent-downloads": 10
	}
	EOF
	echo "step:------> config docker config completed."
	sleep 1
	
	echo "step:------> startup docker "
	sleep 1
	cp docker.service /usr/lib/systemd/system/
	systemctl daemon-reload
	systemctl stop firewalld
	iptables -F && sudo iptables -X && sudo iptables -F -t nat && sudo iptables -X -t nat
	systemctl enable docker
	systemctl start docker
	check_ok
	
	echo "step:------> startup docker completed."
	sleep
	
	docker info	
}

createK8sConfigFiles4Node(){
	cd ${baseDir}/node/k8s
	cat > kubelet.service <<EOF
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service
[Service]
WorkingDirectory=/var/lib/kubelet
ExecStart=/usr/bin/kubelet \\
--address=${NODE_IP} \\
--hostname-override=${NODE_IP} \\
--pod-infra-container-image=registry.access.redhat.com/rhel7/pod-infrastructure:latest \\
--experimental-bootstrap-kubeconfig=/etc/kubernetes/bootstrap.kubeconfig \\
--kubeconfig=/etc/kubernetes/kubelet.kubeconfig \\
--require-kubeconfig \\
--cert-dir=/etc/kubernetes/ssl \\
--cluster_dns=10.254.0.2 \\
--cluster_domain=cluster.local. \\
--hairpin-mode=promiscuous-bridge \\
--allow-privileged=true \\
--serialize-image-pulls=false \\
--logtostderr=true \\
--v=0
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF


	cat > kube-proxy.service <<EOF
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
[Service]
WorkingDirectory=/var/lib/kube-proxy
ExecStart=/usr/bin/kube-proxy \\
--bind-address=${NODE_IP} \\
--hostname-override=${NODE_IP} \\
--cluster-cidr=10.254.0.0/16 \\
--kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig \\
--logtostderr=true \\
--v=0
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

}

configKubelet(){
	#这个操作时在master上做！
	#kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
	cd ${/softdb}/node/k8s
	cp kube-proxy.service  /usr/lib/systemd/system
	systemctl daemon-reload
	systemctl enable kube-proxy
	systemctl start kube-proxy
	
	#在node第一次启动kubelet后，相当于是有个加入节点的请求，需要在master端做操作
	#kubectl get csr
	#kubectl certificate approve xxx
	#kubectl get node
}

configKubeProxy(){
	cd ${/softdb}/node/k8s
	cp kubelet.service /usr/lib/systemd/system
	systemctl daemon-reload
	systemctl enable kubelet
	systemctl start kubelet
}

doSomeOsConfig
createK8scomponents
configFlannel
configDocker
createK8sConfigFiles4Node
configKubelet
configKubeProxy