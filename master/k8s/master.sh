#!/bin/bash

#######Begin########
echo "***************************************************************************************************"
echo "*                                                                                                 *"
echo "*                     Note: Before run master.sh,You must config pem first                        *"
echo "*                                                                                                 *"
echo "***************************************************************************************************"
echo "Have you configured CA yet? (yes/no):"
read answer
if [ "${answer}" = "yes" -o "${answer}" = "y" ];then
	echo "Have you config /etc/hosts? (yes/no):"
	read answer2
	if [ "${answer2}" = "yes" -o "${answer2}" = "y" ];then
		echo "Have you make sure your network device name is $2? (yes/no):"
		read answer3
		if [ "${answer3}" = "yes" -o "${answer3}" = "y" ];then
		echo "***************************************************************************************************"
		echo "*                                                                                                 *"
		echo "*                                 begin to install k8s-master                                     *"
		echo "*                                                                                                 *"
		echo "***************************************************************************************************"
		else
			echo "***************************************************************************************************"
			echo "*                     You should query your network device name first!                            *"
			echo "***************************************************************************************************"
			exit 1
		fi
	else
		echo "***************************************************************************************************"
		echo "*                         You should config /etc/hosts as first!                                  *"
		echo "***************************************************************************************************"
		exit 1
	fi
else
	echo "***************************************************************************************************"
	echo "*                   You should execut \"ca/configpem.sh\" at first!                                 *"
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

pkgYum() {
if ! rpm -qa|grep -q "^$1"
then
    yum install -y $1
    check_ok
else
    echo $1 already installed.
fi
}

##some env

baseDir="$1"
networkDeviceName="$2"
k8s_version="v1.6.2"
k8s_file="kubernetes-server-linux-amd64.tar.gz"
etcd_version="v3.1.9"
etcd_file="etcd-v3.1.9-linux-amd64.tar.gz"
flannel_version="v0.7.1"
flannel_file="flannel-v0.7.1-linux-amd64.tar.gz"
serviceDir="/usr/lib/systemd/system"
MASTER_NAME=`hostname`
MASTER_IP=`ifconfig ${networkDeviceName}|sed -n '2p'|awk '{print $2}'|cut -c 1-20`
ETC_NAME=etcd-`hostname`
#BOOTSTRAP_TOKEN="90db8027f413b5d51b563643478e2875"
BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x| tr -d ' ')
KUBE_APISERVER="https://${MASTER_IP}:6443"
SERVICE_CIDR="10.254.0.0/16"
CLUSTER_CIDR="172.30.0.0/16"
mkdir -p /var/lib/etcd
mkdir -p /etc/kubernetes/
mkdir -p ~/.ssh
#rm -rf /lib/systemd/system/kube*

backService(){
    if [  -f "${serviceDir}/$1" ]; then
		echo "step:------>backup service config file "$1
		sleep 1
		mv ${serviceDir}/$1 ${serviceDir}/$1.bak
    fi
}

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

enableAndStarService(){
	echo "step:------> startup $1 "
	sleep 1
	systemctl daemon-reload
	systemctl enable $1
	systemctl start $1
	check_ok
	echo "step:------> startup $1 comleted."
	sleep 1
}

createK8scomponents(){
	cd ${baseDir}/master/k8s/
    if [ ! -f "${baseDir}/master/k8s/${k8s_file}" ]; then
        #echo "${k8s_file} is not exist!"
        #exit 0
		echo "***************************************************************************************************"
		echo "*                                                                                                 *"
		echo "*             kubernetes-server-linux-amd64.tar.gzis not exist! Now,We will get it first!         *"
		echo "*                                                                                                 *"
		echo "***************************************************************************************************"
		sleep  2
		echo "step:------> wget ${k8s_file}"
		wget https://dl.k8s.io/${k8s_version}/${k8s_file}
		#wget https://github.com/kubernetes/kubernetes/releases/download/${k8s_version}/kubernetes.tar.gz
		check_ok
		echo "step:------> wget ${k8s_file} completed."
		sleep 1
    fi
	echo "step:------> unzip k8s-package"
	sleep 1
	cd ${baseDir}/master/k8s
    tar -zxf ${k8s_file}
    check_ok
	echo "step:------> unzip k8s-package comleted."
	sleep 1
	echo "step:------> copy kube-master components to /usr/bin"
	sleep 1
	rm -rf /usr/bin/kube*
    cp -r kubernetes/server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl} /usr/bin/
    chmod 755 /usr/bin/kube*
	check_ok
	echo "step:------> copy kube-master components to /usr/bin completed."
	sleep 1
	rm -rf kubernetes
}

