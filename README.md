# network-debug

utility tool written in golang to automate network debugging in linux servers. This tool works offline to perform debugging task and report potential network issues either its DNS, internet connection, interface issues or others.

Debugging steps:
1) check network interfaces and connection type (all the interface)
2) find the network engine used and check the state and logs from systemd
3) read network config files
4) read etc/host etc/switch files for DNS configuration
5) ping 8.8.8.8 ip then ping DNS

Steps can be skipped and reorder in config file.

support: debian, ubuntu 
future support: centos


