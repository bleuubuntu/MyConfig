#!/bin/bash

apt remove wkhtmltopdf
apt --fix-broken install
wget http://ftp.br.debian.org/debian/pool/main/libj/libjpeg-turbo/libjpeg62-turbo_1.5.1-2_amd64.deb
dpkg -i libjpeg62-turbo_1.5.1-2_amd64.deb

 wget http://mirrors.kernel.org/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb
dpkg -i libpng12-0_1.2.54-1ubuntu1_amd64.deb

sudo wget http://downloads.wkhtmltopdf.org/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb --no-check-certificate
sudo dpkg -i wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
sudo apt-get install -f -y

sudo cp /usr/local/bin/wkhtmltopdf /usr/bin
sudo cp /usr/local/bin/wkhtmltoimage /usr/bin
