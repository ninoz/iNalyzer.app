#!/bin/bash
if [ "$1" == "" ]; then
	echo "usage: $0 <plist file> <output file>"
fi

file=$1
if [ ! -f "$file" ]; then
	echo "Error: The file $file was not found"
fi
filename=$(basename "$file")

output=$2
if [ ! -f "$output" ]; then
        echo "Plist files" > $output
        echo "=======" >> $output
fi

sections=$(cat "$output" | grep  '\\section plist_' | wc -l | awk '{print $1}')
echo "\section plist_${sections} $filename" >> $output
echo "~~~~~~~~~~~~{.xml}" >> $output
echo "Path: ${file}" >> $output
echo "" >> $output
dir=$(dirname "$output")
cp -f "$file" "${dir}/${filename}.tmp"
plutil -convert xml1 "${dir}/${filename}.tmp"
cat "${dir}/${filename}.tmp" >> $output
rm -rf "${dir}/${filename}.tmp"
#echo "Done: ${output}/${filename}"
echo  "~~~~~~~~~~~~" >> $output
