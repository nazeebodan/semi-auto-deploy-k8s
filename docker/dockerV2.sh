
#!/bin/bash

#######Begin########
echo "begin to install docker-ce"
sleep 1

##check last command is OK or not.
check_ok() {
        if [ $? != 0 ]
                then
                echo "Error, Check the error log."
                exit 1
        fi
}

##some env


echo "step:------> remove old docker version"
sleep 1
yum remove docker docker-common container-selinux docker-selinux docker-engine
check_ok
echo "step:------> remove old docker version completed."
sleep 1

echo "step:------> yum install some needed package for docker"
sleep 1
yum install -y yum-utils device-mapper-persistent-data lvm2
echo "step:------> yum install some needed package for docker completed."
sleep 1

echo "step:------> config repo for docker"
sleep 1
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable docker-ce-edge
echo "step:------> config repo for docker completed."
sleep 1

echo "step:------> install docker"
sleep 1
yum makecache fast
yum install -y docker-ce
echo "step:------> install docker completed."
sleep 1

echo "step:------> make devicemapper config"
sleep 1
mkdir -p /etc/docker/
echo "{
		\"storage-driver\": \"devicemapper\"
}" > daemon.json
echo "step:------> make devicemapper config comleted"
sleep 1

echo "step:------> startup docker"
sleep 1
systemctl start docker
check_ok
docker info

