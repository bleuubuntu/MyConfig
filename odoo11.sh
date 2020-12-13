#!/bin/bash
################################################################################
# Script for installing Odoo V11 only on Ubuntu 
# Author: Djerad Bessam
# They are some problem with python3-pip
# It's recommanded that you install it and reboot your computer before running this software 
#-------------------------------------------------------------------------------
# This script will install Odoo on your Ubuntu  server. It can install multiple Odoo instances
# in one Ubuntu because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# sudo sh
# sh odoo11.sh
################################################################################
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y locales

OE_USER="odoo"
OE_HOME="/odoo"
OE_HOME_EXT="/$OE_USER/$OE_USER"


OE_VERSION="11.0"

#Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="8069"

#set the superadmin passwordكلمةسوب
OE_SUPERADMIN="Super11Pass"
OE_CONFIG="$OE_USER"



#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------

echo -e "\n---- Install PostgreSQL 10 Serv ----"
# sudo apt-get install postgresql -y
# echo 'deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
# wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# sudo apt-get update

sudo apt-get install postgresql postgresql-contrib -y

echo -e "\n---- PostgreSQL $PG_VERSION Settings  ----"
# A VOIR sudo sed -i s/"#listen_addresses = 'localhost'"/"listen_addresses = '*'"/g /etc/postgresql/10/main/postgresql.conf

echo -e "\n---- Creating the 
PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

sudo service postgresql restart

#--------------------------------------------------
# System Settings
#--------------------------------------------------

echo -e "\n---- Create ODOO system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER

echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER


#--------------------------------------------------
# Install Basic Dependencies
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
apt-get install python3-pip -y

wget https://raw.githubusercontent.com/odoo/odoo/$OE_VERSION/requirements.txt
pip3 install -r requirements.txt

pip3 install docutils ebaysdk feedparser gevent greenlet html2text Jinja2 lxml Mako MarkupSafe mock ofxparse passlib psutil psycogreen psycopg2 pydot pyparsing pyserial pytz pyusb pyyaml qrcode reportlab requests six suds-py3 vatnumber vobject werkzeug XlsxWriter xlwt xlrd passlib 
pip3 install libsass==0.12.3

#--------------------------------------------------
# Odoo Web Dependencies
#--------------------------------------------------

sudo apt-get install -y npm

sudo ln -s /usr/bin/nodejs /usr/bin/node

sudo npm install -g less less-plugin-clean-css

sudo apt-get install node-less -y


#--------------------------------------------------
# cd /opt/$OE_USER

# sudo wget https://pypi.python.org/packages/a8/70/bd554151443fe9e89d9a934a7891aaffc63b9cb5c7d608972919a002c03c/gdata-2.0.18.tar.gz

# sudo tar zxvf gdata-2.0.18.tar.gz

# sudo chown -R $OE_USER: gdata-2.0.18

# sudo -s

# cd gdata-2.0.18/

# python setup.py install


#--------------------------------------------------
# Install ODOO
#--------------------------------------------------

echo -e "\n==== Download ODOO Server ===="
cd $OE_HOME
git clone --depth 1 --single-branch --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/
cd -

echo -e "\n---- Create custom module directory ----"
mkdir $OE_HOME/custom
mkdir $OE_HOME/custom/addons



echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

sudo mkdir /var/lib/$OE_USER
sudo chown -R $OE_USER:$OE_USER /var/lib/$OE_USER


echo -e "\n---- Install wkhtml and place on correct place for ODOO 8-9-10 ----"
wget http://ftp.br.debian.org/debian/pool/main/libj/libjpeg-turbo/libjpeg62-turbo_1.5.1-2_amd64.deb
dpkg -i libjpeg62-turbo_1.5.1-2_amd64.deb

 wget http://mirrors.kernel.org/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb
dpkg -i libpng12-0_1.2.54-1ubuntu1_amd64.deb

