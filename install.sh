#!/bin/bash
# ToonRecovery Installer for Raspberry Pi Zero 2W by DjBiohazard
echo "                                                                                                    
                                           @@@        @@@                                           
                                      @@@@                @@@@                                      
                                   @@@@                      @@@@                                   
                                @@@@@                          @@@@@                                
                              @@@@@                              @@@@@                              
                            @@@@@                                  @@@@@                            
                           @@@@@                                    @@@@@                           
                          @@@@@                                      @@@@@                          
                        @@@@@@@                                      @@@@@@@                        
                        @@@@@@                                        @@@@@@                        
                       @@@@@@@                                        @@@@@@@                       
                      @@@@@@@@                                        @@@@@@@@                      
                      @@@@@@@@                                        @@@@@@@@                      
                     @@@@@@@@@                @@@@@@@@                @@@@@@@@@                     
                     @@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@                     
                     @@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@                     
                     @@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@                     
                     @@@@@@@@@@@@  @@@@@@@@@@          @@@@@@@@@@  @@@@@@@@@@@@                     
                     @@@@@@@@@@@@@  @@@@                    @@@@  @@@@@@@@@@@@@                     
                  @@@@@@@@@@@@@@@@@@                            @@@@@@@@@@@@@@@@@@                  
               @@@@@@@@@@@@@@@@@@@@@@@                        @@@@@@@@@@@@@@@@@@@@@@@               
             @@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@             
           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           
         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         
        @@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@        
       @@@@@@@@@@       @@@      @@@@@@@@@@@@@        @@@@@@@@@@@@@      @@@       @@@@@@@@@@       
      @@@@@@@           @@@@@@@      @@@@@@@@          @@@@@@@@      @@@@@@@           @@@@@@@      
     @@@@@@             @@@@@@@        @@@@@            @@@@@        @@@@@@@             @@@@@@     
    @@@@@@              @@@@@@@          @@@@          @@@@          @@@@@@@              @@@@@@    
    @@@@                @@@@@@@                                      @@@@@@@                @@@@    
   @@@@                 @@@@@@@@           @@@@@    @@@@@           @@@@@@@@                 @@@@   
   @@@                   @@@@@@@            @@@@@@@@@@@@            @@@@@@@                   @@@   
   @@@                    @@@@@@@           @@@@@@@@@@@@           @@@@@@@                    @@@   
   @@                     @@@@@@@@           @@@@@@@@@@           @@@@@@@@                     @@   
   @@                      @@@@@@@@          @@@@@@@@@@          @@@@@@@@                      @@   
   @@                       @@@@@@@@@        @@@@@@@@@@        @@@@@@@@@                       @@   
   @@                         @@@@@@@@@@     @@@@@@@@@@     @@@@@@@@@@                         @@   
    @                          @@@@@@@@@@@@  @@@@@@@@@@  @@@@@@@@@@@@                          @    
    @@                           @@@@@@@@@@ @@@@@@@@@@@@ @@@@@@@@@@                           @@    
                                    @@@@@@  @@@@@@@@@@@@  @@@@@@                                    
                                       @@  @@@@@@@@@@@@@@  @@                                       
                                          @@@@@@@@@@@@@@@@                                          
                                         @@@@@@@@@@@@@@@@@@                                         
         @@                            @@@@@@@@@@@@@@@@@@@@@@                            @@         
           @@                        @@@@@@@@@@@@@@@@@@@@@@@@@@                        @@           
             @@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                  @@@             
               @@@@@@@      @@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@      @@@@@@@               
                  @@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@                  
                      @@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@@@@@@@                      
                                                                                                    
                                                                                                    
                                                                                                    
                                                                                                    
"
echo "ToonRecovery installer by DjBiohazard (Eric van den Hurck)"
echo "Based (and contains) on scripts by IgorYbema, TheHogNL, MarcelR."
echo "Press any key to continue..."
read -n 1 -s
set -e

# Check if resuming after reboot
if [ -f /root/.toonrecovery_continue_after_reboot ]; then
    echo "Resuming ToonRecovery installation after reboot..."
    rm /root/.toonrecovery_continue_after_reboot
    CONTINUE_AFTER_REBOOT=true
else
    CONTINUE_AFTER_REBOOT=false
fi

