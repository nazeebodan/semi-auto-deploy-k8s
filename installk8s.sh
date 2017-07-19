#!/bin/bash

#env
baseDir=""
#######Begin########

case $1 in
-h)
	echo ""
	echo " -h            help information"
	echo " -d            baseDir, Where you store your software "
	echo "               the default value is \"/softdb/semi-auto-deploy-k8s\""
	echo ""
	echo " Example: sh installk8s.sh "
	echo " Example: sh installk8s.sh -d /xxxx"
	echo ""
	exit 0
	;;
-d)
	if [ ! -n "$2" ]; then
		baseDir="/softdb/semi-auto-deploy-k8s"
	else
		baseDir=$2
	fi
	;;
*)
	if [ ! -n "$1" ]; then
	    baseDir="/softdb/semi-auto-deploy-k8s"
	else
		echo "invalid option --$1"
		echo "Try 'sh installk8s.sh -h' for more information."
		exit 1
	fi
	;;
esac

echo "------------------------------------Kubernetes Install Menu----------------------------------------"
echo "| Choose your option                                                                              |"
echo "|                                                                                                 |"
echo "|                        1.Config CA                                                              |"
echo "|                        2.Install K8s On Master                                                  |"
echo "|                        3.Install K8s On Node                                                    |"
echo "|                        4.Load Docker Images For Node                                            |"
echo "|                        5.Uninstall K8s On Master                                                |"
echo "|                        6.Uninstall K8s On Node                                                  |"
echo "|                        7.Exit                                                                   |"
echo "|                                                                                                 |"
echo "---------------------------------------------------------------------------------------------------"
echo "Choose your option (1-7):"
read answer
case $answer in
1)
	sh ca/configpem.sh ${baseDir}
	;;
2)
	sh master/k8s/master.sh ${baseDir}
	;;
3)
	sh node/node.sh ${baseDir}
	;;
4)
	sh docker/dockerLoad.sh ${baseDir}
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
	echo "Error! The number you input isn't 1 to 9"
	exit 1
	;;
esac