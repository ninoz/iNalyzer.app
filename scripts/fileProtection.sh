#!/bin/bash

path=$1
output=$2

if [ -z "$output" ]; then exit 1; fi

if [ ! -f "$output" ]; then
        echo "Protection Classes" > "$output"
        echo "=======" >> "$output"
fi

echo "" > "${output}.tmp"
echo "
function fileProtection() {
	var path = @\"${path}/\";
	var fm = [ NSFileManager defaultManager ];
	fin = [ fm enumeratorAtPath:path ];
	ps= [] ;
	while (name=[fin nextObject] )
	{
		fPath=path+name
		pClass=[[ fm attributesOfItemAtPath:fPath error:nil ] objectForKey:@\"NSFileProtectionKey\" ]
		if(pClass == null) {
			pClass=@\"[Folder]\"
		}
		pName=name
		ps.push('<tr><td>'+pName+'</td><td>'+pClass+'</td></tr>')
	}
	return ps.toString().replace(/,/g,'');
}

table = fileProtection();
[[NSString stringWithString:table] writeToFile:\"${output}.tmp\" atomically:NO encoding:4 error:NULL]

" | /usr/bin/cycript

echo "Path: ${path}<br />" >> "$output"
echo -e "<Table>\n<tr><th>File Path</th><th>NSFileProtectionKey</th></tr>$(cat "${output}.tmp")</table><br />\n<br />\n" >> "$output"
rm -rf "${output}.tmp"
