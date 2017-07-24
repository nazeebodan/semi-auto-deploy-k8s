# 采用shell的方式进行半自动部署k8s

### 目录说明：
* ca: 用于安装认证的配置文件和工具以及脚本
	* kubernetes-csr.json 重点关注这个json文件，因为里面的ip地址和域名和生成CA有关，如果没有添加或者修改正确的ip地址和域名，那么会引起证书不正确，从而使得配置出错!
	* configpem.sh 生成根证书、kubernetes证书、admin证书、kube-proxy证书的shell脚本
	* cleanCA.sh 删除证书，该脚本已经废弃
	* cfssl工具
		* cfssl_linux-amd64
		* cfssl-certinfo_linux-amd64
		* cfssljson_linux-amd64
* docker: 
	* docker.sh docker的yum安装配置步骤，已经废弃
	* docker-17.05.0-ce.tgz docker的最新ce版本的安装包
	* dockerdir.tar.gz 一些docker的镜像打包，使用dockerLoad.sh装载
	* dockerLoad.sh 装载docker的镜像的shell脚本
	* dockerLoadDetail.sh 具体的docker load脚本
* master:
	* etcd: etcd的二进制安装包
	* flannel: flannel的二进制安装包
	* k8s: master节点的配置和清除脚本
	* repo: 配置信息的说明文档，用作参考
* node: node节点的配置和清除脚本
* deploy: 用于部署k8s的相关组件

### 执行说明
* 添加了统一的入口installk8s.sh,包括功能：
	* 1.配置CA 
	* 2.部署k8s在master节点
	* 3.部署k8s在node节点
	* 4.清除master节点的k8s配置（包括：k8s、etcd、flannel）
	* 5.清除node节点的k8s配置（包括：k8s、flannel、docker） 
	* 6.装载一部分需要的docker镜像（如pod-infrastructure、pause、dns等）

* 添加了统一的配置入口configk8scomp.sh,包括功能：
	* 1.配置docker(主要用于单独部署docker，如果是节点要部署整套k8s，那么不需要调用它) 
	* 2.配置harbor(用于harbor仓库的部署，和k8s关系不大，可与第一项的配置docker配合起来使用)
	* 3.部署Kube-DNS
	* 4.部署Kube-Dashboard
	* 5.部署EFK日志套件
	

### 补充说明：
* 1.使用前请先修改一些配置文件，如/etc/hosts，将master和node的主机名和ip加进去
* 2.运行配置CA前应该修改kubernetes-csr.json配置文件，修改对应的ip地址和主机名
* 3.脚本的默认baseDir路径为/softdb/semi-auto-deploy-k8s,如需修改使用 -d 参数，同样也可以用 -h 来查看帮助
* 4.部署master节点，执行master/k8s目录下的master.sh(配置flannel的时候需要先确定-iface=eth0 这个选项)
* 5.因为加入了CA认证的配置，所以在node节点第一次加入集群后(启动kubelet,kube-proxy)，需要master节点认证(kubectl certificate approve),node才可见
* 6.部署node节点时，为了减少输入密码的次数，添加了ssh的配置，当然为了安全性也可以不配置
	