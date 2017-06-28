#!/bin/bash

#######Begin########
echo "---------------------------------Kubernetes Install Menu-------------------------------------------"
echo "| Choose your option                                                                              |"
echo "|                                                                                                 |"
echo "|                     1.Config CA                                                                 |"
echo "|                     2.Install K8s On Master                                                     |"
echo "|                     3.Install K8s On Node                                                       |"
echo "|                     4.Uninstall K8s On Master                                                   |"
echo "|                     5.Uninstall K8s On Node                                                     |"
echo "|                     6.Exit                                                                      |"
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
	sh master/k8s/cleanMaster.sh
	;;
5)
	sh node/cleanNode.sh
	;;
6)
	echo "byebye"
	exit 1
	;;
*)
	echo "Error! The number you input isn't 1 to 6"
	exit 1
	;;
esac