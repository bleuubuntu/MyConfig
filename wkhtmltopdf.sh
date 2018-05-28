#!/bin/bash

apt remove wkhtmltopdf
apt --fix-broken install
wget http://ftp.br.debian.org/debian/pool/main/libj/libjpeg-turbo/libjpeg62-turbo_1.5.1-2_amd64.deb
dpkg -i libjpeg62-turbo_1.5.1-2_amd64.deb
http://mirrors.edge.kernel.org/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb
dpkg -i libpng12-0_1.2.54-1ubuntu1_amd64.deb
wget https://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb
dpkg -i wkhtmltox-0.12.1.2_linux-jessie-amd64.deb
apt install -f -y
