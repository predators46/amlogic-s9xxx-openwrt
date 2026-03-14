#!/bin/bash
#================================================================================================
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of the OpenWrt Image Builder workflow
# https://github.com/ophub/amlogic-s9xxx-openwrt
#
# Description: Build OpenWrt firmware using the official Image Builder
# Copyright (C) 2021~ https://github.com/unifreq/openwrt_packit
# Copyright (C) 2021~ https://github.com/ophub/amlogic-s9xxx-openwrt
# Copyright (C) 2021~ https://downloads.openwrt.org/releases
# Copyright (C) 2023~ https://downloads.immortalwrt.org/releases
#
# Download from: https://downloads.openwrt.org/releases
#                https://downloads.immortalwrt.org/releases
#
# Documentation: https://openwrt.org/docs/guide-user/additional-software/imagebuilder
# Instructions:  Download the official OpenWrt Image Builder,
#                then use it to add packages, libraries, themes, apps, and i18n support.
#
# Command: ./config/imagebuilder/imagebuilder.sh <source:branch>
#          ./config/imagebuilder/imagebuilder.sh openwrt:24.10.4
#
#======================================== Functions list ========================================
#
# error_msg               : Output error message and abort
# download_imagebuilder   : Download and extract the OpenWrt Image Builder
# adjust_settings         : Adjust Image Builder .config settings
# custom_packages         : Download and add custom packages
# custom_config           : Load custom package configuration
# custom_files            : Add custom overlay files
# rebuild_firmware        : Build firmware using Image Builder
# custom_settings         : Apply post-build customizations
#
#================================ Set make environment variables ================================
#
# Set default parameters
make_path="${PWD}"
openwrt_dir="imagebuilder"
imagebuilder_path="${make_path}/${openwrt_dir}"
custom_files_path="${make_path}/config/imagebuilder/files"
custom_config_file="${make_path}/config/imagebuilder/config"
output_path="${make_path}/output"
tmp_path="${imagebuilder_path}/tmp"
unpack_path="${tmp_path}/unpacked_rootfs"

# Set default parameters
STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
WARNING="[\033[93m WARNING \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"
#
#================================================================================================

# Output error message and abort script execution
error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

# Downloading OpenWrt ImageBuilder
download_imagebuilder() {
    cd ${make_path}
    echo -e "${STEPS} Downloading OpenWrt ImageBuilder..."

    # Downloading imagebuilder files
    if [[ "${op_sourse}" == "immortalwrt" ]]; then
        download_url="immortalwrt.kyarucloud.moe"
    else
        download_url="downloads.openwrt.org"
    fi
    download_file="https://${download_url}/releases/${op_branch}/targets/armsr/armv8/${op_sourse}-imagebuilder-${op_branch}-armsr-armv8.Linux-x86_64.tar.zst"
    curl -fsSOL ${download_file}
    [[ "${?}" -eq "0" ]] || error_msg "Failed to download: [ ${download_file} ]"

    # Unzip and change the directory name
    rm *-imagebuilder-*.tar.zst
    wget https://github.com/predators46/amlogic-s9xxx-openwrt/releases/download/OpenWrt_imagebuilder_openwrt_24.10.5_2026.03/openwrt-imagebuilder-25.12.0-armsr-armv8.Linux-x86_64.tar.zst
    tar -I zstd -xvf *-imagebuilder-*.tar.zst -C . && sync && rm -f *-imagebuilder-*.tar.zst
    mv -f *-imagebuilder-* ${openwrt_dir}

    sync && sleep 3
    echo -e "${INFO} [ ${make_path} ] directory contents: \n$(ls -lh . 2>/dev/null)"
}

# Adjust related files in the ImageBuilder directory
adjust_settings() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Adjusting ImageBuilder .config settings..."

    # For .config file
    if [[ -s ".config" ]]; then
        # Root filesystem archives
        sed -i "s|CONFIG_TARGET_ROOTFS_CPIOGZ=.*|# CONFIG_TARGET_ROOTFS_CPIOGZ is not set|g" .config
        # Root filesystem images
        sed -i "s|CONFIG_TARGET_ROOTFS_EXT4FS=.*|# CONFIG_TARGET_ROOTFS_EXT4FS is not set|g" .config
        sed -i "s|CONFIG_TARGET_ROOTFS_SQUASHFS=.*|# CONFIG_TARGET_ROOTFS_SQUASHFS is not set|g" .config
        sed -i "s|CONFIG_TARGET_IMAGES_GZIP=.*|# CONFIG_TARGET_IMAGES_GZIP is not set|g" .config
    else
        echo -e "${INFO} [ ${imagebuilder_path} ] directory contents: \n$(ls -lh . 2>/dev/null)"
        error_msg "No .config file found in [ ${download_file} ]."
    fi

    # For other files
    # ......

    sync && sleep 3
    echo -e "${INFO} [ ${imagebuilder_path} ] directory contents: \n$(ls -lh . 2>/dev/null)"
}

