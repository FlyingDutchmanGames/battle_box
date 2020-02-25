## Add remote bare git repo
```
root@robotgame:~# mkdir battle_box.git
root@robotgame:~# cd battle_box.git/
root@robotgame:~/battle_box.git# git init --bare
Initialized empty Git repository in /root/battle_box.git/
```

## Add remote locally
```
git remote add deploy ssh://root@robotgame.grantjamespowell.com/root/battle_box.git
```

## Push Master
```
git push deploy master
```

# On Server

## clone repo
```
git clone battle_box.git battle_box
```

## Install asdf + languages
```
apt install unzip autoconf libncurses5-dev libssl-dev gpg
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.7.6
echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc
echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
asdf plugin add elixir
asdf plugin add erlang
asdf plugin add nodejs
bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
```

## Install Battlebox deps
```
asdf install
```

## Build it on the server
```
export MIX_ENV=prod
cd /root/battle_box
git pull master
mix deps.get --only prod
mix compile
npm install --prefix ./assets
mkdir -p priv/static
npm run deploy --prefix ./assets
mix phx.digest
mix release
```
