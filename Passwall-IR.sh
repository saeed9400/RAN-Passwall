#!/bin/sh
# =====================================================================
# Passwall2 + Iran Traffic Split
# =====================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[*] $1${NC}"; }
log_repo()  { echo -e "${BLUE} $1${NC}"; }
log_ok()    { echo -e "${GREEN}[OK] $1${NC}"; }
log_fail()  { echo -e "${RED}[X] $1${NC}"; exit 1; }

clear
echo ""
echo ""
log_repo "╔════════════════════════════════════════════════════════════════════╗"
log_repo "║                                                                    ║"
log_repo "║   Starting PassWall2 installation and Iranian traffic routing...   ║"
log_repo "║                                                                    ║"
log_repo "║            Version: 1.0 — Thanks to @PeDitX (EZPasswall)           ║"
log_repo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo ""

# ———————— تست اینترنت مخصوص ایران ————————
check_internet_iran() {
    log_info "Internet check..."

    # 1. PING
    if ! ping -4 -c 3 -W 6 8.8.8.8 >/dev/null 2>&1; then
        log_fail "No connectivity – ping failed"
    else
        log_ok "Ping test to 8.8.8.8 succeeded"
    fi

    # 2. HTTPS TEST 
    SUCCESS=0
	echo ""
    log_info "Iran-friendly internet check (CDN + HTTPS)..."
    wget --timeout=10 -q --spider https://www.google.com 2>/dev/null
    if [ $? -eq 0 ]; then
        log_ok "Google.com reachable"
        SUCCESS=1
    else
        log_repo "Google.com not reachable"
    fi

    wget --timeout=10 -q --spider https://openwrt.org 2>/dev/null
    if [ $? -eq 0 ]; then
        log_ok "OpenWrt.org reachable"
        SUCCESS=1
    else
        log_repo "OpenWrt.org not reachable"
    fi

    wget --timeout=10 -q --spider https://www.cloudflare.com 2>/dev/null
    if [ $? -eq 0 ]; then
        log_ok "Cloudflare.com reachable"
        SUCCESS=1
    else
        log_repo "Cloudflare.com not reachable"
    fi

    if [ $SUCCESS -eq 1 ]; then
        log_ok "HTTPS check passed"
    else
        log_info "HTTPS check failed for all tested sites, But ping is OK. Try to Continuing..."
    fi

    return 0
}

# Check RUN 
if ! check_internet_iran; then
    echo
    log_fail "Installation stopped – fix internet first"
    exit 1
fi

# 1. Update package lists
echo ""
log_repo "---------------------------------------------------------------"
echo ""
log_info "Updating package lists..."
opkg update >/dev/null 2>&1 || log_fail "Failed to run 'opkg update' – check internet connection"

# 2. Install/Replace dnsmasq → dnsmasq-full
echo ""
log_repo "---------------------------------------------------------------"
echo ""
log_info "Installing dnsmasq-full and required kernel modules..."
opkg remove dnsmasq --force-depends >/dev/null 2>&1
opkg install dnsmasq-full kmod-nft-tproxy kmod-nft-socket tcpdump-mini >/dev/null 2>&1
if [ $? -eq 0 ]; then
    log_ok "dnsmasq-full + nft modules installed"
else
    log_fail "Failed to install dnsmasq-full or nft modules"
fi

# 3. Add official PassWall2 feeds (no duplicates)
echo ""
log_repo "---------------------------------------------------------------"
echo ""
log_info "Adding official PassWall2 feeds..."
sed -i '/passwall_packages/d' /etc/opkg/customfeeds.conf 2>/dev/null
sed -i '/passwall2/d' /etc/opkg/customfeeds.conf 2>/dev/null

wget -q -O /tmp/passwall.pub https://master.dl.sourceforge.net/project/openwrt-passwall-build/passwall.pub
[ -f /tmp/passwall.pub ] && opkg-key add /tmp/passwall.pub && rm -f /tmp/passwall.pub

release=$( . /etc/openwrt_release ; echo ${DISTRIB_RELEASE%.*} )
arch=$( . /etc/openwrt_release ; echo $DISTRIB_ARCH )