createK8sConfigFiles4Master(){
	cd ${baseDir}/master/k8s
	#创建 apiserver.service
	cat > kube-apiserver.service <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
After=etcd.service
[Service]
ExecStart=/usr/bin/kube-apiserver \\
--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,DefaultStorageClass,ResourceQuota \\
--advertise-address=${MASTER_IP} \\
--bind-address=${MASTER_IP} \\
--insecure-bind-address=${MASTER_IP} \\
--authorization-mode=RBAC \\
--runtime-config=rbac.authorization.k8s.io/v1alpha1 \\
--kubelet-https=true \\
--experimental-bootstrap-token-auth \\
--token-auth-file=/etc/kubernetes/ssl/token.csv \\
--service-cluster-ip-range=${SERVICE_CIDR} \\
--service-node-port-range=30000-32767 \\
--tls-cert-file=/etc/kubernetes/ssl/kubernetes.pem \\
--tls-private-key-file=/etc/kubernetes/ssl/kubernetes-key.pem\\
--client-ca-file=/etc/kubernetes/ssl/ca.pem \\
--service-account-key-file=/etc/kubernetes/ssl/ca-key.pem \\
--etcd-cafile=/etc/kubernetes/ssl/ca.pem \\
--etcd-certfile=/etc/kubernetes/ssl/kubernetes.pem \\
--etcd-keyfile=/etc/kubernetes/ssl/kubernetes-key.pem \\
--enable-swagger-ui=true \\
--apiserver-count=3 \\
--audit-log-maxage=30 \\
--audit-log-maxbackup=3 \\
--audit-log-maxsize=100 \\
--audit-log-path=/var/lib/audit.log \\
--event-ttl=1h \\
--etcd-servers=https://${MASTER_IP}:2379 \\
--logtostderr=true \\
--v=0 \\
--allow-privileged=true
Restart=on-failure
Type=notify
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF


	#创建controller.servic
	cat > kube-controller-manager.service <<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
[Service]
ExecStart=/usr/bin/kube-controller-manager \\
--address=127.0.0.1 \\
--allocate-node-cidrs=true \\
--service-cluster-ip-range=${SERVICE_CIDR} \\
--cluster-cidr=${CLUSTER_CIDR} \\
--cluster-name=kubernetes \\
--cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem \\
--cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem \\
--service-account-private-key-file=/etc/kubernetes/ssl/ca-key.pem \\
--root-ca-file=/etc/kubernetes/ssl/ca.pem \\
--leader-elect=true \\
--logtostderr=true \\
--v=0 \\
--master=http://${MASTER_NAME}:8080
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

	#创建scheduler.service
	cat > kube-scheduler.service <<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
[Service]
ExecStart=/usr/bin/kube-scheduler \\
--address=127.0.0.1 \\
--leader-elect=true \\
--logtostderr=true \\
--v=0 \\
--master=http://${MASTER_NAME}:8080
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

	#create service config file: apiserver,controller-manager,scheduler
	cpServiceConfig kube-apiserver.service
	check_ok
	cpServiceConfig kube-controller-manager.service
	check_ok
	cpServiceConfig kube-scheduler.service
	check_ok
}

startKubeService(){
	#start service : apiserver,controller-manager,scheduler
	enableAndStarService kube-apiserver
	enableAndStarService kube-controller-manager
	enableAndStarService kube-scheduler
	echo "***************************************************************************************************"
	echo "*                                                                                                 *"
	echo "*     show the kube-master cs status,If any component's status is not healty,Pls check err log    *"
	echo "*                                                                                                 *"
	echo "***************************************************************************************************"
	sleep  2
	kubectl get cs
	
}

cpServiceConfig(){
	cd ${baseDir}/master/k8s/
	echo "step:------> create $1 config "
	sleep 1
	
	if [  -f "${serviceDir}/$1" ]; then
		echo "step:------>backup service config file "$1
        	sleep 1
		mv ${serviceDir}/$1 ${serviceDir}/$1.bak
		check_ok
    fi
		
    mv ${baseDir}/master/k8s/$1 ${serviceDir}/
	check_ok
	echo "step:------> create $1 config completed."
	sleep 1
}

createToken(){
	cd ${baseDir}/master/k8s
	echo "step:------> create and copy bootstart_token"
	sleep 1
	cat > token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF

	echo "step:------> create bootstart_token completed."
	sleep 1
	mkdir -p /etc/kubernetes/ssl
	cp token.csv /etc/kubernetes
	cp token.csv /etc/kubernetes/ssl
	echo "step:------> copy bootstart_token completed."
	sleep 1
	rm -rf token.csv
}

