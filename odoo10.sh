#!/bin/bash
################################################################################
# Script for installing Odoo V10 on Ubuntu 
# Author: Djerad Bessam
#-------------------------------------------------------------------------------
# This script will install Odoo on your Ubuntu  server. It can install multiple Odoo instances
# in one Ubuntu because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# sudo sh
# sh odoo_set10.sh
################################################################################
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y locales


OE_USER="odoo11"
OE_HOME="/odoo"
OE_HOME_EXT="/$OE_USER/$OE_USER"


OE_VERSION="11.0"

#Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="8069"

#set the superadmin passwordكلمةسوب
OE_SUPERADMIN="SuperPass"
OE_CONFIG="$OE_USER"



#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------

echo -e "\n---- Install PostgreSQL 10 Serv ----"
# sudo apt-get install postgresql -y
echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

sudo apt-get update

sudo apt-get install postgresql postgresql-contrib

echo -e "\n---- PostgreSQL $PG_VERSION Settings  ----"
sudo sed -i s/"#listen_addresses = 'localhost'"/"listen_addresses = '*'"/g /etc/postgresql/10/main/postgresql.conf

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
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
sudo apt-get install python3-pip


pip3 install Babel decorator docutils ebaysdk feedparser gevent greenlet html2text Jinja2 lxml Mako MarkupSafe mock num2words ofxparse passlib Pillow psutil psycogreen psycopg2 pydot pyparsing PyPDF2 pyserial python-dateutil python-openid pytz pyusb PyYAML qrcode reportlab requests six suds-jurko vatnumber vobject Werkzeug XlsxWriter xlwt xlrd

#--------------------------------------------------
# Odoo Web Dependencies
#--------------------------------------------------

sudo apt-get install -y npm

sudo ln -s /usr/bin/nodejs /usr/bin/node

sudo npm install -g less less-plugin-clean-css

sudo apt-get install node-less

#--------------------------------------------------
cd /opt/odoo

sudo wget https://pypi.python.org/packages/a8/70/bd554151443fe9e89d9a934a7891aaffc63b9cb5c7d608972919a002c03c/gdata-2.0.18.tar.gz

sudo tar zxvf gdata-2.0.18.tar.gz

sudo chown -R odoo: gdata-2.0.18

sudo -s

cd gdata-2.0.18/

python setup.py install

exit




#--------------------------------------------------
# Install ODOO
#--------------------------------------------------

echo -e "\n==== Download ODOO Server ===="
cd $OE_HOME
sudo su $OE_USER -c "git clone --depth 1 --single-branch --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/"
cd -

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "\n---- Create custom module directory ----"
sudo su $OE_USER -c "mkdir $OE_HOME/custom"
sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons"

sudo mkdir /var/lib/odoo
sudo chown -R $OE_USER:$OE_USER /var/lib/odoo


echo -e "\n---- Install wkhtml and place on correct place for ODOO 8-9-10 ----"
sudo wget http://downloads.wkhtmltopdf.org/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
sudo dpkg -i wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
sudo apt-get install -f -y
sudo dpkg -i wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
sudo cp /usr/local/bin/wkhtmltopdf /usr/bin
sudo cp /usr/local/bin/wkhtmltoimage /usr/bin


#--------------------------------------------------
# Configure ODOO
#--------------------------------------------------
sudo mkdir /etc/$OE_USER/
sudo cp $OE_HOME_EXT/debian/odoo.conf /etc/$OE_USER/$OE_CONFIG.conf
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
sudo echo '#!/bin/sh' >> $OE_HOME/start.sh
sudo echo 'sudo -u $OE_USER $OE_HOME_EXT/odoo-bin --config=/etc/$OE_USER/$OE_CONFIG.conf' >> $OE_HOME/start.sh
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
