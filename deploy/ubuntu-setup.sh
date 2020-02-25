#!/bin/bash -ex

# Setup Firewall
ufw allow ssh/tcp
ufw allow http/tcp
ufw allow https/tcp
ufw allow 4001
ufw logging on
ufw enable
ufw status

# Install Nginx
apt update
apt install nginx

# Configure Nginx
cat > /etc/nginx/sites-available/default <<'CONF'
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name robotgame.grantjamespowell.com;
  location ~ /.well-known {
    root /var/www/html;
    allow all;
  }
  location / {
    proxy_pass http://127.0.0.1:4000/;
    proxy_http_version 1.1;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
  }
}
CONF

# Install Certbot (letsencrypt)
echo 'deb http://deb.debian.org/debian stretch-backports main' >> /etc/apt/sources.list
gpg --keyserver pgp.mit.edu --recv-keys 7638D0442B90D010 8B48AD6246925553
gpg --armor --export 7638D0442B90D010 | apt-key add -
gpg --armor --export 8B48AD6246925553 | apt-key add -
apt update
apt install certbot python-certbot-nginx -t stretch-backports
certbot --nginx

# Install Postgres
apt install postgresql postgresql-contrib
sudo -u postgres createuser --echo --no-createdb --pwprompt --no-superuser battle_box
sudo -u postgres createdb battle_box

# Install the App
useradd battle_box
mkdir /srv/battle_box
chown battle_box:battle_box /srv/battle_box

(cd /srv/battle_box && sudo -u battle_box tar -xf ../battle_box.tar.gz)

cat > /etc/default/battle_box <<CONF
BATTLE_BOX_SECRET_KEY_BASE=
BATTLE_BOX_DB_USER=battle_box
BATTLE_BOX_DB_PASS=
BATTLE_BOX_DB_DATABASE=battle_box
BATTLE_BOX_DB_HOST=localhost
BATTLE_BOX_GITHUB_CLIENT_ID=
BATTLE_BOX_GITHUB_CLIENT_SECRET=
CONF

/srv/battle_box/bin/battle_box migrate

cat > /etc/systemd/system/battle_box.service <<CONF
[Unit]
Description=BattleBox Server
After=network.target
[Service]
Type=simple
User=battle_box
Group=battle_box
WorkingDirectory=/srv/battle_box
EnvironmentFile=/etc/default/battle_box
ExecStart=/srv/battle_box/bin/battle_box foreground
Restart=on-failure
RestartSec=5
Environment=LANG=en_US.UTF-8
SyslogIdentifier=battle_box
RemainAfterExit=no
[Install]
WantedBy=multi-user.target
CONF

systemctl enable battle_box.service
