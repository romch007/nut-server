#!/bin/sh
set -eu

: "${UPS_NAME:=apc}"
: "${UPS_DRIVER:=usbhid-ups}"
: "${UPS_PORT:=auto}"
: "${UPS_VENDORID:=051d}"
: "${UPS_PRODUCTID:=0002}"
: "${UPS_DESC:=APC UPS}"

: "${NUT_LISTEN:=0.0.0.0}"
: "${NUT_PORT:=3493}"

: "${NUT_USER:=homeassistant}"
: "${NUT_PASSWORD:?NUT_PASSWORD must be set}"

mkdir -p /run/nut /var/state/nut
chown -R nut:nut /run/nut /var/state/nut

cat > /etc/nut/nut.conf <<EOF
MODE=netserver
EOF

cat > /etc/nut/ups.conf <<EOF
[$UPS_NAME]
    driver = $UPS_DRIVER
    port = $UPS_PORT
    vendorid = $UPS_VENDORID
    productid = $UPS_PRODUCTID
    desc = "$UPS_DESC"
EOF

cat > /etc/nut/upsd.conf <<EOF
LISTEN $NUT_LISTEN $NUT_PORT
EOF

cat > /etc/nut/upsd.users <<EOF
[$NUT_USER]
    password = $NUT_PASSWORD
    upsmon slave
EOF

chmod 640 /etc/nut/upsd.users
chown nut:nut /etc/nut/*.conf /etc/nut/upsd.users

echo "Starting NUT driver..."
su-exec nut upsdrvctl start

echo "Starting NUT server..."
exec su-exec nut upsd -F
