#!/bin/bash
function filter(){
sed '{
s/%23/#/g;
s/%0D%0A/n/g;
s/%5E/^/g;
s/%3A/:/g;
s/%2F///g;
s/%28/\(/g;
s/%7C/\|/g;
s/%29/\)/g;
s/%24/$/g;
s/%25/%/g;
s/%3F/?/g;
s/%3D/=/g;
s/%5C/\/g;
}' $1
}

function regulate(){
sed "{
1i#$custom
$a#$custom+end
$!N; /^(.*)n1$/!P;D
}" $1
}

function uniform(){
awk -F"[+| ]" '{
for(i=1;i<=NF;i++){
if($i~/[0-9]+.[0-9]+.[0-9]+.[0-9]+/){
print $i
}
}
}'
}

echo "Content-type:text/html"
echo ""
echo "<html>"
if [ "$REQUEST_METHOD" = "POST" ] ; then
QUERY_STRING=`cat -`
fi

#echo "<center>$QUERY_STRING</center>"
action=`echo $QUERY_STRING|awk -F"[=|&]" '{print $8}'`
custom=`echo $QUERY_STRING|awk -F"[=|&]" '{print $6}'`
iplist=`echo $QUERY_STRING|awk -F"[=|&]" '{print $4}'|filter|uniform`

case $action in
add)
ref_conf=`echo $QUERY_STRING|awk -F"[=|&]" '{print $2}'|filter|regulate|sed '1!G;h;$!d'`
#echo "$ref_conf"
for ip in $iplist;do
ping -c 3 $ip|awk -F, '/loss/{print $3}'
for ref in $ref_conf;do
echo "$ref<br>"
/usr/local/bin/sshpass -p 123456 ssh -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no root@$ip sed -i "/config/a\`echo $ref|sed 's/+/\ /g'`" /home/squid/etc/squid.conf && /home/squid/sbin/squid -k reconfigure
done
done
;;
wget)
test_url=`echo $QUERY_STRING|awk -F"[=|&]" '{print $2}'|filter`
for ip in $iplist;do
for url in $test_url;do
domain=`echo $url|awk -F/ '{print $3}'`
echo "$ip $domain" > /etc/hosts
wget -S -O /dev/null "$url" -o wget.log ?no-check-certificate -t 1
cat wget.log|awk 'BEGIN{ORS="<br>"}1'
done
done
;;
curl)
test_url=`echo $QUERY_STRING|awk -F"[=|&]" '{print $2}'|filter`
for url in $test_url;do
echo "##################################<br>"
echo "###$url<br>"
for ip in $iplist;do
domain=`echo $url|awk -F/ '{print $3}'`
echo "##############<br>"
echo "$ip<br>"
curl -I -x $ip:80 -A "support/RT (21V-CDN)" -e "http://$domain" "$url"|awk 'BEGIN{ORS="<br>"}/HTTP/1|Cache|Age/'
sleep 1;
done
done
;;
*)
echo '<head><META HTTP-EQUIV="refresh" Content="0;URL=http://1.2.3.4/index.html"></head>'
;;
esac

echo "</html>"
