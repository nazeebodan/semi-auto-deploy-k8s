
#!/bin/bash

#######Begin########
echo "===========================>begin to config ca"
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
baseDir="/softdb/semi-auto-deploy-k8s"
mkdir -p /etc/kubernetes/ssl

configSSLTools(){
	cd ${baseDir}/ca
	echo "step:------> config sslTools "
    sleep 1
	
	if [ ! -f "$baseDir/ca/cfssl_linux-amd64" ]; then
        wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
		check_ok
    fi
	
	if [ ! -f "$baseDir/ca/cfssljson_linux-amd64" ]; then
        wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
		check_ok
    fi
	
	if [ ! -f "$baseDir/ca/cfssl-certinfo_linux-amd64" ]; then
        wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
		check_ok
    fi
	
	
	chmod +x cfssl_linux-amd64
	cp cfssl_linux-amd64 /usr/bin/cfssl
	chmod +x cfssljson_linux-amd64
	cp cfssljson_linux-amd64 /usr/bin/cfssljson
	chmod +x cfssl-certinfo_linux-amd64
	cp cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo
    
	echo "step:------> config sslTools comleted."
    sleep 1
}

createPem(){
	cd ${baseDir}/ca
	echo "step:------> create ca cert ."
    sleep 1
	cfssl gencert -initca ca-csr.json | cfssljson -bare ca
	check_ok
	echo "step:------> create ca cert comleted."
    sleep 1
	
	echo "step:------> create kubernetes cert "
    sleep 1
	cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes
	check_ok
	echo "step:------> create kubernetes cert completed"
    sleep 1	
	
	echo "step:------> create admin cert "
    sleep 1
	cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin
	check_ok
	echo "step:------> create admin cert comleted."
    sleep 1
	
	echo "step:------> create kube-proxy cert "
    sleep 1
	cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy
	check_ok
	echo "step:------> create kube-proxy cert comleted."
    sleep 1
}

cpPem(){
	cd ${baseDir}/ca
	echo "step:------> copy *.pem to ssl "
    sleep 1
	cp *.pem /etc/kubernetes/ssl
	check_ok
	echo "step:------> copy *.pem to ssl comleted."
	sleep 1
}

configSSLTools
createPem
cpPem
