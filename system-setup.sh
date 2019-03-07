
# Colors Setup
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Install fuzzy finder
pacman -S fzf

# Set time zone
printf "\n${YELLOW}Please select your time zone (type to find match, country code first): "
this_zone=$(du -a /usr/share/zoneinfo/* | fzf)
printf "${NC}"

ln -sf $this_zone /etc/localtime
hwclock --systohc

# Establish locale settings
printf "\n${YELLOW}Please select your locale (type to find match): "
this_locale=$(grep '^#[a-z]' /etc/locale.gen | sed 's/^#//' | fzf)
this_lang=$(echo $this_locale | awk '{ print $1 }')
printf "${NC}"

sed -i "s\/^\#${this_locale}\/${this_locale}\/" /etc/locale.gen # uncomment the `en_US.UTF-8 UTF-8`
locale-gen

echo "LANG=$this_lang" > /etc/locale.conf

# Set the hostname and establish a simple hosts file
printf "${YELLOW}"
read -p "Please specify the hostname for this system (e.g., arch-devbox): " this_hostname
printf "${NC}"

echo "$this_hostname" > /etc/hostname
echo > /etc/hosts <<EOF
127.0.0.1	$this_hostname
::1       $this_hostname
127.0.1.1	${this_hostname}.localdomain  $this_hostname
EOF

# Create the linux boot image
mkinitcpio -p linux

# Set the root password
passwd

# Install the boot loader and set the default image to boot to Arch (after 4 second delay)
bootctl --path=/boot install
echo > /boot/loader/loader.conf <<EOF
default arch
timeout 4
EOF

# Set up Arch boot entry
root_vol_line=$(grep -n '/[^a-z]' /etc/fstab)
rv_lineno=$(echo $root_vol_line | cut -d : -f 1)
rv_fs=$(echo $root_vol_line | cut -f 3)
rv_dev=$(sed -n "s/# \(\/..*\)/\1/p;${rv_lineno}q" /etc/fstab)
rv_partuuid=$(blkid $rv_dev | sed 's/..*PARTUUID="\(..*\)"$/\1/')
sed -e "s/XXXX/${rv_partuuid}/" -e "s/XXXX/${rv_fs}/" -e 's/$/ rw/' /usr/share/systemd/bootctl/arch.conf > /boot/loader/entries/arch.conf

pacman -S gnome gnome-extra networkmanager networkmanager-openvpn xterm
systemctl enable gdm
systemctl enable NetworkManager

printf "${YELLOW}"
read -p "Please specify a username: " this_username
printf "\nPlease select a shell for the specified user (type to find match): "
this_shell=$(grep '^/' /etc/shells | fzf)
printf "${NC}"

useradd -m -s $this_shell $this_username
passwd $this_username
sed -i "root ALL=(ALL) ALL/a $this_username ALL=(ALL) ALL" /etc/sudoers

printf "\n${GREEN}System should be ready for use!\n${NC}"

exit
