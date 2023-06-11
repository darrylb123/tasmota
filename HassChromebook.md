## Turn on Linux container

Settings -> Advanced -> Developers -> Turn on Linux

Once running, Add port forwarding 8123 & 1883

## Install docker

Ref: https://www.techrepublic.com/article/install-docker-chromeos/


```
$ sudo apt update
$ sudo apt upgrade
$ sudo apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y
$ curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
$ sudo apt-key fingerprint 0EBFCD88
$ sudo add-apt-repository “deb https://download.docker.com/linux/debian $(lsb_release -cs) stable”
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io -y
$ sudo usermod -aG docker $USER

```
Log out, then log back in

## Install Home Assistant
```
$ docker run -d \
  --name homeassistant \
  --privileged \
  --restart=unless-stopped \
  -e TZ=Australia/Brisbane \
  -v $HOME/hass:/config \
  --network=host \
  ghcr.io/home-assistant/home-assistant:stable
```
## Install mosquitto MQTT broker
```
$ sudo apt install mosquitto mosquitto-clients -y
```
Create a file /etc/mosquitto/conf.d/hass.conf with the following contents
```
listener 1883
allow_anonymous true
```
Start the mosquitto broker
```
$ sudo systemctl start mosquitto
```

With the ports forwarded from step 1 homeassistant and mqtt broker should be accessible from other computers on the network.

## Start home assistant
Configure the browser to start with the following tabs
Browser Settings -> On Start Up -> Open a specific page or set of pages

Add 2 tabs
- chrome-untrusted://terminal/html/terminal.html
- http://localhost:8123/

In Setting, configure to restart apps on login.
