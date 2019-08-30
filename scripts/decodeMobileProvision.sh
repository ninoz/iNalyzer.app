#!/bin/bash

if [ "$1" == "" ]; then
	echo "usage: $0 <mobileProvisionFile> <output dir>"
fi

file=$1
output=$2
echo $file

if [ ! -f "$file" ]; then
	echo "Error: The file $file was not found"
elif [ ! -d "$output" ]; then
	echo "Error: The folder $output was not found"
else
	filename=$(basename "$file")
	openssl smime -in "$file" -inform DER -verify -noverify > "${output}/${filename}.decoded"
	echo "Done: ${output}/${filename}.decoded"
fi
