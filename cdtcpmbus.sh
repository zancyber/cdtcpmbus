#!/bin/sh
echo "----- start download plugin serialmodbus rtu -------"
echo "----- create folder -------"
mkdir -p /home/cudo/squash-agent/plugins
chmod -R 755 /home/cudo/squash-agent/plugins
cd /home/cudo/squash-agent/plugins/
rm -rf /home/cudo/squash-agent/plugins/tcpmodbus

#wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id= 1MRd2uL2iO9lYX\-LneMstH2TISSaUxZr9' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1MRd2uL2iO9lYX-LneMstH2TISSaUxZr9" -O tcpmodbus.tar && rm -rf /tmp/cookies.txt
yum install -y unzip jq
wget https://github.com/zancyber/tcpmbus/archive/refs/heads/main.zip
unzip main.zip -d /home/cudo/squash-agent/plugins/tcpmodbus
rm -rf main.zip
cd /home/cudo/squash-agent/plugins/tcpmodbus
find /home/cudo/squash-agent/plugins/tcpmodbus -type f -exec chmod -R 755 {} \;
rm -rf /usr/lib/systemd/system/tcpmodbus.service


SNMP_CONF="/home/cudo/squash-agent/plugins/snmp/config.conf"
TCPMODBUS_CONF="/home/cudo/squash-agent/plugins/tcpmodbus/config.conf"
BACKUP_FILE="${TCPMODBUS_CONF}.bak.$(date +%Y%m%d%H%M%S)"

if ! command -v jq &> /dev/null; then
  echo "Error: jq belum terinstall. Silakan install jq terlebih dahulu."
  exit 1
fi

ENC_PASS=$(jq -r '.enc_iot_server_mqtt_password' "$SNMP_CONF")
MQTT_URL=$(jq -r '.iot_server_mqtt_url' "$SNMP_CONF")
MQTT_USER=$(jq -r '.iot_server_mqtt_username' "$SNMP_CONF")

if [[ -z "$ENC_PASS" || -z "$MQTT_URL" || -z "$MQTT_USER" ]]; then
  echo "Error: Salah satu nilai tidak ditemukan di $SNMP_CONF"
  exit 1
fi

cp "$TCPMODBUS_CONF" "$BACKUP_FILE"
echo "Backup dibuat di: $BACKUP_FILE"

TMP_FILE=$(mktemp)
jq --arg pass "$ENC_PASS" --arg url "$MQTT_URL" --arg user "$MQTT_USER" \
  '.enc_iot_server_mqtt_password = $pass | .iot_server_mqtt_url = $url | .iot_server_mqtt_username = $user' \
  "$TCPMODBUS_CONF" > "$TMP_FILE" && mv -f "$TMP_FILE" "$TCPMODBUS_CONF"

echo "Config berhasil diperbarui di: $TCPMODBUS_CONF"

touch /usr/lib/systemd/system/tcpmodbus.service
printf "[Unit]\nDescription=Squash - PLUGIN - MODBUS TCP/IP\n[Service]\nType=simple\nRestart=always\nRestartSec=5s\nExecStart=/home/cudo/squash-agent/plugins/tcpmodbus/tcpmodbus\nWorkingDirectory=/home/cudo/squash-agent/plugins/tcpmodbus/\n[Install]\nWantedBy=multi-user.target" >/usr/lib/systemd/system/tcpmodbus.service
cp /home/cudo/squash-agent/plugins/snmp/license.lic /home/cudo/squash-agent/plugins/tcpmodbus/
systemctl start tcpmodbus.service
systemctl enable tcpmodbus.service
