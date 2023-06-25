#!/bin/sh

if not xpath > /dev/null 2>&1
then
	apt install libxml-xpath-perl
fi

for file in "$@"
do
	outfile=$(basename -s '.html' $file).json
	echo "[" > .$outfile
	xpath -q -s "@@@@" -e '//tr' $file | tr -d '\n' | sed -e 's/@@@@/\n/g' -e 's/[ 	]\+/ /g' \
	| while read line
	do
		name=$(echo $line | xpath -q -e '//td[@data-type]/text()')
		id=$(echo $line | xpath -q -e 'string(//a/@href)' | sed -e 's/^[^=]\+=//')
		echo "	{ 'name':'$name', 'id':'$id', 'server_only':'false' }," | tr "'" '"' >> .$outfile
	done
	echo "]" >> .$outfile
	mkdir -p /etc/arma3/modpacks/
	cat .$outfile | sed "$(($(cat .$outfile | wc -l)-1))s/,$//" > /etc/arma3/modpacks/$outfile
	rm .$outfile
done
