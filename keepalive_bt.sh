#!/bin/sh
# keepalive_bt.sh - Keepalive BT WiFi access
# Edit values in keepalive_bt.cfg
# Typically script is called by 1 min cron

BTUSER="$(awk '$1 == "username" {value=$3; exit} END {print value}' "value=default" keepalive_bt.cfg)"
BTPW="$(awk '$1 == "password" {value=$3; exit} END {print value}' "value=default" keepalive_bt.cfg)"
BTLOGON_DATA="username=$BTUSER&password=$BTPW"
BTLOGON_URL="https://192.168.23.21:8443/ante"
BTLOGOFF_URL="https://192.168.23.21:8443/accountLogoff/Home"

# State reading functions
current_ap() { iw dev ath0 station dump | grep Station | grep -o -E "(([a-f0-9]){2}:){5}([a-f0-9]){2}"; }
current_route() { ip route list 0/0 | grep -o -E "([0-9]{1,3}\.){3}[0-9]{1,3}";  }
current_signal() { iw dev ath0 station dump | grep -E "tx bitrate|rx bitrate|signal avg" | awk '{ printf "%s " $3 }'; }
bt_headers() { grep -i "btopenzone" /tmp/google_headers; }
logon_successful() { grep -i "online" /tmp/bt_logon_response; }

# Action functions
dhcp_release() { kill -USR2 "$(pidof "udhcpc")"; sleep 1; }
dhcp_renew() { kill -USR1 "$(pidof "udhcpc")"; sleep 1; }
disconnect_ap() { iw dev ath0 disconnect; sleep 1; }
request_google_headers() { curl --max-time 3 -I -s www.google.com > /tmp/google_headers; }
send_logon() { curl --max-time 3 -k -d \""$BTLOGON_DATA"\" "$BTLOGON_URL" > /tmp/bt_logon_response; }
send_logoff() { curl --max-time 3 -I -s -k $BTLOGOFF_URL; sleep 1; }
reset_connection() {
    send_logoff; disconnect_ap; send_logoff; disconnect_ap; send_logoff
    dhcp_release; disconnect_ap; dhcp_release; disconnect_ap; dhcp_release
    dhcp_renew; attempt_logon
}

# Misc functions
pad() { printf "%-${2}s" "$1"; }
log() { rt=$(pad "$(current_route)" 15); ap=$(pad "$(current_ap)" 16)
        sg=$(pad "$(current_signal)" 12); timestamp=$(date +%F" "%T)
        msg="$timestamp | $rt | $ap | $sg | $1"
        echo "$msg" >> /tmp/bt.log; }

# Start here
if [ -z "$(current_ap)" ]; then
    log "not connected to an access point"
    reset_connection
    exit 0
fi

if [ -z "$(current_route)" ]; then
    log "ath0 no route via $current_ap" 
    reset_connection
    exit 0
fi

request_google_headers

if [ "$?" != "0" ]; then
    log "No response, attempting recovery"
    reset_connection
    exit 0
fi

if [ -z "$(bt_headers)" ]; then
    log "Connected"
    exit 0
fi

send_logon;
if [ "$?" != "0" ]; then
    log "Failed to send logon"
    reset_connection
    exit 0
fi

if [ -n "$(logon_successful)" ]; then
    log "Logged on"
else
    log "Logon sent okay, but unexpected response"
fi
