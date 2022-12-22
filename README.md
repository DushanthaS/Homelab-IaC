# Homelab-IaC
Infrastructure as Code files for homelab

# MikroTik hAP ac2 RBD52G-5HacD2HnD-TC

I have MikroTik RouterOS device with multiple VLANs configured. I have have set up six VLANs with VLAN IDs 10, 15, 20, 30, 40, and 99. This scriptis designed to set up several wireless interfaces, each associated with a different security profile and VLAN, DHCP servers for each VLAN, as well as pools of IP addresses for each VLAN, hotspot profiles and hotspot users.

VLANs (Virtual Local Area Networks) allow you to segment your network into different logical subnetworks, each with its own set of devices. This can be useful for separating different types of devices or for creating separate networks for different purposes, such as a guest network.

I also have set up VLAN tagging on Router and cisco switch ports, which means that packets sent on those ports will be tagged with the appropriate VLAN ID. This allows the devices on different VLANs to communicate with each other, while still being isolated from devices on other VLANs.
