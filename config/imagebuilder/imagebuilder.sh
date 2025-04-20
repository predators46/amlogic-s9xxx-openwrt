#!/bin/bash
#================================================================================================
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of the make OpenWrt for Amlogic s9xxx tv box
# https://github.com/ophub/amlogic-s9xxx-openwrt
#
# Description: Build OpenWrt with Image Builder
# Copyright (C) 2021~ https://github.com/unifreq/openwrt_packit
# Copyright (C) 2021~ https://github.com/ophub/amlogic-s9xxx-openwrt
# Copyright (C) 2021~ https://downloads.openwrt.org/releases
# Copyright (C) 2023~ https://downloads.immortalwrt.org/releases
#
# Download from: https://downloads.openwrt.org/releases
#                https://downloads.immortalwrt.org/releases
#
# Documentation: https://openwrt.org/docs/guide-user/additional-software/imagebuilder
# Instructions:  Download OpenWrt firmware from the official OpenWrt,
#                Use Image Builder to add packages, lib, theme, app and i18n, etc.
#
# Command: ./config/imagebuilder/imagebuilder.sh <source:branch>
#          ./config/imagebuilder/imagebuilder.sh openwrt:21.02.3
#
#======================================== Functions list ========================================
#
# error_msg               : Output error message
# download_imagebuilder   : Downloading OpenWrt ImageBuilder
# adjust_settings         : Adjust related file settings
# custom_packages         : Add custom packages
# custom_config           : Add custom config
# custom_files            : Add custom files
# rebuild_firmware        : rebuild_firmware
#
#================================ Set make environment variables ================================
#
# Set default parameters
make_path="${PWD}"
openwrt_dir="imagebuilder"
imagebuilder_path="${make_path}/${openwrt_dir}"
custom_files_path="${make_path}/config/imagebuilder/files"
custom_config_file="${make_path}/config/imagebuilder/config"

# Set default parameters
STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
WARNING="[\033[93m WARNING \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"
#
#================================================================================================

# Encountered a serious error, abort the script execution
error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

# Downloading OpenWrt ImageBuilder
download_imagebuilder() {
    cd ${make_path}
    echo -e "${STEPS} Start downloading OpenWrt files..."

    # Determine the target system (Imagebuilder files naming has changed since 23.05.0)
    if [[ "${op_branch:0:2}" -ge "23" && "${op_branch:3:2}" -ge "05" ]]; then
        target_system="armsr/armv8"
        target_name="armsr-armv8"
        target_profile=""
    else
        target_system="armvirt/64"
        target_name="armvirt-64"
        target_profile="Default"
    fi

    # Downloading imagebuilder files
    download_file="https://downloads.${op_sourse}.org/releases/${op_branch}/targets/${target_system}/${op_sourse}-imagebuilder-${op_branch}-${target_name}.Linux-x86_64.tar.xz"
    curl -fsSOL ${download_file}
    [[ "${?}" -eq "0" ]] || error_msg "Download failed: [ ${download_file} ]"

    # Unzip and change the directory name
    tar -xf *-imagebuilder-* && sync && rm -f *-imagebuilder-*.tar.xz
    mv -f *-imagebuilder-* ${openwrt_dir}

    sync && sleep 3
    echo -e "${INFO} [ ${make_path} ] directory status: $(ls -al 2>/dev/null)"
}

# Adjust related files in the ImageBuilder directory
adjust_settings() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adjusting .config file settings..."

    # For .config file
    if [[ -s ".config" ]]; then
        # Root filesystem archives
        sed -i "s|CONFIG_TARGET_ROOTFS_CPIOGZ=.*|# CONFIG_TARGET_ROOTFS_CPIOGZ is not set|g" .config
        # Root filesystem images
        sed -i "s|CONFIG_TARGET_ROOTFS_EXT4FS=.*|# CONFIG_TARGET_ROOTFS_EXT4FS is not set|g" .config
        sed -i "s|CONFIG_TARGET_ROOTFS_SQUASHFS=.*|# CONFIG_TARGET_ROOTFS_SQUASHFS is not set|g" .config
        sed -i "s|CONFIG_TARGET_IMAGES_GZIP=.*|# CONFIG_TARGET_IMAGES_GZIP is not set|g" .config
    else
        echo -e "${INFO} [ ${imagebuilder_path} ] directory status: $(ls -al 2>/dev/null)"
        error_msg "There is no .config file in the [ ${download_file} ]"
    fi

    # For other files
    # ......

    sync && sleep 3
    echo -e "${INFO} [ ${imagebuilder_path} ] directory status: $(ls -al 2>/dev/null)"
}

# Add custom packages
# If there is a custom package or ipk you would prefer to use create a [ packages ] directory,
# If one does not exist and place your custom ipk within this directory.
custom_packages() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adding custom packages..."

    # Clone [ packages ] directory
    #rm -rf packages && git clone "https://github.com/esaaprillia/packages"
    #git clone "https://github.com/esaaprillia/package" && cp -r package/* packages/ && rm -rf package
    [[ "${?}" -eq "0" ]] || error_msg "[ packages ] clone failed!"
    echo -e "${INFO} The [ packages ] is clone successfully."

    # Download other luci-app-xxx
    # ......

    sync && sleep 3
    echo -e "${INFO} [ packages ] directory status: $(ls -al 2>/dev/null)"
}

