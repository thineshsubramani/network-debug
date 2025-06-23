# Network Debug Script
### What’s This?
I put together this Bash script for my homelab to sort out network issues fast. My setup’s a mix of old laptops with flaky NICs and shaky wires that keep going down, unlike my high-end server with solid monitoring and less downtime. These network gremlins mess with my other work, forcing me to log into the server console way too often. This script’s my fix-it’s a quick way to debug network problems so I can get back to the fun stuff. Might add more features down the road!



### Why It’s Awesome
Saves Time: Hits all the network pain points—interfaces, DNS, firewalls, SSH—in one go.
Works Offline: Runs on basic Linux tools (ip, ping, systemctl) for when my network’s acting up.
Flexible: I can pick which checks to run by tweaking the STEPS array.
Deep Checks: Grabs IPs, gateways, Ethernet vs. Wi-Fi, DNS files (/etc/hosts, /etc/nsswitch.conf), blocked firewall rules, and SSH status.



### What It Does
Checks my OS (Ubuntu, CentOS, etc.).
Lists UP interfaces with IP, gateway, and type; debugs DOWN ones with cable/config info.
Tests loopback interface.
Spots active network engines (systemd-networkd, NetworkManager).
Finds netplan or ifupdown configs.
Pings 8.8.8.8 and google.com, shows DNS files, runs dig if available.
Checks for auth issues.
Shows blocked firewall rules (UFW, iptables, nftables) and their status.
Displays routing table.
Verifies SSH (sshd or ssh) is running, checks root login in /etc/ssh/sshd_config.



### How to Use It
Save as network_debug.sh.
Make it runnable: chmod +x network_debug.sh.
Run it: ./network_debug.sh (or sudo for SSH/systemctl checks).
Edit STEPS (0-9) to run specific checks.

### Sample Output
```bash
Starting Network Debug Tool
Steps: 0 1 2 3 4 5 6 7 8 9

========================================
Checking Operating System
========================================
OS: Ubuntu 22.04

========================================
Checking Network Hardware Interfaces
========================================
Interfaces: eth0 wlan0
Interface eth0: UP
  - Private IP: 192.168.1.100
  - Gateway: 192.168.1.1
  - Type: Ethernet (eth0)
Interface wlan0: DOWN
  - No cable plugged in

...

========================================
Checking SSHD Service
========================================
SSHD (sshd): Running
Config: /etc/ssh/sshd_config
Root Login: Not allowed

Network Debug Done
```

### Why It’s Cool
This script’s a lifesaver for my homelab’s janky network setup. It catches issues fast, from loose wires to DNS fails, letting me reduce spend too much time on console login and focus on my actual TASK. Built it to be simple, flexible, and ready for more tweaks later.
