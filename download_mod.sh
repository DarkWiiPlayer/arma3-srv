#!/bin/sh
id=$1
dir=/srv/arma3/steamapps/workshop/content/107410/$id
script_path=$(dirname $(realpath $0))

echo() { /bin/echo -e "\x1b[35m$*\x1b[0m"; }

if find $dir/updated -mmin -60
then
	echo "Skipping $id"
else
	echo "Downloading $id"
	until steamcmd +force_install_dir /srv/arma3/ +login "$(cat /etc/arma3/steam_user)" +workshop_download_item 107410 $id +quit
	do
		echo "Failed downloading $id, retrying in 5 seconds..."
		sleep 5
	done
	sh $script_path/fix_case.sh $dir
	touch $dir/updated
fi
