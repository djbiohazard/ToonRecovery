import serial
import logging
import re
import telnetlib
import os
import subprocess
import tarfile
import base64
import string
import random
from time import sleep
from serial.serialutil import Timeout
import StringIO
import tempfile
import sys

logging.basicConfig(level=logging.DEBUG)
log = logging.getLogger(__name__)

class Recover(object):
    def __init__(self, **params):
        if type(params['port']) is str:
            params['port']=serial.Serial(
                port=params['port'],
                baudrate=115200
            )
        self._port = params['port']
        self._has_jtag = params['has_jtag']
        self._check_uboot = params['check_uboot']
        self._jtag_hardware = params['jtag_hardware']
	self._boot_only = params['boot_only']
	self._gatewayip = params['gatewayip']
	self._serverip = params['serverip']

    def run(self):
        port = self._port
        has_jtag = self._has_jtag
        check_uboot = self._check_uboot
	boot_only = self._boot_only
	gatewayip = self._gatewayip
	serverip = self._serverip

        if check_uboot:
            uboot_passwords={
                "2010.09-R6" : "f4E9J",
                "2010.09-R8" : "3BHf2",
                "2010.09"    : "toon"
            }
            log.info("Waiting for Toon to restart")
            uboot_version=self.read_uboot_version()
            log.info("Toon has U-Boot version {}".format(uboot_version))
            if uboot_version in uboot_passwords:
                log.info("Using password to log in")
                self.access_uboot(uboot_passwords[uboot_version])
		self.patch_uboot()
                if boot_only:
                	log.info("Your Toon is now booting into a serial console")
		else:
                	log.info("Waiting for boot up")
                        self.start_recovery()
                return
            elif has_jtag is False:
                log.error("Unable to log in using password (need JTAG, but it's disabled)")
                sys.exit()
        if has_jtag:
            log.info("Loading new bootloader")
            self.start_bootloader("assets/u-boot.bin")
            port.reset_input_buffer()
            self._has_jtag = False
            self._check_uboot = True
            self.run()
        else:
            log.error("Need JTAG to access this Toon")
            sys.exit()

    def read_uboot_version(self):
        version_line_match = re.compile(r'^U-Boot ([^ ]+)')
        while True:
            line = self._port.readline().strip()
            match = version_line_match.match(line)
            if match:
                return match.group(1)

    def access_uboot(self, password):
        log.info("Logging in to U-Boot")
        self._port.write(password)
        self._port.flush()
        log.debug(self._port.read_until("U-Boot>"))
        log.debug("Logged in to U-Boot")

    def dhcp_uboot(self):
        port = self._port
        gatewayip = self._gatewayip

        log.info("Requesting network details using DHCP...")
	cmd = "dhcp"
        port.write(cmd + "\n")
        port.flush()
        log.debug(port.read_until("U-Boot>"))

        port.write("printenv\n")
        port.flush()
        gatewayip_match = re.compile(r'^gatewayip=(.+)$')
        gatewayip_val = None
        netmask_match = re.compile(r'^netmask=(.+)$')
        netmask_val = None
        ipaddr_match = re.compile(r'^ipaddr=(.+)$')
        ipaddr_val = None

        sleep(0.5)

        lines = port.read_until("U-Boot>")
        log.debug(lines)
        for line in lines.split('\n'):
            line = line.strip()
            log.debug(line)
            match = gatewayip_match.match(line)
            if match:
                gatewayip_val = match.group(1)
            match = netmask_match.match(line)
            if match:
                netmask_val = match.group(1)
            match = ipaddr_match.match(line)
            if match:
                ipaddr_val = match.group(1)

        #if gatewayip_val is None:
        if gatewayip_val is None:
            if gateway is None:
                log.error("Could not find value for gatewayip environment variable. Please set gatewayip manually!")
                sys.exit()
            else:
                log.debug("Setting static gateway ip")
	        cmd = "setenv gatewayip ".format(gatewayip)
                port.write(cmd + "\n")
                port.flush()
                log.debug(port.read_until("U-Boot>"))
                
        if netmask_val is None:
            log.error("Could not find value for netmask environment variable")
            sys.exit()
        if ipaddr_val is None:
            log.error("Could not find value for ipaddr environment variable")
            sys.exit()

        log.info("Received valid IP address, netmask and gateway using DHCP.")

    def patch_uboot(self):
        port = self._port
        serverip = self._serverip

        log.info("Patching U-Boot")
        port.reset_input_buffer()
        sleep(0.1)


	#TODO: set static network details
        self.dhcp_uboot()

        log.info("Loading kernel into memory from server. Should not take more than 60 seconds ...")
	cmd = "setenv serverip {}".format(serverip)
        port.write(cmd + "\n")
        port.flush()
        log.debug(port.read_until("U-Boot>"))

	cmd = "setenv bootargs root=/dev/nfs rw nfsroot=${serverip}:/srv/nfs/toon,nfsvers=3,nolock,tcp console=ttymxc0,115200 loglevel=8 mtdparts=mxc_nand:512K@0x00100000(u-boot-env)ro,1536K(splash-image),3M(kernel),3M(kernel-backup),119M(rootfs) ip=${ipaddr}:${serverip}:${gatewayip}:${netmask}:toon::off panic=0"
        port.write(cmd + "\n")
        port.flush()
        log.debug(port.read_until("U-Boot>"))

	cmd = "nfs 0xa1000000 /srv/nfs/toon/boot/uImage-nfs;bootm"
        port.write(cmd + "\n")
        port.flush()
        kernel_load_error_match = re.compile(r'.*ERROR.*')
        kernel_load_timeout_match = re.compile(r'.*T T T T.*')
        while True:
            line = self._port.readline().strip()
            log.debug(format(line))
            match = kernel_load_error_match.match(line)
            if match:
                log.info("Error loading from NFS server")
                sys.exit()
            match = kernel_load_timeout_match.match(line)
            if match:
                log.info("Timeout loading from NFS server")
                sys.exit()
            if line == 'done':
                break


        log.info("Kernel loaded into memory. Now booting from server...");


    def start_recovery(self):
        port = self._port

        log.info("Toon booting into recovery shell. For now, just start your favourite serial terminal")

    def start_bootloader(self, bin_path):

        log.info("Starting openocd")

        proc = subprocess.Popen([
            'openocd',
                '-s', '/usr/share/openocd',
                '-f', 'assets/adapters/{}.cfg'.format(self._jtag_hardware),
                '-f', 'assets/boards/ed20.cfg'
            ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        try:
            wait = 5
            log.info("Waiting for {} seconds".format(wait))
            sleep(wait)
            client = telnetlib.Telnet('localhost', 4444)
            #enable debugging if loading image is not working properly
            #client.set_debuglevel(1)
            log.debug(client.read_until("> "))
            log.info("Halting CPU")
            client.write("soft_reset_halt\n")
            log.debug(client.read_until("> "))
            sleep(0.1)
            client.write("reset halt\n")
            log.debug(client.read_until("> "))
            sleep(0.1)
            log.info("Loading new image to RAM")
            client.write("load_image {} 0xa1f00000\n".format(bin_path))
            log.debug(client.read_until("> "))
            sleep(0.1)
            log.info("Starting up new image")
            client.write("resume 0xa1f00000\n")
        except:
            try:
                log.exception(proc.communicate()[0])
            except:
                pass
            proc.terminate()
            raise

        proc.terminate()

def read_until(port, terminators=None, size=None):
    """\
    Read until any of the termination sequences is found ('\n' by default), the size
    is exceeded or until timeout occurs.
    """
    if not terminators:
        terminators = ['\n']
    terms = map(lambda t: (t, len(t)), terminators)
    line = bytearray()
    timeout = Timeout(port._timeout)
    while True:
        c = port.read(1)
        if c:
            line += c
            for (terminator, lenterm) in terms:
                if line[-lenterm:] == terminator:
                    # break does not work here because it will only step out of for
                    return bytes(line)
            if size is not None and len(line) >= size:
                break
        else:
            break
        if timeout.expired():
            break
    return bytes(line)
