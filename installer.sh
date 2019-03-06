#!/bin/sh

# Colors Setup
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Internet Setup
ping -c 1 google.com
if [[ $? -eq 0 ]]; then
	printf "\n${GREEN}INTERNET - OK"
else
	printf "\n${RED}INTERNET NEEDED"
	wifi-menu
fi
printf "\n${NC}"

# System Disk
read -p "${YELLOW}Disk to install to ? (e.g.: /dev/nvme0n1): ${NC}" disk

#printf "\n${YELLOW}How much RAM ?       (e.g.: 16 for 16G): "
read -p "${YELLOW}How much RAM ?       (e.g.: 16 for 16G): ${NC}" ram
#printf "\n${NC}"
totalSwap=$((2*$ram))
totalSwapEnd="${totalSwap}.5"

parted "${disk}" --script \
	mklabel gpt \
	mkpart ESP fat32 1MiB 551MiB \
	set 1 esp on \
	mkpart primary linux-swap 551MiB "${totalSwap}GiB" \
	mkpart primary ext4 "${totalSwapEnd}GiB" 100%

# TODO - Provision more disks in friendly manner
# TODO - Disk encryption option
mkfs.fat "${disk}p1"
mkswap "${disk}p2"
mkfs.ext4 "${disk}p3"

swapon "${disk}p2"

mount "${disk}p3" /mnt
mkdir /mnt/boot
mount "${disk}p1" /mnt/boot

timedatectl set-ntp true

# Update pacman mirrorlist
# TODO - Troubleshoot?
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
pacman -S reflector --noconfirm
reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

pacstrap /mnt base base-devel
genfstab -U /mnt >> /mnt/etc/fstab

# Put updated mirrorlist on new system
cp /mnt/etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist.backup
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# TODO - Copy network settings if necessary

# Pull and run system setup script
read -p "${YELLOW}Remote setup script? (e.g.: https://raw.githubusercontent.com/jstolle/ArchLinuxInstaller/master/system-setup.sh): ${NC}" rsetup

if [[ -n "${rsetup}" ]]; then
	curl -o /mnt/root/system-setup.sh "${rsetup}"
	arch-chroot /mnt sh /root/system-setup.sh
else
	arch-chroot /mnt
fi

read -p "${YELLOW}Ready to reboot? ${NC}" reboottime

case $reboottime in
	yes|y|yeah|sure|yep|yup|youbetcha)  printf "\n${GREEN}Rebooting...."
	                                    reboot
																			;;
	*)                                  printf "\n${YELLOW}Make any more updates required and manually reboot.${NC}"
	                                    ;;
esac
