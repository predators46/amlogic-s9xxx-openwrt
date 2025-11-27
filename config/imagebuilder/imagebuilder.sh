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
#          ./config/imagebuilder/imagebuilder.sh openwrt:24.10.4
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
# custom_settings         : Custom settings after rebuild
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

# Encountered a serious error, abort the script execution
error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

# Downloading OpenWrt ImageBuilder
download_imagebuilder() {
    cd ${make_path}
    echo -e "${STEPS} Start downloading OpenWrt files..."

    # Downloading imagebuilder files
    download_file="https://downloads.${op_sourse}.org/releases/${op_branch}/targets/armsr/armv8/${op_sourse}-imagebuilder-${op_branch}-armsr-armv8.Linux-x86_64.tar.zst"
    curl -fsSOL ${download_file}
    [[ "${?}" -eq "0" ]] || error_msg "Download failed: [ ${download_file} ]"

    # Unzip and change the directory name
    tar -I zstd -xvf *-imagebuilder-*.tar.zst -C . && sync && rm -f *-imagebuilder-*.tar.zst
    mv -f *-imagebuilder-* ${openwrt_dir}

    sync && sleep 3
    echo -e "${INFO} [ ${make_path} ] directory status: \n$(ls -lh . 2>/dev/null)"
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
        echo -e "${INFO} [ ${imagebuilder_path} ] directory status: \n$(ls -lh . 2>/dev/null)"
        error_msg "There is no .config file in the [ ${download_file} ]"
    fi

    # For other files
    # ......

    sync && sleep 3
    echo -e "${INFO} [ ${imagebuilder_path} ] directory status: \n$(ls -lh . 2>/dev/null)"
}

# Add custom packages
# If there is a custom package or ipk you would prefer to use create a [ packages ] directory,
# If one does not exist and place your custom ipk within this directory.
custom_packages() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adding custom packages..."

    # Download [ packages ] directory
    #rm -rf packages && git clone -b 24 "https://github.com/esaaprillia/packages"
    mkdir -p packages && wget https://github.com/firmwarecostum/mosdns/releases/download/909-1/mosdns_ipk_ARMSR.zip
    unzip mosdns_ipk_ARMSR.zip && cp -r bin/packages/aarch64_generic/python/* packages/ && rm -rf bin
    wget https://github.com/esaaprillia/packages/raw/refs/heads/ha/libgfortran_13.3.0-r4_aarch64_generic.ipk && cp -r libgfortran_13.3.0-r4_aarch64_generic.ipk packages/
    [[ "${?}" -eq "0" ]] || error_msg "[ packages ] download failed!"
    echo -e "${INFO} The [ packages ] is download successfully."

    # Download other luci-app-xxx
    # ......

    sync && sleep 3
    echo -e "${INFO} [ packages ] directory status: \n$(ls -lh . 2>/dev/null)"
}

# Add custom packages, lib, theme, app and i18n, etc.
custom_config() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adding custom config..."

    config_list=""
    if [[ -s "${custom_config_file}" ]]; then
        config_list="$(sed -n 's/^CONFIG_PACKAGE_\(.*\)=y$/\1/p' "${custom_config_file}" | tr '\n' ' ')"
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
    echo -e "${STEPS} Start adding custom files..."

    if [[ -d "${custom_files_path}" ]]; then
        # Copy custom files
        [[ -d "files" ]] || mkdir -p files
        cp -rf ${custom_files_path}/* files

        sync && sleep 3
        echo -e "${INFO} [ files ] directory status: \n$(ls -lh files/ 2>/dev/null)"
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
        openssh-sftp-server \
        \
        zoneinfo-all zoneinfo-core \
        \
        luci \
        \
        dnsmasq-full \
        \
        python3-asyncio python3-codecs python3-ctypes python3-dbm python3-decimal python3-email python3-logging python3-lzma python3-multiprocessing python3-ncurses python3-openssl python3-pydoc python3-readline python3-sqlite3 python3-unittest python3-urllib python3-uuid python3-venv python3-webbrowser python3-xml \
        \
        python3-homeassistant python3-aioesphomeapi python3-esphome-dashboard-api python3-bleak-esphome python3-zha python3-universal-silabs-flasher python3-pure-pcapy3 python3-radios python3-pymetno python3-gtts python3-text-to-speech python3-mutagen python3-sense-energy python3-restrictedpython python3-pyhaversion python3-aiodhcpwatcher python3-aiodiscover python3-aiodns python3-aiohasupervisor python3-aiohttp-asyncmdnsresolver python3-aiohttp-fast-zlib python3-aiohttp python3-aiohttp-cors python3-aiousbwatcher python3-aiozoneinfo python3-annotatedyaml python3-astral python3-async-interrupt python3-async-upnp-client python3-atomicwrites-homeassistant python3-attrs python3-audioop-lts python3-av python3-awesomeversion python3-bcrypt python3-bleak-retry-connector python3-bleak python3-bluetooth-adapters python3-bluetooth-auto-recovery python3-bluetooth-data-tools python3-cached-ipaddress python3-certifi python3-ciso8601 python3-cronsim python3-cryptography python3-dbus-fast python3-file-read-backwards python3-fnv-hash-fast python3-go2rtc-client python3-ha-ffmpeg python3-habluetooth python3-hass-nabucasa python3-hassil python3-home-assistant-bluetooth python3-home-assistant-frontend python3-home-assistant-intents python3-httpx python3-ifaddr python3-jinja2 python3-lru-dict python3-mutagen python3-orjson python3-packaging python3-paho-mqtt python3-pillow python3-propcache python3-psutil-home-assistant python3-pyjwt python3-pymicro-vad python3-pynacl python3-pyopenssl python3-pyserial python3-pyspeex-noise python3-slugify python3-pyturbojpeg python3-yaml python3-requests python3-securetar python3-sqlalchemy python3-standard-aifc python3-standard-telnetlib python3-typing-extensions python3-ulid-transform python3-urllib3 python3-uv python3-voluptuous-openapi python3-voluptuous-serialize python3-voluptuous python3-webrtc-models python3-yarl python3-zeroconf python3-cryptodome python3-httplib2 python3-grpcio python3-grpcio-status python3-grpcio-reflection python3-btlewrap python3-anyio python3-h11 python3-httpcore python3-hyperframe python3-numpy python3-pandas python3-multidict python3-backoff python3-pydantic python3-mashumaro python3-pubnub python3-iso4217 python3-protobuf python3-faust-cchardet python3-websockets python3-getmac python3-charset-normalizer python3-dacite python3-chacha20poly1305-reuseable python3-pycountry python3-scapy python3-tuf python3-tenacity python3-async-timeout python3-aiofiles python3-multidict python3-rpds-py python3-num2words python3-pymodbus python3-gql python3-pytest-rerunfailures \
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
    sudo tar xvf openwrt-24.10.4-armsr-armv8-generic-rootfs.tar.gz -C openwrt
    
    sudo wget https://github.com/predators46/amlogic-s9xxx-openwrt/releases/download/OpenWrt_imagebuilder_openwrt_24.10.4_2025.11/openwrt_official_amlogic_s905x_k6.6.117_2025.11.26.img.gz
    sudo gunzip openwrt_official_amlogic_s905x_k6.6.117_2025.11.26.img.gz
    sudo mkdir armbian
    sudo losetup -P -f --show openwrt_official_amlogic_s905x_k6.6.117_2025.11.26.img
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
    
    sudo xz --compress openwrt_official_amlogic_s905x_k6.6.117_2025.11.26.img

    sync && sleep 3
    echo -e "${INFO} [ ${openwrt_dir}/bin/targets/*/*/ ] directory status: \n$(ls -lh bin/targets/*/*/ 2>/dev/null)"
    echo -e "${INFO} The rebuild is successful."
}