if [ "$CONTINUE_AFTER_REBOOT" = false ]; then
# Check for required tools
REQUIRED_TOOLS=("curl" "git" "tar" "make" "python")
for tool in "${REQUIRED_TOOLS[@]}"; do
    command -v $tool &>/dev/null || { echo "Error: $tool is not installed!"; exit 1; }
done

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update package list to ensure latest package availability
echo "Updating package list..."
apt update

# Install necessary dependencies for NFS, Python, and OpenOCD
echo "Installing necessary packages..."
apt install -y nfs-kernel-server portmap nfs-common python-serial git make libtool libtool-bin pkg-config autoconf automake texinfo libusb-1.0 libusb-dev python minicom

# Enable onboard serial and disable shell over serial
echo "Configuring serial port..."
sed -i '/^enable_uart=/c\enable_uart=1' /boot/config.txt
grep -qxF 'enable_uart=1' /boot/config.txt || echo 'enable_uart=1' >> /boot/config.txt

# Remove serial console from cmdline.txt if present
if grep -q 'console=serial0,115200' /boot/cmdline.txt; then
    sed -i 's/console=serial0,115200 //g' /boot/cmdline.txt
    echo "Serial console disabled. Reboot is required for changes to take effect."
fi

# Stop and disable serial-getty service to prevent conflicts
systemctl stop serial-getty@serial0.service || true
systemctl disable serial-getty@serial0.service || true
fi

if [ "$CONTINUE_AFTER_REBOOT" = false ]; then
    echo "Installation requires a reboot for the serial port settings to take effect."
    echo "This is required for the script to work."
    touch /root/.toonrecovery_continue_after_reboot
    sleep 5
    reboot
    exit 0
fi

# Configure NFS server settings
NFS_EXPORT_DIR="/srv/nfs"
echo "Setting up NFS..."
mkdir -p "$NFS_EXPORT_DIR"

# Define NFS export rules
echo "$NFS_EXPORT_DIR *(rw,no_subtree_check,async,no_root_squash)" > /etc/exports

# Apply NFS export changes
exportfs -a

# Enable NFS v2 support for compatibility
echo "Configuring NFS to allow v2..."
sed -i 's/^RPCNFSDCOUNT=.*/RPCNFSDCOUNT="-V 2 8"/' /etc/default/nfs-kernel-server
sed -i 's/^RPCMOUNTDOPTS=.*/RPCMOUNTDOPTS="-V 2 --manage-gids"/' /etc/default/nfs-kernel-server

# Download and extract NFS recovery image
echo "Downloading and extracting the NFS recovery image..."
if [ ! -f "$NFS_EXPORT_DIR/toon-recovery-nfs-server-image.tar.gz" ]; then
    if ! curl -L -Nks "http://qutility.nl/toon-recovery-nfs-server-image.tar.gz" -o "$NFS_EXPORT_DIR/toon-recovery-nfs-server-image.tar.gz"; then
        echo "Failed to download NFS recovery image!"
        exit 1
    fi
fi
tar -xzvf "$NFS_EXPORT_DIR/toon-recovery-nfs-server-image.tar.gz" -C "$NFS_EXPORT_DIR"

# Restart NFS server now that configurations and files are in place
echo "Rebooting NFS server..."
systemctl restart nfs-kernel-server

# Validate NFS server is running
if ! systemctl is-active --quiet nfs-kernel-server; then
    echo "NFS server failed to start! Check logs for details."
    exit 1
fi

# Build and install JimTCL (required for OpenOCD)
echo "Building and installing JimTCL..."
cd /opt
rm -rf jimtcl
git clone https://github.com/msteveb/jimtcl.git
cd jimtcl
./configure
make -j4
sudo make install

# Build and install OpenOCD
echo "Building and installing OpenOCD..."
cd /opt
rm -rf openocd
if ! git clone --recursive git://git.code.sf.net/p/openocd/code openocd; then
    echo "Failed to clone OpenOCD repository!"
    exit 1
fi
cd openocd
./bootstrap
./configure --enable-sysfsgpio --enable-bcm2835gpio --prefix=/usr
make -j$(nproc)
make install

# Download and set up ToonRecovery
echo "Downloading ToonRecovery..."
cd /opt
rm -rf ToonRecovery
if ! git clone https://github.com/djbiohazard/ToonRecovery.git; then
    echo "Failed to clone ToonRecovery repository!"
    exit 1
fi
cd ToonRecovery

