# Build directory, where output ends up
BUILD ?= build

# What config to build
CONFIG ?= config/cantina

# What flavour of the config to build
FLAVOUR ?= protectli-1

# Name of the ST image to build
STIMAGE_NAME ?= protecli-1

# Basename of the kernel, kernel cmdline and initramfs files
BINDIST ?= debian-bookworm-amd64

# URL to download image from
NETBOOT_URL ?= http://10.10.10.1:80/$(STIMAGE_NAME)

# Cert/key file pairs to sign the image with. Set to empty string to disable signing.
SIGN ?= $(KEYS)

# Set to ./contain in order to run mmdebstrap in a container
CONTAIN ?=

####################
STIMAGE = $(BUILD)/$(STIMAGE_NAME).zip
KERNEL = $(BUILD)/$(BINDIST).vmlinuz
CMDLINE = $(BUILD)/$(BINDIST).kcmdline
INITRAMFS = $(BUILD)/$(BINDIST).cpio.gz
CA = keys/rootcert.pem keys/rootkey.pem
KEYS = keys/cert.pem keys/key.pem
STBOOT_ISO = $(BUILD)/stboot.iso
STBOOT_UKI = $(BUILD)/stboot.uki

####################
all: stimage
stimage: $(STIMAGE)
kernel: $(KERNEL)
cmdline: $(CMDLINE)
initramfs: $(INITRAMFS)
stboot-iso stboot: $(STBOOT_ISO)
stboot-uki: $(STBOOT_UKI)
boot: boot-qemu
clean:
	$(CONTAIN) rm -rf $(BUILD)
distclean: clean
	-rm -rf $(KEYS) $(CA) $(GUEST_DATADIR)

.PHONY: all stimage kernel cmdline initramfs boot clean distclean
####################
$(STIMAGE): $(INITRAMFS) $(KERNEL) $(CMDLINE) $(SIGN)
	./build-stimage $@ $(NETBOOT_URL).zip $(KERNEL) $(CMDLINE) $(INITRAMFS) $(SIGN)

# NOTE: Kernel is copied from initramfs (kernel modules are not)
# NOTE: Avoid circular dependencies by not depending on initramfs even though it's needed
$(KERNEL):
	./build-kernel $(CONFIG) $(FLAVOUR) $@

$(CMDLINE):
	./build-kcmdline $(CONFIG) $(FLAVOUR) $@

$(INITRAMFS): $(CONFIG)/pkgs/000base.pkglist
	$(CONTAIN) ./build-initramfs $(CONFIG) $@ $(FLAVOUR)

$(STBOOT_ISO): keys/rootcert.pem
	./contrib/stboot/build-stboot $(NETBOOT_URL).json $< iso $@
$(STBOOT_UKI): keys/rootcert.pem
	./contrib/stboot/build-stboot $(NETBOOT_URL).json $< uki $@

####################
keys/rootcert.pem keys/rootkey.pem:
	(umask 0077 && mkdir -p keys)
	(cd keys && stmgr keygen certificate --isCA)

keys/cert.pem keys/key.pem:
	$(MAKE) keys/rootcert.pem
	(cd keys && stmgr keygen certificate --rootCert rootcert.pem --rootKey rootkey.pem)


