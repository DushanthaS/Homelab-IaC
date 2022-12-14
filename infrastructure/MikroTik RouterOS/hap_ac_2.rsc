# dec/05/2022 22:58:46 by RouterOS 7.6
# software id = S16I-AD03
# model = RBD52G-5HacD2HnD
############################################################################
# Notes: Start with a reset 
# Replace passw0rd2022
# Export configs > /export compact file=flash/hap_ac_2.rsc
# Restore   > /system reset-configuration keep-users=yes skip-backup=yes no-defaults=yes run-after-reset=flash/12_02_2022_g.rsc
# /import file-name=hap_ac_2.rsc verbose=yes

########## MY HOME LAB CONFIGS ##############################################

#######################################
# VLAN Overview
#######################################
# vlan 10 : IpCameras / no internet
# vlan 15 : DNS (pihole)
# vlan 20 : Servers 
# vlan 30 : iOT with internet / Alexa / HA
# vlan 40 : Home Network
# vlan 99 : BASE

#######################################
# Router Overview
#######################################
# eth1 ----- WAN
# eth2 ----- trunk
# eth3 ----- untagged 99
# eth4 ----- untagged home 40
# eth5 ----- trunk


# #######################################
# # Interfaces
# #######################################

# ##################
# # Ethernet ports
# ##################

/interface ethernet
set [ find default-name=ether1 ] disabled=no
set [ find default-name=ether2 ] disabled=no
set [ find default-name=ether3 ] disabled=no
set [ find default-name=ether4 ] disabled=no
set [ find default-name=ether5 ] disabled=no


# #######################################
# # Bridge
# #######################################

# # create one bridge
/interface bridge
add admin-mac=48:8F:5A:48:B4:80 auto-mac=no name=bridge

/interface bridge port
add bridge=bridge interface=ether2 hw=yes
add bridge=bridge interface=ether5 hw=yes

# # #######################################
# # # VLAN interface creation and adding to the bridge
# # #######################################

/interface vlan
add interface=bridge name=IpCameras-10 vlan-id=10
add interface=bridge name=DNS-15 vlan-id=15
add interface=bridge name=Servers-20 vlan-id=20
add interface=bridge name=IOT-30 vlan-id=30
add interface=bridge name=Home-40 vlan-id=40
add interface=bridge name=BASE-99 vlan-id=99

/interface ethernet switch port
set 1 vlan-mode=secure
set 2 default-vlan-id=99 vlan-header=always-strip vlan-mode=secure
set 3 default-vlan-id=40 vlan-header=always-strip vlan-mode=secure
set 4 vlan-mode=secure
set 5 vlan-mode=secure


# #################
# ##  WIFI Setup
# #################

# Wireless security-profiles
/interface wireless security-profiles
add authentication-types=wpa2-psk mode=dynamic-keys  wpa2-pre-shared-key="passw0rd2022" name=ioT \
    supplicant-identity=MikroTik
add authentication-types=wpa2-psk mode=dynamic-keys wpa2-pre-shared-key="passw0rd2022" name=BASE \
    supplicant-identity=MikroTik
add authentication-types=wpa2-psk mode=dynamic-keys wpa2-pre-shared-key="passw0rd2022" name=home \
    supplicant-identity=MikroTik


/interface wireless

# SSID MT-BASE
set [ find default-name=wlan2 ] country=canada disabled=no installation=\
    indoor mode=ap-bridge name=wlan2 security-profile=BASE ssid=Mt-BASE \
    vlan-id=99 vlan-mode=use-tag wps-mode=disabled
# SSID IOT
set [ find default-name=wlan1 ] disabled=no mode=ap-bridge name=wlan1-IoT \
    security-profile=ioT ssid=IoT vlan-id=30 vlan-mode=use-tag \
    wps-mode=disabled
# SSID IOT-cam
add disabled=no  master-interface=wlan1-IoT \
    name=IpCameras security-profile=ioT ssid=IoT-Cam vlan-id=10 vlan-mode=use-tag \
    wps-mode=disabled
# SSID home
add disabled=no  master-interface=wlan2 \
    name=wlan2-home security-profile=home ssid=home vlan-id=40 vlan-mode=use-tag \
    wps-mode=disabled


# #######################################
# # VLAN Security
# #######################################

# # Only allow ingress packets without tags on Access Ports

/interface bridge port
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=wlan1-IoT pvid=30
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=IpCameras pvid=10
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=wlan2-home pvid=40
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=wlan2 pvid=99
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=ether3 pvid=99
add bridge=bridge frame-types=admit-only-untagged-and-priority-tagged \
    interface=ether4 pvid=40