# Installation complete message
echo "Installation complete. Please make sure the Toon and Pi are connected before running the script. Refer to readme.md"

# Ask if they want to continue or quit
read -p "Do you want to continue with running ToonRecovery? (y/n): " CONTINUE
if [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
    echo "Exiting the installer. Goodbye!"
    exit 0
fi

# Ask for the serial port
read -p "Enter the serial port (default /dev/serial0): " SERIAL_PORT
SERIAL_PORT=${SERIAL_PORT:-/dev/serial0}

# Ask for the output level
echo "Select output level:"
echo "1. INFO"
echo "2. DEBUG"
read -p "Choose output level (1 or 2): " OUTPUT_LEVEL
if [[ "$OUTPUT_LEVEL" == "2" ]]; then
    OUTPUT_LEVEL="DEBUG"
else
    OUTPUT_LEVEL="INFO"
fi

# Ask for the gateway IP
read -p "Enter gateway IP (leave blank for default): " GATEWAY_IP

# Ask for the server IP
read -p "Enter server IP (leave blank for default): " SERVER_IP

# Ask if JTAG is available
read -p "Is JTAG available? (y/n): " JTAG_AVAILABLE
if [[ "$JTAG_AVAILABLE" == "y" || "$JTAG_AVAILABLE" == "Y" ]]; then
    JTAG_AVAILABLE="--jtag-available"
else
    JTAG_AVAILABLE=""
fi

# Ask for JTAG hardware type
echo "Select JTAG hardware type:"
echo "1. auto"
echo "2. rpi1"
echo "3. rpi2"
echo "4. rpi3 (choose this one for Pi Zero 2W)"
read -p "Choose JTAG hardware type (1-4): " JTAG_HARDWARE
case "$JTAG_HARDWARE" in
    1) JTAG_HARDWARE="auto" ;;
    2) JTAG_HARDWARE="rpi1" ;;
    3) JTAG_HARDWARE="rpi2" ;;
    4) JTAG_HARDWARE="rpi3" ;;
    *) JTAG_HARDWARE="auto" ;;
esac

# Ask if we should skip U-Boot check
read -p "Skip U-Boot check? (y/n): " DONT_CHECK_UBOOT
if [[ "$DONT_CHECK_UBOOT" == "y" || "$DONT_CHECK_UBOOT" == "Y" ]]; then
    DONT_CHECK_UBOOT="--dont-check-uboot"
else
    DONT_CHECK_UBOOT=""
fi

# Ask if we should only boot and not auto-recover
read -p "Only boot, don't auto-recover? (y/n): " BOOT_ONLY
if [[ "$BOOT_ONLY" == "y" || "$BOOT_ONLY" == "Y" ]]; then
    BOOT_ONLY="--boot-only"
else
    BOOT_ONLY=""
fi

# Display final choices
echo ""
echo "You have chosen the following options:"
echo "Serial Port: $SERIAL_PORT"
echo "Output Level: $OUTPUT_LEVEL"
echo "Gateway IP: $GATEWAY_IP"
echo "Server IP: $SERVER_IP"
echo "JTAG Available: $JTAG_AVAILABLE"
echo "JTAG Hardware Type: $JTAG_HARDWARE"
echo "Skip U-Boot Check: $DONT_CHECK_UBOOT"
echo "Boot Only: $BOOT_ONLY"
echo ""

# Run the Python script with the chosen arguments. Abort the script if it fails.
if ! sudo python your_script.py --serial-port "$SERIAL_PORT" --output-level "$OUTPUT_LEVEL" --gatewayip "$GATEWAY_IP" --serverip "$SERVER_IP" $JTAG_AVAILABLE --jtag-hardware "$JTAG_HARDWARE" $DONT_CHECK_UBOOT $BOOT_ONLY; then
    echo "❌ ToonRecovery script failed. Aborting."
    exit 1
fi


# After installation, ask if they want to connect via minicom
echo ""
read -p "Do you want to connect to the Toon now using minicom? (y/n): " CONNECT
if [[ "$CONNECT" == "y" || "$CONNECT" == "Y" ]]; then
    # Launch minicom with the chosen serial port and settings
    echo "Connecting to the Toon via minicom..."
    sudo minicom -D "$SERIAL_PORT" -b 115200 -o -8 -d
else
    echo "You can connect to the Toon later using minicom."
fi
