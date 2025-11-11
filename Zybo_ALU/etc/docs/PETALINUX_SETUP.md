# PetaLinux Setup Guide for ALU AXI Project
# Engineer: 나무
# Date: 2025-11-12

## Prerequisites
- Vivado 2022.2 or later
- PetaLinux 2022.2 or later
- Zybo Z7-20 board
- Linux host machine (Ubuntu 20.04/22.04 recommended)

## Step 1: Create Vivado Hardware Project

### 1.1 Launch Vivado and Create Project
```bash
cd zybo_alu_axi/tcl
vivado -mode tcl -source create_project.tcl
```

### 1.2 Generate Bitstream
In Vivado GUI:
1. Click "Generate Bitstream"
2. Wait for completion (may take 15-30 minutes)

### 1.3 Export Hardware
1. File → Export → Export Hardware
2. Check "Include bitstream"
3. Export to: `zybo_alu_axi/hardware/system_wrapper.xsa`

## Step 2: Create PetaLinux Project

### 2.1 Source PetaLinux Settings
```bash
source /tools/Xilinx/PetaLinux/2022.2/settings.sh
```

### 2.2 Create Project
```bash
cd zybo_alu_axi
petalinux-create --type project --template zynq --name petalinux_alu
cd petalinux_alu
```

### 2.3 Configure Hardware
```bash
petalinux-config --get-hw-description=../hardware
```

Configuration options:
- Leave most settings as default
- Navigate to "Image Packaging Configuration"
  - Set "Root filesystem type" to "SD card"
- Save and exit

## Step 3: Add Custom Driver Module

### 3.1 Create Kernel Module
```bash
petalinux-create -t modules --name alu-driver --enable
```

### 3.2 Copy Driver Source
```bash
cp ../sw/alu_driver.c project-spec/meta-user/recipes-modules/alu-driver/files/alu-driver.c
```

### 3.3 Edit Module Recipe
Edit `project-spec/meta-user/recipes-modules/alu-driver/alu-driver.bb`:
```bitbake
SUMMARY = "ALU AXI Lite Driver"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=12f884d2ae1ff87c09e5b7ccc2c4ca7e"

inherit module

SRC_URI = "file://Makefile \
           file://alu-driver.c \
           file://COPYING \
          "

S = "${WORKDIR}"

RPROVIDES_${PN} += "kernel-module-alu-driver"
```

## Step 4: Add Device Tree Overlay

### 4.1 Create Device Tree File
```bash
mkdir -p project-spec/meta-user/recipes-bsp/device-tree/files
cp ../sw/alu-overlay.dts project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi
```

### 4.2 Edit Device Tree Recipe
Edit `project-spec/meta-user/recipes-bsp/device-tree/device-tree.bbappend`:
```bitbake
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://system-user.dtsi"
```

## Step 5: Add User Application

### 5.1 Create Application Recipe
```bash
petalinux-create -t apps --name alu-test --enable
```

### 5.2 Copy Application Source
```bash
cp ../sw/alu_test_devmem.c project-spec/meta-user/recipes-apps/alu-test/files/alu_test_devmem.c
cp ../sw/alu_test_sysfs.c project-spec/meta-user/recipes-apps/alu-test/files/alu_test_sysfs.c
cp ../sw/Makefile project-spec/meta-user/recipes-apps/alu-test/files/Makefile
```

### 5.3 Edit Application Recipe
Edit `project-spec/meta-user/recipes-apps/alu-test/alu-test.bb`:
```bitbake
SUMMARY = "ALU AXI Test Application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://alu_test_devmem.c \
           file://alu_test_sysfs.c \
           file://Makefile \
          "

S = "${WORKDIR}"

do_compile() {
    oe_runmake
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 alu_test_devmem ${D}${bindir}
    install -m 0755 alu_test_sysfs ${D}${bindir}
}

FILES_${PN} = "${bindir}/*"
```

## Step 6: Configure Kernel

### 6.1 Enable Required Kernel Options
```bash
petalinux-config -c kernel
```

Navigate and enable:
- Device Drivers → Character devices → `/dev/mem` device support (CONFIG_DEVMEM=y)
- Device Drivers → Userspace I/O drivers (CONFIG_UIO=y)

Save and exit.

## Step 7: Configure Root Filesystem

### 7.1 Add Packages
```bash
petalinux-config -c rootfs
```

