#!/bin/sh

script_path=$(dirname $(realpath $0))

/bin/echo -e -n "\x1b[33mPlease select a steam username: \x1b[0m"
/bin/echo -e "\x1b[s"
/bin/echo -e -n "\x1b[31mNote: \x1b[0mFor mod installation to work, this user must own Arma 3."
/bin/echo -e -n "\x1b[u"
read steam_user
/bin/echo -e -n "\x1b[K"

/bin/echo -e -n "\x1b[33mChoose a server name: \x1b[0m"
/bin/echo -e "\x1b[s"
/bin/echo -e -n "\x1b[31mNote: \x1b[0mThis name can later be modified in the run script under /srv/arma3"
/bin/echo -e -n "\x1b[u"
read name
/bin/echo -e -n "\x1b[K"

/bin/echo -e -n "\x1b[33mPlease set the server password: \x1b[0m"
read password

/bin/echo -e -n "\x1b[33mPlease set the \x1b[31madmin\x1b[33m password: \x1b[0m"
read admin_password

/bin/echo -e "\x1b[32mUpdating system...\x1b[0m"
dpkg --add-architecture i386
apt update
apt install -y libc6:i386
apt install -y jq steamcmd runit runit-systemd libxml-xpath-perl rename

useradd arma
mkdir -p /srv/arma3
chown arma:arma /srv/arma3

mkdir -p /etc/arma3
mkdir -p /etc/sv/arma3

echo $steam_user > /etc/arma3/steam_user

cat <<EOF > /etc/sv/arma3/run
#!/bin/sh
cd /srv/arma3
exec chpst -u arma:arma -U arma:arma -n -5 sh start_server.sh
EOF
chmod +x /etc/sv/arma3/run
touch /etc/sv/arma3/down
ln -s /etc/sv/arma3 /etc/service

cat <<EOF > /srv/arma3/start_server.sh
#!/bin/sh
mods() {
	cat /etc/arma3/mods.json | jq -r -c '.[] | select(.server_only!="true") | .name' | tr 'A-Z ' 'a-z_' | xargs -I{} echo -mod=@{} | tr '\n' ' '
	cat /etc/arma3/mods.json | jq -r -c '.[] | select(.server_only=="true") | .name' | tr 'A-Z ' 'a-z_' | xargs -I{} echo -servermod=@{} | tr '\n' ' '
}
exec ./arma3server -profiles=/etc/arma3 -name="Shenanigans" -config=/etc/arma3/server.cfg \$(mods)
EOF

if ! [ -f /etc/arma3/mods.json ]
then
	echo "[]" > /etc/arma3/mods.json
fi

if ! [ -f /etc/arma3/server.cfg ]
then
	cat $script_path/server.cfg | sed -e 's/$password/'"$password/" -e 's/$admin_password/'"$admin_password/" -e 's/$name/'"$name/" > /etc/arma3/server.cfg
fi

mkdir -p /etc/arma3/home/$name/
if ! [ -f /etc/arma3/home/$name/$name.Arma3Profile ]
then
	cp $script_path/Arma3Profile /etc/arma3/home/$name/$name.Arma3Profile 
fi

chown --recursive arma:arma /etc/arma3
chown --recursive arma:arma /srv/arma3

bullet() { /bin/echo -e "\x1b[31m•\x1b[33m $*\x1b[0m"; }
echo 'Done!'
bullet 'Please check out your server configs under /etc/arma3'
bullet 'Run `update.sh` to install / update the game and your configured mods'
bullet 'Use `sv up arma3` to start the server for testing'
bullet 'Delete `/etc/sv/arma3/down` to make the server autostart'
