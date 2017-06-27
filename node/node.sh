#!/bin/bash

#######Begin########
echo "***************************************************************************************************"
echo "*                                                                                                 *"
echo "*                Note: Before run node.sh,You should set MASTER_NAME && MASTER_IP                 *"
echo "*                                                                                                 *"
echo "***************************************************************************************************"
echo "Please input master's hostname :"
read masterhostname
MASTER_NAME=${masterhostname}
echo "Please input master's ipaddr :"
read masterip
MASTER_IP=${masterip}
echo "you input MASTER_NAME is \""${MASTER_NAME}"\",and MASTER_IP is \""${MASTER_IP}"\",do you confirm ?(yes/no):"
read answer
if [ "${answer}" = "yes" -o "${answer}" = "y" ];then
	echo "Have you config /etc/hosts? (yes/no):"
	read answer2
	if [ "${answer2}" = "yes" -o "${answer2}" = "y" ];then
		echo "***************************************************************************************************"
		echo "*                                                                                                 *"
		echo "*                                 begin to install k8s-node                                       *"
		echo "*                                                                                                 *"
		echo "***************************************************************************************************"
	else
		echo "***************************************************************************************************"
		echo "*                         You should config /etc/hosts as first!                                  *"
		echo "***************************************************************************************************"
		exit 1
	fi
sleep 1
else
	echo "***************************************************************************************************"
	echo "*             You should make sure the MASTER_NAME && MASTER_IP correct First!                    *"
	echo "***************************************************************************************************"
	exit 1
fi

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
#MASTER_NAME="sure-master"
#MASTER_IP="172.18.78.47"
NODE_NAME=`hostname`
NODE_IP=`ifconfig eth0|sed -n '2p'|awk '{print $2}'|cut -c 1-20`
KUBE_APISERVER="https://${MASTER_IP}:6443"


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
	mkdir -p /etc/kubernetes/ssl /var/lib/kubelet /var/lib/kube-proxy
}