Navigate to:
- Filesystem Packages → misc → alu-test → [*]
- Filesystem Packages → modules → alu-driver → [*]

Also enable:
- Filesystem Packages → base → tar
- Filesystem Packages → devel → gcc
- Filesystem Packages → devel → make

Save and exit.

## Step 8: Build PetaLinux

### 8.1 Build Everything
```bash
petalinux-build
```

This will take 1-3 hours depending on your machine.

### 8.2 Generate Boot Images
```bash
petalinux-package --boot --fsbl images/linux/zynq_fsbl.elf \
                          --fpga images/linux/system_wrapper.bit \
                          --u-boot --force
```

## Step 9: Prepare SD Card

### 9.1 Partition SD Card (Linux)
```bash
sudo fdisk /dev/sdX  # Replace X with your SD card

# Create two partitions:
# Partition 1: 512MB, FAT32, bootable
# Partition 2: Remaining space, ext4

sudo mkfs.vfat -F 32 /dev/sdX1
sudo mkfs.ext4 /dev/sdX2
```

### 9.2 Copy Boot Files
```bash
# Mount boot partition
sudo mount /dev/sdX1 /mnt/boot

# Copy boot files
cd images/linux
sudo cp BOOT.BIN /mnt/boot/
sudo cp image.ub /mnt/boot/
sudo cp boot.scr /mnt/boot/

sudo umount /mnt/boot
```

### 9.3 Extract Root Filesystem
```bash
# Mount rootfs partition
sudo mount /dev/sdX2 /mnt/rootfs

# Extract rootfs
cd images/linux
sudo tar xvf rootfs.tar.gz -C /mnt/rootfs

sudo umount /mnt/rootfs
```

## Step 10: Boot and Test

### 10.1 Boot Zybo Z7-20
1. Insert SD card
2. Set boot mode to SD card (JP5 set to SD)
3. Connect USB-UART (115200 8N1)
4. Power on board

### 10.2 Login
Default credentials:
- Username: root
- Password: root

### 10.3 Verify Hardware
```bash
# Check if driver is loaded
lsmod | grep alu

# Check device tree
ls -l /sys/devices/platform/amba/43c00000.alu/

# Check sysfs interface
ls -l /sys/devices/platform/amba/43c00000.alu/
```

### 10.4 Run Tests
```bash
# Test with sysfs interface
alu_test_sysfs -t

# Test with direct memory access
alu_test_devmem -t

# Interactive mode
alu_test_devmem -i

# Single computation
alu_test_devmem -c 25 5 0  # 25 + 5

# Benchmark
alu_test_devmem -b
```

## Troubleshooting

### Driver Not Loading
```bash
# Check kernel messages
dmesg | grep alu

# Manually load driver
modprobe alu-driver

# Check device tree
cat /proc/device-tree/amba/alu@43c00000/compatible
```

### Device Not Found
```bash
# Check memory mapping
cat /proc/iomem | grep 43c00000

# Try direct register access
devmem 0x43C00000 32
devmem 0x43C00004 32
devmem 0x43C00008 32
devmem 0x43C0000C 32
```

### Permission Denied
```bash
# For /dev/mem access
sudo chmod 666 /dev/mem

# Or run as root
sudo alu_test_devmem -t
```

## Additional Resources

### Register Map Summary
```
0x43C00000: OPERAND_A register (bits [7:0])
0x43C00004: OPERAND_B register (bits [7:0])
0x43C00008: CONTROL register (bits [2:0] opcode, bit [3] enable)
0x43C0000C: RESULT register (bits [15:0], read-only)
```

### Operation Codes
```
0: Addition       (a + b)
1: Subtraction    (a - b)
2: Multiplication (a * b)
3: Division       (a / b)
4: Modulo         (a % b)
5: Equal          (a == b)
6: Greater than   (a > b)
7: Less than      (a < b)
```

### Useful Commands
```bash
# Read all registers
for i in 0 4 8 C; do devmem 0x43C000$i 32; done

# Write to operand A
devmem 0x43C00000 32 0x000000FF

# Write to operand B
devmem 0x43C00004 32 0x00000010

# Set operation (0=ADD) and enable
devmem 0x43C00008 32 0x00000008

# Read result
devmem 0x43C0000C 32
```

## Notes
- Make sure Vivado and PetaLinux versions match
- Build times can be long - have patience
- Keep SD card backup after successful boot
- For updates, only rebuild changed components

## Contact
Engineer: 나무
Date: 2025-11-12
