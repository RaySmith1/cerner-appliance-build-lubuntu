#!/bin/bash

function f_log {
	MSG="$@"
	echo "$(date) [INSTALL] $@" | tee -a ${0%.sh}.log
}

[ -f ${0%.sh}.log ] && { f_log "Install already run."; exit 0; }

source /etc/os-release
f_log "Installing on '${PRETTY_NAME}'."

f_log "Updating locale to en_US.UTF-8"
update-locale LANG=en_US.UTF-8

#***************************
# GRUB SETTINGS
#***************************
f_log "Setting grub options (/etc/default/grub & /etc/grub.d/10-appliance-tuning.cfg)."
# update grub settings
sed -i \
-e 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=0/' \
-e '/^GRUB_TIMEOUT=/ a \
GRUB_TIMEOUT_STYLE=hidden' \
-e '/^GRUB_TIMEOUT=/ a \
GRUB_RECORDFAIL_TIMEOUT=2' \
-e 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*$/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/' \
-e '/^#GRUB_TERMINAL/ s/^#//' \
-e '/^#GRUB_DISABLE_RECOVERY/ s/^#//' \
-e '$ a \
GRUB_DISABLE_OS_PROBER=true' \
/etc/default/grub

mkdir -p /etc/default/grub.d/
cat <<-'EOF' > /etc/default/grub.d/10-appliance-tuning.cfg
GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT intel_idle.max_cstate=1 intel_pstate=disable apm=off pcie_aspm=off i915.enable_rc6=0 i915.enable_fbc=0 i915.semaphores=1 pnpbios=off acpi_osi=linux"

EOF

cat <<-'EOF' > /etc/default/grub.d/15-appliance-hwe-kernel-tune.cfg
GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT noapic"

EOF

cat <<-'EOF' > /etc/default/grub.d/20-appliance-disable-kpti.cfg
GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT nopti"

EOF

cat <<-'EOF' > /etc/default/grub.d/50-appliance-optional-disable-ipv6.cfg
# Disable IPv6 at Kernel (optional)
GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT ipv6.disable=1"

EOF

f_log "Updating grub (update-grub)."
update-grub > /dev/null 2>&1

cat <<-'EOF' > /etc/udev/rules.d/75-persistent-net-generator.rules
# Disabled on Appliance (file should be empty)

EOF

f_log "Disable bluetooth service."
systemctl disable bluetooth

f_log "Custom Security Disable (/etc/modprobe.d/custom-security-disable.conf)"
cat <<-'EOF' > /etc/modprobe.d/custom-security-disable.conf

# Unused  filesystem types (disable)
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install udf /bin/true

# Unused protocols (disable)
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true

# Exras removed
install btrfs /bin/true
install joydev /bin/true
install psmouse /bin/true

EOF

cat <<-'EOF' > /etc/modprobe.d/nf_conntrack.conf
# IP Tables Security
options nf_conntrack nf_conntrack_helper=0

EOF

f_log "Setting shared memory restrictions (/etc/fstab)."
cat <<-'EOF' >> /etc/fstab
# Secure shared memory
tmpfs     /run/shm     tmpfs     defaults,noexec,nosuid     0     0

EOF

f_log "Setting tcp tuning recommendations (/etc/sysctl.d/70-custom-tcp-tuning.conf)."
cat <<-'EOF' > /etc/sysctl.d/70-custom-tcp-tuning.conf
# How many times to retry before determining something is wrong
# tcp_retries1 RFC 1122 recommends at least 3 retransmissions
# Default 3 retries
# Set to 3 retries
net.ipv4.tcp_retries1 = 3

# How many times to retry before killing an alive TCP connection
# tcp_retries2 RFC 1122 recommends at least 100 seconds (normally way too short)
# Default 15 (~900 seconds)
# RFC min 8 (~100 seconds)
# Extreme 6 (~25 seconds)
net.ipv4.tcp_retries2 = 8

# How many times to retry a connection to another host
# Default 5 (~180 seconds)
# Set to 5 (~180 seconds)
net.ipv4.tcp_syn_retries = 5

# How many times to retry a connection from another host
# Default 5 (~180 seconds)
# Set to 2 (~70 seconds)
net.ipv4.tcp_synack_retries = 2

# How long to keep socket in FIN-WAIT if we closed it
# Default 60 seconds
# Set to 3 seconds
net.ipv4.tcp_fin_timeout = 3

# TCP Keepalive
# Ferquency of probes
# Default 75 seconds
# Set to 15 seconds
net.ipv4.tcp_keepalive_intvl = 15

# Number of failed probes before connection is broken
# Default 9
# Set to 8
net.ipv4.tcp_keepalive_probes = 8

# How often to send keepalive message (when connection idle)
# Default 7200 seconds
# Set to 120 seconds
net.ipv4.tcp_keepalive_time = 120

EOF

f_log "Setting network hardening recommendations (/etc/sysctl.d/80-custom-hardening.conf)."
cat <<-'EOF' > /etc/sysctl.d/80-custom-hardening.conf
# Data protection
fs.suid_dumpable = 0
kernel.randomize_va_space = 2

# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log Martians (optional logging)
#net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.all.log_martians = 0

