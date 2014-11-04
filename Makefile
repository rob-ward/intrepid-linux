# Copyright Rob Ward 2014

SHELL := /bin/dash

TOP_DIR := $(shell pwd)
SRC_DIR := $(TOP_DIR)/src
CONFIG_FILES_DIR := $(TOP_DIR)/config_files
OUTPUT_DIR := $(TOP_DIR)/output

HOST_DIR := $(OUTPUT_DIR)/host
BUILD_DIR := $(OUTPUT_DIR)/build
INSTALL_DIR := $(OUTPUT_DIR)/install
INITRAMFS_DIR := $(OUTPUT_DIR)/initramfs_install

LINUX_INITRAMFS_CONFIG := $(CONFIG_FILES_DIR)/initramfs_config_file

LINUX_SRC_DIR := $(SRC_DIR)/linux-stable
MICROINIT_SRC_DIR := $(SRC_DIR)/microinit
TOYBOX_SRC_DIR := $(SRC_DIR)/toybox

QUIET := @

default: linux microinit toybox

linux: microinit toybox
	$(QUIET)cd $(LINUX_SRC_DIR) && $(MAKE) x86_64_defconfig
	$(QUIET)cd $(LINUX_SRC_DIR) && $(MAKE) --jobs=4 modules
	$(QUIET)cd $(LINUX_SRC_DIR) && $(MAKE) --jobs=4 modules_install INSTALL_MOD_PATH=$(INITRAMFS_DIR)
	# Now setup the initramfs
	$(QUIET)sed -i s^CONFIG_INITRAMFS_SOURCE=\"\"^CONFIG_INITRAMFS_SOURCE=\"\"\\nCONFIG_INITRAMFS_ROOT_UID=\\nCONFIG_INITRAMFS_ROOT_GID=\\n^g $(LINUX_SRC_DIR)/.config
	$(QUIET)sed -i s^CONFIG_INITRAMFS_SOURCE=\"\"^CONFIG_INITRAMFS_SOURCE=\"$(LINUX_INITRAMFS_CONFIG)\ $(INITRAMFS_DIR)\"^g $(LINUX_SRC_DIR)/.config
	$(QUIET)sed -i s^CONFIG_INITRAMFS_ROOT_UID=^CONFIG_INITRAMFS_ROOT_UID=`id -u`^g $(LINUX_SRC_DIR)/.config
	$(QUIET)sed -i s^CONFIG_INITRAMFS_ROOT_GID=^CONFIG_INITRAMFS_ROOT_GID=`id -u`^g $(LINUX_SRC_DIR)/.config
	$(QUIET)cd $(LINUX_SRC_DIR) && $(MAKE) --jobs=4

microinit:
	$(QUIET) cd $(MICROINIT_SRC_DIR) && $(MAKE) --jobs=4 DESTDIR=$(INITRAMFS_DIR)/

toybox:
	$(QUIET)cd $(TOYBOX_SRC_DIR) && $(MAKE) defconfig
	$(QUIET)sed -i "s^# CONFIG_SH is not set^CONFIG_SH=y^" $(TOYBOX_SRC_DIR)/.config
	$(QUIET)cd $(TOYBOX_SRC_DIR) && $(MAKE) CFLAGS="--static" toybox --jobs=4
	$(QUIET)cd $(TOYBOX_SRC_DIR) && $(MAKE) install PREFIX=$(INITRAMFS_DIR)