cat << EOF >> /etc/opkg/customfeeds.conf
src/gz passwall_packages https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-$release/$arch/passwall_packages
src/gz passwall2 https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-$release/$arch/passwall2
EOF

opkg update >/dev/null 2>&1

# 4. Install PassWall2 and geo files
echo ""
log_repo "---------------------------------------------------------------"
echo ""
log_info "Installing luci-app-passwall2 + geo databases..."
opkg install luci-app-passwall2 v2ray-geosite-ir v2ray-geoip >/dev/null 2>&1
if [ $? -eq 0 ]; then
    log_ok "luci-app-passwall2 and geo files installed successfully"
else
    log_fail "Failed to install PassWall2 packages – check internet or feeds"
fi

# 5. System settings (timezone + DNS)
echo ""
log_repo "---------------------------------------------------------------"
echo ""
log_info "Applying system settings (Tehran timezone + no ISP DNS)..."
uci set system.@system[0].zonename='Asia/Tehran' 2>/dev/null
uci set system.@system[0].timezone='<+0330>-3:30' 2>/dev/null
uci set network.wan.peerdns='0' 2>/dev/null
uci set network.wan6.peerdns='0' 2>/dev/null
uci set network.wan6.dns='2001:4860:4860::8888' 2>/dev/null
uci commit system >/dev/null 2>&1
uci commit network >/dev/null 2>&1
log_ok "System settings applied"

# 6. Global PassWall2 settings
echo ""
log_repo "---------------------------------------------------------------"
echo ""
log_info "Configuring PassWall2 global rules..."
uci -q delete passwall2.@global_forwarding[0]
uci add passwall2 global_forwarding
uci set passwall2.@global_forwarding[-1].tcp_no_redir_ports='disable'
uci set passwall2.@global_forwarding[-1].udp_no_redir_ports='disable'
uci set passwall2.@global_forwarding[-1].tcp_redir_ports='1:65535'
uci set passwall2.@global_forwarding[-1].udp_redir_ports='1:65535'
uci set passwall2.@global[0].remote_dns='8.8.4.4'
log_ok "Global forwarding configured"

# 7. Remove default rules
echo ""
log_repo "---------------------------------------------------------------"
echo ""
log_info "Removing default unnecessary rules..."
for r in ProxyGame GooglePlay Netflix OpenAI Proxy China QUIC UDP; do
    uci -q delete passwall2.$r
done
log_ok "Default rules removed"


### 8. Delete unused rules
uci delete passwall2.ProxyGame
uci delete passwall2.GooglePlay
uci delete passwall2.Netflix
uci delete passwall2.OpenAI
uci delete passwall2.Proxy
uci delete passwall2.China
uci delete passwall2.QUIC
uci delete passwall2.UDP

### 9. IRAN direct rules
uci set passwall2.Direct=shunt_rules
uci set passwall2.Direct.network='tcp,udp'
uci set passwall2.Direct.remarks='IRAN Geo'
uci set passwall2.Direct.ip_list='geoip:ir
0.0.0.0/8
10.0.0.0/8
100.64.0.0/10
127.0.0.0/8
169.254.0.0/16
172.16.0.0/12
192.0.0.0/24
192.0.2.0/24
192.88.99.0/24
192.168.0.0/16
198.19.0.0/16
198.51.100.0/24
203.0.113.0/24
224.0.0.0/4
240.0.0.0/4
255.255.255.255/32
::/128
::1/128
::ffff:0:0:0/96
64:ff9b::/96
100::/64
2001::/32
2001:20::/28
2001:db8::/32
2002::/16
fc00::/7
fe80::/10
ff00::/8'

uci set passwall2.Direct.domain_list='regexp:^.+\.ir$
geosite:category-ir'

