#!/bin/bash

#env
baseDir="/softdb/semi-auto-deploy-k8s"
networkDeviceName="eth0"
#######Begin########
printHelp(){
	echo ""
	echo " -h            help information"
	echo " -d            baseDir, Where you store your software "
	echo "               the default value is \"/softdb/semi-auto-deploy-k8s\""
	echo " -n            network device name, such as eth0,ens32,etc.. "
	echo "               the default value is \"eth0\""
	echo ""
	echo " Example: sh installk8s.sh "
	echo " Example: sh installk8s.sh -d /xxxx -n ens32"	
}

while getopts d:n:h x
do
    case $x in
        d) baseDir=$OPTARG
        	;;
        n) networkDeviceName=$OPTARG
        	;;
        h) printHelp
        	exit 0
        	;;
        \?) echo "invalid parameter"
        	printHelp
        	exit 0
        	;;
    esac
done


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
	sh master/k8s/master.sh ${baseDir} ${networkDeviceName}
	;;
3)
	sh node/node.sh ${baseDir} ${networkDeviceName}
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
	echo "Error! The number you input isn't 1 to 7"
	exit 1
	;;
esac
