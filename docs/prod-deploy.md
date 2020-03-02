# Deploying Botskrieg

This is mostly for me, but others might find it interesting

## One time setup

1.) Provision a server from Digital Ocean using the `docker` base image
  A.) (I'm using the 5$ a month 1gb 1vcpu instance)
2.) Choose a dns name and point it at your instance `app.botskrieg.com` => server
  A.) Check that its pointed correctly
```
  ➜  docs git:(docker-prod-builds-part-2) ✗ dig app.botskrieg.com

; <<>> DiG 9.10.6 <<>> app.botskrieg.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 62775
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;app.botskrieg.com.		IN	A

;; ANSWER SECTION:
app.botskrieg.com.	3588	IN	A	68.183.104.42

;; Query time: 66 msec
;; SERVER: 8.8.8.8#53(8.8.8.8)
;; WHEN: Sun Mar 01 20:11:30 EST 2020
;; MSG SIZE  rcvd: 62
```
3.) Allow these ports through your firewall in digital ocean networking console
  A.) Port 22 (SSH)
  B.) Port 80 (HTTP to be redirected to HTTP 443)
  C.) Port 443 (HTTPS)
  D.) Port 4001 (BattleBox TCP Connections)
  E.) Port 4002 (BattleBox WS Connections)
4.) Go to Github and make a new Oauth App
  A.) Set the callback to `$BATTLE_BOX_HOST/auth/github/callback` (for me `https://app.botskrieg.com/auth/github/callback`)

## Box Setup (To be run on the server)

Export the hostname for your server

```
export BATTLE_BOX_HOST=app.botskrieg.com
```

### Enable Firewall

```
ufw allow ssh/tcp
ufw allow http/tcp
ufw allow https/tcp
ufw allow 4001
ufw allow 4002
ufw logging on
yes | ufw enable
ufw status
```

### Update server

```
apt update && apt upgrade
```

### Install Certbot (lets encrypt)
```
echo 'deb http://deb.debian.org/debian stretch-backports main' >> /etc/apt/sources.list
gpg --keyserver pgp.mit.edu --recv-keys 7638D0442B90D010 8B48AD6246925553
gpg --armor --export 7638D0442B90D010 | apt-key add -
gpg --armor --export 8B48AD6246925553 | apt-key add -
apt update
apt install certbot python-certbot-nginx -t stretch-backports
```

### Install Postgres

```
apt install postgresql postgresql-contrib
sudo -u postgres createuser --echo --no-createdb --pwprompt --no-superuser battle_box
sudo -u postgres createdb battle_box
```

### Create the `battle_box` User Who Will Run the App

```
useradd battle_box
mkdir /srv/battle_box
chown battle_box:battle_box /srv/battle_box
```

### Fill in These Values then add them to an env file

```base
cat | envsubst > /etc/default/battle_box <<CONF
BATTLE_BOX_HOST=$BATTLE_BOX_HOST
BATTLE_BOX_SECRET_KEY_BASE=$FILL_ME_IN
BATTLE_BOX_DATABASE_URL=$FILL_ME_IN
BATTLE_BOX_GITHUB_CLIENT_ID=$FILL_ME_IN
BATTLE_BOX_GITHUB_CLIENT_SECRET=$FILL_ME_IN
BATTLE_BOX_LIVE_VIEW_SALT=$FILL_ME_IN
CONF
```

### Install NGINX

```
apt install nginx
```

# Configure Nginx

This has to be done in two steps, so that lets encrypt can get its certs and then we configure nginx to listen on 4001 with the lets encrypt certs

```
cat | envsubst '$BATTLE_BOX_HOST' > /etc/nginx/sites-available/default <<'CONF'
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name $BATTLE_BOX_HOST;
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
```

```
certbot --nginx
```

```
cat | envsubst '$BATTLE_BOX_HOST' > /etc/nginx/nginx.conf <<'CONF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;


events {
	worker_connections 768;
}

http {
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	gzip on;

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}

stream {
  server {
	  listen 4242 ssl;
	  proxy_pass 127.0.0.1:4001;
	  ssl_certificate /etc/letsencrypt/live/$BATTLE_BOX_HOST/fullchain.pem;
	  ssl_certificate_key /etc/letsencrypt/live/$BATTLE_BOX_HOST/privkey.pem;
  }
}
CONF
```
### Building the Image

Setup SSH forwarding to grab the repo
```
https://developer.github.com/v3/guides/using-ssh-agent-forwarding/
```

Clone it 
```
git clone git@github.com:GrantJamesPowell/battle_box.git
```

Build the Image
```
root@botskreig:~/battle_box# docker build . -t battle_box:`git rev-parse HEAD`
root@botskreig:~/battle_box# docker build . -t battle_box:master
```

### Setting the image to run as Service

```
mkdir /srv/battle_box
```

```
cat > /etc/systemd/system/battle_box.service <<CONF
[Unit]
Description=BattleBox
After=network.target
[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/srv/battle_box
EnvironmentFile=/etc/default/battle_box
ExecStart=/usr/bin/docker run -p 4000 -p 4001 -p 4002 --network="host" --env-file=/etc/default/battle_box battle_box:master
Restart=on-failure
RestartSec=5
Environment=LANG=en_US.UTF-8
SyslogIdentifier=battle_box
RemainAfterExit=no
[Install]
WantedBy=multi-user.target
CONF
```

```
systemctl enable battle_box.service
```

### To shell into the box

```
docker exec -it `docker ps | grep battle_box | awk '{print $1}'` /bin/bash
```

Once inside

```
./battle_box/bin/battle_box remote
```