### 10. International direct rule
uci set passwall2.DirectGame=shunt_rules
uci set passwall2.DirectGame.network='tcp,udp'
uci set passwall2.DirectGame.remarks='International-Direct'
uci set passwall2.DirectGame.ip_list=''  # لیست IP خالی
uci set passwall2.DirectGame.domain_list='epicgames.com
capcut.com
adobe.com
ubisoft.com
google.com
bingx.com
openwrt.org
twitch.tv
byteoversea.com
xbox.com
fcdn.co
adobe.io
cloudflare.com
playstation.com
tradingview.com
reachthefinals.com
midi-mixer.com
google-analytics.com
cloudflare-dns.com
bingx.com
activision.com
biostar.com.tw
aternos.me
geforce.com
gvt1.com
ubi.com
ea.com
eapressportal.com
myaccount.ea.com
origin.com
epicgames.dev
rockstargames.com
rockstarnorth.com
googlevideo.com
2ip.io
safepal.com
microsoft.com
apps.microsoft.com
live.com
ytimg.com
t.me
whatsapp.com
reddit.com
pvp.net
discord.com
discord.gg
discordapp.net
discordapp.com
bing.com
discord.media
approved-proxy.bc.ubisoft.com
tlauncher.org
aternos.host
aternos.me
aternos.org
aternos.net
aternos.com
steamcommunity.com
steam.com
steampowered.com
steamstatic.com'


uci set passwall2.myshunt.Direct='_direct'
uci set passwall2.myshunt.DirectGame='_direct'
uci delete passwall2.myshunt

###  11. MainShunt
uci set passwall2.MainShunt=nodes
uci set passwall2.MainShunt.remarks='MainShunt'
uci set passwall2.MainShunt.type='Xray'
uci set passwall2.MainShunt.protocol='_shunt'
uci set passwall2.MainShunt.Direct='_direct'
uci set passwall2.MainShunt.DirectGame='_default'

###  12. PC-Shunt
uci set passwall2.PC_Shunt=nodes
uci set passwall2.PC_Shunt.remarks='PC-Shunt'
uci set passwall2.PC_Shunt.type='Xray'
uci set passwall2.PC_Shunt.protocol='_shunt'
uci set passwall2.PC_Shunt.Direct='_direct'
uci set passwall2.PC_Shunt.DirectGame='_default'

uci commit passwall2
uci commit system

### 13. Rebind Domain
uci set dhcp.@dnsmasq[0].rebind_domain='www.ebanksepah.ir 
my.irancell.ir'

uci commit

log_ok "IRAN rule is set..."

# 14. Download banner
echo ""
log_repo "---------------------------------------------------------------"
echo ""
log_info "Download Passwall2 Banner..."
FILE_URL="https://raw.githubusercontent.com/saeed9400/Easy-IRAN-Passwall/main/status.htm"
DEST_DIR="/usr/lib/lua/luci/view/passwall2/global"
DEST_FILE="$DEST_DIR/status.htm"

# 14.1 Make Dir
[ ! -d "$DEST_DIR" ] && mkdir -p "$DEST_DIR"

# 14.2 Backup Current File
if [ -f "$DEST_FILE" ]; then
    BACKUP_FILE="$DEST_FILE.bak_$(date +%Y-%m-%d_%H-%M-%S)"
    mv "$DEST_FILE" "$BACKUP_FILE"
    echo "Backup created: $BACKUP_FILE"
fi

# 14.3 Download File
wget -q -O "$DEST_FILE" "$FILE_URL"

# 14.4 Check Downloading
if [ $? -eq 0 ]; then
	log_ok "File downloaded and saved to: $DEST_FILE"
else
    log_fail "Download failed!"
fi


# 15. Final commit & restart
echo ""
log_repo "---------------------------------------------------------------"
echo ""
log_info "Saving configuration and restarting service..."
uci -q delete passwall2.myshunt
uci commit passwall2 >/dev/null 2>&1
/etc/init.d/passwall2 restart >/dev/null 2>&1
/sbin/reload_config >/dev/null 2>&1
log_ok "Configuration saved and service restarted"

echo ""
echo ""
log_repo "╔═════════════════════════════════════════════════════════════════╗"
log_repo "║       PassWall2 installed and configured successfully!          ║"
log_repo "║            Enjoy your fast & split connection. :)               ║"
log_repo "╚═════════════════════════════════════════════════════════════════╝"
echo ""
echo ""
# =====================================================================