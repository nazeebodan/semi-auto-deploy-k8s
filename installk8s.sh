#!/bin/bash

#######Begin########
echo "---------------------------------Kubernetes Install Menu-------------------------------------------"
echo "| Choose your option                                                                              |"
echo "|                                                                                                 |"
echo "|                       1.Config CA                                                               |"
echo "|                       2.Install K8s On Master                                                   |"
echo "|                       3.Install K8s On Node                                                     |"
echo "|                       4.Load Docker Images For Node                                             |"
echo "|                       5.Uninstall K8s On Master                                                 |"
echo "|                       6.Uninstall K8s On Node                                                   |"
echo "|                       7.Exit                                                                    |"
echo "|                                                                                                 |"
echo "---------------------------------------------------------------------------------------------------"
echo "Choose your option (1-6):"
read answer
case $answer in
1)
	sh ca/configpem.sh
	;;
2)
	sh master/k8s/master.sh
	;;
3)
	sh node/node.sh
	;;
4)
	sh docker/dockerLoad.sh
	;;
5)
	sh master/k8s/cleanMaster.sh
	;;
6)
	sh node/cleanNode.sh
	;;
7)
	echo "byebye"
	exit 1
	;;
*)
	echo "Error! The number you input isn't 1 to 7"
	exit 1
	;;
esac