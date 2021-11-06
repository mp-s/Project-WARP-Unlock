#!/bin/bash

# > System:Ubuntu 20

source /etc/profile

head_url="https://raw.githubusercontent.com/mp-s/Project-WARP-Unlock/sub-lite/"
function Start {
    echo -e " [Intro] One-Click Unlock Stream Media Script By Cloudflare-WARP"
    echo -e " [Intro] OpenSource-Project:https://github.com/acacia233/Project-WARP-Unlock"
    echo -e " [Intro] Version:2021-11-03-1"
    echo -e " [Intro] Require Kernel Version > 5.6,Press Ctrl + C to exit..."
    sleep 5
    Check_System_Depandencies
}

function Check_System_Depandencies {
    echo -e " [Info] Installing Depandencies..."
    apt-get update >/dev/null
    apt-get install -yq ipset dnsmasq wireguard resolvconf mtr >/dev/null 2>&1
    Download_Profile
    Generate_WireGuard_WARP_Profile
}

function Download_Profile {
    wget -qO /etc/dnsmasq.d/warp.conf ${head_url}dnsmasq/warp.conf
    wget -qO /etc/wireguard/up ${head_url}scripts/up
    wget -qO /etc/wireguard/down ${head_url}scripts/down
    chmod +x /etc/wireguard/up
    chmod +x /etc/wireguard/down
}

function Generate_WireGuard_WARP_Profile {

    
    WGCF_Profile='wgcf-profile.conf'
    WGCF_ProfileDir="${HOME}/.wgcf"
    WGCF_ProfilePath="${WGCF_ProfileDir}/${WGCF_Profile}"

    if [[ -f ${WGCF_Profile} ]]; then
        echo -e "[Info] Found ${WGCF_Profile}"
        cp -f ${WGCF_Profile} /etc/wireguard/wg.conf
    elif [ -f "${WGCF_ProfilePath}" ]; then
        echo -e "[Info] Found ${WGCF_ProfilePath}"
        cp -f ${WGCF_ProfilePath} /etc/wireguard/wg.conf
    else
        echo -e " [Info] Generating WARP Profile,Please Wait..."
        mkdir ${WGCF_ProfileDir}
        wget -qO ${WGCF_ProfileDir}/wgcf https://github.com/ViRb3/wgcf/releases/download/v2.2.8/wgcf_2.2.8_linux_amd64
        chmod +x ${WGCF_ProfileDir}/wgcf
        ${WGCF_ProfileDir}/wgcf register --accept-tos --config ${WGCF_ProfileDir}/wgcf-account.toml >/dev/null 2>&1
        sleep 10
        ${WGCF_ProfileDir}/wgcf generate --config ${WGCF_ProfileDir}/wgcf-account.toml --profile ${WGCF_ProfilePath} >/dev/null 2>&1
        sleep 10
        cp -f ${WGCF_ProfilePath} /etc/wireguard/wg.conf
    fi
    


    sed -i '7 i Table = off' /etc/wireguard/wg.conf
    sed -i '8 i PostUp = /etc/wireguard/up' /etc/wireguard/wg.conf
    sed -i '9 i Predown = /etc/wireguard/down' /etc/wireguard/wg.conf
    sed -i '15 i PersistentKeepalive = 5' /etc/wireguard/wg.conf
    sed -i "s/engage.cloudflareclient.com/162.159.193.1/g" /etc/wireguard/wg.conf
    Routing_WireGuard_WARP
}

function Routing_WireGuard_WARP {
    local rt_tables_status="$(cat /etc/iproute2/rt_tables | grep warp)"
    if [[ ! -n "$rt_tables_status" ]]; then
        echo '250   warp' >>/etc/iproute2/rt_tables
        echo -e " [Info] Creating Routing Table..."
    fi
    systemctl disable systemd-resolved --now >/dev/null 2>&1
    sleep 2
    systemctl enable dnsmasq --now >/dev/null 2>&1
    sleep 2
    systemctl enable wg-quick@wg --now >/dev/null 2>&1
    sleep 2
    systemctl restart dnsmasq >/dev/null 2>&1
    echo 'nameserver 127.0.0.1' > /etc/resolv.conf
    Check_finished
}

function Check_finished {
    local wireguard_status="$(ip link | grep wg)"
    if [[ "$wireguard_status" != *"wg"* ]]; then
        echo -e " [Error] WireGuard is not Running,Restarting..."
        systemctl restart wg-quick@wg
    else
        echo -e " [Info] WireGuard is Running,Check Connection..."
    fi
    local connection_status="$(ping 1.1.1.1 -I wg -c 1 2>&1)"
    if [[ "$connection_status" != *"unreachable"* ]] && [[ "$connection_status" != *"Unreachable"* ]] && [[ "$connection_status" != *"SO_BINDTODEVICE"* ]] && [[ "$connection_status" != *"100% packet loss"* ]]; then
        echo -e " [Info] Connection Established..."
    else
        echo -e " [Error] Connection Refused,Please check manually!"
        exit
    fi
    local routing_status="$(mtr -4wn -c 1 youtube.com)"
    if [[ "$routing_status" != *"172.16.0.1"* ]]; then
        echo -e " [Error] Routing is not correct,Please check manually!"
    else
        echo -e " [Info] Routing is working normally,Enjoy~"
    fi
}

Start
