# 采用shell的方式进行半自动部署k8s

### 目录说明：
* ca: 用于安装认证的配置文件和工具
* docker: docker的安装配置脚本，注意：在node.sh脚本已经包含了docker的安装
* master:
	* etcd: etcd的安装文件
	* flannel: flannel的安装文件
	* k8s: master节点的部署脚本
	* repo: 用于常用备注的说明
* node: node节点的部署 
	

### 执行顺序说明：
* 1.修改kubernetes-csr.json配置文件，修改对应的ip地址和主机名
* 2.执行ca里面的configpem.sh生成key
* 3.修改一些配置文件
	* os的配置文件，如/etc/hosts，将master和node的主机名和ip加进去
	* 确定好软件包的存放位置后，修改脚本的baseDir
* 4.部署master节点，执行master/k8s目录下的master.sh(配置flannel的时候需要先确定-iface=eth0 这个选项)
* 5.部署node节点
* 6.因为加入了认证的配置，所以在node节点第一次加入集群的情况下，需要master节点认证,node才可见