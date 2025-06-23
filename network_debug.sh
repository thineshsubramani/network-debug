#!/bin/bash

# Network Debugging Tool
# Usage: Modify the STEPS array to include/exclude steps (0-9)
# Run: ./network_debug.sh

# Define the order of debug steps (modify to include/exclude steps)
STEPS=(0 1 2 3 4 5 6 7 8 9)

# Function to print section headers
print_header() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

# 0) Check OS type
check_os() {
    print_header "Checking Operating System"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "OS: $NAME $VERSION"
    else
        echo "OS: Unknown (no /etc/os-release found)"
    fi
}

# 1) Check hardware interfaces, debug down interfaces, and report details for UP interfaces
check_hardware() {
    print_header "Checking Network Hardware Interfaces"
    if command -v ip >/dev/null; then
        interfaces=$(ip link show | awk '/^[0-9]+:/ {print $2}' | sed 's/://')
        echo "Interfaces found: $interfaces"
        for iface in $interfaces; do
            if ip link show "$iface" | grep -q "UP"; then
                echo "Interface $iface: UP"
                # Get private IP address
                ip_addr=$(ip addr show "$iface" | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
                [ -n "$ip_addr" ] && echo "  - Private IP: $ip_addr" || echo "  - Private IP: Not assigned"
                # Get gateway IP
                gateway=$(ip route | grep "default via" | grep "$iface" | awk '{print $3}' | head -1)
                [ -n "$gateway" ] && echo "  - Gateway IP: $gateway" || echo "  - Gateway IP: Not found"
                # Determine connection type (Ethernet or wireless)
                if [ -d "/sys/class/net/$iface/wireless" ]; then
                    echo "  - Connection Type: Wireless (Interface: $iface)"
                else
                    echo "  - Connection Type: Ethernet (Interface: $iface)"
                fi
            else
                echo "Interface $iface: DOWN"
                echo "Debugging $iface:"
                if [ -d "/sys/class/net/$iface" ]; then
                    if [ -f "/sys/class/net/$iface/carrier" ]; then
                        carrier=$(cat "/sys/class/net/$iface/carrier" 2>/dev/null)
                        [ "$carrier" = "0" ] && echo "  - No carrier (cable unplugged or hardware issue)"
                        [ "$carrier" = "1" ] && echo "  - Carrier detected"
                    fi
                    if [ -f "/etc/network/interfaces" ]; then
                        grep -q "$iface" /etc/network/interfaces && echo "  - Config found in /etc/network/interfaces" || echo "  - No config in /etc/network/interfaces"
                    fi
                    if [ -d /etc/netplan ]; then
                        grep -r "$iface" /etc/netplan 2>/dev/null && echo "  - Config found in netplan" || echo "  - No config in netplan"
                    fi
                else
                    echo "  - Interface $iface not found in /sys/class/net"
                fi
            fi
        done
    else
        echo "Error: 'ip' command not found"
    fi
}

# 2) Check loopback interface health
check_loopback() {
    print_header "Checking Loopback Interface"
    if ip link show lo | grep -q "UP"; then
        echo "Loopback interface (lo): UP"
    else
        echo "Loopback interface (lo): DOWN"
    fi
    ip addr show lo | grep inet
}

# 3) Check network engine (e.g., systemd-networkd, NetworkManager)
check_network_engine() {
    print_header "Checking Network Engine"
    if command -v systemctl >/dev/null; then
        if systemctl is-active --quiet systemd-networkd; then
            echo "systemd-networkd: Running"
            systemctl status systemd-networkd --no-pager | grep Active
        fi
        if systemctl is-active --quiet NetworkManager; then
            echo "NetworkManager: Running"
            systemctl status NetworkManager --no-pager | grep Active
        fi
    else
        echo "systemctl not found"
    fi
}

# 4) Check network configuration tool (e.g., netplan, ifupdown)
check_network_tool() {
    print_header "Checking Network Configuration Tool"
    if [ -d /etc/netplan ]; then
        echo "Netplan detected"
        cat /etc/netplan/*.yaml 2>/dev/null || echo "No netplan config files found"
    elif [ -f /etc/network/interfaces ]; then
        echo "ifupdown detected"
        cat /etc/network/interfaces 2>/dev/null
    else
        echo "No known network configuration tool detected"
    fi
}

# 5) Check DNS (ping google.com, 8.8.8.8, dig, and DNS file paths)
check_dns() {
    print_header "Checking DNS Connectivity and Configuration"
    if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
        echo "Ping to 8.8.8.8: SUCCESS"
        if ! ping -c 2 google.com >/dev/null 2>&1; then
            echo "Ping to google.com: FAILED (DNS issue likely)"
            echo "DNS Configuration Files:"
            [ -f /etc/resolv.conf ] && echo "  - /etc/resolv.conf:" && cat /etc/resolv.conf || echo "  - /etc/resolv.conf: Not found"
            [ -f /etc/hosts ] && echo "  - /etc/hosts:" && cat /etc/hosts || echo "  - /etc/hosts: Not found"
            [ -f /etc/nsswitch.conf ] && echo "  - /etc/nsswitch.conf:" && cat /etc/nsswitch.conf || echo "  - /etc/nsswitch.conf: Not found"
            if command -v dig >/dev/null; then
                echo "Running dig google.com:"
                dig google.com +short
            else
                echo "dig command not found"
            fi
        else
            echo "Ping to google.com: SUCCESS"
        fi
    else
        echo "Ping to 8.8.8.8: FAILED (connectivity issue)"
    fi
}

# 6) Check network authentication issues
check_network_auth() {
    print_header "Checking Network Authentication"
    if ip link show | grep -v lo | grep -q "UP"; then
        echo "At least one network interface (non-loopback) is UP"
    else
        echo "No network interfaces (non-loopback) are UP"
    fi
    if [ -f /etc/NetworkManager/system-connections/*.nmconnection ]; then
        echo "NetworkManager connection profiles found:"
        ls /etc/NetworkManager/system-connections/
    else
        echo "No NetworkManager connection profiles found"
    fi
}

# 7) Check firewall rules (only blocked rules and firewall status)
check_firewall() {
    print_header "Checking Firewall Status and Blocked Rules"
    if command -v ufw >/dev/null; then
        if ufw status | grep -q "Status: active"; then
            echo "UFW Firewall: Active"
            echo "Blocked rules (UFW):"
            ufw status | grep DENY || echo "  - No DENY rules found"
        else
            echo "UFW Firewall: Inactive"
        fi
    else
        echo "UFW Firewall: Not installed"
    fi
    if command -v iptables >/dev/null; then
        echo "iptables: Installed"
        echo "Blocked rules (iptables):"
        iptables -L -v -n --line-numbers | grep DROP || echo "  - No DROP rules found"
    else
        echo "iptables: Not installed"
    fi
    if command -v nft >/dev/null; then
        echo "nftables: Installed"
        echo "Blocked rules (nftables):"
        nft list ruleset | grep drop || echo "  - No drop rules found"
    else
        echo "nftables: Not installed"
    fi
}

# 8) Check routing table
check_routing() {
    print_header "Checking Routing Table"
    ip route show
}

# 9) Check SSHD service status with enhanced checks
check_ssh() {
    print_header "Checking SSHD Service"
    local sshd_running=0
    if command -v systemctl >/dev/null; then
        if systemctl is-active --quiet sshd; then
            echo "SSHD Service (sshd): Running"
            systemctl status sshd --no-pager | grep Active
            sshd_running=1
        elif systemctl is-active --quiet ssh; then
            echo "SSHD Service (ssh): Running"
            systemctl status ssh --no-pager | grep Active
            sshd_running=1
        else
            echo "SSHD Service (systemctl): Not running (checked sshd and ssh)"
        fi
    else
        echo "systemctl not found, falling back to process check"
    fi
    # Fallback to checking if sshd process is running
    if [ $sshd_running -eq 0 ] && command -v ps >/dev/null; then
        if ps aux | grep -v grep | grep -q "[s]shd"; then
            echo "SSHD Process: Running (detected via ps)"
            sshd_running=1
        else
            echo "SSHD Process: Not running (no sshd process found)"
        fi
    fi
    if [ -f /etc/ssh/sshd_config ]; then
        echo "SSHD Configuration File: /etc/ssh/sshd_config"
        if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
            echo "Root Login: Permitted"
        elif grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
            echo "Root Login: Not permitted"
        else
            echo "Root Login: Not explicitly configured (default varies by SSH version)"
        fi
    else
        echo "SSHD Configuration File: /etc/ssh/sshd_config not found"
    fi
    # Suggest running with sudo if not running as root
    if [ $sshd_running -eq 0 ] && [ $EUID -ne 0 ]; then
        echo "Note: If SSHD is running, try running this script with sudo to check systemctl status properly."
    fi
}

# Main function to control debug flow
main() {
    echo "Starting Network Debug Tool"
    echo "Steps to run: ${STEPS[*]}"
    echo ""

    for step in "${STEPS[@]}"; do
        case $step in
            0) check_os ;;
            1) check_hardware ;;
            2) check_loopback ;;
            3) check_network_engine ;;
            4) check_network_tool ;;
            5) check_dns ;;
            6) check_network_auth ;;
            7) check_firewall ;;
            8) check_routing ;;
            9) check_ssh ;;
            *) echo "Unknown step: $step" ;;
        esac
    done

    echo ""
    echo "Network Debug Completed"
}

# Execute the main function
main
