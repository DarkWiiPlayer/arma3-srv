sv -v -w 60 down arma3
script_path=$(dirname $(realpath $0))

steamcmd +force_install_dir /srv/arma3/ +login "$(cat /etc/arma3/steam_user)" +app_update 233780 validate +quit

# Download or update mods
cat /etc/arma3/mods.json | jq -c .[].id | xargs -P 8 -I{} sh $script_path/download_mod.sh {}

cd /srv/arma3

mkdir -p keys
find . -maxdepth 1 -type l -name "@*" -delete
cat /etc/arma3/mods.json | jq -c .[] | while read mod
do
	name=$(echo $mod | jq -r -c .name | tr "A-Z " "a-z_")
	id=$(echo $mod | jq -r -c .id)
	ln -s steamapps/workshop/content/107410/$id @$name
done
find keys -type f -not -name 'a3.bikey' -delete
find . -name "*.bikey" | xargs -I{} -P$(nproc) cp {} keys/

chown -R arma:arma /srv/arma3

sv up arma3
