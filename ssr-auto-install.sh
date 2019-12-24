#!/bin/bash
user=$(whoami)
if [ $user != root ]
then
	echo "Please run this script with sudo"
fi
# Install dependencies
apt install -y python3 libssl-dev git 2> /dev/null || yum install git python3 -y 2> /dev/null 
# Clone the repo
if [ $? -eq 0 ] 
then
	git clone https://github.com/shadowsocksrr/shadowsocksr.git /usr/share/ssrr-python
else
	exit
fi
# Choose server encryption method
function encryptmethod {
	echo -e "\t\t\tPlease choose your server encryption method\n"
	echo -e "\t1. none"
	echo -e "\t2. chacha20-ietf"
	echo -e "\t0. Exit\n\n"
	read -n 1 -p "Type your option[none]:" method
	echo -e "\n"
}
encryptmethod 
case ${method} in
	0)
		break ;;
	1)
		method=none ;;
	2)
		method=chacha20-ietf ;;
	*)
		method=none
esac
if [ -z "${method}" ]
then
	method="none"
fi
# Server password
function ssrpassword {
	old_kpasswd=`head -c 100 /dev/urandom | tr -dc a-z0-9A-Z |head -c 8`
	read  -p "Please Enter your server password[${old_kpasswd}]:" kpasswd
	echo -e "\n"
}
ssrpassword
if [ -z "${kpasswd}" ]
then
	kpasswd="${old_kpasswd}"
fi
# Server port
function ssrport {
	read -p "Type in your server port[1-65535][8888]:" pport
	if [ ! ${pport} ]
	then 
		pport=8888
	fi
	echo -e "\n"
}
ssrport
if [ ${pport} -gt 65535 ] || [ ${pport} -lt 0 ]
then 
	echo "You have wrong port number! Exit"
	exit 
fi
# obfs plugin
function ssrobfs {
	echo -e "\t\t\t obfsplugin \n"
	echo -e "\t1.plain"
	echo -e "\t2.http_simple"
	echo -e "\t3.tls_simple"
	echo -e "\t0.Exit"
	read -n 1 -p "Choose your obfsplugin[plain]:" oobfs
	echo -e "\n"
}
ssrobfs 
case ${oobfs} in 
	0)
		break ;;
	1)
		oobfs=plain ;; 
	2) 
		oobfs=http_simple ;;
	3)
		oobfs=tls_simple ;;
	*)
		oobfs=plain ;;
esac
# ssr protocol
function ssrprotocol {
       echo -e "\t\t\t Choose your server protocol" 
       echo -e "\t1.origin"
       echo -e "\t2.auth_chain_a"
       echo -e "\t3.auth_chain_b"
       echo -e "\t0.Exit\n"
       read -n 1 -p "Enter your option[auth_chain_a]:" oprotocol
       echo -e "\n"
}
ssrprotocol
case ${oprotocol} in
	0) 
		break ;;
	1)
		oprotocol=origin ;;
	2)
		oprotocol=auth_chain_a ;;
	3)
		oprotocol=auth_chain_b ;;
	*)
		oprotocol=auth_chain_a ;;
esac
# setup ssr systemd unit
function setup_ssr_unit {
cat /dev/null > /etc/systemd/system/suansuanru.service
echo "[Unit]" >> /etc/systemd/system/suansuanru.service
echo "Description=Started SSR Service" >> /etc/systemd/system/suansuanru.service
echo "After=network.target" >> /etc/systemd/system/suansuanru.service
echo "Wants=network.target" >> /etc/systemd/system/suansuanru.service
echo -e "\n" >> /etc/systemd/system/suansuanru.service
echo "[Service]" >> /etc/systemd/system/suansuanru.service
echo "ExecStart=/usr/bin/python3 /usr/share/ssrr-python/shadowsocks/server.py -p ${pport} -k ${kpasswd} -m ${method} -O ${oprotocol} -o ${oobfs} --workers 4" >> /etc/systemd/system/suansuanru.service
echo -e "\n" >> /etc/systemd/system/suansuanru.service
echo "[Install]" >> /etc/systemd/system/suansuanru.service
echo -e "WantedBy=multi-user.target" >> /etc/systemd/system/suansuanru.service
systemctl daemon-reload > /dev/null 2>&1
systemctl enable suansuanru.service && systemctl start suansuanru.service
}
setup_ssr_unit 
