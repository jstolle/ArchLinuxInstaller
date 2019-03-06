#### Arch Linux Automated Installers under [TFL](https://github.com/nic0lae/TrueFreeLicense)

The scripts provided here are not meant to be all-encompassing, but will get a new Arch system to a generally usable state with relative ease. Personally, all of the packages installed by the system-setup.sh script outlined below are removed once I have my git and gpg setup in place on a system, but this gets me a usable system quickly. I may come back and replace some or all of the setup packages with other (less friendly?) options to achieve the same results.

## Usage

### Installer

Download the raw copy of the [installer.sh](./installer.sh) file to a freshly booted Arch ISO and execute it, answering the prompts along the way. An option is given to pull down a system setup script as well; the one cited in the installer.sh script is outlined below.

### System Setup

After an Arch image has been successfully initialized with `pacstrap`, download the raw copy of the [system-install.sh](./system-setup.sh) into the new system (preferably into `/root/system-setup.sh` as in the installer.sh script outlined above) and run in an `arch-chroot` environment to install the basics on a system.