# Add custom packages
# If there is a custom package or ipk you would prefer to use create a [ packages ] directory,
# If one does not exist and place your custom ipk within this directory.
custom_packages() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Adding custom packages..."

    # Create a [ packages ] directory
#    [[ -d "packages" ]] || mkdir packages
    
    wget https://github.com/firmwarecostum/mosdns/releases/download/hm/mosdns_ipk_ARMSR.zip
    unzip mosdns_ipk_ARMSR.zip && cp -r bin/packages/aarch64_generic/python/* packages/ && cp -r bin/packages/aarch64_generic/packages/* packages/ && cp -r bin/packages/aarch64_generic/base/* packages/ && cp -r bin/targets/armsr/armv8/packages/* packages/
    
    cd packages

    rm base-files-1693~f919e7899d.apk
    wget https://github.com/esaaprillia/packages/raw/refs/heads/25/base-files-1693~f919e7899d.apk
    wget https://github.com/esaaprillia/packages/raw/refs/heads/25/libgfortran-14.3.0-r5.apk
    wget https://github.com/esaaprillia/packages/raw/refs/heads/25/libgomp-14.3.0-r5.apk
    wget https://github.com/esaaprillia/packages/raw/refs/heads/25/libubox20260213-2026.02.13~1aa36ee7-r1.apk
    [[ "${?}" -eq "0" ]] || error_msg "[ packages ] download failed!"
    echo -e "${INFO} The [ packages ] is download successfully."

    # Download other luci-app-xxx
    # ......

    sync && sleep 3
    echo -e "${INFO} [ packages ] directory contents: \n$(ls -lh . 2>/dev/null)"
}

# Add custom packages, lib, theme, app and i18n, etc.
custom_config() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Loading custom package configuration..."

    config_list=""
    if [[ -s "${custom_config_file}" ]]; then
        config_list="$(sed -n 's/^CONFIG_PACKAGE_\(.*\)=y$/\1/p' "${custom_config_file}" | tr '\n' ' ')"
        echo -e "${INFO} Custom package list: \n$(echo "${config_list}" | tr ' ' '\n')"
    else
        echo -e "${INFO} No custom package configuration found."
    fi
}

# Add custom files
# The FILES variable allows custom configuration files to be included in images built with Image Builder.
# The [ files ] directory should be placed in the Image Builder root directory where you issue the make command.
custom_files() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Adding custom files..."

    if [[ -d "${custom_files_path}" ]]; then
        # Copy custom files
        [[ -d "files" ]] || mkdir -p files
        cp -rf ${custom_files_path}/* files

        sync && sleep 3
        echo -e "${INFO} [ files ] directory contents: \n$(ls -lh files/ 2>/dev/null)"
    else
        echo -e "${INFO} No custom files found."
    fi
}

# Rebuild OpenWrt firmware
rebuild_firmware() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Building OpenWrt firmware with Image Builder..."

    # Selecting default packages, lib, theme, app and i18n, etc.
    my_packages="\
        kmod-usb-core kmod-usb2 usb-modeswitch libusb-1.0 kmod-usb-net-cdc-ether \
        \
        kmod-usb-net-rndis kmod-usb-net-cdc-ncm kmod-usb-net-huawei-cdc-ncm kmod-usb-net-cdc-eem kmod-usb-net-cdc-ether kmod-usb-net-cdc-subset kmod-nls-base kmod-usb-core kmod-usb-net kmod-usb-net-cdc-ether kmod-usb2 \
        \
        openssh-sftp-server unzip \
        \
        zoneinfo-all zoneinfo-core \
        \
        luci \
        \
        dnsmasq-full \
        \
        python3-asyncio python3-codecs python3-ctypes python3-dbm python3-decimal python3-email python3-logging python3-lzma python3-multiprocessing python3-ncurses python3-openssl python3-pydoc python3-readline python3-sqlite3 python3-unittest python3-urllib python3-uuid python3-venv python3-webbrowser python3-xml \
        \
        python3-homeassistant \
        \
        -dnsmasq \
        \
        kmod-fs-vfat lsblk btrfs-progs uuidgen dosfstools tar fdisk \
        \
        ${config_list} \
        "

    # Rebuild firmware
    make image PROFILE="" PACKAGES="${my_packages}" FILES="files"
    
    cd bin/targets/*/*/
    
    sudo mkdir openwrt
    #wget https://github.com/predators46/hack/releases/download/18.06.4/openwrt-18.06.4-armvirt-64-default-rootfs.tar.gz
    sudo tar xvf openwrt-24.10.5-armsr-armv8-generic-rootfs.tar.gz -C openwrt
    
    sudo wget https://github.com/predators46/amlogic-s9xxx-openwrt/releases/download/OpenWrt_imagebuilder_openwrt_24.10.5_2026.02/openwrt_official_amlogic_s905x_k6.6.127_2026.02.28.img.gz
    sudo gunzip openwrt_official_amlogic_s905x_k6.6.127_2026.02.28.img.gz
    sudo mkdir armbian
    sudo losetup -P -f --show openwrt_official_amlogic_s905x_k6.6.127_2026.02.28.img
    sudo ls /dev/loop0*
    sudo mount /dev/loop0p2 armbian
    
    sudo rm -rf openwrt/lib/firmware
    sudo rm -rf openwrt/lib/modules
    
    sudo mv armbian/lib/modules openwrt/lib/
    sudo mv armbian/lib/firmware openwrt/lib/

    sudo sed -i '/kmodloader/i \\tulimit -n 51200\n' openwrt/etc/init.d/boot
    
    sudo rm -rf armbian/*
    sudo rm -rf armbian/.reserved
    sudo rm -rf armbian/.snapshots
    sudo mv openwrt/* armbian/
    sudo mkdir armbian/boot
    sudo sync
    sudo umount armbian
    sudo losetup -d /dev/loop0
    
    sudo xz --compress openwrt_official_amlogic_s905x_k6.6.127_2026.02.28.img

    sync && sleep 3
    echo -e "${INFO} [ ${openwrt_dir}/bin/targets/*/*/ ] directory contents: \n$(ls -lh bin/targets/*/*/ 2>/dev/null)"
    echo -e "${INFO} Firmware build completed successfully."
}