# Add VLAN table entries to allow frames with specific VLAN IDs between ports:
/interface ethernet switch vlan
add independent-learning=no ports=ether2,ether5,ether3,ether4,switch1-cpu switch=\
    switch1 vlan-id=99
add independent-learning=no ports=ether2,ether5,switch1-cpu switch=switch1 \
    vlan-id=10
add independent-learning=no ports=ether2,ether5,switch1-cpu switch=switch1 \
    vlan-id=20
add independent-learning=no ports=ether2,ether5,switch1-cpu switch=switch1 \
    vlan-id=30
add independent-learning=no ports=ether2,ether5,ether3,ether4,switch1-cpu switch=switch1 \
    vlan-id=40


#######################################
# IP Addressing & Routing
#######################################

/ip dns
set allow-remote-requests=yes servers=1.1.1.1,9.9.9.9

#######################################
# IP Services
#######################################

# IpCameras VLAN interface creation, IP assignment, and DHCP service

/ip address add interface=IpCameras-10 address=10.0.10.1/24
/ip pool add name=IpCameras_POOL ranges=10.0.10.2-10.0.10.254
/ip dhcp-server add address-pool=IpCameras_POOL interface=IpCameras-10 name=IpCameras_DHCP disabled=no
/ip dhcp-server network add address=10.0.10.0/24 dns-server=8.8.8.8 gateway=10.0.10.1

# DNS VLAN interface creation, IP assignment, and DHCP service

/ip address add interface=DNS-15 address=10.0.15.1/24
/ip pool add name=DNS_POOL ranges=10.0.15.2-10.0.15.254
/ip dhcp-server add address-pool=DNS_POOL interface=DNS-15 name=DNS_DHCP disabled=no
/ip dhcp-server network add address=10.0.15.0/24 dns-server=8.8.8.8 gateway=10.0.15.1

# Servers VLAN interface creation, IP assignment, and DHCP service

/ip address add interface=Servers-20 address=10.0.20.1/24
/ip pool add name=Servers_POOL ranges=10.0.20.2-10.0.20.254
/ip dhcp-server add address-pool=Servers_POOL interface=Servers-20 name=Servers_DHCP disabled=no
/ip dhcp-server network add address=10.0.20.0/24 dns-server=8.8.8.8 gateway=10.0.20.1

# iOT VLAN interface creation, IP assignment, and DHCP service

/ip address add interface=IOT-30 address=10.0.30.1/24
/ip pool add name=IOT_POOL ranges=10.0.30.2-10.0.30.254
/ip dhcp-server add address-pool=IOT_POOL interface=IOT-30 name=IOT_DHCP disabled=no
/ip dhcp-server network add address=10.0.30.0/24 dns-server=8.8.8.8 gateway=10.0.30.1

# Home VLAN interface creation, IP assignment, and DHCP service

/ip address add interface=Home-40 address=10.0.40.1/24
/ip pool add name=Home_POOL ranges=10.0.40.2-10.0.40.254
/ip dhcp-server add address-pool=Home_POOL interface=Home-40 name=Home_DHCP disabled=no
/ip dhcp-server network add address=10.0.40.0/24 dns-server=8.8.8.8 gateway=10.0.40.1


# BASE VLAN interface creation, IP assignment, and DHCP service

/ip address add interface=BASE-99 address=10.0.99.1/24
/ip pool add name=BASE_POOL ranges=10.0.99.2-10.0.99.254
/ip dhcp-server add address-pool=BASE_POOL interface=BASE-99 name=BASE_DHCP disabled=no
/ip dhcp-server network add address=10.0.99.0/24 dns-server=8.8.8.8 gateway=10.0.99.1


#dhcp-client to get public IP
/ip dhcp-client
add interface=ether1 script="{\\r\\\r\
    \n        :local rmark \\\"WAN1\\\"\\r\\\r\
    \n        :local count [/ip route print count-only where comment=\\\"WAN1\
    \\\"]\\r\\\r\
    \n        :if (\\\$bound=1) do={\\r\\\r\
    \n            :if (\\\$count = 0) do={\\r\\\r\
    \n                /ip route add gateway=\\\$\\\"gateway-address\\\" commen\
    t=\\\"WAN1\\\" routing-mark=\\\$rmark\\r\\\r\
    \n            } else={\\r\\\r\
    \n                :if (\\\$count = 1) do={\\r\\\r\
    \n                    :local test [/ip route find where comment=\\\"WAN1\\\
    \"]\\r\\\r\
    \n                    :if ([/ip route get \\\$test gateway] != \\\$\\\"gat\
    eway-address\\\") do={\\r\\\r\
    \n                        /ip route set \\\$test gateway=\\\$\\\"gateway-a\
    ddress\\\"\\r\\\r\
    \n                    }\\r\\\r\
    \n                } else={\\r\\\r\
    \n                    :error \\\"Multiple routes found\\\"\\r\\\r\
    \n                }\\r\\\r\
    \n            }\\r\\\r\
    \n        } else={\\r\\\r\
    \n            /ip route remove [find comment=\\\"WAN1\\\"]\\r\\\r\
    \n        }\\r\\\r\
    \n    }\\r\\" use-peer-dns=no