# Custom settings after rebuild
custom_settings() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start performing custom settings after rebuild..."

    # Clean up temporary and output directories
    [[ -d "${tmp_path}" ]] && rm -rf "${tmp_path:?}"/* || mkdir -p "${tmp_path}"
    [[ -d "${output_path}" ]] && rm -rf "${output_path:?}"/* || mkdir -p "${output_path}"

    # Find the original *rootfs.tar.gz file
    original_archive="$(ls -1 bin/targets/*/*/*rootfs.tar.gz 2>/dev/null | head -n 1)"

    # Check if the original archive exists
    if [[ ! -f "${original_archive}" ]]; then
        error_msg "No *rootfs.tar.gz found."
    else
        echo -e "${INFO} Processing: ${original_archive}"

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
            echo -e "${INFO} Modifying etc/openwrt_release..."
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
        echo -e "${INFO} Moving repacked OpenWrt rootfs file to output directory..."
        mv -f "${tmp_path}/${original_filename}" "${output_path}/"
        # Copy the config file to the output directory
        cp -f .config "${output_path}/config" || true
        cp -f bin/targets/*/*/*img.xz "${output_path}" || true
    fi

    sync && sleep 3
    cd ${make_path}
    rm -rf "${imagebuilder_path}"
    echo -e "${INFO} [ ${output_path} ] directory status: \n$(ls -lh ${output_path}/ 2>/dev/null)"
    echo -e "${INFO} Modification successfully."
}

# Show welcome message
echo -e "${STEPS} Welcome to Rebuild OpenWrt Using the Image Builder."
[[ -x "${0}" ]] || error_msg "Please give the script permission to run: [ chmod +x ${0} ]"
[[ -z "${1}" ]] && error_msg "Please specify the OpenWrt Branch, such as [ ${0} openwrt:24.10.4 ]"
[[ "${1}" =~ ^[a-z]{3,}:[0-9]+ ]] || error_msg "Incoming parameter format <source:branch>: openwrt:24.10.4"
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
custom_settings
#
# Show server end information
echo -e "${SUCCESS} OpenWrt ImageBuilder processed successfully."
echo -e "${INFO} Server space usage after compilation: \n$(df -hT ${make_path}) \n"
