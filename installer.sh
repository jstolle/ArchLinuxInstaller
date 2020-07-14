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

timedatectl set-ntp true

# System Disk
printf "${YELLOW}"
read -p "Disk to install to ? (e.g.: /dev/nvme0n1): " disk
printf "${NC}"

boot_disk="${disk}p1"

printf "${YELLOW}"
read -p "How much RAM ?       (e.g.: 16 for 16G): " ram
printf "${NC}"
totalSwap=$((2*$ram))

printf "${YELLOW}"
read -p "Would you like to encrypt the main drive? " encrypted
printf "${NC}"

case $encrypted in
    yes|y|yeah|sure|yep|yup|youbetcha)  encr="yes" ;;
    *)                                  encr="no"  ;;
esac

## TODO - Get the secure deletion of the drive working
# printf "${YELLOW}"
# read -p "Would you like to wipe current data on the drive? (This will take a long time.) " do_wipe
# printf "${NC}"

# case $do_wipe in
#       yes|y|yeah|sure|yep|yup|youbetcha)  wipe="yes" ;;
#       *)                                  wipe="no"  ;;
# esac

if [ "${encr}" = "yes" ]; then
    swap_disk=/dev/SysVolGroup/swap
    root_disk=/dev/SysVolGroup/root
    home_disk=/dev/SysVolGroup/home
    parted "${disk}" --script \
           mklabel gpt \
           mkpart ESP fat32 1MiB 551MiB \
           set 1 esp on \
           mkpart primary ext4 551MiB 100%
    cryptsetup luksFormat "${disk}p2"
    cryptsetup open "${disk}p2" cryptlvm
    pvcreate /dev/mapper/cryptlvm
    vgcreate SysVolGroup /dev/mapper/cryptlvm
    lvcreate -L ${totalSwap}G SysVolGroup -n swap
    lvcreate -L 64G SysVolGroup -n root
    lvcreate -l 100%FREE SysVolGroup -n home
else
    totalSwapEnd="${totalSwap}.5"
    swap_disk="${disk}p2"
    root_disk="${disk}p3"
    parted "${disk}" --script \
           mklabel gpt \
           mkpart ESP fat32 1MiB 551MiB \
           set 1 esp on \
           mkpart primary linux-swap 551MiB "${totalSwap}GiB" \
           mkpart primary ext4 "${totalSwapEnd}GiB" 100%
fi

# TODO - Provision more disks in friendly manner

mkfs.fat -F32 $boot_disk
mkswap $swap_disk
mkfs.ext4 $root_disk
swapon $swap_disk

mount $root_disk /mnt
mkdir /mnt/boot
mount $boot_disk /mnt/boot

if [ "x${home_disk}" != "x" ]; then
    mkfs.ext4 $home_disk
    mkdir -p /mnt/home
    mount $home_disk /mnt/home
fi

# Update pacman mirrorlist
# TODO - Troubleshoot?
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
pacman -S reflector --noconfirm
reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

pacstrap /mnt base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

# Put updated mirrorlist on new system
cp /mnt/etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist.backup
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

# TODO - Copy network settings if necessary

# Pull and run system setup script
printf "${YELLOW}"
read -p "Remote setup script? (e.g.: https://raw.githubusercontent.com/jstolle/ArchLinuxInstaller/master/system-setup.sh): " rsetup
printf "${NC}"

if [[ -n "${rsetup}" ]]; then
    curl -o /mnt/root/system-setup.sh "${rsetup}"
    arch-chroot /mnt sh /root/system-setup.sh
else
    arch-chroot /mnt
fi

printf "${YELLOW}"
read -p "Ready to reboot? " reboottime
printf "${NC}"

case $reboottime in
    yes|y|yeah|sure|yep|yup|youbetcha)  printf "\n${GREEN}Rebooting...."
                                        reboot
                                        ;;
    *)                                  printf "\n${YELLOW}Make any more updates required and manually reboot.${NC}"
                                        ;;
esac
