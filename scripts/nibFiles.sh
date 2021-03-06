#!/bin/bash

path=$1
output=$2

if [ -z "$output" ]; then exit 1; fi
if [ ! -f "$output" ]; then
        echo "Interfaces" > $output
        echo "=======" >> $output
fi

echo "\section interfaces_nibFiles *.nib files" >> $output

echo -e "<Table>\n<tr><th>Filename</th><th>Path</th></tr>" >> $output
find "${path}" -name "*.nib" -printf "<tr><td>%f</td><td>%p</td></tr>\n" >> $output
echo "</table>" >> $output
