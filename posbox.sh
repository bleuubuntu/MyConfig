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
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y locales


OE_USER="odoo"
OE_HOME="odoobo"
OE_HOME_EXT="/odoobo/odoo"


OE_VERSION="11.0"

#Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="9069"

#set the superadmin passwordكلمةسوب
OE_SUPERADMIN="Super"
OE_CONFIG="odoobo"



#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------

echo -e "\n---- Install PostgreSQL 10 Serv ----"
# sudo apt-get install postgresql -y
# echo 'deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
# wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# sudo apt-get update


echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/odoobo
sudo chown odoo:odoo /var/log/odoobo

sudo mkdir /odoobo
sudo chown odoo:odoo /odoobo

#--------------------------------------------------
# Install Basic Dependencies
#--------------------------------------------------

echo -e "\n==== Download ODOO Server ===="
cd /odoobo
cp -R /odoo/odoo /odoobo/
cd -

echo -e "\n---- Create custom module directory ----"
mkdir /odoobo/custom
mkdir /odoobo/custom/addons



echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R odoo:odoo /odoobo/*

sudo mkdir /var/lib/odoobo/
sudo chown -R odoo:odoo /var/lib/odoobo/

# Configure ODOO
#--------------------------------------------------
sudo mkdir /etc/odoobo/
sudo cp /odoobo/odoo/debian/odoo.conf /etc/odoobo/odoobo.conf
sudo chown odoo:odoo /etc/odoobo/odoobo.conf
sudo chmod 640 /etc/odoobo/odoobo.conf

echo -e "* Change server config file"
echo -e "** Remove unwanted lines"
sudo sed -i "/db_user/d" /etc/odoobo/odoobo.conf
sudo sed -i "/admin_passwd/d" /etc/odoobo/odoobo.conf
sudo sed -i "/addons_path/d" /etc/odoobo/odoobo.conf

echo -e "** Add correct lines"
sudo su root -c "echo 'db_user = odoo' >> /etc/odoobo/odoobo.conf"
sudo su root -c "echo 'admin_passwd = Super' >> /etc/odoobo/odoobo.conf"
sudo su root -c "echo 'addons_path=/odoobo/odoo/addons,/odoobo/custom/addons' >> /etc/odoobo/odoobo.conf"
sudo su root -c "echo 'logfile = /var/log/odoo/odoobo$1.log' >> /etc/odoobo/odoobo.conf"
echo -e "* Change default xmlrpc port"
sudo su root -c "echo 'xmlrpc_port = 9069' >> /etc/odoobo/odoobo.conf"
sudo su root -c "echo 'longpolling_port = 9072' >> /etc/odoobo/odoobo.conf"
sudo su root -c "echo 'server_wide_modules = web,hw_proxy,hw_posbox_homepage,hw_escpos,hw_printer_network,hw_screen' >> /etc/odoobo/odoobo.conf"



echo -e "* Create startup file"
sudo touch start.sh
sudo su root -c "echo '#!/bin/sh' >> /odoobo/odoo/start.sh"
sudo su root -c "echo 'sudo -u odoo /odoobo/odoo/odoo-bin --config=/etc/${OE_CONFIG}.conf' >> /odoobo/odoo/start.sh"
sudo chmod 755 /odoobo/odoo/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------
echo -e "* Create init file"
echo '#!/bin/sh' >> ~/odoobo
echo '### BEGIN INIT INFO' >> ~/odoobo
echo "# Provides: odoobo" >> ~/odoobo
echo '# Required-Start: $remote_fs $syslog' >> ~/odoobo
echo '# Required-Stop: $remote_fs $syslog' >> ~/odoobo
echo '# Should-Start: $network' >> ~/odoobo
echo '# Should-Stop: $network' >> ~/odoobo
echo '# Default-Start: 2 3 4 5' >> ~/odoobo
echo '# Default-Stop: 0 1 6' >> ~/odoobo
echo '# Short-Description: POSBOX Enterprise Business Applications' >> ~/odoobo
echo '# Description: posbox ODOO Business Applications' >> ~/odoobo
echo '### END INIT INFO' >> ~/odoobo
echo 'PATH=/bin:/sbin:/usr/bin' >> ~/odoobo
echo "DAEMON=/odoobo/odoo/odoo-bin" >> ~/odoobo
echo "NAME=odoobo" >> ~/odoobo
echo "DESC=odoobo" >> ~/odoobo
echo '' >> ~/odoobo
echo '# Specify the user name (Default: odoo).' >> ~/odoobo
echo "USER=odoo" >> ~/odoobo
echo '' >> ~/odoobo
echo '# Specify an alternate config file (Default: /etc/openerp-server.conf).' >> ~/odoobo
echo "CONFIGFILE=\"/etc/odoobo/odoobo.conf\"" >> ~/odoobo
echo '' >> ~/odoobo
echo '# pidfile' >> ~/odoobo
echo 'PIDFILE=/var/run/$NAME.pid' >> ~/odoobo
echo '' >> ~/odoobo
echo '# Additional options that are passed to the Daemon.' >> ~/odoobo
echo 'DAEMON_OPTS="-c $CONFIGFILE"' >> ~/odoobo
echo '[ -x $DAEMON ] || exit 0' >> ~/odoobo
echo '[ -f $CONFIGFILE ] || exit 0' >> ~/odoobo
echo 'checkpid() {' >> ~/odoobo
echo '[ -f $PIDFILE ] || return 1' >> ~/odoobo
echo 'pid=`cat $PIDFILE`' >> ~/odoobo
echo '[ -d /proc/$pid ] && return 0' >> ~/odoobo
echo 'return 1' >> ~/odoobo
echo '}' >> ~/odoobo
echo '' >> ~/odoobo
echo 'case "${1}" in' >> ~/odoobo
echo 'start)' >> ~/odoobo
echo 'echo -n "Starting ${DESC}: "' >> ~/odoobo
echo 'start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> ~/odoobo
echo '--chuid ${USER} --background --make-pidfile \' >> ~/odoobo
echo '--exec ${DAEMON} -- ${DAEMON_OPTS}' >> ~/odoobo
echo 'echo "${NAME}."' >> ~/odoobo
echo ';;' >> ~/odoobo
echo 'stop)' >> ~/odoobo
echo 'echo -n "Stopping ${DESC}: "' >> ~/odoobo
echo 'start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> ~/odoobo
echo '--oknodo' >> ~/odoobo
echo 'echo "${NAME}."' >> ~/odoobo
echo ';;' >> ~/odoobo
echo '' >> ~/odoobo
echo 'restart|force-reload)' >> ~/odoobo
echo 'echo -n "Restarting ${DESC}: "' >> ~/odoobo
echo 'start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> ~/odoobo
echo '--oknodo' >> ~/odoobo
echo 'sleep 1' >> ~/odoobo
echo 'start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> ~/odoobo
echo '--chuid ${USER} --background --make-pidfile \' >> ~/odoobo
echo '--exec ${DAEMON} -- ${DAEMON_OPTS}' >> ~/odoobo
echo 'echo "${NAME}."' >> ~/odoobo
echo ';;' >> ~/odoobo
echo '*)' >> ~/odoobo
echo 'N=/etc/init.d/${NAME}' >> ~/odoobo
echo 'echo "Usage: ${NAME} {start|stop|restart|force-reload}" >&2' >> ~/odoobo
echo 'exit 1' >> ~/odoobo
echo ';;' >> ~/odoobo
echo '' >> ~/odoobo
echo 'esac' >> ~/odoobo
echo 'exit 0' >> ~/odoobo








echo -e "* Security Init File"
sudo mv ~/odoobo /etc/init.d/odoobo
sudo chmod 755 /etc/init.d/odoobo
sudo chown root: /etc/init.d/odoobo

echo -e "* Start ODOO on Startup"
sudo update-rc.d odoobo defaults
 
sudo service odoobo start
echo "Done! The ODOO server can be started with: service odoobo start"





echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: 9069"
echo "User service: odoo"
echo "User PostgreSQL: odoo"
echo "Code location: odoo"
echo "Addons folder: odoo/odoobo/addons/"
echo "Start Odoo service: sudo service odoobo start"
echo "Stop Odoo service: sudo service odoobo stop"
echo "Restart Odoo service: sudo service odoobo restart"
echo "----------------------------------------------------------"
