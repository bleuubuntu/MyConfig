#!/bin/bash

# إعداد المتغيرات
OE_USER="odoo19"
OE_HOME="/odoo19"
OE_HOME_EXT="$OE_HOME/$OE_USER"
OE_VERSION="19.0"
OE_PORT="8099"
OE_SUPERADMIN="admin"
OE_CONFIG="$OE_USER"

echo "==== إنشاء مستخدم النظام ===="
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER

echo "==== إنشاء مجلدات وتسجيل صلاحيات ===="
sudo mkdir -p $OE_HOME/custom/addons
sudo mkdir -p $OE_HOME/venv
sudo mkdir -p /var/log/$OE_USER /var/lib/$OE_USER /etc/$OE_USER
sudo chown -R $OE_USER:$OE_USER $OE_HOME /var/log/$OE_USER /var/lib/$OE_USER /etc/$OE_USER

echo "==== إنشاء مستخدم PostgreSQL بنفس الاسم ===="
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true
sudo systemctl restart postgresql

echo "==== إنشاء بيئة Python افتراضية ===="
sudo -H -u $OE_USER bash -c "python3 -m venv $OE_HOME/venv"

echo "==== تحميل Odoo من GitHub ===="
sudo -u $OE_USER git clone --depth 1 --single-branch --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT

echo "==== تحميل ملف requirements.txt وتثبيت الحزم ===="
wget https://raw.githubusercontent.com/odoo/odoo/$OE_VERSION/requirements.txt -O /tmp/requirements.txt
sudo -H -u $OE_USER bash -c "$OE_HOME/venv/bin/pip install --upgrade pip setuptools wheel"
sudo -H -u $OE_USER bash -c "$OE_HOME/venv/bin/pip install -r /tmp/requirements.txt"

echo "==== إنشاء ملف odoo.conf ===="
cat <<EOF | sudo tee /etc/$OE_USER/$OE_CONFIG.conf > /dev/null
[options]
; التكوين الأساسي
admin_passwd = $OE_SUPERADMIN
db_user = $OE_USER
addons_path = $OE_HOME_EXT/addons,$OE_HOME/custom/addons
logfile = /var/log/$OE_USER/$OE_CONFIG.log
xmlrpc_port = $OE_PORT
EOF
sudo chown $OE_USER:$OE_USER /etc/$OE_USER/$OE_CONFIG.conf
sudo chmod 640 /etc/$OE_USER/$OE_CONFIG.conf

echo "==== إنشاء خدمة init.d لتشغيل Odoo تلقائيًا مع venv ===="
cat <<EOF | sudo tee /etc/init.d/$OE_CONFIG > /dev/null
#!/bin/sh
### BEGIN INIT INFO
# Provides:          $OE_CONFIG
# Required-Start:    \$network \$remote_fs
# Required-Stop:     \$network \$remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Odoo 17 with venv
# Description:       ERP server
### END INIT INFO

PATH=/bin:/sbin:/usr/bin
DAEMON_PYTHON=$OE_HOME/venv/bin/python
DAEMON=$OE_HOME_EXT/odoo-bin
NAME=$OE_CONFIG
DESC="Odoo Server"

USER=$OE_USER
CONFIGFILE="/etc/$OE_USER/$OE_CONFIG.conf"
PIDFILE=/var/run/\$NAME.pid
DAEMON_OPTS="-c \$CONFIGFILE"

[ -x \$DAEMON_PYTHON ] || exit 0
[ -f \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0

checkpid() {
    [ -f \$PIDFILE ] || return 1
    pid=\$(cat \$PIDFILE)
    [ -d /proc/\$pid ] && return 0
    return 1
}

case "\$1" in
start)
    echo -n "Starting \$DESC: "
    start-stop-daemon --start --quiet --pidfile \$PIDFILE \\
        --chuid \$USER --background --make-pidfile \\
        --exec \$DAEMON_PYTHON -- \$DAEMON \$DAEMON_OPTS
    echo "\$NAME."
    ;;
stop)
    echo -n "Stopping \$DESC: "
    start-stop-daemon --stop --quiet --pidfile \$PIDFILE --oknodo
    echo "\$NAME."
    ;;
restart|force-reload)
    echo -n "Restarting \$DESC: "
    start-stop-daemon --stop --quiet --pidfile \$PIDFILE --oknodo
    sleep 1
    start-stop-daemon --start --quiet --pidfile \$PIDFILE \\
        --chuid \$USER --background --make-pidfile \\
        --exec \$DAEMON_PYTHON -- \$DAEMON \$DAEMON_OPTS
    echo "\$NAME."
    ;;
*)
    echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
    exit 1
    ;;
esac
exit 0
EOF

sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG
sudo update-rc.d $OE_CONFIG defaults

echo "✅ تم التثبيت! يمكنك الآن تشغيل Odoo بالأمر التالي:"
echo "    sudo service $OE_CONFIG start"
