#!/bin/sh
#
# Usage: dumpKeychain.sh EntitlementsFile outputfile
#
#

if [[ -z ${2} ]]; then
echo "Usage: $0 EntitlementsFile outputfile"
exit 1
fi
output=$2

echo "Keychain Data" > "${output}"
echo "=============" >> "${output}"

ids=$( cat ${1} | tr '\n' '@' | sed 's/.*keychain-access-groups<\/key>//g' | sed 's/<\/array>.*//g' | tr '@' '\n' | grep -ia string | sed 's/.*<string>//g' | sed 's/<\/string>.*//')
ids=$ids$'\n'$( cat ${1} | tr '\n' '@' | sed 's/.*application-identifier<\/key>//g' | sed 's/<\/string>.*//' | sed 's/.*<string>//g')
for id in ${ids}; do
echo "Entitlement Group: $id" >> "$output"
IFS=$'\n'

#data=$(cat $3)
data=$(tr -d '\0' < $3)

data=$(echo $data |  grep -ao ";[^;]*Entitlement Group: ${id}~[^;]*")

table_begin="<table><tr><th>Property</th><th>Value</th></tr><tr><td>Type</td><td>"
table_end="</td></tr></table>"

table_begin=$(echo $table_begin | sed 's/\//\\\//g')
table_end=$(echo "$table_end" | sed 's/\//\\\//g')

data=$(echo $data | sed "s/;/${table_end}${table_begin}/g" | sed 's/~/<\/td><\/tr><tr><td>/g' | sed 's/: /<\/td><td>/g')

table_begin=$(echo $table_begin | sed 's/\\\//\//g')
table_end=$(echo $table_end | sed 's/\\\//\//g')

echo "${table_begin}${data}${table_end}" >> "$output"
done