sudo wget http://downloads.wkhtmltopdf.org/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb --no-check-certificate
sudo dpkg -i wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
sudo apt-get install -f -y

sudo cp /usr/local/bin/wkhtmltopdf /usr/bin
sudo cp /usr/local/bin/wkhtmltoimage /usr/bin

pip3 install pypdf2==1.26.0
pip3 install passlib
pip3 install werkzeug==0.11.15
pip3 install lxml
apt install python-dateutil
pip3 install datetimerange
pip3 install psycopg2==2.3.7.1
pip3 install pillow
pip3 install psutil
pip3 install reportlab
pip3 install html2text
pip3 install paramiko
pip3 install num2words
pip3 install suds-jurko==0.6
#--------------------------------------------------
# Configure ODOO
#--------------------------------------------------
sudo mkdir /etc/$OE_USER/
sudo cp $OE_HOME_EXT/debian/$OE_USER.conf /etc/$OE_USER/$OE_CONFIG.conf
sudo chown $OE_USER:$OE_USER /etc/$OE_USER/$OE_CONFIG.conf
sudo chmod 640 /etc/$OE_USER/$OE_CONFIG.conf

echo -e "* Change server config file"
echo -e "** Remove unwanted lines"
sudo sed -i "/db_user/d" /etc/$OE_USER/$OE_CONFIG.conf
sudo sed -i "/admin_passwd/d" /etc/$OE_USER/$OE_CONFIG.conf
sudo sed -i "/addons_path/d" /etc/$OE_USER/$OE_CONFIG.conf

echo -e "** Add correct lines"
sudo su root -c "echo 'db_user = $OE_USER' >> /etc/$OE_USER/$OE_CONFIG.conf"
sudo su root -c "echo 'admin_passwd = $OE_SUPERADMIN' >> /etc/$OE_USER/$OE_CONFIG.conf"
sudo su root -c "echo 'addons_path=$OE_HOME_EXT/addons,$OE_HOME/custom/addons' >> /etc/$OE_USER/$OE_CONFIG.conf"
sudo su root -c "echo 'logfile = /var/log/$OE_USER/$OE_CONFIG$1.log' >> /etc/$OE_USER/$OE_CONFIG.conf"
echo -e "* Change default xmlrpc port"
sudo su root -c "echo 'xmlrpc_port = $OE_PORT' >> /etc/$OE_USER/$OE_CONFIG.conf"



