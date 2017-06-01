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

OE_USER="odoo"
OE_HOME="/odoo"
OE_HOME_EXT="/$OE_USER/$OE_USER-server"

#Enter version for checkout "9.0" for version 9.0,"8.0" for version 8.0, "7.0 (version 7), "master" for trunk
OE_VERSION="10.0"

#Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="8069"

#set the superadmin passwordكلمةسوب
OE_SUPERADMIN="SuperPass"
OE_CONFIG="$OE_USER-server"



#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------


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
echo -e "* Create server config file"
sudo cp $OE_HOME/debian/odoo.conf /etc/$OE_CONFIG.conf
sudo chown $OE_USER:$OE_USER /etc/$OE_CONFIG.conf
sudo chmod 640 /etc/$OE_CONFIG.conf

echo -e "* Change server config file"
echo -e "** Remove unwanted lines"
sudo sed -i "/db_user/d" /etc/$OE_CONFIG.conf
sudo sed -i "/admin_passwd/d" /etc/$OE_CONFIG.conf
sudo sed -i "/addons_path/d" /etc/$OE_CONFIG.conf

echo -e "** Add correct lines"
sudo su root -c "echo 'db_user = $OE_USER' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'admin_passwd = $OE_SUPERADMIN' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'logfile = /var/log/$OE_USER/$OE_CONFIG$1.log' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'addons_path=$OE_HOME_EXT/addons,$OE_HOME/custom/addons' >> /etc/$OE_CONFIG.conf"

echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/openerp-server --config=/etc/$OE_CONFIG.conf' >> $OE_HOME_EXT/start.sh"
sudo chmod 755 $OE_HOME_EXT/start.sh

echo -e "* Security Init File"
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Change default xmlrpc port"
sudo su root -c "echo 'xmlrpc_port = $OE_PORT' >> /etc/${OE_CONFIG}.conf"


echo -e "* Start ODOO on Startup"
sudo update-rc.d $OE_CONFIG defaults
 
sudo service $OE_CONFIG start

echo "Done! The ODOO server can be started with: service $OE_CONFIG start"
echo "Port: $OE_PORT"

    Contact GitHub API Training Shop Blog About 

    © 2016 GitHub, Inc. Terms Privacy Security Status Help 