/ip dhcp-server config
set store-leases-disk=12h


## disable unwanted services

/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set ssh disabled=yes
set api disabled=yes
set api-ssl disabled=yes

#######################################
# Firewalling & NAT
# A good firewall for WAN. Up to you
# about how you want LAN to behave.
#######################################

# Use MikroTik's "list" feature for easy rule matchmaking.

/interface list add name=WAN
/interface list add name=VLAN
/interface list add name=BASE

/interface list member
add interface=ether1     list=WAN
add interface=IpCameras-10 list=VLAN
add interface=DNS-15 list=VLAN
add interface=Servers-20 list=VLAN
add interface=IOT-30 list=VLAN
add interface=Home-40 list=VLAN
add interface=BASE-99 list=VLAN
add interface=BASE-99  list=BASE
add interface=bridge list=VLAN



/ip firewall address-list
add address=10.0.99.0/24 list=adminAccess

# VLAN aware firewall. Order is important.
/ip firewall filter


##################
# INPUT CHAIN
##################
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked

add action=drop chain=input connection-state=new in-interface=ether1 \
    src-address-list=!adminAccess

add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid

# Allow BASE_VLAN full access to the device for Winbox, etc.
add action=accept chain=input comment=\
    "Allow Base access to all router services" in-interface-list=BASE

# Allow VLAN access to DHCP DNS and ping.
add action=accept chain=input comment="Allow VLAN DHCP" dst-port=67 \
    in-interface-list=VLAN protocol=udp
add action=accept chain=input comment="Allow VLAN DNS UDP" dst-port=53 \
    in-interface-list=VLAN protocol=udp
add action=accept chain=input comment="Allow VLAN DNS TCP" dst-port=53 \
    in-interface-list=VLAN protocol=tcp
add action=accept chain=input comment="Allow VLAN ICMP Ping" \
    in-interface-list=VLAN protocol=icmp

add action=drop chain=input comment="Drop all other traffic" 

##################
# FORWARD CHAIN
##################
add action=fasttrack-connection chain=forward comment="defconf: fasttrack" \
    connection-state=established,related hw-offload=yes

add action=accept chain=forward comment=\
    "defconf: accept established,related, untracked" connection-state=\
    established,related,untracked

# Allow all VLANs to access the Internet only, NOT each other
add chain=forward action=accept connection-state=new in-interface-list=VLAN out-interface-list=WAN comment="VLAN Internet Access only"

# Allow BASE_VLAN full access to other VLAN
add action=accept chain=forward comment="Allow Base to access all VLAN" \
    in-interface=BASE-99 out-interface=all-vlan
# Optional
add action=accept chain=forward comment=\
    "Allow Port Forwarding - DSTNAT - enable if need server" \
    connection-nat-state=dstnat connection-state=new disabled=yes \
    in-interface-list=WAN

add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add chain=forward action=drop comment="Drop"

##################
# NAT
##################
/ip firewall nat add chain=srcnat action=masquerade out-interface-list=WAN comment="Default masquerade"


##################
# NTP client & server
##################

/system ntp server set enabled=yes
/system ntp client servers
:do { add address=time.cloudflare.com } on-error={}

#######################################
# MAC Server settings
#######################################

# Ensure only visibility and availability from BASE_VLAN, the MGMT network
/ip neighbor discovery-settings set discover-interface-list=BASE
/tool mac-server mac-winbox set allowed-interface-list=BASE
/tool mac-server set allowed-interface-list=BASE


#######################################
# System settings
#######################################

/tool graphing interface
add allow-address=10.0.99.0/24 interface=ether1
add allow-address=10.0.99.0/24 interface=BASE-99
add allow-address=10.0.99.0/24 interface=IpCameras
add allow-address=10.0.99.0/24 interface=DNS-15
add allow-address=10.0.99.0/24 interface=Servers-20
add allow-address=10.0.99.0/24 interface=IOT-30
add allow-address=10.0.99.0/24 interface=Home-40
add allow-address=10.0.99.0/24
/tool graphing resource
add allow-address=10.0.99.0/24

/system identity set name="MikroTik-v9"
/system clock
set time-zone-name=America/Winnipeg
/system routerboard settings
set auto-upgrade=yes