echo -e "* Create startup file"
sudo touch start.sh
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/odoo-bin --config=/etc/${OE_CONFIG}.conf' >> $OE_HOME_EXT/start.sh"
sudo chmod 755 $OE_HOME/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------
echo -e "* Create init file"
echo '#!/bin/sh' >> ~/$OE_CONFIG
echo '### BEGIN INIT INFO' >> ~/$OE_CONFIG
echo "# Provides: $OE_CONFIG" >> ~/$OE_CONFIG
echo '# Required-Start: $remote_fs $syslog' >> ~/$OE_CONFIG
echo '# Required-Stop: $remote_fs $syslog' >> ~/$OE_CONFIG
echo '# Should-Start: $network' >> ~/$OE_CONFIG
echo '# Should-Stop: $network' >> ~/$OE_CONFIG
echo '# Default-Start: 2 3 4 5' >> ~/$OE_CONFIG
echo '# Default-Stop: 0 1 6' >> ~/$OE_CONFIG
echo '# Short-Description: Enterprise Business Applications' >> ~/$OE_CONFIG
echo '# Description: ODOO Business Applications' >> ~/$OE_CONFIG
echo '### END INIT INFO' >> ~/$OE_CONFIG
echo 'PATH=/bin:/sbin:/usr/bin' >> ~/$OE_CONFIG
echo "DAEMON=$OE_HOME_EXT/odoo-bin" >> ~/$OE_CONFIG
echo "NAME=$OE_CONFIG" >> ~/$OE_CONFIG
echo "DESC=$OE_CONFIG" >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# Specify the user name (Default: odoo).' >> ~/$OE_CONFIG
echo "USER=$OE_USER" >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# Specify an alternate config file (Default: /etc/openerp-server.conf).' >> ~/$OE_CONFIG
echo "CONFIGFILE=\"/etc/$OE_USER/$OE_CONFIG.conf\"" >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# pidfile' >> ~/$OE_CONFIG
echo 'PIDFILE=/var/run/$NAME.pid' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# Additional options that are passed to the Daemon.' >> ~/$OE_CONFIG
echo 'DAEMON_OPTS="-c $CONFIGFILE"' >> ~/$OE_CONFIG
echo '[ -x $DAEMON ] || exit 0' >> ~/$OE_CONFIG
echo '[ -f $CONFIGFILE ] || exit 0' >> ~/$OE_CONFIG
echo 'checkpid() {' >> ~/$OE_CONFIG
echo '[ -f $PIDFILE ] || return 1' >> ~/$OE_CONFIG
echo 'pid=`cat $PIDFILE`' >> ~/$OE_CONFIG
echo '[ -d /proc/$pid ] && return 0' >> ~/$OE_CONFIG
echo 'return 1' >> ~/$OE_CONFIG
echo '}' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo 'case "${1}" in' >> ~/$OE_CONFIG
echo 'start)' >> ~/$OE_CONFIG
echo 'echo -n "Starting ${DESC}: "' >> ~/$OE_CONFIG
echo 'start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> ~/$OE_CONFIG
echo '--chuid ${USER} --background --make-pidfile \' >> ~/$OE_CONFIG
echo '--exec ${DAEMON} -- ${DAEMON_OPTS}' >> ~/$OE_CONFIG
echo 'echo "${NAME}."' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo 'stop)' >> ~/$OE_CONFIG
echo 'echo -n "Stopping ${DESC}: "' >> ~/$OE_CONFIG
echo 'start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> ~/$OE_CONFIG
echo '--oknodo' >> ~/$OE_CONFIG
echo 'echo "${NAME}."' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo 'restart|force-reload)' >> ~/$OE_CONFIG
echo 'echo -n "Restarting ${DESC}: "' >> ~/$OE_CONFIG
echo 'start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> ~/$OE_CONFIG
echo '--oknodo' >> ~/$OE_CONFIG
echo 'sleep 1' >> ~/$OE_CONFIG
echo 'start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> ~/$OE_CONFIG
echo '--chuid ${USER} --background --make-pidfile \' >> ~/$OE_CONFIG
echo '--exec ${DAEMON} -- ${DAEMON_OPTS}' >> ~/$OE_CONFIG
echo 'echo "${NAME}."' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo '*)' >> ~/$OE_CONFIG
echo 'N=/etc/init.d/${NAME}' >> ~/$OE_CONFIG
echo 'echo "Usage: ${NAME} {start|stop|restart|force-reload}" >&2' >> ~/$OE_CONFIG
echo 'exit 1' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo 'esac' >> ~/$OE_CONFIG
echo 'iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8069' >> ~/$OE_CONFIG
echo 'exit 0' >> ~/$OE_CONFIG








echo -e "* Security Init File"
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Start ODOO on Startup"
sudo update-rc.d $OE_CONFIG defaults
 
sudo service $OE_CONFIG start
echo "Done! The ODOO server can be started with: service $OE_CONFIG start"





echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: $OE_PORT"
echo "User service: $OE_USER"
echo "User PostgreSQL: $OE_USER"
echo "Code location: $OE_USER"
echo "Addons folder: $OE_USER/$OE_CONFIG/addons/"
echo "Start Odoo service: sudo service $OE_CONFIG start"
echo "Stop Odoo service: sudo service $OE_CONFIG stop"
echo "Restart Odoo service: sudo service $OE_CONFIG restart"
echo "----------------------------------------------------------"