# Custom settings after rebuild
custom_settings() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Applying post-build customizations..."

    # Clean up temporary and output directories
    [[ -d "${tmp_path}" ]] && rm -rf "${tmp_path:?}"/* || mkdir -p "${tmp_path}"
    [[ -d "${output_path}" ]] && rm -rf "${output_path:?}"/* || mkdir -p "${output_path}"

    # Find the original *rootfs.tar.gz file
    original_archive="$(ls -1 bin/targets/*/*/*rootfs.tar.gz 2>/dev/null | head -n 1)"

    # Check if the original archive exists
    if [[ ! -f "${original_archive}" ]]; then
        error_msg "No rootfs.tar.gz archive found in build output."
    else
        echo -e "${INFO} Found rootfs archive: ${original_archive}"

        # Get the filename and path
        original_filename="$(basename "${original_archive}")"
        original_path="$(dirname "${original_archive}")"

        # Unpack the original archive
        echo -e "${INFO} Unpacking ${original_filename}..."
        mkdir -p "${unpack_path}"
        tar -xzpf "${original_archive}" -C "${unpack_path}"

        # Modify etc/openwrt_release
        release_file="${unpack_path}/etc/openwrt_release"
        if [[ -f "${release_file}" ]]; then
            echo -e "${INFO} Updating etc/openwrt_release..."
            {
                echo "DISTRIB_SOURCEREPO='github.com/${op_sourse}/${op_sourse}'"
                echo "DISTRIB_SOURCECODE='${op_sourse}'"
                echo "DISTRIB_SOURCEBRANCH='${op_branch}'"
            } >>"${release_file}"
        else
            error_msg "${release_file} not found."
        fi

        # Repack the modified root filesystem
        echo -e "${INFO} Repacking into ${original_filename}..."
        (cd "${unpack_path}" && tar -czpf "${tmp_path}/${original_filename}" ./)

        # Move the repacked archive to the output directory
        echo -e "${INFO} Moving modified rootfs to output directory..."
        mv -f "${tmp_path}/${original_filename}" "${output_path}/"
        # Copy the config file to the output directory
        cp -f .config "${output_path}/config" || true
        cp -f bin/targets/*/*/*img.xz "${output_path}" || true
    fi

    sync && sleep 3
    cd ${make_path}
    rm -rf "${imagebuilder_path}"
    echo -e "${INFO} [ ${output_path} ] directory contents: \n$(ls -lh ${output_path}/ 2>/dev/null)"
    echo -e "${INFO} Post-build customizations applied successfully."
}

# Show welcome message
echo -e "${STEPS} Welcome to the OpenWrt Image Builder."
[[ -x "${0}" ]] || error_msg "Please grant execution permission: [ chmod +x ${0} ]"
[[ -z "${1}" ]] && error_msg "Please specify the OpenWrt source and branch, e.g. [ ${0} openwrt:24.10.4 ]"
[[ "${1}" =~ ^[a-z]{3,}:[0-9]+ ]] || error_msg "Invalid parameter format. Expected <source:branch>, e.g. openwrt:24.10.4"
op_sourse="${1%:*}"
op_branch="${1#*:}"
echo -e "${INFO} Working directory: [ ${PWD} ]"
echo -e "${INFO} Source: [ ${op_sourse} ], Branch: [ ${op_branch} ]"
echo -e "${INFO} Server disk usage before build: \n$(df -hT ${make_path}) \n"
#
# Perform related operations
download_imagebuilder
adjust_settings
custom_packages
custom_config
custom_files
rebuild_firmware
custom_settings
#
# Show server end information
echo -e "${SUCCESS} OpenWrt Image Builder completed successfully."
echo -e "${INFO} Server disk usage after build: \n$(df -hT ${make_path}) \n"
