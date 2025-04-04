# ToonRecovery

## What it does
This application boots a recovery environment for your Toon 1 from a Raspberry Pi or another device with a JTAG debugger attached.

At the moment, the following is implemented:
 - Setting up your Pi as NFS v2 server and populating the image
 - Install needed tools for ToonRecovery
 - Compile and install dependencies automatically
 - Guide users through running the script (WIP)
 - Detection of the U-Boot version
 - Loading of modified U-Boot version using JTAG
 - Logging in to supported versions of U-Boot
 - Setting up the U-Boot environment so the Toon boots into the recovery console
 - Set your own boot server IP address and/or the gateway IP address

## Prerequisites
Raspberry Pi Zero 2W (with a header installed, this is not optional!)

2021-05-07-raspios-buster-armhf.img (https://archive.org/details/2021-05-07-raspios-buster-armhf)

Raspberry Pi Imager (https://www.raspberrypi.com/software/)

Windows PC (Windows 10 or higher) with Putty installed.

Micro USB data cable.

## Setting up the Pi

Using a Raspberry Pi Zero 2W, image an SD card with "2021-05-07-raspios-buster-armhf.img"
Use Raspberry Pi Imager for this.
----------------------------------------------------------------------------------------------------
Select Raspberry Pi Device: Pi Zero 2 W
Operating System: Custom (use previously downloaded .img)
Storage: Select the SD card.

OS Customisation settings: choose Edit Settings
----------------------------------------------------------------------------------------------------
Under General tab:

Set hostname: raspberrypi.local
Set username and password: 
 Username: toon 
 Password: toon
Configure wireless LAN: 
 Enter your SSID and password.
----------------------------------------------------------------------------------------------------
Under Services tab:

Enable SSH: Use password authentication (enabling you to SSH into the Pi Zero with toon toon)
----------------------------------------------------------------------------------------------------
Under Options: 

Uncheck Eject media when finished

Click the save button.

The imager will now begin to image the SD card, and will verify it afterwards.
Because we unchecked "Eject media when finished", you'll see two partitions pop up. One asks to format, select no.
The other one is called "boot". If you configured the SSID/Password for Wireless LAN, you can skip this. 

If you didn't, you can configure the Pi to work through the host's USB: 
 
First, edit the file config.txt (in the boot partition) and append this line at the end:
dtoverlay=dwc2
Second, we will edit the file cmdline.txt. After rootwait, we will add
modules-load=dwc2,g_ether

Eject the SD card, and plug it into your RPi.
Plug the USB cable in the port closest to the HDMI port.

If you configured the Pi to connect to your wireless network, it should start to boot, and show up in your modem/router.
If you skipped it, you can open Putty, make sure it's on SSH, enter raspberrypi.local as address.

Here, you'll log in with toon / toon.

At this point, you should have a connection to the Pi, and the Pi should have internet access.


## How to use it?

Just like the Toon Rooter it at least requires a serial connection to the Toon. If your Toon 1 is from a newer generation with U-Boot after version 2010-R8, it also requires a JTAG connection. Serial and JTAG connection can be used from the GPIO of a Raspberry PI.

Make sure there's no power going in to either of the devices, and double check the connections
before powering up again.
Connect your Toon's debugging header to a Raspberry Pi according to the following pin assignments:

| Toon | Signal | Pi   |
|:----:|:------:|:----:|
|  1   |  RTCK  |      |
|  2   |  TRST  |  24  |
|  3   |  GND   |  25  |
|  4   |  TCK   |  23  |
|  5   |  GND   |  20  |
|  6   |  TMS   |  22  |
|  7   |  SRST  |  18  |
|  8   |  TDI   |  19  |
|  9   |  Vt    |      |
|  10  |  TDO   |  21  |
|  11  |  RxD   |  8   |
|  12  |        |      |
|  13  |  TxD   |  10  |
|  14  |  GND   |  9   |


Then make sure the serial port on the Pi is enabled and the serial console is disabled
using `raspi_config` and reboot if necessary. Install the dependencies mentioned in the
[Dependencies](#dependencies)-section.

Then run this command:
```
sudo curl -O https://raw.githubusercontent.com/djbiohazard/ToonRecovery/master/install.sh && sudo chmod +x install.sh && sudo ./install.sh
```

The script will then run. Once it configures the serial settings, it'll automatically reboot.
It'll close the ssh connection. Wait for the Pi to finish rebooting, and log back in with toon / toon.

Once back in, run 
```
sudo ./install.sh
```
The script will then continue where it left off.

## Command line arguments

```
usage: sudo python . [-h] [--serial-port PATH] [--gatewayip IP] [--serverip IP]
                  [--output-level INFO|DEBUG] [--jtag-available] [--jtag-hardware TYPE]
                  [--dont-check-uboot] [--boot-only]

Recover your Toon.

optional arguments:
  -h, --help            show this help message and exit
  --serial-port PATH    The path of the serial port to use. Per default it will use /dev/serial0 
  --output-level INFO|DEBUG
                        The level of output to print to the console
  --gatewayip IP        Set a gateway IP address if DHCP is not providing the gateway IP to your toon.
  --serverip IP         Set the NFS server IP address where the recovery image is located. Defaults to
                        where this script is running on.
  --jtag-available      Indicates you have a JTAG debugger connected to your
                        Toon's JTAG headers
  --jtag-hardware TYPE  The JTAG debugger type that we're working with. The
                        default is to autodetect the JTAG debugger (which
                        currently only works on Raspberry Pi). Supported
                        values are: auto, rpi1, rpi2, rpi3
  --dont-check-uboot    Don't check whether we can access the installer
                        version of U-Boot before using JTAG to start up the
                        custom one.
  --boot-only           Don't auto-recover, just boot into the serial
                        console for manual recovery
```

Als you need to connect the Toon to your network using the builtin UTP/LAN/ethernet port. It is not possible to boot from wifi.

Then reset your Toon and let the magic happen :) After it is finished you must connect to your toon over serial and you will see that your Toon is booted into the recovery console. The root password from recovery is set to 'toon'. You will probably want to change that aftwerwards.

## Recovery
When the Toon is booted into the recovery environment start your favourite serial terminal console client. You will presented a menu like this one.

```
Welcome to the Toon recovery environment.
--> Your Toon has hostname: eneco-001-xxxxxx
--> We have a VPN config file in the backup location
=========================================
1) Backup Toon VPN config
2) Format Toon filesystem
3) Recover Toon filesystem
4) Restore Toon hostname and VPN config from backup
9) Reboot Toon
0) Drop to shell
=========================================
Choose an option:
```
The first option will mount your Toon filesystem (if possible) and make a backup of your VPN config file. This is the only thing which makes your Toon unique and necessary to have your Toon connected to the Eneco server later on (for example, for updates).

The second option will format your Toon filesystem. Be sure you have a backup of the VPN config and agree with formatting the filesystem. You will loose every history of your Toon!

The third option will allow you to recover your Toon from a few supplied firmware versions.

The fourth option will recover your Toon VPN config and hostname after the recovery.


## Thanks
This application is based on ToonRooter from Marten Jacobs https://github.com/martenjacobs/ToonRooter and information provided by
- TheHogNL
- MarcelR
