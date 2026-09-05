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
: "${NUT_INSTCMDS:=}"

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

{
    echo "[$NUT_USER]"
    echo "    password = $NUT_PASSWORD"

    if [ -n "$NUT_INSTCMDS" ]; then
        OLDIFS="$IFS"
        IFS=','
        for cmd in $NUT_INSTCMDS; do
            echo "    instcmds = $cmd"
        done
        IFS="$OLDIFS"
    fi
} > /etc/nut/upsd.users

chmod 640 /etc/nut/upsd.users
chown nut:nut /etc/nut/*.conf /etc/nut/upsd.users

UPSD_PID=""

shutdown() {
    echo "Shutting down..."
    if [ -n "$UPSD_PID" ]; then
        kill -TERM "$UPSD_PID" 2>/dev/null || true
        wait "$UPSD_PID" 2>/dev/null || true
    fi
    /usr/sbin/upsdrvctl stop || true
    exit 0
}

trap shutdown TERM INT QUIT

echo "Starting NUT driver..."
/usr/sbin/upsdrvctl -u root start

echo "Starting NUT server..."
/usr/sbin/upsd -u root -F &
UPSD_PID=$!

wait "$UPSD_PID"