# Add custom packages, lib, theme, app and i18n, etc.
custom_config() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adding custom config..."

    config_list=""
    if [[ -s "${custom_config_file}" ]]; then
        config_list="$(cat ${custom_config_file} 2>/dev/null | grep -E "^CONFIG_PACKAGE_.*=y" | sed -e 's/CONFIG_PACKAGE_//g' -e 's/=y//g' -e 's/[ ][ ]*//g' | tr '\n' ' ')"
        echo -e "${INFO} Custom config list: \n$(echo "${config_list}" | tr ' ' '\n')"
    else
        echo -e "${INFO} No custom config was added."
    fi
}

# Add custom files
# The FILES variable allows custom configuration files to be included in images built with Image Builder.
# The [ files ] directory should be placed in the Image Builder root directory where you issue the make command.
custom_files() {
    cd ${imagebuilder_path}
    #wget -O include/prereq-build.mk "https://raw.githubusercontent.com/esaaprillia/br/refs/heads/main/prereq-build.mk"
    echo -e "${STEPS} Start adding custom files..."

    if [[ -d "${custom_files_path}" ]]; then
        # Copy custom files
        [[ -d "files" ]] || mkdir -p files
        cp -rf ${custom_files_path}/* files

        sync && sleep 3
        echo -e "${INFO} [ files ] directory status: $(ls files -al 2>/dev/null)"
    else
        echo -e "${INFO} No customized files were added."
    fi
}

# Rebuild OpenWrt firmware
rebuild_firmware() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start building OpenWrt with Image Builder..."

    # Selecting default packages, lib, theme, app and i18n, etc.
    my_packages="\
        kmod-usb-core kmod-usb2 usb-modeswitch libusb-1.0 kmod-usb-net-cdc-ether \
        \
        kmod-usb-net-rndis kmod-usb-net-cdc-ncm kmod-usb-net-huawei-cdc-ncm kmod-usb-net-cdc-eem kmod-usb-net-cdc-ether kmod-usb-net-cdc-subset kmod-nls-base kmod-usb-core kmod-usb-net kmod-usb-net-cdc-ether kmod-usb2 \
        \
        luci \
        \
        kmod-fs-vfat lsblk btrfs-progs uuidgen dosfstools tar fdisk \
        \
        e2fsprogs fstools mkf2fs partx-utils \
        \
        openssh-sftp-server \
        \
        zoneinfo-asia zoneinfo-core \
        \
        dnsmasq-full \
        \
        -dnsmasq \
        \
        ${config_list} \
        "

    # Rebuild firmware
    make image PROFILE="${target_profile}" PACKAGES="${my_packages}" FILES="files"
    
    cd bin/targets/*/*/
    
    mkdir openwrt
    #wget https://github.com/predators46/hack/releases/download/18.06.4/openwrt-18.06.4-armvirt-64-default-rootfs.tar.gz
    tar xvf openwrt-21.02.7-armvirt-64-default-rootfs.tar.gz -C openwrt
    
    wget https://github.com/predators46/amlogic-s9xxx-openwrt/releases/download/OpenWrt_imagebuilder__2025.04/openwrt_amlogic_s905x_k5.4.292_2025.04.20.img.gz
    gunzip openwrt_amlogic_s905x_k5.4.292_2025.04.20.img.gz
    mkdir armbian
    sudo losetup -P -f --show openwrt_amlogic_s905x_k5.4.292_2025.04.20.img
    ls /dev/loop3*
    sudo mount /dev/loop3p2 armbian
    
    sudo rm -rf openwrt/lib/firmware
    sudo rm -rf openwrt/lib/modules
    
    sudo mv armbian/lib/modules openwrt/lib/
    sudo mv armbian/lib/firmware openwrt/lib/

    sudo sed -i '/kmodloader/i \\tulimit -n 51200\n' openwrt/etc/init.d/boot
    
    sudo rm -rf armbian/*
    sudo mv openwrt/* armbian/
    sudo mkdir armbian/boot
    sudo sync
    sudo umount armbian
    sudo losetup -d /dev/loop3
    
    xz --compress openwrt_amlogic_s905x_k5.4.292_2025.04.20.img
    
    cd ${imagebuilder_path}

    sync && sleep 3
    echo -e "${INFO} [ ${openwrt_dir}/bin/targets/*/* ] directory status: $(ls bin/targets/*/* -al 2>/dev/null)"
    echo -e "${SUCCESS} The rebuild is successful, the current path: [ ${PWD} ]"
}

# Show welcome message
echo -e "${STEPS} Welcome to Rebuild OpenWrt Using the Image Builder."
[[ -x "${0}" ]] || error_msg "Please give the script permission to run: [ chmod +x ${0} ]"
[[ -z "${1}" ]] && error_msg "Please specify the OpenWrt Branch, such as [ ${0} openwrt:22.03.3 ]"
[[ "${1}" =~ ^[a-z]{3,}:[0-9]+ ]] || error_msg "Incoming parameter format <source:branch>: openwrt:22.03.3"
op_sourse="${1%:*}"
op_branch="${1#*:}"
echo -e "${INFO} Rebuild path: [ ${PWD} ]"
echo -e "${INFO} Rebuild Source: [ ${op_sourse} ], Branch: [ ${op_branch} ]"
echo -e "${INFO} Server space usage before starting to compile: \n$(df -hT ${make_path}) \n"
#
# Perform related operations
download_imagebuilder
adjust_settings
custom_packages
custom_config
custom_files
rebuild_firmware
#
# Show server end information
echo -e "Server space usage after compilation: \n$(df -hT ${make_path}) \n"
# All process completed
wait
