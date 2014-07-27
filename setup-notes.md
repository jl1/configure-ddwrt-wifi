# Guide to upgrade Netgear WNDR3700V4



If feeling brave, DL latest version (jul14) from here: 
ftp://ftp.dd-wrt.com/betas/2014/06-23-2014-r24461/netgear-wndr3700v4/
use webflash if flashing from dd-wrt to dd-wrt, otherwise factory from the stock netgear upgrade page

The wiki recommended (jul14) is 23919, so that's what i used.

Once flashed, connect to 192.168.1.1 in browser, using machine with static ip in 192.168.1.0/24

Set a username and password for the webaccess gui.

go to wireless->basic settings, set the network mode to disabled for both adaptors
save, apply

setup tab,
specify hostname and domain or dropbear won't work and you won't be able to ssh

Administration tab, at the bottom, choose brainslayer style in router gui style and save
Services tab,
enable sshd
save, apply, reboot

Make an ssh connection to the router

The magic happens by sending https post with credentials, and so we need to get curl installed on the router.
Download this: http://downloads.openwrt.org/kamikaze/8.09.2/ar7/packages/curl_7.17.1-1.2_mipsel.ipk
Either scp onto the router
or serve on the lan with something like python -m SimpleHTTPServer and wget from router
or can configure the router's ath0 in client mode to connect to another ap like an android hotspot
or netcat


Anyway, get curl and then run
ipkg install curl_7.17.1-1.2_mipsel.ipk

Go to wireless->basic settings
set SSID to BTWiFi-with-FON


curl -o keepalive_bt.sh github.com/jl1/.../btkeepalive.sh
chmod +x /tmp/keepalive_bt.sh

add cron entry:
* * * * * root /bin/sh /tmp/btkeepalive.sh

