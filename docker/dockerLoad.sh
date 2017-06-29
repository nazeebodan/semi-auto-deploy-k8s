#!/bin/bash

##check last command is OK or not.
check_ok() {
        if [ $? != 0 ]
                then
                echo "Error, Check the error log."
                exit 1
        fi
}

#env
baseDir="$1"

echo "***************************************************************************************************"
echo "*   NOTE:                                                                                         *"
echo "*            Now,We will load some docker images (pod-infrastructure,pasue,dns,etc..),            *"
echo "*            And it will store docker's default datadir !                                         *"
echo "*                                                                                                 *"
echo "*            If you want to change the default docker datadir,Please input 'no'                   *"
echo "*            After you change the default datadir,you may load those images  manually             *"
echo "*                                                                                                 *"
echo "*                                                                                                 *"
echo "***************************************************************************************************"
echo "would you load some docker images now? (yes/no):"
read loadanswer
if [ "${loadanswer}" = "yes" -o "${loadanswer}" = "y" ];then
	echo "step:------> loading some docker images"
	sleep 1
	cd ${baseDir}/docker
	echo "step:------> unzip docker images packages"
	sleep 1
	tar -zxf dockerdir.tar.gz
	check_ok
	echo "step:------> unzip docker images packages completed."
	sleep 1
	echo "step:------> loading some docker images"
	sleep 1
	sh dockerLoadDetail.sh
	echo "step:------> loading some docker images completed."
	sleep 1
fi