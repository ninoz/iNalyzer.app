#!/bin/sh
#
# Usage: dumpSQLfiels.sh lookupdir outputfile
#
#

if [[ -z ${1} ]]; then
	return;
fi
if [[ -z ${2} ]]; then
	return;
fi

#dblist=$(find ${1} -type f -print | xargs grep -sali sqlite)
#dblist=$(grep -rsnliw ${1} -e "sqlite")
IFS=$'\n'
dblist=$( find ${1} -type f -exec grep -asli sqlite {} \; )

outfile=$2

if [ ! -f "$outfile" ]; then
        echo "Database Files" > $outfile
        echo "=======" >> $outfile

	if ! sqlite3 < /dev/null > /dev/null 2>&1 ; then
	        echo "sqlite3 is not installed on the device... Cannot dump databases"
	        echo "sqlite3 is not installed on the device... Cannot dump databases" >> "${2}"
	        return;
	fi
	sqlite3 -version
fi

i=0
for source in ${dblist}; do 

	tlist=$(echo '.tables' | sqlite3 ${source} | sed 's/\s\+/\n/g')

	dbname=$(echo ${source} | tr '/' '\n' | tail -1)

	echo "\section Table${i} ${dbname}" >> ${outfile}
	echo "=======" >> ${outfile}
 #       echo "Path: ${source}" >> $outfile
	i=$(( i+1 ))
	emptyList=""
	for t in ${tlist}; do 
#		echo "T VALUE" $t
		header=$(printf ".head on\n.mode html\nselect * from ${t};" | sqlite3 ${source})
#		echo "header" $header
		if [[ ! -z ${header} ]]; then
			echo "\subsection ${t}${i} ${t}"  >> ${outfile}
			echo "" >> ${outfile}
			echo '<Table>' >>${outfile}
			echo "${header}" >>${outfile}
			echo '</Table>' >>${outfile}
		else
			emptyList="${emptyList} ${t}"
		fi
	done
	if [[ ! -z ${emptyList} ]]; then
		echo "\subsection Empty${i} Empty Tables"  >> ${outfile}
		echo "${emptyList}" >> ${outfile}
	fi
	#echo "SOURCE" $source " DONE"
done
echo "\n" >>${outfile}
