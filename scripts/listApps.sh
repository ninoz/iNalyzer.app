if [[ "$1" == "all" ]]; then
        find /var/mobile/Containers/ -name '*.app'
else
	#find /var/mobile/Containers/Bundle/ -name '*.app'
	if [ -d /var/mobile/Containers/Bundle/Application ]; then
		find /var/mobile/Containers/Bundle/Application/ -maxdepth 2 -name '*.app' | awk -F "/" '{print $7 " " $8}'
	fi
	if [ -d /var/containers/Bundle/Application ]; then
		find /var/containers/Bundle/Application/ -maxdepth 2 -name '*.app' | awk -F "/" '{print $6 " " substr($0, index($0,$7))}'
	fi
fi
