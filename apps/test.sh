#MY_IP=curl ifconfig.me
var=$(curl -s checkip.amazonaws.com 2>&1)
all=$(ls -ali)

echo "$var"

mkdir -p doc && cd ./doc

echo "palabas" > deno.txt
echo "$var" >> deno.txt

echo "$var" > my-ip.txt