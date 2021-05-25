# cerner-appliance-build-lubuntu

Cerner Connectivity Engine Generic Lubuntu Build

## Overview

This GIT repository provides the automation instructions for installing Lubuntu 18.04 LTS onto a Cerner Connectivity Engine.  This generic build/image can be used to remove all propriatray information from the Cerner Connectivity Engine converting it into a functional gerneric Linux system.  This is useful when discarding or selling the hardware.

-----

## FAQ

### What is a Cerner Connectivity Engine?

The Cerner Connectivity Engine (CCE) is a Linux-based system used to run drivers for Bedside Medical Devices (BMDI) or, with the CCE4TS, Lab Medical Device Interfaces (LMDI).   However, the CCE is not a medical device.  The CCE is used with a Device Adapter (DA) for serial connectivity to a medical device.  The DA is a custom USB to Serial device that stores device type and unique identifier that represents the connected device. As such, the DA is intended to stay with the medical device.  The CCE is part of the CareAware iBus ecosystem and is primarily a producer (or publisher) of data that is consumed by subscribers.  Therefor, as designed, the CCE is not a standalone device and not very useful on its own.

| Cerner Model | System Type | SubType | Mfg | MfgID | BIOS ID | EoL/EoS |
| ----- | ----- | ----- | ----- | ----- | ----- | ----- | 
| CCE3Blackbox | Embedded x86 | | iEi | IBX-530B-R30-AN2/N270 | H409 | 4/1/2021 |
| CCE3Touchscreen | Embedded x86 | PanelPC | iEi | AFL-08AH-N270-CR | H603 | 4/1/2021 |
| CCE4 (Blackbox) | Embedded x86_64 | | iEi | uIBX-230-N2930-CR | B380 | |
| CCE4 (Touchscreen) | Embedded x86_64 | PanelPC | iEi | AFL3-W07A-N2930-CR | B378 | |

### Why Lubuntu? 

[Lubuntu](https://lubuntu.net) is one of the few supported Linux distrobutions that still provide a 32-bit image that can fit within the smaller 4GB disks included in older CCEs. The debian preseed automation makes customization and installation ideal for individuals that do not have a direct relationship with Cerner.  As 32-bit hardware is depricated, this same approach can be used for 64-bit hardware with greater options for Ubuntu-based distrobutions.

-----

## Lubuntu Installation

> **NOTE**: Installation assume Windows machine for USB creation activity.

### Requirements

The following items are required to perform this installation:
- [ ] **USB disk** (2GB or greater)
- [ ] **USB Keyboard**
- [ ] [Rufus](https://rufus.ie/) or [Rufus Portable](https://portableapps.com/apps/utilities/rufus-portable) - Used to create USB bootable media
- [ ] **Lubuntu CD Image** - Source of bootable media
  - [ ] **x86 System**: [lubuntu-18.04-alternate-i386.iso](http://cdimage.ubuntu.com/lubuntu/releases/18.04/release/lubuntu-18.04-alternate-i386.iso)
  - [ ] **x86_86 System**: [lubuntu-18.04-alternate-amd64.iso](http://cdimage.ubuntu.com/lubuntu/releases/18.04/release/lubuntu-18.04-alternate-amd64.iso)
- [ ] Wired DHCP Internet connection for hardware during build 

### Create Bootable USB Media

> **NOTE**: [Rufus](https://rufus.ie/) simplifies the process to format media, copy ISO, and make USB bootable.

Complete the following steps to create a bootable USB for Linux installation media:
1. With access to [Lubuntu](https://lubuntu.net) installation media (ISO) and [Rufus](https://rufus.ie/) application, insert USB into Windows system.
1. Start Rufus:
    1. Under **Device**, select destination USB disk.
    1. Next to checkbox labeled **Create a bootable disk image using**, select **ISO Image** and use the disk media icon to select the [Lubuntu](https://lubuntu.net) installation media.  For example, [lubuntu-18.04-alternate-i386.iso](http://cdimage.ubuntu.com/lubuntu/releases/18.04/release/lubuntu-18.04-alternate-i386.iso).
    1. Click **Start**.
1. When process is complete, Click **Close** and exit [Rufus](https://rufus.ie/).

> **NOTE**: This process can take some time but should start right away. Some security software can lock the media and prevent immediate progress. If this happens, close Rufus, remove and reinsert the USB disk. In extreme cases, remove the assigned drive letter for the USB disk through Windows Disk Management. This will help prevent access by other applications during Rufus use.

### Add Build Automation to Media

Complete the following steps to include custom installation preseed:
1. Insert USB disk and mount in Windows.
1. On the root of the USB disk, create a directory **appliance**.
1. Copy the content of [cdrom/appliance](cdrom/appliance) from this GIT repository to the new directory
1. Customize USB BIOS boot /isolinux/txt.cfg.  Example: [cdrom/isolinux/txt.cfg](cdrom/isolinux/txt.cfg)
```
label install
  menu label ^Install Lubuntu on CCE
  kernel /install/vmlinuz
  append  file=/cdrom/appliance/appliance-lubuntu.seed console-setup/ask_detect=false console-keymaps-at/keymap=us keyboard-configuration/layoutcode=us locale=en_US hostname=cce vga=788 initrd=/install/initrd.gz quiet noapic noacpi nosplash irqpol ---
```
1. When complete, eject USB media and unplug USB disk from system.

### Installation Lubuntu

Complete the following steps to install Lubuntu:
1. Insert USB Keyboard and USB media into CCE.
2. Connect Ethernet cable to CCE.
3. Boot (or Reboot) the hardware.
4. After BIOS Post 'beeps', Press boot overide key.
    1. **F11** for x86 hardware.
    1. **F7** for x86_64 hardware.
5. Select language, for example *English*.
6. Select **Install Lubuntu on CCE**.

> **NOTE**: The installation will install and update the system.  For older hardware the installation can take some time.  

### Post Installation Steps

> **Important!**: Post installation steps are only required for x86 systems that you want to maintain Touchscreen functionality.  x86_86 systems should be fully functional.

Completethe following steps to install x86 touchscreen drivers:
... **TODO**

-----

## Cloning Disk Image

The installation is design to support basic cloning.  Disk imaging is not covered with this installation information.


