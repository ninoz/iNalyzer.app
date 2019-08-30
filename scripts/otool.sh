#!/bin/bash

if [ "$1" == "" ]; then
	echo "usage: $0 [encryption | is_encrypted | pie | stack_smashing | arc] <binary>"
fi

func=$1
binary=$2
if [ ! -f "$binary" ]; then echo "Error! File not found: $binary"; exit 1; fi

if [ "$func" == "encryption" ]; then
	#otool -l "$binary" | grep -i crypt
	ret=$(otool -l "$binary" | grep LC_ENCRYPTION_INFO | wc -l | tr -d ' ')
	if [ "$ret" == "1" ]; then
		otool -l "$binary" | grep -A 4 LC_ENCRYPTION_INFO
	else
		#echo "otool didn't find LC_ENCRYPTION_INFO, probably the otool isn't updated. Trying to run jtool..."
		jtool -l -arch 0 "$binary" | grep LC_ENCRYPTION_INFO
	fi
elif [ "$func" == "is_encrypted" ]; then
	output=$(./otool.sh encryption "$binary" | grep -E "(cryptid.*1|Encryption: 1)")
	#echo $output
	if [ -z "$output" ]; then
		echo 0
	else
		echo 1
	fi
elif [ "$func" == "pie" ]; then
	otool -Vh "$binary"
elif [ "$func" == "stack_smashing" ]; then
	otool -Iv "$binary" | grep stack
elif [ "$func" == "arc" ]; then
	otool -Iv "$binary" | grep _objc_release
else
	echo "unrecognized flag: $func"

fi
