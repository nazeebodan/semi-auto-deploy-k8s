
#!/bin/bash

#######Begin########
echo "It will install k8s-master."
sleep 1

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

hostname=`hostname`
baseDir="/softdb"
file="kubernetes-server-linux-amd64.tar.gz"
serviceDir="/lib/systemd/system"
mkdir -p /etc/kubernetes/
rm -rf /etc/kubernetes/*
rm -rf /lib/systemd/system/kube*

function closeSelinux(){
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

function backService(){
        if [  -f "$serviceDir/$1" ]; then
		echo "step:------>backup service config file "$1
        	sleep 1
		mv $serviceDir/$1 $serviceDir/$1.bak
        fi
}

function closeIptables(){
	echo "step:------> stop iptables "
	sleep 1
        iptables-save > /etc/sysconfig/iptables_`date +%s`
        iptables -F
        systemctl stop iptables
	echo "step:------> stop iptables completed."
	sleep 1
}

function enableAndStarService(){
	echo "step:------> startup $1 "
	sleep 1
	systemctl daemon-reload
	systemctl enable $1
	systemctl start $1
	check_ok
	echo "step:------> startup $1 comleted."
	sleep 1
}

function createK8scomponents(){
        if [ ! -f "$file" ]; then
                echo "$file is not exist!"
                exit 0
        fi
	echo "step:------> unzip k8s-package"
	sleep 1
    tar -zxf $file
    cd kubernetes
	echo "step:------> unzip k8s-package comleted."
	sleep 1
	echo "step:------> copy kube-node components to /usr/bin"
	sleep 1
	rm -rf /usr/bin/kube*
    cp -r server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl} /usr/bin/
    chmod 755 /usr/bin/kube*
	check_ok
	echo "step:------> copy kube-node components to /usr/bin completed."
	sleep 1
	rm -rf kubernetes
}

function createConfigFiles(){
	echo "step:------> create k8s config "
	sleep 1
	sed -e "s/masterhostname/$hostname/g" $baseDir/master/repo/config.repo > $baseDir/master/repo/config.$hostname
	check_ok
	mv $baseDir/master/repo/config.$hostname /etc/kubernetes/config
	echo "step:------> create k8s config comleted."
	sleep 1
	
	echo "step:------> create apiserver config "
	sleep 1
	sed -e "s/masterhostname/$hostname/g" $baseDir/master/repo/apiserver.repo > $baseDir/master/repo/apiserver.$hostname
	check_ok
	mv $baseDir/master/repo/apiserver.$hostname /etc/kubernetes/apiserver
	echo "step:------> create apiserver config comleted."
	sleep 1
	
	echo "step:------> create scheduler config "
	sleep 1
	cp $baseDir/master/repo/scheduler.repo /etc/kubernetes/scheduler
	echo "step:------> create scheduler config comleted."
	sleep 1
	
	echo "step:------> create controller-manager config "
	sleep 1
	cp $baseDir/master/repo/controller-manager.repo /etc/kubernetes/
	mv /etc/kubernetes/controller-manager.repo /etc/kubernetes/controller-manager
	echo "step:------> create controller-manager config comleted."
	sleep 1
	
	#create service config file: apiserver,controller-manager,scheduler
	cpServiceConfig kube-apiserver.service
	cpServiceConfig kube-controller-manager.service
	cpServiceConfig kube-scheduler.service
	
}

function startKubeService(){
	#start service : apiserver,controller-manager,scheduler
	enableAndStarService kube-apiserver
	enableAndStarService kube-controller-manager
	enableAndStarService kube-scheduler
}

function cpServiceConfig(){
	echo "step:------> create $1 config "
	sleep 1
	
	if [  -f "$serviceDir/$1" ]; then
		echo "step:------>backup service config file "$1
        	sleep 1
		mv $serviceDir/$1 $serviceDir/$1.bak
		check_ok
    fi
		
    cp $baseDir/master/repo/$1 $serviceDir/
	check_ok
	echo "step:------> create $1 config completed."
	sleep 1
}

function installEtcdAndFlannel(){
	echo "step:------> install etcd flannel package"
	rpm -e --nodeps etcd
	rpm -e --nodeps flannel
	for p in etcd flannel
	do
		pkgYum $p
	done	
	check_ok
	echo "step:------> install etcd flannel package completed."
}

function configEtcd(){
	echo "step:------> config etcd"
	sleep 1
	mv /etc/etcd/etcd.conf /etc/etcd/etcd.conf.bak
	sed -e "s/localhost/0.0.0.0/g" /etc/etcd/etcd.conf.bak > /etc/etcd/etcd.conf
	check_ok
	systemctl start etcd
	check_ok
	etcdctl mkdir /kube-centos/network
	etcdctl mk /kube-centos/network/config "{ \"Network\": \"172.30.0.0/16\", \"SubnetLen\": 24, \"Backend\": { \"Type\": \"vxlan\" } }"
	echo "step:------> config etcd completed"
	sleep 1	
}

function configFlannel(){
	echo "step:------> config flannel"
	sleep 1
	mv /etc/sysconfig/flanneld /etc/sysconfig/flanneld.bak1
	sed -e "s/127.0.0.1/$hostname/g" /etc/sysconfig/flanneld.bak1 > /etc/sysconfig/flanneld.bak2
	sed -e "s/atomic.io/kube-centos/g" /etc/sysconfig/flanneld.bak2 > /etc/sysconfig/flanneld
	check_ok
	systemctl start flanneld
	check_ok
	echo "step:------> config flannel completed"
	sleep 1	
}

closeSelinux
closeIptables
createK8scomponents

createConfigFiles
installEtcdAndFlannel
configEtcd
configFlannel
startKubeService

#echo "k8s-node installed complete!"

