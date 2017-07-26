#!/bin/bash
## $1 = domain name

mkdir $1


echo "Extracting Subdomains ....."
/home/sada/Sublist3r/sublist3r.py -d $1 -o $1/subdomains.txt > $1/sublister.log
echo "$1" >> $1/subdomains.txt

echo "Digging Subdomains ....."
for url in $(cat $1/subdomains.txt); do dig $url; done > $1/dig.log

echo "Extracting IP Addresses ....."
grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' $1/dig.log | sort | uniq > $1/IP_Addresses.txt

echo "Extracting CNames....."
grep "CNAME" $1/dig.log > $1/CNAMEs.txt

if [ "$2" == "scan" ]; then
	echo "NMapping Subdomains....."
		for ip in $(cat $1/IP_Addresses.txt); 
		do 
			echo "*****************" >> $1/nmapscan.txt; 
			echo $ip >> $1/nmapscan.txt; 
			echo "*****************" >> $1/nmapscan.txt; 
			echo "   " >> $1/nmapscan.txt; 
			nmap -T4 -F $ip | grep "open" >> $1/nmapscan.txt;
			echo "   " >> $1/nmapscan.txt; 
		done
fi
echo "Checking WordPress Installations....."
for url in $(cat $1/subdomains.txt);
do
	wpurl1=http://$url
	wpstring1=$(curl -s -m 5 $wpurl1 | grep -o "$url/wp-content" &)
	if [ "$wpstring1" != "" ]; then
		echo $wpurl1 >> $1/wordpress_urls.txt
		xmlrpcurl="http://$url/xmlrpc.php"
		xmlrpcstr=$(curl -s -m 5 $xmlrpcurl | grep -o "XML-RPC server accepts POST requests only" &)
		if [ "$xmlrpcstr" != "" ]; then
			echo $xmlrpcurl >> $1/wordpress_urls.txt
		fi
	fi

	wpurl2=https://$url
	wpstring2=$(curl -s -m 5 $wpurl2 | grep -o "$url/wp-content" &)
	if [ "$wpstring2" != "" ]; then
		echo $wpurl2 >> $1/wordpress_urls.txt
		xmlrpcurl="https://$url/xmlrpc.php"
		xmlrpcstr=$(curl -s -m 5 $xmlrpcurl | grep -o "XML-RPC server accepts POST requests only" &)
		if [ "$xmlrpcstr" != "" ]; then
			echo $xmlrpcurl >> $1/wordpress_urls.txt
		fi
	fi
done
