
import argparse, os, re
import socket


supported_jtag_hardware=['auto']
try:
    for file in os.listdir("assets/adapters"):
        m=re.match(r"^(.+)\.cfg$", file)
        if m:
            supported_jtag_hardware.append(m.group(1))
except:
    pass


parser = argparse.ArgumentParser(prog='sudo python .',
                                 description='Network recovery for your Toon.')

parser.add_argument('--serial-port',
                        metavar='PATH',
                        help='The path of the serial port to use',
                        default='/dev/serial0')

parser.add_argument('--serverip',
                        metavar='IP',
                        help='The NFS server IP where the recovery image is located. Default is the IP adddress of the server running this script.',
                        default=None)

parser.add_argument('--gatewayip',
                        metavar='IP',
                        help='The gateway IP if DHCP does not work',
                        default=None)

parser.add_argument('--output-level',
                        metavar='INFO|DEBUG',
                        help='The level of output to print to the console',
                        default="INFO")

parser.add_argument('--jtag-available',         action='store_true', help='Indicates you have a JTAG debugger connected to your Toon\'s JTAG headers')
parser.add_argument('--jtag-hardware',
                        metavar='TYPE',
                        help='The JTAG debugger type that we\'re working with. The default is to autodetect the JTAG debugger (which currently only works on Raspberry Pi). Supported values are: {}'.format(', '.join(supported_jtag_hardware)),
                        default="auto")

parser.add_argument('--dont-check-uboot',       action='store_true', help='Don\'t check whether we can access the installer version of U-Boot before using JTAG to start up the custom one.')

parser.add_argument('--boot-only',              action='store_true', help='Don\'t start recovery, just boot into the serial console')


args = parser.parse_args()

import logging
logging.basicConfig(level={
    "INFO":logging.INFO,
    "DEBUG":logging.DEBUG,
}[args.output_level])
log = logging.getLogger(__name__)

def get_cpuinfo():
    info = {}
    with open('/proc/cpuinfo') as fo:
        for line in fo:
            name_value = [s.strip() for s in line.split(':', 1)]
            if len(name_value) != 2:
                continue
            name, value = name_value
            if name not in info:
                info[name]=[]
            info[name].append(value)
    return info
def find_rpi_version():
    try:
        revision = get_cpuinfo()['Revision'][0]
        return {
            "Beta":     "rpi1",
            "0002":     "rpi1",
            "0003":     "rpi1",
            "0004":     "rpi1",
            "0005":     "rpi1",
            "0006":     "rpi1",
            "0007":     "rpi1",
            "0008":     "rpi1",
            "0009":     "rpi1",
            "000d":     "rpi1",
            "000e":     "rpi1",
            "000f":     "rpi1",
            "0010":     "rpi1",
            "0011":     "rpi1",
            "0012":     "rpi1",
            "0013":     "rpi1",
            "0014":     "rpi1",
            "0015":     "rpi1",
            "a01040":   "rpi2",
            "a01041":   "rpi2",
            "a21041":   "rpi2",
            "a22042":   "rpi2",
            "900021":   "rpi1",
            "900032":   "rpi1",
            "900092":   "rpi1",
            "900093":   "rpi1",
            "920093":   "rpi1",
            "9000c1":   "rpi1",
            "a02082":   "rpi3",
            "a020a0":   "rpi3",
            "a22082":   "rpi3",
            "a32082":   "rpi3",
            "a020d3":   "rpi3",
	    "a03111":   "rpi4",
            "b03111":   "rpi4",
            "c03111":   "rpi4",
        }[revision]
    except:
        pass
    return None

def detect_jtag_hardware():
    hardware=find_rpi_version()# or detect_usb_device() or detect_something_else()
    #TODO: implement more checks here
    if not hardware:
        raise Exception("Cannot autodetect jtag hardware")
    return hardware

def get_ip_address():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    return s.getsockname()[0]

def main():

    log.info("Starting up...")

    import recovery

    serial_path = args.serial_port
    jtag_available = args.jtag_available
    jtag_hardware = args.jtag_hardware
    check_current_bootloader = not args.dont_check_uboot
    boot_only = args.boot_only
    gatewayip = args.gatewayip
    serverip = args.serverip

    if jtag_hardware == "auto":
        jtag_hardware = detect_jtag_hardware()
        log.info("Detected JTAG hardware '{}'".format(jtag_hardware))

    if serverip is None:
        serverip = get_ip_address()
        log.info("Setting server ip to {}".format(serverip))

    import json
    params = {
        "port" : serial_path,
        "has_jtag" : jtag_available,
        "check_uboot" : check_current_bootloader,
        "jtag_hardware" : jtag_hardware,
	"boot_only" : boot_only,
	"gatewayip" : gatewayip,
	"serverip" : serverip 
    }
    log.debug(json.dumps(params))
    recovery.Recover(**params).run()

if __name__ == '__main__' :
    try:
        main()
    except Exception as e:
        if args.output_level=="DEBUG":
            raise
        else:
            log.fatal(str(e))