createKubectlConfig(){
	
	cd ${baseDir}/master/k8s
	
	echo "step:------> create kubectl kubeconfig"
	sleep 1
	#设置集群参数
	kubectl config set-cluster kubernetes --certificate-authority=/etc/kubernetes/ssl/ca.pem --embed-certs=true --server=${KUBE_APISERVER}
	#设置客户端认证参数
	kubectl config set-credentials admin --client-certificate=/etc/kubernetes/ssl/admin.pem --embed-certs=true --client-key=/etc/kubernetes/ssl/admin-key.pem
	#设置上下文参数
	kubectl config set-context kubernetes --cluster=kubernetes --user=admin
	#设置默认上下文
	kubectl config use-context kubernetes
	echo "step:------> create kubectl kubeconfig completed."
	sleep 1
	
	echo "step:------> create kubelet bootstrapping kubeconfig"
	sleep 1
	#设置集群参数
	kubectl config set-cluster kubernetes --certificate-authority=/etc/kubernetes/ssl/ca.pem --embed-certs=true --server=${KUBE_APISERVER} --kubeconfig=bootstrap.kubeconfig
	#设置客户端认证参数
	kubectl config set-credentials kubelet-bootstrap --token=${BOOTSTRAP_TOKEN} --kubeconfig=bootstrap.kubeconfig
	#设置上下文参数
	kubectl config set-context default --cluster=kubernetes --user=kubelet-bootstrap --kubeconfig=bootstrap.kubeconfig
	#设置默认上下文
	kubectl config use-context default --kubeconfig=bootstrap.kubeconfig
	echo "step:------> create kubelet bootstrapping kubeconfig completed."
	sleep 1
	
	echo "step:------> create kube-proxy kubeconfig"
	sleep 1
	#设置集群参数
	kubectl config set-cluster kubernetes --certificate-authority=/etc/kubernetes/ssl/ca.pem --embed-certs=true --server=${KUBE_APISERVER} --kubeconfig=kube-proxy.kubeconfig
	#设置客户端认证参数
	kubectl config set-credentials kube-proxy --client-certificate=/etc/kubernetes/ssl/kube-proxy.pem --client-key=/etc/kubernetes/ssl/kube-proxy-key.pem --embed-certs=true --kubeconfig=kube-proxy.kubeconfig
	#设置上下文参数
	kubectl config set-context default --cluster=kubernetes --user=kube-proxy --kubeconfig=kube-proxy.kubeconfig
	#设置默认上下文
	kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
	echo "step:------> create kube-proxy kubeconfig completed."
	sleep 1
	
	cp bootstrap.kubeconfig kube-proxy.kubeconfig /etc/kubernetes/
	rm -rf  bootstrap.kubeconfig kube-proxy.kubeconfig
}

configEtcd(){
	cd ${baseDir}/master/etcd
	echo "step:------> config etcd "
	sleep 1
	
	mkdir -p /var/lib/etcd
	
	if [ ! -f "${baseDir}/master/etcd/${etcd_file}" ]; then
		wget https://github.com/coreos/etcd/releases/download/${etcd_version}/${etcd_file}
		check_ok
	fi
	tar -zxf ${baseDir}/master/etcd/${etcd_file}
	mv ${baseDir}/master/etcd/etcd-v3.1.9-linux-amd64/etcd* /usr/bin/
	chown root.root /usr/bin/etc*
	rm -rf ${baseDir}/master/etcd/etcd-v3.1.9-linux-amd64
	
	cat > ${baseDir}/master/etcd/etcd.service <<EOF
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
--initial-advertise-peer-urls=https://${MASTER_IP}:2380 \\
--listen-peer-urls=https://${MASTER_IP}:2380 \\
--listen-client-urls=https://${MASTER_IP}:2379,https://127.0.0.1:2379,http://127.0.0.1:2379 \\
--advertise-client-urls=https://${MASTER_IP}:2379 \\
--initial-cluster-token=etcd-cluster-0 \\
--initial-cluster=${ETC_NAME}=https://${MASTER_NAME}:2380 \\
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
	rm -rf ${serviceDir}/etcd.service
	mv etcd.service ${serviceDir}
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
	etcdctl --endpoints=https://${MASTER_NAME}:2379 --ca-file=/etc/kubernetes/ssl/ca.pem --cert-file=/etc/kubernetes/ssl/kubernetes.pem --key-file=/etc/kubernetes/ssl/kubernetes-key.pem mk /kube-centos/network/config '{"Network":"172.30.0.0/16", "SubnetLen": 24, "Backend": {"Type": "vxlan"}}'
	#etcdctl mk /kube-centos/network/config "{ \"Network\": \"172.30.0.0/16\", \"SubnetLen\": 24, \"Backend\": { \"Type\": \"vxlan\" } }"
	echo "step:------> config etcd network completed."
	sleep 1	
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
-iface=${networkDeviceName}
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

closeSelinux #关闭selinux
closeIptables #关闭防火墙
configEtcd #配置etcd
configFlannel #配置flannel
createK8scomponents #创建k8s的bin执行文件
createK8sConfigFiles4Master #配置master节点的k8s
createToken #创建token
createKubectlConfig #创建kubectl的配置文件
startKubeService #启动master节点的k8s服务

echo "***************************************************************************************************"
echo "*                                                                                                 *"
echo "*                                 k8s-master install completed!                                   *"
echo "*                                                                                                 *"
echo "***************************************************************************************************"