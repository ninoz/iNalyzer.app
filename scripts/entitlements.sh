#!/bin/bash

if [ "$1" == "" ]; then
	echo "usage: $0 <binary> <output file>"
fi

binary=$1
if [ ! -f "$binary" ]; then echo "Error! File not found: $binary"; exit 1; fi
filename=$(basename "$binary")

output=$2
if [ ! -f "$output" ]; then
	echo "Entitlements" > $output
	echo "=======" >> $output
fi

sections=$(cat "$output" | grep  '\\section entitlements_' | wc -l | awk '{print $1}')
echo "\section entitlements_${sections} Binary - $filename" >> $output
echo "~~~~~~~~~~~~{.xml}" >> $output
echo "Path: ${binary}" >> $output
echo "" >> $output
sed -n '/<dict>/,/<\/dict>/p' "$binary" >> $output
echo  "~~~~~~~~~~~~" >> $output