# Ignore Bogus Error Responses (log reduction)
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Ignore Secure ICMP redirects from gateways (optional)
#net.ipv4.conf.all.secure_redirects = 0
#net.ipv4.conf.default.secure_redirects = 0

# Ignore Directed pings (optional)
#net.ipv4.icmp_echo_ignore_all = 1

# Do not become a router
net.ipv4.ip_forward = 0

# Do not accept IPv6 router advertisements (optional)
#net.ipv6.conf.all.accept_ra = 0
#net.ipv6.conf.default.accept_ra = 0

EOF

f_log "Enabling Firewall."
sed -i -e 's/^ENABLED=.*$/ENABLED=yes/' /etc/ufw/ufw.conf

#***************************
# DRIVER SETTINGS
#***************************

f_log "Setting TouchScreen Config (/etc/eGTouchL.ini)"
# eGTouch Config
cat <<-'EOF' > /etc/eGTouchL.ini
[eGTouchL.ini]
DebugEnableBits			1
ShowDebugPosition		1
DeviceNums			1
BaudRate			0
ScanInterface			1
UseDriverCalib			1
SkipFirstByte			0
ShiftByteBothEnd		1
[String]
SerialPath0			default
SerialPath1			default
DevPID0				null
DevPID1				null

[Device_No.0]
Physical_Address
SupportPoints			10
SendRawPoints			0
Direction			0
Orientation			0
EdgeCompensate			0
	EdgeLeft		100
	EdgeRight		100
	EdgeTop			100
	EdgeBottom		100
HoldFilterEnable		0
	HoldRange		10
SplitRectMode			0
	CustomRectLeft		0
	CustomRectRight		2047
	CustomRectTop		0
	CustomRectBottom	2047
DetectRotation			1
ReportMode			2
EventType			1
BtnType				0
RightClickEnable		1
	RightClickDuration	1500
	RightClickRange		10
BeepState			0
	BeepDevice		0
	BeepFreq		1000
	BeepLen			200
VKEYEnable                      1
        VKEYReportMod           1
        VKEY_0                  0
[EndOfDevice]

[EndOfFile]

EOF

f_log "Setting Realtek wireless options (/etc/modprobe.d/rtl8821ae.conf)"
cat <<-'EOF' > /etc/modprobe.d/rtl8821ae.conf
# Ubuntu Wireless Issues
options rtl8821ae int_clear=0 fwlps=0 ips=0

EOF

f_log "Adding Serial Console Config (/lib/systemd/system/ttyS0.service)"
# Serial Console
cat <<-'EOF' > /lib/systemd/system/ttyS0.service
[Unit]
Description=Serial Console Service

[Service]
ExecStart=/sbin/getty -L 115200 ttyS0 xterm
Restart=always

[Install]
WantedBy=multi-user.target

EOF

#***************************
# APPLIANCE SETTINGS
#***************************

# osbuildinfo.properties (create)
mkdir -p /usr/share/appliance
cat <<-EOF > /usr/share/appliance/osbuildinfo.properties
version=0.0.1
buildDate=$(date +"%m/%d/%Y")
applianceType=Generic

EOF

# 64-bit kernel ?
[ "$(uname -i)" == "x86_64" ] && SWBIT=64 || SWBIT=32

# Get product name for iEi Known
PRODUCT_NAME="$(dmidecode -t system | grep -oE "Product\ Name:.*$" | grep -oE "(H|B)[0-9]{3}|SC[0-9]{2}")"

# Get Other
[ -z "${PRODUCT_NAME}" ] && PRODUCT_NAME="$(dmidecode -t system | sed -n -r  "s/.*(Product\ Name):\ (.*)$/\2/p")"

source /etc/os-release # Get ${VERSION_ID}

f_log "Running ${VERSION_ID} with ${SWBIT}-bit kernel [${PRODUCT_NAME}]"

case "${PRODUCT_NAME}" in
	H603|H409|SC86) # CCE3 (CCE3Touchscreen) & Roomlink3
					CUSTOM_SH="/appliance.build/custom-32.sh"
 					ENABLE_SC=0
					# NOTE: Install penmount after system built
   ;;
	B378|B380|B379) # CCE4 Unified (TouchScreen and Blackbox) and Roomlink 4
					declare -a DRVS_TGZS=( "00-egalax-drivers-${SWBIT}.tgz" "00-rtl8812-firmware.tgz")
					CUSTOM_SH="/appliance.build/custom-${SWBIT}.sh"
					ENABLE_SC=0
	;;
	*)          	# Other
					CUSTOM_SH="/appliance.build/custom-${SWBIT}.sh"
					ENABLE_SC=0
	;;
esac

# Custom Steps
[ -f "${CUSTOM_SH}" ] && /bin/bash ${CUSTOM_SH}

# Extract Drivers
for t in "${DRVS_TGZS[@]}"; do
	[ -f /appliance.build/$t ] &&  tar -zhxf /appliance.build/$t -C / > /dev/null 2>&1 &
done

# disable swapfile (if used)
if [ -f /swapfile ]; then
	swapoff -a
	sed -i -e '/swapfile/ s/^/#/' /etc/fstab
	rm /swapfile
fi

# Issue with corrupt grubenv entry
[ -f /boot/grub/grubenv ] && rm /boot/grub/grubenv

exit 0