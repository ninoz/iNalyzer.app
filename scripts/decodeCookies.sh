#!/bin/bash

if [ "$1" == "" ]; then
	echo "usage: $0 <binary cookies file> <output file>"
fi

file=$1
if [ ! -f "$file" ]; then
	echo "Error: The file $file was not found"
fi

output=$2
if [ ! -f "$output" ]; then
        echo "Binary cookies" > "$output"
        echo "=======" >> "$output"
fi

#sections=$(cat "$output" | grep  '\\section plist_' | wc -l | awk '{print $1}')
#echo "\section plist_${sections} $file" >> $output

echo "~~~~~~~~~~~~{.xml}" >> "$output"
if perl < /dev/null > /dev/null 2>&1 ; then
	perl ../tools/safari_cookie_bin.pl "${file}" >> "${output}"
elif python < /dev/null > /dev/null 2>&1 ; then
	echo "Perl is not installed.. trying a python decoder"
	python ../tools/BinaryCookieReader.py "${file}" >> "${output}"
else
	echo "Perl and Python are not installed on the device... Cannot decrypt"
	echo "Perl and Python are not installed on the device... Cannot decrypt" >> "$output"
fi
echo "~~~~~~~~~~~~" >> "$output"
