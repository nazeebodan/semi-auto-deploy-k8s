
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
baseDir="/softdb"
DOCKER_FILE="docker-17.05.0-ce.tgz"

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
tar -xvf ${DOCKER_FILE}
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
cat > /etc/docker/daemon2.json <<EOF
{
"registry-mirrors": ["https://docker.mirrors.ustc.edu.cn", "hub-mirror.c.163.com"],"max-concurrent-downloads": 10
}
EOF
echo "step:------> config docker config completed."
sleep 1

echo "step:------> startup docker "
sleep 1
cp docker.service /usr/lin/systemd/system/
systemctl daemon-reload
systemctl stop firewalld
iptables -F && sudo iptables -X && sudo iptables -F -t nat && sudo iptables -X -t nat
systemctl enable docker
systemctl start docker
check_ok

echo "step:------> startup docker completed."
sleep

docker info