#!/bin/bash

if [ "$1" == "" ]; then
	echo "usage: $0 <binary> <output file>"
fi

binary=$1
if [ ! -f "$binary" ]; then echo "Error! File not found: $binary"; exit 1; fi
filename=$(basename "$binary")

output=$2
if [ ! -f "$output" ]; then
	echo "Binary info" > $output
	echo "=======" >> $output
fi

sections=$(cat "$output" | grep  '\\section binaryInfo_' | wc -l | awk '{print $1}')
echo "\section binaryInfo_${sections} ${filename}" >> $output

echo "\subsection binaryInfoPath_${sections} Path" >> $output
echo "~~~~~~~~~~~~{.xml}" >> $output
echo "${binary}" >> $output
echo  "~~~~~~~~~~~~" >> $output

echo "\subsection binaryInfoHeaders_${sections} Headers" >> $output
echo "~~~~~~~~~~~~{.xml}" >> $output
otool -arch all -h "$binary" >> $output
echo  "~~~~~~~~~~~~" >> $output

echo "\subsection binaryInfoPIE_${sections} PIE" >> $output
echo "~~~~~~~~~~~~{.xml}" >> $output
./otool.sh pie "$binary" >> $output
echo  "~~~~~~~~~~~~" >> $output

echo "\subsection binaryInfoStackSmashing_${sections} Stack Smashing" >> $output
echo "~~~~~~~~~~~~{.xml}" >> $output
./otool.sh stack_smashing "$binary" >> $output
echo  "~~~~~~~~~~~~" >> $output

echo "\subsection binaryInfoArc_${sections} ARC" >> $output
echo "~~~~~~~~~~~~{.xml}" >> $output
./otool.sh arc "$binary" >> $output
echo  "~~~~~~~~~~~~" >> $output

echo "\subsection binaryInfoEncryption_${sections} Encryption information" >> $output
echo "~~~~~~~~~~~~{.xml}" >> $output
./otool.sh encryption "$binary" >> $output
echo  "~~~~~~~~~~~~" >> $output
