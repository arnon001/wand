#!/bin/bash
clear
echo "Setting up the enviroment."
sudo apt update
sudo apt install docker.io git curl
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo "Done setting up the enviroment."
echo "Downloading Game Files"
git clone --recurse-submodules https://github.com/solero/wand && cd wand
echo "Done Downloading the game files."
sudo rm -r .env
echo "Please answer this questions for setting up the game:"

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

echo "enter the hostname for the game (example: example.com) (leave empty for localhost)"
read hostname
if [ -z "$hostname" ]; then
	hostname=localhost
fi
echo "Enter your external IP address (leave empty for localhost):"
read ipadd
if [ -z "$ipadd" ]; then
	ipadd=127.0.0.1
fi

echo "# database
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
GAME_LOGIN_PORT=6112" > .env

echo "Done!"
echo "You can now run the game doing the command"
echo "cd wand && sudo docker-compose up"