#!/bin/bash

# Ensure the script runs with root privileges
if [ "$(id -u)" -ne "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Bring up the ens3 interface
echo "Configuring network interface ens3..."
ip link set ens3 up

# Install dhclient if not already installed
echo "Installing dhclient..."

# Configure dhclient for ens3
echo "Creating dhclient service for ens3..."
cat <<EOF > /etc/systemd/system/dhclient.service
[Unit]
Description=Dynamic Host Configuration Protocol Client
After=network.target

[Service]
Type=simple
ExecStart=/sbin/dhclient -v ens3
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target

EOF

# Restart dhclient service
echo "Starting dhclient for ens3..."
dhclient ens3

# Configure netplan
echo "Configuring netplan..."
cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    ens3:
      dhcp4: yes
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4

EOF

# Apply netplan configuration
echo "Applying netplan configuration..."
netplan apply

# Reinstall OpenSSH server
echo "Reinstalling OpenSSH server..."
apt-get install --reinstall -y openssh-server
echo "PasswordAuthentication yes" | tee -a sshd_config
sed -i '/PasswordAuthentication no/d' sshd_config
echo "PermitRootLogin yes" | tee -a sshd_config
ssh-keygen -A

echo "Setup completed."