cpCAFromMaster(){
	cd /etc/kubernetes/ssl
	echo "step:------> copy k8s.pem,ca.pem,token.csv from k8s-master, Plsase input MASTER_HOST's passwd:"
	#scp ${MASTER_IP}:/etc/kubernetes/ssl/{ca.pem,kubernetes.pem,kubernetes-key.pem,token.csv} .
	scp ${MASTER_IP}:/etc/kubernetes/ssl/* .
	echo "step:------> copy k8s.pem,ca.pem,token.csv from k8s-master complted"
	cp /etc/kubernetes/ssl/token.csv /etc/kubernetes/token.csv
	sleep 1
	
	cd /etc/kubernetes
	echo "step:------> copy *.kubeconfig, Plsase input MASTER_HOST's passwd:"
	scp ${MASTER_IP}:/etc/kubernetes/*.kubeconfig .
	echo "step:------> copy *.kubeconfig completed."
	sleep 1
	
	echo "step:------> copy ~/.kube/comfig to node, Plsase input MASTER_HOST's passwd:"
	mkdir -p ~/.kube
	scp ${MASTER_IP}:~/.kube/config ~/.kube
	echo "step:------> copy ~/.kube/comfig to node completed."
	sleep 1
}

createK8scomponents(){
	cd ${baseDir}/master/k8s
    if [ ! -f "${baseDir}/master/k8s/${k8s_file}" ]; then
        #echo "${k8s_file} is not exist!"
        #exit 0
		echo "***************************************************************************************************"
		echo "*                                                                                                 *"
		echo "*             kubernetes-server-linux-amd64.tar.gzis not exist! Now,We will get it first!         *"
		echo "*                                                                                                 *"
		echo "***************************************************************************************************"
		echo "step:------> wget ${k8s_file}"
		wget https://dl.k8s.io/${k8s_version}/kubernetes-server-linux-amd64.tar.gz
		#wget https://github.com/kubernetes/kubernetes/releases/download/${k8s_version}/kubernetes.tar.gz
		check_ok
		echo "step:------> wget ${k8s_file} completed."
    fi
	echo "step:------> unzip k8s-package"
	sleep 1
	cd ${baseDir}/master/k8s
    tar -zxf ${k8s_file}
    check_ok
	echo "step:------> unzip k8s-package comleted."
	sleep 1
	echo "step:------> copy kube-node components to /usr/bin"
	sleep 1
    cp -r kubernetes/server/bin/{kubelet,kube-proxy,kubectl} /usr/bin/
    chmod 755 /usr/bin/kube*
	check_ok
	echo "step:------> copy kube-node components to /usr/bin completed."
	sleep 1
	
	rm -rf kubernetes
}

configFlannel(){
	cd ${baseDir}/master/flannel
	echo "step:------> config flannel "
	sleep 1
	mkdir -p ${baseDir}/master/flannel/flannel
	
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
	cd ${baseDir}/docker
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
		echo "***************************************************************************************************"
		echo "*                                                                                                 *"
		echo "*                  Now,We will get it docker binary  install package first!                       *"
		echo "*                                                                                                 *"
		echo "***************************************************************************************************"
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
ExecStart=/usr/bin/dockerd --log-level=error \$DOCKER_NETWORK_OPTIONS
ExecReload=/bin/kill -s HUP \$MAINPID
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
	sleep 1
	
	docker info	
}

sshCreateClusterrolebinding(){
	echo "***************************************************************************************************"
	echo "*                                                                                                 *"
	echo "*            Now,We should create clusterrolebinding kubelet-bootstrap on master                  *"
	echo "*                                                                                                 *"
	echo "***************************************************************************************************"
	sleep 1
	ssh ${MASTER_NAME} kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
	echo "step:------> create clusterrolebinding kubelet-bootstrap on master completed."
}

createK8sConfigFiles4Node(){
	mkdir -p ${baseDir}/node/k8s
	cd ${baseDir}/node/k8s
	echo "step:------> create kubelet configFile"
	sleep 1
	mkdir -p /var/lib/kubelet
	
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

	echo "step:------> create kubelet configFile completed"
	sleep 1
	
	echo "step:------> create kube-proxy configFile"
	sleep 1
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
	echo "step:------> create kube-proxy configFile completed."
	sleep 1
}

configKubelet(){
	#这个操作之前需要在master上做！
	#kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
	echo "step:------> startup kubelet"
	sleep 1
	cd ${baseDir}/node/k8s
	mv kubelet.service /usr/lib/systemd/system
	systemctl daemon-reload
	systemctl enable kubelet
	systemctl start kubelet
	check_ok
	echo "step:------> startup kubelet comleted."
	sleep 1
}

configKubeProxy(){
	echo "step:------> startup kube-proxy"
	sleep 1
	cd ${baseDir}/node/k8s
	mv kube-proxy.service  /usr/lib/systemd/system
	systemctl daemon-reload
	systemctl enable kube-proxy
	systemctl start kube-proxy
	check_ok
	echo "step:------> startup kube-proxy completed."
	sleep 1
}

beforeFinishedNotice(){
	
	#在node第一次启动kubelet后，相当于是有个加入节点的请求，需要在master端做操作
	#kubectl get csr
	#kubectl certificate approve xxx
	#kubectl get node
	echo "***************************************************************************************************"
	echo "*                                                                                                 *"
	echo "*  k8s-config finished on node.                                                                   *"
	echo "*  But you should continue to certicate approve node on master.                                   *"
	echo "*  The commands are as follows:                                                                   *"
	echo "*       kubectl get csr                                                                           *"
	echo "*       kubectl certificate approve xxx                                                           *"
	echo "*       kubectl get node                                                                          *"
	echo "*                                                                                                 *"
	echo "***************************************************************************************************"
}

doSomeOsConfig
cpCAFromMaster
createK8scomponents
configFlannel
configDocker
sshCreateClusterrolebinding
createK8sConfigFiles4Node
configKubelet
configKubeProxy
beforeFinishedNotice