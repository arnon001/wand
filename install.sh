#!/bin/bash
clear
echo "Please answer these questions to set up the game:"
echo "Enter password for the database (leave empty for a random password):"
dbpass=""
while IFS= read -r -s -n1 char; do
    if [[ -z $char ]]; then
        break
    elif [[ $char == $'\177' ]]; then # handle backspace
        if [ ${#dbpass} -gt 0 ]; then
            dbpass="${dbpass%?}" # remove last character
            echo -ne '\b \b' # erase last character on the screen
        fi
    else
        echo -n '*'
        dbpass+="$char"
    fi
done

if [ -z "$dbpass" ]; then
    dbpass=$(openssl rand -base64 12)
fi

echo "Enter the hostname for the game (example: example.com) (leave empty for localhost):"
read hostname
if [ -z "$hostname" ]; then
    hostname=localhost
fi

echo "Enter your external IP address (leave empty for localhost):"
read ipadd
if [ -z "$ipadd" ]; then
    ipadd=127.0.0.1
fi

read -p "Do you want to run the game when the installation ends? (y/N): " run_game


if [[ $(uname) == "Linux" ]]; then
    read -p "Do you want to setup SSL? (will not work if not using a domain!) (y/N): " ssl
    echo "Setting up the environment."
    sudo apt update
    sudo apt install docker.io git curl -y
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
elif [[$(uname) == "Darwin" ]]; then
    echo "Installing homebrew"
    sudo curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
    brew install docker
    brew install git
    brew install docker-compose@2.20.3
else
    echo "This operating system isn't supported yet. feel free to join the discord and ask questions."
    exit 1
fi

echo "Done setting up the environment."
echo "Downloading Game Files"
git clone --recurse-submodules https://github.com/solero/wand && cd wand
echo "Done Downloading the game files."
sudo rm -r .env

echo "# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$dbpass

# Web
WEB_PORT=80
WEB_HOSTNAME=$hostname

WEB_LEGACY_PLAY=http://old.$hostname
WEB_LEGACY_MEDIA=http://legacy.$hostname

WEB_VANILLA_PLAY=http://play.$hostname
WEB_VANILLA_MEDIA=http://media.$hostname

WEB_RECAPTCHA_SITE=
WEB_RECAPTCHA_SECRET=

WEB_SENDGRID_KEY=

# Game
GAME_ADDRESS=$ipadd
GAME_LOGIN_PORT=6112

# Snowflake
SNOWFLAKE_HOST=$ipadd
SNOWFLAKE_PORT=7002

APPLY_WINDOWMANAGER_OFFSET=False

ALLOW_FORCESTART_SNOW=False
ALLOW_FORCESTART_TUSK=True

MATCHMAKING_TIMEOUT=30" > .env

echo "Done!"

if [ "$ssl" == "y" ] || [ "$ssl" == "Y" ]; then
    echo "Setting up SSL"
    sudo apt install certbot -y
    certbot certonly --standalone -d $hostname -d play.$hostname -d media.$hostname -d legacy.$hostname -d old.$hostname
    sudo apt install nginx -y
    sudo echo "server {
    listen 443 ssl;
    server_name play.$hostname old.$hostname legacy.$hostname media.$hostname;
    ssl_certificate /etc/letsencrypt/live/$hostname/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$hostname/privkey.pem;

    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://localhost:8080/;
        error_log /var/log/wand.log;
    }
}" > /etc/nginx/sites-available/wand
    sudo ln -s /etc/nginx/sites-available/wand /etc/nginx/sites-enabled/

fi

if [ "$run_game" == "y" ] || [ "$run_game" == "Y" ]; then
    sudo docker-compose up
else
    echo "You chose not to run the game. To run the game later, execute the command: cd wand && sudo docker-compose up"
fi
