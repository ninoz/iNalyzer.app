#!/bin/bash

if [ "$1" == "" ]; then
	echo "usage: $0 <binary> <output file>"
fi

binary=$1
if [ ! -f "$binary" ]; then echo "Error! File not found: $binary"; exit 1; fi
filename=$(basename "$binary")

output=$2
if [ ! -f "$output" ]; then
	echo "Symbols analysis - Memory functions" > $output
	echo "=======" >> $output
fi

sections=$(cat "$output" | grep  '\\section symbols_' | wc -l | awk '{print $1}')
echo "Looking for secure and insecure functions in the executables: strlcat, strncat, strcat, strlcopy, strncpy, strcpy, snprintf, vsnprintf, sprint, vsprintf, asprintf, fgest, gets, malloc, free" >> $output
echo "\section symbols_${sections} Binary - $filename" >> $output
echo "~~~~~~~~~~~~{.xml}" >> $output
echo "Path: ${binary}" >> $output
echo "" >> $output
otool -Iv "$binary" | grep -iE '(strlcat|strncat|strcat|strlcopy|strncpy|strcpy|snprintf|vsnprintf|sprint|vsprintf|asprintf|fgest|gets|malloc|free)$' >> $output
echo  "~~~~~~~~~~~~" >> $output
