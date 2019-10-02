#!/bin/bash
InalyzerDir=/Applications/iNalyzer.app/
InalyzerWorkdir=~/
#InalyzerWorkdir=/var/root/Documents
#LogFile=/var/root/Documents/iNalyzer/log.txt

cd $InalyzerDir/scripts

if [ -z "$1" ] || [ "$1" == "help" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
	echo ""
	echo "Usage: $0 [list | clean | version | help]"
	echo "Usage: $0 [info | ipa | sandbox | dynamic | nslog | cycript] <bundleGUID>"
	echo "Usage: $0 [static] [auto | class-dump-z | classdump-dyld] <bundleGUID>"
	echo ""
	exit 0
fi

InalyzerMode=$1
appGuid=$2
ClassdumpMode=$3
if [ -z "$ClassdumpMode" ]; then
	ClassdumpMode=auto
fi

#echo ""
#echo "--------------------------------"
#echo "Mode: list"
#echo "--------------------------------"
#echo ""
if [ "$InalyzerMode" == "list" ]; then
	./listApps.sh | sort -k 2 -f
	exit 0
fi

#echo ""
#echo "--------------------------------"
#echo "Mode: clean"
#echo "--------------------------------"
#echo ""
if [ "$InalyzerMode" == "clean" ]; then
	echo "Deleting ${InalyzerWorkdir}/iNalyzer"
	rm -rf "${InalyzerWorkdir}/iNalyzer"
	exit 0
fi

#echo ""
#echo "--------------------------------"
#echo "Mode: version"
#echo "--------------------------------"
#echo ""
if [ "$InalyzerMode" == "version" ]; then
	echo "Version: 9.3.3"
	exit 0
fi

#echo ""
#echo "--------------------------------"
#echo "Step 1: Gather app's details..."
#echo "Mode: info
#echo "--------------------------------"
#echo ""
echo appGuid=$appGuid
if [ -z "$appGuid" ]; then exit 1; fi

if [ -d /var/mobile/Containers/Bundle/Application ]; then
	appDir=$(find /var/mobile/Containers/Bundle/Application/${appGuid}/ -name *.app | head -n1)
fi
if [ -z "$appDir" ] && [ -d /var/containers/Bundle/Application ]; then
	appDir=$(find /var/containers/Bundle/Application/${appGuid}/ -name *.app | head -n1)
fi
echo appDir=$appDir
if [ -z "$appDir" ]; then exit 1; fi

appName=$( echo "$appDir" | sed 's/^.*\///' | sed 's/\.app//' )
echo appName=$appName
if [ -z "$appName" ]; then exit 1; fi

appBundleId=$( plutil "$appDir/Info.plist" | grep CFBundleIdentifier | sed 's/^.*= "\{0,1\}//' | sed 's/"\{0,1\};.*$//')
echo appBundleId=$appBundleId
if [ -z "$appBundleId" ]; then exit 1; fi

#clutchAppId=$($InalyzerDir/tools/clutchios11 -i -n | grep "$appBundleId" | cut -d ':' -f1)
#clutchAppId=$(echo $clutchAppId | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" ) #removing color characters
#echo clutchAppId=$clutchAppId
#if [ -z "$clutchAppId" ]; then echo "Warning! Clutch does not detect the app"; fi

mainExecutable=$(plutil "$appDir/Info.plist" | grep "CFBundleExecutable" | sed 's/^.*= "\{0,1\}//' | sed 's/"\{0,1\};.*$//')
echo mainExecutable=$mainExecutable
if [ -z "$mainExecutable" ]; then exit 1; fi

OIFS=$IFS
IFS=$'\n'
for file in $(find "$appDir" -name "Info.plist"); do
	exec=$(plutil "$file" | grep "CFBundleExecutable" | sed 's/^.*= "\{0,1\}//' | sed 's/"\{0,1\};.*$//')
	if [ -z "$exec" ]; then continue; fi
	
	execFullPath=$(dirname "$file")/$exec
	if [ ! -z "$appExecutablesFullPath" ]; then execFullPath=$'|'$execFullPath; fi
       	appExecutablesFullPath=${appExecutablesFullPath}$execFullPath

	if [ ! -z "$appExecutables" ] && [ ! -z "$exec" ]; then exec=$'|'$exec; fi
	appExecutables=${appExecutables}$exec
done
IFS=$OIFS
echo appExecutables=$appExecutables
echo appExecutablesFullPath=$appExecutablesFullPath
if [ -z "$appExecutables" ]; then exit 1; fi

echo isEncrypted=$(./otool.sh is_encrypted "$appDir/$mainExecutable" | xargs)

if [ -f /var/mobile/Library/FrontBoard/applicationState.plist ]; then
	appSandbox=$(plutil /var/mobile/Library/FrontBoard/applicationState.plist | grep "${appGuid}" -A 1000 | grep "sandboxPath" | head -1)
elif [ -f /var/mobile/Library/BackBoard/applicationState.plist ]; then
        appSandbox=$(plutil /var/mobile/Library/BackBoard/applicationState.plist | grep "${appGuid}" -A 1000 | grep "sandboxPath" | head -1)
fi
if [ ! -z "$appSandbox" ]; then
	appSandbox=$(echo "$appSandbox" | sed 's/^.*= "\{0,1\}//' | sed 's/";.*$//');
else
	for file in $(find /var/mobile/Containers/Data -type f -name .com.apple.mobile_container_manager.metadata.plist); do
		dir=$(grep -- "$appBundleId"  "$file" | awk '{print substr($0,13,length($0)-70)}')
		if [ ! -z "$appSandbox" ] && [ ! -z "$dir" ]; then dir=$'|'$dir; fi
		appSandbox=${appSandbox}$dir
	done
fi

#deal with multuple sandboxes
if [[ "$appSandbox" == *"|"* ]]; then
	echo "There are multiple Sandboxes"
	echo $appSandbox | tr "|" "\n"
	MainappSandbox=$(echo $appSandbox | awk -F '|' '{print $1}')
else
	MainappSandbox=$appSandbox
fi
echo "MainAppSandbox="$MainappSandbox
if [ -z "$appSandbox" ]; then exit 1; fi

if [ "$InalyzerMode" == "info" ]; then exit 0; fi

#echo ""
#echo "--------------------------------"
#echo "Mode: nslog"
#echo "--------------------------------"
#echo ""
if [ "$InalyzerMode" == "nslog" ]; then
	echo "------Start-----"
	#ondeviceconsole | grep -E ".*(${appExecutables})\[.*"
	ondeviceconsole |& grep --line-buffered -E  ".*(${appExecutables})\[.*"
	exit 0
fi

#echo ""
#echo "--------------------------------"
#echo "Step 2: Prepare the workdir..."
#echo "--------------------------------"
#echo ""

#Verify that iNalyzer workdir exist
if [ ! -d "${InalyzerWorkdir}/" ]; then mkdir "${InalyzerWorkdir}/"; fi
if [ ! -d "${InalyzerWorkdir}/iNalyzer/" ]; then mkdir "${InalyzerWorkdir}/iNalyzer/"; fi

InalyzerWorkdir="${InalyzerWorkdir}/iNalyzer/${appGuid}"
if [ ! -d "${InalyzerWorkdir}" ]; then
	mkdir "${InalyzerWorkdir}"
fi


if [ "$InalyzerMode" == "ipa" ]; then
	echo ""
	echo "--------------------------------"
	echo "Mode: ipa"
	echo "--------------------------------"
	echo ""
	echo "Preparing folders for IPA..."
	if [ -d "${InalyzerWorkdir}/ipa" ]; then
		rm -rf "${InalyzerWorkdir}/ipa"
	fi
	mkdir "${InalyzerWorkdir}/ipa"

	echo "Creating IPA file..."
	mkdir "${InalyzerWorkdir}/ipa/Payload"
	cp -rf "$appDir"/* "${InalyzerWorkdir}/ipa/Payload/"
	cp -f "${appDir}/../iTunesMetadata.plist" "${InalyzerWorkdir}/ipa/"
	cp -f "${appDir}/../iTunesArtwork" "${InalyzerWorkdir}/ipa/"
	dir=$(pwd)
	cd "${InalyzerWorkdir}/ipa"
	zip -qr "${appName}.ipa" *
	rm -rf Payload iTunes*
	cd "$dir"
	echo "OUTPUTFILE:${InalyzerWorkdir}/ipa/${appName}.ipa"
		echo "scp -P 2222 root@127.0.0.1:${InalyzerWorkdir}/ipa/${appName}.ipa ."
	exit 0
fi


if [ "$InalyzerMode" == "sandbox" ]; then
	echo ""
	echo "--------------------------------"
	echo "Mode: sandbox"
	echo "--------------------------------"
	echo ""
        echo "Preparing folders for sandbox"
        if [ -d "${InalyzerWorkdir}/sandbox" ]; then
                rm -rf "${InalyzerWorkdir}/sandbox"
        fi
        mkdir "${InalyzerWorkdir}/sandbox"

	OIFS=$IFS
	IFS=$'|'
	echo Â$appSandbox
	filename=sandbox_$(date +%Y_%m_%d-%H_%M_%S).zip
	for dir in $appSandbox; do
		echo -n "."
		echo $dir
	#find  $appSandbox -type b -type c -o -type d -o -type f -o -type l -o -type s | zip ${InalyzerWorkdir}/sandbox/$filename -@
	find  $appSandbox -type b -type c -o -type d -o -type f -o -type l -o -type s  | zip -u -q  ${InalyzerWorkdir}/$filename -@
	#zip ${InalyzerWorkdir}/$filename $(find $appSandbox -type b -type c -o -type d -o -type f -o -type l -o -type s)
	#find $appSandbox -type b -type c -o -type d -o -type f -o -type l -o -type s  -exec bash -c 'zip ${InalyzerWorkdir}/$filename' _ {} \;
	#echo zip ${InalyzerWorkdir}/$filename $(find $appSandbox -type b -type c -o -type d -o -type f -o -type l -o -type s)  2>/dev/null
	done
	IFS=$OIFS
	echo "OUTPUTFILE:${InalyzerWorkdir}/$filename"
	echo "scp -P 2222 root@127.0.0.1:${InalyzerWorkdir}/$filename ."
    exit 0
fi


if [ "$InalyzerMode" == "dynamic" ]; then
	echo ""
	echo "--------------------------------"
	echo "Mode: dynamic"
	echo "--------------------------------"
	echo ""
	
	echo "Preparing folders for dynamic..."
	if [ -d "${InalyzerWorkdir}/dynamic" ]; then
			rm -rf "${InalyzerWorkdir}/dynamic"
	fi
	mkdir "${InalyzerWorkdir}/dynamic"
	mkdir "${InalyzerWorkdir}/dynamic/data"
	mkdir "${InalyzerWorkdir}/dynamic/decodedFiles"

	echo "Preparing doxigen folders..."
	cp -rf ../doxygen/* "${InalyzerWorkdir}/dynamic/"
	sed -i -- "s/@TITLE@/iNalyzer - Dynamic Analysis/g" "${InalyzerWorkdir}/dynamic/doxygen/footer.html"
	sed -i -- "s/@PNAME@/${appBundleId}/g" "${InalyzerWorkdir}/dynamic/doxygen/dox.template"
	sed -i -- "s/@OUTDIR@/.\//g" "${InalyzerWorkdir}/dynamic/doxygen/dox.template"
	sed -i -- "s/@INDIR@/.\/data/g" "${InalyzerWorkdir}/dynamic/doxygen/dox.template"

	echo "===Dump keychain"
	echo "Watch your device for a promt to enter your pin!!"
	../tools/keychaindumper++ -a | tr '\n' '~' | sed 's/~~/;/g' > ${InalyzerWorkdir}/dynamic/data/keychaindump
	OIFS=$IFS
	IFS=$'|'
	for file in $appExecutablesFullPath; do
		echo -n "."
		./entitlements.sh "$file" "${InalyzerWorkdir}/dynamic/data/__entitlements.md.tmp"
		./dumpKeychain.sh "${InalyzerWorkdir}/dynamic/data/__entitlements.md.tmp" "${InalyzerWorkdir}/dynamic/data/__keychain.md" "${InalyzerWorkdir}/dynamic/data/keychaindump"
		rm -rf "${InalyzerWorkdir}/dynamic/data/__entitlements.md.tmp"
	done
	IFS=$OIFS

	OIFS=$IFS
	IFS=$'|'
	for dir in $appSandbox; do
		echo "***===Analyse $dir"
		echo "===Decode cookies"
		find "${dir}" -name 'Cookies.binarycookies' -print | while read f; do
			./decodeCookies.sh $f "${InalyzerWorkdir}/dynamic/data/__cookies.md"
		done

		echo "===Decode plist files"
		
		if [[ ! -n $(find "$dir" -name "*.plist" -type f) ]]; then
			echo "Plist files was not found"
		else
			find "$dir" -name "*.plist" -type f -print | while read f; do
				 echo -n "."
				./decodePlist.sh "$f" ${InalyzerWorkdir}/dynamic/data/__plist.md
			done
		fi

		echo "===Dump db files"
		./dumpSQLFiles.sh "${dir}" "${InalyzerWorkdir}/dynamic/data/__databases.md"

		echo "===Dump data protection of files"
		./fileProtection.sh "${dir}" "${InalyzerWorkdir}/dynamic/data/__fileProtection.md"
		
		
	done
	
	IFS=$OIFS

	dir=$(pwd)
	cd "${InalyzerWorkdir}/dynamic/"
	filename=dynamic_$(date +%Y_%m_%d-%H_%M_%S).zip
	zip -qr "${InalyzerWorkdir}/$filename" .
	echo "${InalyzerWorkdir}/dynamic/"
	rm -rf "${InalyzerWorkdir}/dynamic/"

	echo "OUTPUTFILE:${InalyzerWorkdir}/$filename"
	echo "scp -P 2222 root@127.0.0.1:${InalyzerWorkdir}/$filename ."
	exit 0
fi



if [ "$InalyzerMode" == "static" ]; then
	echo ""
	echo "--------------------------------"
	echo "Mode: static"
	echo "--------------------------------"
	echo ""
	echo "Preparing folders for static..."
	if [ -d "${InalyzerWorkdir}/static" ]; then
			rm -rf "${InalyzerWorkdir}/static"
	fi
	mkdir "${InalyzerWorkdir}/static"
	mkdir "${InalyzerWorkdir}/static/data"
	mkdir "${InalyzerWorkdir}/static/decodedFiles"
	mkdir "${InalyzerWorkdir}/static/decryptedBinaries"

	echo "Preparing doxigen folders..."
	cp -rf ../doxygen/* "${InalyzerWorkdir}/static/"
	sed -i -- "s/@TITLE@/iNalyzer - Static Analysis/g" "${InalyzerWorkdir}/static/doxygen/footer.html"
	sed -i -- "s/@PNAME@/${appBundleId}/g" "${InalyzerWorkdir}/static/doxygen/dox.template"
	sed -i -- "s/@OUTDIR@/.\//g" "${InalyzerWorkdir}/static/doxygen/dox.template"
	sed -i -- "s/@INDIR@/.\/data/g" "${InalyzerWorkdir}/static/doxygen/dox.template"

	#detect encryption status using otool/jtool
	isEncrypted=$(./otool.sh is_encrypted "$appDir/$mainExecutable" | xargs)

	#Fix common issue of no memmory in clutch when there are a lot of frameworks
	ulimit unlimited
	if [ "$isEncrypted" == "1" ]; then
		decipa="${MainappSandbox}Documents/decrypted-app.ipa"
		echo "DEBUG: $decipa"
		if [ -f "$decipa" ]; then
			echo "decrypted IPA already present"
			echo "We need to class dump the binaries off device, copy the following IPA to a MACOS image"
			echo "    /opt/classdumper/clean.sh"
			echo "    scp -P 2222 root@127.0.0.1:"$MainappSandbox"Documents/decrypted-app.ipa /opt/classdumper/Payload/"
			echo "    unzip /opt/classdumper/Payload/decrypted-app.ipa -d /opt/classdumper/Payload/"
			echo "    /opt/classdumper/dumpheaders.sh"
			echo "SCP the headers back to the device when complete:"
			echo "    scp -r -P 2222 /opt/classdumper/headers/* root@127.0.0.1:$InalyzerWorkdir/static/data/"
			unzip -j -qq -B $MainappSandbox"Documents/decrypted-app.ipa" -d   "${InalyzerWorkdir}/static/decryptedBinaries/" -x *.png
			echo "come back here and enter to continue"
		else
			echo "We need to manually decrypt the App"
			echo "Go to setting and then BFDecrypt"
			echo "Select you app and then launch it"
			echo "you will get a message once its been decrypted"
			echo "come back here and enter to continue"
			read pause			
			unzip -j -qq -B $MainappSandbox"Documents/decrypted-app.ipa" -d   "${InalyzerWorkdir}/static/decryptedBinaries/" -x *.png
			echo "We need to class dump the binaries off device, copy the following IPA to a MACOS image"
			echo "    /opt/classdumper/clean.sh"
			echo "    scp -P 2222 root@127.0.0.1:"$MainappSandbox"Documents/decrypted-app.ipa /opt/classdumper/Payload/"
                        echo "    unzip /opt/classdumper/Payload/decrypted-app.ipa -d /opt/classdumper/Payload/"
                        echo "    /opt/classdumper/dumpheaders.sh"
			echo "SCP the headers back to the device when complete:"
			echo "    scp -r -P 2222 /opt/classdumper/headers/* root@127.0.0.1:$InalyzerWorkdir/static/data/"
			echo "come back here and enter to continue"
		fi
	elif [ $isEncrypted == "0" ]; then
		echo "Binaries are not encrypted, coping them to the decryptedBinaries folder"
		OIFS=$IFS
		IFS=$'|'
		for file in $appExecutablesFullPath; do
			cp -f "$file" "${InalyzerWorkdir}/static/decryptedBinaries/"
		done 
		IFS=$OIFS
			echo "We need to class dump the binaries off device, copy the following IPA to a MACOS image"
			echo "scp -P 2222 -r root@127.0.0.1:${InalyzerWorkdir}/static/decryptedBinaries/ /opt/classdumper//Payload/"
                        echo "    unzip /opt/classdumper/Payload/decrypted-app.ipa -d /opt/classdumper/Payload/"
                        echo "    /opt/classdumper/dumpheaders.sh"
			echo "SCP the headers back to the device when complete:"  
			echo "     scp -r -P 2222  /opt/classdumper/headers/* root@127.0.0.1:$InalyzerWorkdir/static/data/"
			echo "come back here and enter to continue"
	else
        	echo "Error: Unknown encryption status, otool.sh output: $isEncrypted"
	fi
	read waiting
	echo "===Binary analysis on:"
	ls ${InalyzerWorkdir}/static/decryptedBinaries/
	echo "======"
	for f in ${InalyzerWorkdir}/static/decryptedBinaries/*
	do
		(file $f | grep "executable")
		status=$?
		echo -n "."
		if [ "$status" == "0" ]; then
			echo ""
			echo $f "is a binary"
			echo "Fetching binary info"
			./binaryInfo.sh "$f" "${InalyzerWorkdir}/static/data/__binaryInfo.md"
			echo "Fetching entitlements"
			./entitlements.sh "$f" "${InalyzerWorkdir}/static/data/__entitlements.md"
			echo "Looking for interesting symbols"
			./symbols.sh "$f" "${InalyzerWorkdir}/static/data/__symbols.md"
			echo "Dumping strings"
			f_base=$(basename "$f")
			./strings.sh "$f" "${InalyzerWorkdir}/static/data/__strings_${f_base}.md"
		fi
	done
	echo " "
	echo "===Analyze interfaces..."
	./nibFiles.sh "$appDir" "$InalyzerWorkdir/static/data/__interfaces.md"
	./viewControllers.sh "$InalyzerWorkdir/static/data/" "$InalyzerWorkdir/static/data/__interfaces.md"

	echo "===Decode mobile provisioning files..."
	#echo $appDir
	#find "$appDir" -name "*.mobileprovision" -type f -exec ./decodeMobileProvision.sh {} "${InalyzerWorkdir}/static/decodedFiles" \;
	if [[ ! -n $(find "$appDir" -name "*.mobileprovision" -type f) ]]; then
		echo "Mobile provision file was not found"
	else
		find "$appDir" -name "*.mobileprovision" -type f -print | while read f; do
			./decodeMobileProvision.sh "$f" "${InalyzerWorkdir}/static/decodedFiles"
		done
	fi	

	
	echo "===Decode plist files"
	if [[ ! -n $(find "$appDir" -name "*.plist" -type f) ]]; then
		echo "Plist files was not found"
	else
		find "$appDir" -name "*.plist" -type f -print | while read f; do
		./decodePlist.sh "$f" ${InalyzerWorkdir}/static/data/__plist.md
		done
	fi

	dir=$(pwd)
	cd "${InalyzerWorkdir}/static"
	filename=static_$(date +%Y_%m_%d-%H_%M_%S).zip
        zip -qr "$filename" *
	mv "$filename" ../
	cd ../
	rm -rf static
	#rm -rf dox* data decodedFiles decryptedBinaries index.html
	cd "$dir"
	echo "OUTPUTFILE:${InalyzerWorkdir}/$filename"
	echo "scp -P 2222 root@127.0.0.1:${InalyzerWorkdir}/$filename ."
	exit 0
fi
