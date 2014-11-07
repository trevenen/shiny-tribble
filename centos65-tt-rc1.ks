skipx
text
install
url --url=http://mirror.web24.net.au/centos/6.6/os/x86_64
# Firewall configuration
firewall --enabled --service=ssh
repo --name="repo0" --baseurl=http://mirror.rackspace.com/CentOS/6.6/os/x86_64/ 
repo --name="repo1" --baseurl=http://mirrors.xmission.com/centos/6.6/os/x86_64/ 
repo --name="repo2" --baseurl=https://mirror.webtatic.com/yum/el6/x86_64
repo --name="repo3  --baseurl=


rootpw  --iscrypted !$6$8HL.qZujMXUYIwI6$T4HxA9qsw2wUtKn7GI91jOhLJqagxo4b06OhvgoWnd5Yx7/VSfa2hzcZ91.HUIVHupTvZUu82QyEIVBA3tf7U0
authconfig --enableshadow --passalgo=sha512 --enablefingerprint
# System keyboard
keyboard us
# System language
lang en_US.UTF-8
# SELinux configuration
selinux --enforcing
# Installation logging level
logging --level=info

# System services
services --disabled="avahi-daemon,iscsi,iscsid,firstboot,kdump" --enabled="network,sshd,rsyslog,tuned,acpid"
# System timezone
timezone United States/Denver
# Network information
network  --bootproto=dhcp --device=eth0 --onboot=on
bootloader --location=mbr --driveorder=xvda --append="crashkernel=auto"
clearpart --all --drives=xvda --initlabel
part / --fstype=ext4 --grow --size=200

shutdown


%packages --nobase

epel-release
acpid
attr
audit
authconfig
basesystem
bash
coreutils
cpio
cronie
device-mapper
dhclient
dracut
e2fsprogs
efibootmgr
filesystem
glibc
grub
puppetlabs-release
puppet-3.4.3
initscripts
iproute
iptables
iptables-ipv6
iputils
kbd
kernel
kpartx
ncurses
net-tools
nfs-utils
openssh-clients
openssh-server
parted
passwd
policycoreutils
procps
rootfiles
rpm
rsync
rsyslog
selinux-policy
selinux-policy-targeted
sendmail
setup
shadow-utils
sudo
syslinux
tar
tuned
util-linux-ng
vim-minimal
yum
yum-metadata-parser
# User Specific
cloud-init
tmux
nano
screen
ntp
ntpdate
man
curl
wget
yum-versionlock

-*-firmware
-NetworkManager
-b43-openfwwf
-biosdevname
-fprintd
-fprintd-pam
-gtk2
-libfprint
-mcelog
-plymouth
-redhat-support-tool
-system-config-*
-wireless-tools
%end

# post stuff, here's where we do all the customisation
%post

 
# allow sudo powers to cloud-user
echo -e 'cloud-user\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers

# lock root password
passwd -d root
passwd -l root
 

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

# set virtual-guest as default profile for tuned
echo "virtual-guest" > /etc/tune-profiles/active-profile

# prevent udev rules from remapping nics
touch /etc/udev/rules.d/75-persistent-net-generator.rules

# lock puppet to 3.4.3
yum versionlock puppet

yum -y update

# cloud-init is not able to expand the partition to match the new vdisk size, we need to work around it from the initramfs, before the filesystem gets mounted
# to accomplish this we need to generate a custom initrd
cat << EOF > 05-extend-rootpart.sh
#!/bin/sh
 
/bin/echo
/bin/echo RESIZING THE PARTITION
 
/bin/echo "d
n
p
1
2048
 
w
" | /sbin/fdisk -c -u /dev/xvda 
/sbin/e2fsck -f /dev/xvda1
/sbin/resize2fs /dev/xvda1
EOF
 
chmod +x 05-extend-rootpart.sh
 
dracut --force --include 05-extend-rootpart.sh /mount --install 'echo fdisk e2fsck resize2fs' /boot/"initramfs-extend_rootpart-$(ls /boot/|grep initramfs|sed s/initramfs-//g)" $(ls /boot/|grep vmlinuz|sed s/vmlinuz-//g)
rm -f 05-extend-rootpart.sh
 
tail -4 /boot/grub/grub.conf | sed s/initramfs/initramfs-extend_rootpart/g| sed s/CentOS/ResizePartition/g | sed s/crashkernel=auto/crashkernel=0@0/g >> /boot/grub/grub.conf
 
# let's run the kernel & initramfs that expands the partition only once
echo "savedefault --default=1 --once" | grub --batch
 
# swap can lead to high I/O in a "cloud", but linux likes a bit of swap
# let's create a small swap file, 64 MB
fallocate -l 64M /swap.IMG
chmod 600 /swap.IMG
mkswap /swap.IMG
# and add it to fstab
cat << EOF >> /etc/fstab
/swap.IMG	swap	swap	defaults	0	0
 
EOF
 
# Fix some first boot issues
rpm --rebuilddb
touch /.autorelabel

# Fix hostname on boot
sed -i -e 's/\(preserve_hostname:\).*/\1 False/' /etc/cloud/cloud.cfg
sed -i '/HOSTNAME/d' /etc/sysconfig/network
rm /etc/hostname

# DHCP provides resolv.conf
echo "" > /etc/resolv.conf
# Use label for fstab, not UUID
e2label /dev/xvda1 "/"
sed -i -e 's?^UUID=.* / .*?LABEL=/     /           ext4    defaults,relatime  1   1?' /etc/fstab
# PVGRUB uses hd0 not hd0,0, use label
sed -i -e 's/\(hd0\),0/\1/' -e 's?UUID=[^ ]*?LABEL=/?' -e 's/rhgb quiet//' /boot/grub/menu.lst
# Remove all mac address references
sed -i '/HWADDR/d' etc/sysconfig/network-scripts/ifcfg-eth0
sed -i '/HOSTNAME/d' etc/sysconfig/network-scripts/ifcfg-eth0
# SSH login key based only
sed -i -e 's/^\(PasswordAuthentication\) yes/\1 no/' /etc/ssh/sshd_config

# Clean up
yum clean all
rm -f /root/anaconda-ks.cfg
rm -f /root/install.log
rm -f /root/install.log.syslog
find /var/log -type f -delete


%end
