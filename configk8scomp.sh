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
	echo " Example: sh configk8scomp.sh "
	echo " Example: sh configk8scomp.sh -d /xxxx -n ens32"	
}

cmd="sb"
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
echo "|                        1.Install Docker                                                         |"
echo "|                        2.Install Harbor                                                         |"
echo "|                        3.Install Kube-DNS                                                       |"
echo "|                        4.Install Kube-Dashboard                                                 |"
echo "|                        5.Exit                                                                   |"
echo "|                                                                                                 |"
echo "---------------------------------------------------------------------------------------------------"
echo "Choose your option (1-7):"
read answer
case $answer in
1)
	sh docker/docker.sh ${baseDir}
	;;
2)
	echo "to be continue..."
	;;
3)
	sh deploy/dashboard/deploydashboard.sh ${baseDir}
	;;
4)
	echo "to be continue..."
	;;
5)
	echo "byebye"
	exit 1
	;;
*)
	echo "Error! The number you input isn't 1 to 5"
	exit 1
	;;
esac