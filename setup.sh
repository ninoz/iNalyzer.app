#!/bin/bash
running=$(ps aux | grep [C]ydia | wc -l)
if [[ "$running" == "1" ]]; then
        echo "Cydia is running, kill it from the task manager and rerun this script!"
	exit 1
fi

echo "deb https://appsec-labs.com/cydia/ ./" >> /etc/apt/sources.list.d/cydia.list
echo "deb https://level3tjg.me/repo ./" >> /etc/apt/sources.list.d/cydia.list
echo "deb https://jakeashacks.net/cydia/ ./" >> /etc/apt/sources.list.d/cydia.list

apt-get -y --allow-unauthenticated update
apt-get -y --allow-unauthenticated update

apt-get -y --allow-unauthenticated install perl
apt-get -y --allow-unauthenticated install git
apt-get -y --allow-unauthenticated install com.ericasadun.utilities
apt-get -y --allow-unauthenticated install sqlite3 
apt-get -y --allow-unauthenticated install openssl
apt-get -y --allow-unauthenticated install com.jakeashacks.jtool
apt-get -y --allow-unauthenticated install cycript
apt-get -y --allow-unauthenticated install com.level3tjg.bfdecrypt
apt-get -y --allow-unauthenticated install com.appsec-labs.inalyzer
apt-get -y --allow-unauthenticated install com.bingner.plutil

mv /Applications/iNalyzer.app/ /Applications//iNalyzer.appBKUP/ 
cd /Applications/
git clone https://github.com/ninoz/iNalyzer.app.git
chown -R root:admin iNalyzer.app
cd iNalyzer.app
chmod +x iNalyzer.sh
chmod +x scripts/*.sh
chmod +x tools/*
ldid -Stools/entitlements.xml tools/keychaindumper++
dpkg -i /Applications/iNalyzer.app/tools/class_dump_ios.deb
killall -9 SpringBoard
