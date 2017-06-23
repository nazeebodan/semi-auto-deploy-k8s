#半自动部署k8s，第一版采用shell \<br>

###目录说明：
* ca: 用于装认证的配置文件和工具
* docker: docker的安装配置脚本，注意：在node.sh脚本已经包含了docker的安装
* master:
	* etcd: etcd的安装文件
	* flannel: flannel的安装文件
	* k8s: master节点的部署脚本
	* repo: 用于常用备注的说明
* node: node节点的部署 
	

###执行顺序说明：
* 1.执行ca里面的configpem.sh生成key
* 2.部署master节点，执行master/k8s目录下的master.sh
* 3.部署node节点，执行node/node.sh
* 4.因为加入了认证的配置，所以在node节点第一次加入集群的情况下，需要master节点认证,node才可见