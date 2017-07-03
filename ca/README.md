## ca目录说明

### 文件说明：
* kubernetes-csr.json 重点关注这个json文件，因为里面的ip地址和域名和生成CA有关，如果没有添加或者修改正确的ip地址和域名，那么会引起证书不正确，从而使得配置出错!
* configpem.sh 生成根证书、kubernetes证书、admin证书、kube-proxy证书的shell脚本
* cleanCA.sh 删除证书，该脚本已经废弃
* cfssl工具
	* cfssl_linux-amd64
	* cfssl-certinfo_linux-amd64
	* cfssljson_linux-amd64

### 证书说明


### 证书使用帮助
* etcd：使用 ca.pem、kubernetes-key.pem、kubernetes.pem
* kube-apiserver：使用 ca.pem、kubernetes-key.pem、kubernetes.pem
* kubelet：使用 ca.pem
* kube-proxy：使用 ca.pem、kube-proxy-key.pem、kube-proxy.pem
* kubectl：使用 ca.pem、admin-key.pem、admin.pem