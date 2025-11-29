#!/usr/bin/env bash
#
# eve-config-download.sh - EVE-NG 配置文件一键下载与配置脚本
# 版本：v0.1
#

VERSION="v0.1"

#========================#
#      全局常量定义      #
#========================#

# 目录定义
ICONS_DIR="/opt/unetlab/html/images/icons"
SCRIPTS_DIR="/opt/unetlab/config_scripts"
AMD_YML_DIR="/opt/unetlab/html/templates/amd"
INTEL_YML_DIR="/opt/unetlab/html/templates/intel"
QEMU_DIR="/opt/unetlab/addons/qemu"
BACKUP_ROOT="/opt/unetlab/config-back"
TMP_DIR="./ecd"

#------------------------#
# 配置文件下载源 URL
#------------------------#

# hi168 源（配置文件）
HI168_ICONS_URL="https://s3.hi168.com/hi168-18902-7015cman/unetlab/icons.tgz"
HI168_SCRIPTS_URL="https://s3.hi168.com/hi168-18902-7015cman/unetlab/scripts.tgz"
HI168_AMD_URL="https://s3.hi168.com/hi168-18902-7015cman/unetlab/amd.tgz"
HI168_INTEL_URL="https://s3.hi168.com/hi168-18902-7015cman/unetlab/intel.tgz"

# 微软源（配置文件，SharePoint 下载直链）
MS_ICONS_URL="https://jen5-my.sharepoint.com/personal/cingsyuan_jen5_onmicrosoft_com/_layouts/52/download.aspx?share=IQCwcmiQJVt0TLsY-uyhBHulAWGBxsE6Tuj6c8-l1nwFGnM"
MS_SCRIPTS_URL="https://jen5-my.sharepoint.com/personal/cingsyuan_jen5_onmicrosoft_com/_layouts/52/download.aspx?share=IQDq6Y8ztXR-QZD9QXkpvJvoAbsB5sfDxpsMnmxotzZ9r9c"
MS_AMD_URL="https://jen5-my.sharepoint.com/personal/cingsyuan_jen5_onmicrosoft_com/_layouts/52/download.aspx?share=IQAUXZOskSYwR6YyyIpB-lckAVhELmKBTRjL7ZzngNroD6I"
MS_INTEL_URL="https://jen5-my.sharepoint.com/personal/cingsyuan_jen5_onmicrosoft_com/_layouts/52/download.aspx?share=IQDE8Te_V_vvRJ_xdY90zNBhAWeSChYcuXoDt7rgLtT8StY"

#------------------------#
# 锐捷设备镜像下载源 URL
#------------------------#

# hi168 源（锐捷）
HI168_RUIJIE_FIREWALL_URL="https://s3.hi168.com/hi168-18902-7015cman/Ruijie/Ruijiefirewall-V1.03.tgz"
HI168_RUIJIE_ROUTE_URL="https://s3.hi168.com/hi168-18902-7015cman/Ruijie/Ruijieroute-V1.06.tgz"
HI168_RUIJIE_SWITCH_URL="https://s3.hi168.com/hi168-18902-7015cman/Ruijie/Ruijieswitch-V1.06.tgz"

# 微软源（锐捷）
MS_RUIJIE_FIREWALL_URL="https://jen5-my.sharepoint.com/personal/cingsyuan_jen5_onmicrosoft_com/_layouts/52/download.aspx?share=IQD2SISODSVlRpZjTi6-NHCCAR8QEV0DXPYSJcJCJaB2ijk"
MS_RUIJIE_ROUTE_URL="https://jen5-my.sharepoint.com/personal/cingsyuan_jen5_onmicrosoft_com/_layouts/52/download.aspx?share=IQC8yrMf7ZE9QZpV7nl0dPdIAUEc63cZHAYOIneyK4L4Q0E"
MS_RUIJIE_SWITCH_URL="https://jen5-my.sharepoint.com/personal/cingsyuan_jen5_onmicrosoft_com/_layouts/52/download.aspx?share=IQCpu5lWECGkQ6WI3H11XVnPAaxinW7pqsH-DwHJYcYdyGU"

# 当前使用的下载源（默认 hi168）
CURRENT_SOURCE="hi168"

# 配置文件当前源 URL（根据源切换）
ICONS_URL="$HI168_ICONS_URL"
SCRIPTS_URL="$HI168_SCRIPTS_URL"
AMD_URL="$HI168_AMD_URL"
INTEL_URL="$HI168_INTEL_URL"

# 锐捷当前源 URL（根据源切换）
RUIJIE_FIREWALL_URL="$HI168_RUIJIE_FIREWALL_URL"
RUIJIE_ROUTE_URL="$HI168_RUIJIE_ROUTE_URL"
RUIJIE_SWITCH_URL="$HI168_RUIJIE_SWITCH_URL"

# 系统信息全局变量
SYSTEM_OS="未知"
SYSTEM_CPU="未知"
SYSTEM_ARCH="未知"

#========================#
#      基础函数模块      #
#========================#

print_disclaimer() {
    cat <<EOF
============================================================
 eve-config-download ${VERSION}
============================================================
本项目及其源代码遵循 GPLv3 许可协议：
 - 允许修改与分发，但必须保留原项目的版权与许可声明；
 - 修改后的项目必须继续使用相同的开源协议；
 - 禁止未经授权的商业使用；
 - 需保留署名与来源；
 - 本项目仅供学习与研究使用，作者不对使用本项目产生的任何
   直接或间接后果承担责任；
 - 生产环境用户与EVE-NG Pro用户，请务必进行充分审计、测试以及评估后再部署。；
------------------------------------------------------------
本脚本使用 hi168 / Microsoft SharePoint 为配置文件与镜像存储源，
本项目为面向ChatGPT开发，石山勿Q。
项目地址 https://github.com/ChengCingSyuan/EVE-Config-Shell
============================================================

EOF
    read -rp "已阅读并同意以上声明，请按回车继续（Ctrl+C 退出）..."
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "[-] 本脚本需要 root 权限运行，请使用 sudo 或以 root 运行。"
        exit 1
    fi
}

# 配置文件所需：wget + tar
check_requirements() {
    local missing=()

    command -v wget >/dev/null 2>&1 || missing+=("wget")
    command -v tar  >/dev/null 2>&1 || missing+=("tar")

    if ((${#missing[@]} > 0)); then
        echo "[-] 检测到以下组件缺失：${missing[*]}"
        echo "    请在主菜单执行 1) 安装必要组件 后再重试当前操作。"
        return 1
    fi

    return 0
}

# 锐捷镜像所需：aria2c + tar
check_requirements_ruijie() {
    local missing=()

    command -v aria2c >/dev/null 2>&1 || missing+=("aria2")
    command -v tar    >/dev/null 2>&1 || missing+=("tar")

    if ((${#missing[@]} > 0)); then
        echo "[-] 安装锐捷镜像需要以下组件：${missing[*]}"
        echo "    请在主菜单执行 1) 安装必要组件 后再重试当前操作。"
        return 1
    fi

    return 0
}

check_directories() {
    local missing=0

    for d in "$ICONS_DIR" "$SCRIPTS_DIR" "$AMD_YML_DIR" "$INTEL_YML_DIR" "$QEMU_DIR"; do
        if [[ ! -d "$d" ]]; then
            echo "[-] 缺少目录：$d"
            missing=1
        fi
    done

    if [[ $missing -ne 0 ]]; then
        echo
        echo "[-] 检测到 EVE-NG 目录结构不完整，可能未正确安装 EVE-NG。"
        echo "    请确认 EVE-NG 已正确安装后，再运行本脚本。"
        exit 1
    fi
}

#------------------------#
# 系统信息检测（菜单展示）
#------------------------#
update_system_info() {
    # OS
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        SYSTEM_OS="${PRETTY_NAME:-${NAME:-未知}}"
    else
        SYSTEM_OS="$(uname -s) $(uname -r)"
    fi

    # CPU
    SYSTEM_CPU="未知"
    if command -v lscpu >/dev/null 2>&1; then
        SYSTEM_CPU=$(lscpu | awk -F: '/Model name|型号名称/ {gsub(/^[ \t]+/, "", $2); print $2; exit}')
    fi
    if [[ -z "$SYSTEM_CPU" && -r /proc/cpuinfo ]]; then
        SYSTEM_CPU=$(grep -m1 -E 'model name|Hardware|Processor' /proc/cpuinfo | cut -d: -f2- | sed 's/^[ \t]*//')
    fi
    [[ -z "$SYSTEM_CPU" ]] && SYSTEM_CPU="Unknown CPU"

    # 架构
    SYSTEM_ARCH="$(uname -m 2>/dev/null || echo unknown)"
}

#========================#
#   APT & 组件安装模块   #
#========================#

backup_sources_list_once() {
    if [[ ! -f /etc/apt/sources.list.bak_eve_config ]]; then
        cp /etc/apt/sources.list /etc/apt/sources.list.bak_eve_config 2>/dev/null || true
        echo "[*] 已备份原 APT 源到 /etc/apt/sources.list.bak_eve_config"
    fi
}

check_is_ubuntu_jammy_or_confirm() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        if [[ "${VERSION_ID}" != "22.04" && "${VERSION_CODENAME}" != "jammy" ]]; then
            echo "[!] 检测到当前系统并非 Ubuntu 22.04 (jammy)，该操作可能不适用。"
            read -rp "[?] 仍然要覆盖 /etc/apt/sources.list 吗？[y/N]: " force
            force=${force:-N}
            if [[ ! "$force" =~ ^[Yy]$ ]]; then
                echo "[*] 已取消 sources.list 修改。"
                return 1
            fi
        fi
    fi
    return 0
}

# 1：安装必要组件
install_necessary_components() {
    echo
    echo "============================================================"
    echo "  1 - 安装必要组件（vim sudo curl wget aria2 tar 等）"
    echo "============================================================"

    echo "[*] 正在执行 apt update ..."
    apt update

    echo "[*] 正在安装组件：ca-certificates vim sudo curl wget aria2 tar openssh-server gnupg"
    apt install -y ca-certificates vim sudo curl wget aria2 tar openssh-server gnupg

    echo "[+] 必要组件安装完成。"
}

# 2：切换为 Ubuntu22 官方默认源
switch_sources_official() {
    echo
    echo "============================================================"
    echo "  2 - 切换为 Ubuntu 22 官方默认源"
    echo "============================================================"

    if ! check_is_ubuntu_jammy_or_confirm; then
        return 0
    fi

    backup_sources_list_once

    cat >/etc/apt/sources.list <<'EOF'
# Ubuntu 22.04 官方默认源（main / restricted / universe / multiverse）

deb http://archive.ubuntu.com/ubuntu jammy main restricted
# deb-src http://archive.ubuntu.com/ubuntu jammy main restricted

## Major bug fix updates produced after the final release of the distribution.
deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted
# deb-src http://archive.ubuntu.com/ubuntu jammy-updates main restricted

## Universe
deb http://archive.ubuntu.com/ubuntu jammy universe
# deb-src http://archive.ubuntu.com/ubuntu jammy universe
deb http://archive.ubuntu.com/ubuntu jammy-updates universe
# deb-src http://archive.ubuntu.com/ubuntu jammy-updates universe

## Multiverse
deb http://archive.ubuntu.com/ubuntu jammy multiverse
# deb-src http://archive.ubuntu.com/ubuntu jammy multiverse
deb http://archive.ubuntu.com/ubuntu jammy-updates multiverse
# deb-src http://archive.ubuntu.com/ubuntu jammy-updates multiverse

## Backports
deb http://archive.ubuntu.com/ubuntu jammy-backports main restricted universe multiverse
# deb-src http://archive.ubuntu.com/ubuntu jammy-backports main restricted universe multiverse

## Security
deb http://security.ubuntu.com/ubuntu jammy-security main restricted
# deb-src http://security.ubuntu.com/ubuntu jammy-security main restricted
deb http://security.ubuntu.com/ubuntu jammy-security universe
# deb-src http://security.ubuntu.com/ubuntu jammy-security universe
deb http://security.ubuntu.com/ubuntu jammy-security multiverse
# deb-src http://security.ubuntu.com/ubuntu jammy-security multiverse
EOF

    echo "[*] 已写入 Ubuntu 官方源，正在执行 apt update ..."
    apt update
    echo "[+] 已切换为 Ubuntu 官方源。"
}

# 3：切换为 Ubuntu22 阿里云源
switch_sources_aliyun() {
    echo
    echo "============================================================"
    echo "  3 - 切换为 Ubuntu 22 阿里云源"
    echo "============================================================"

    if ! check_is_ubuntu_jammy_or_confirm; then
        return 0
    fi

    backup_sources_list_once

    cat >/etc/apt/sources.list <<'EOF'
deb https://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse

# deb https://mirrors.aliyun.com/ubuntu/ jammy-proposed main restricted universe multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ jammy-proposed main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
EOF

    echo "[*] 已写入阿里云源，正在执行 apt update ..."
    apt update
    echo "[+] 已切换为阿里云源。"
}

# 4：切换为 Ubuntu22 清华源
switch_sources_tsinghua() {
    echo
    echo "============================================================"
    echo "  4 - 切换为 Ubuntu 22 清华源"
    echo "============================================================"

    if ! check_is_ubuntu_jammy_or_confirm; then
        return 0
    fi

    backup_sources_list_once

    cat >/etc/apt/sources.list <<'EOF'
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
# deb-src http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-proposed main restricted universe multiverse
# # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-proposed main restricted universe multiverse
EOF

    echo "[*] 已写入清华源，正在执行 apt update ..."
    apt update
    echo "[+] 已切换为清华源。"
}

# 5：切换为 Ubuntu22 腾讯源
switch_sources_tencent() {
    echo
    echo "============================================================"
    echo "  5 - 切换为 Ubuntu 22 腾讯源"
    echo "============================================================"

    if ! check_is_ubuntu_jammy_or_confirm; then
        return 0
    fi

    backup_sources_list_once

    cat >/etc/apt/sources.list <<'EOF'
deb http://mirrors.tencent.com/ubuntu/ jammy main restricted universe multiverse
deb http://mirrors.tencent.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://mirrors.tencent.com/ubuntu/ jammy-updates main restricted universe multiverse
#deb http://mirrors.tencent.com/ubuntu/ jammy-proposed main restricted universe multiverse
#deb http://mirrors.tencent.com/ubuntu/ jammy-backports main restricted universe multiverse
deb-src http://mirrors.tencent.com/ubuntu/ jammy main restricted universe multiverse
deb-src http://mirrors.tencent.com/ubuntu/ jammy-security main restricted universe multiverse
deb-src http://mirrors.tencent.com/ubuntu/ jammy-updates main restricted universe multiverse
#deb-src http://mirrors.tencent.com/ubuntu/ jammy-proposed main restricted universe multiverse
#deb-src http://mirrors.tencent.com/ubuntu/ jammy-backports main restricted universe multiverse
EOF

    echo "[*] 已写入腾讯源，正在执行 apt update ..."
    apt update
    echo "[+] 已切换为腾讯源。"
}

#========================#
#      源切换模块        #
#========================#

set_source_hi168() {
    CURRENT_SOURCE="hi168"
    # 配置文件
    ICONS_URL="$HI168_ICONS_URL"
    SCRIPTS_URL="$HI168_SCRIPTS_URL"
    AMD_URL="$HI168_AMD_URL"
    INTEL_URL="$HI168_INTEL_URL"
    # 锐捷镜像
    RUIJIE_FIREWALL_URL="$HI168_RUIJIE_FIREWALL_URL"
    RUIJIE_ROUTE_URL="$HI168_RUIJIE_ROUTE_URL"
    RUIJIE_SWITCH_URL="$HI168_RUIJIE_SWITCH_URL"

    echo "[*] 已切换到 hi168 下载源。"
}

set_source_ms() {
    CURRENT_SOURCE="microsoft"
    # 配置文件
    ICONS_URL="$MS_ICONS_URL"
    SCRIPTS_URL="$MS_SCRIPTS_URL"
    AMD_URL="$MS_AMD_URL"
    INTEL_URL="$MS_INTEL_URL"
    # 锐捷镜像
    RUIJIE_FIREWALL_URL="$MS_RUIJIE_FIREWALL_URL"
    RUIJIE_ROUTE_URL="$MS_RUIJIE_ROUTE_URL"
    RUIJIE_SWITCH_URL="$MS_RUIJIE_SWITCH_URL"

    echo "[*] 已切换到 微软（SharePoint）下载源。"
    echo "    注意：SharePoint 链接可能需要额外验证，请确认当前环境可访问。"
}

#========================#
#     安装配置文件模块    #
#========================#

backup_or_clean() {
    echo
    read -rp "[?] 是否备份现有配置文件到 ${BACKUP_ROOT} ? [Y/n]: " ans
    ans=${ans:-Y}
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        local ts
        ts=$(date +"%Y%m%d-%H%M%S")
        local backup_dir="${BACKUP_ROOT}/${ts}"
        mkdir -p "$backup_dir"

        echo "[*] 正在备份（剪切）现有配置到：$backup_dir"

        # 把原目录整个 mv 到备份目录
        [[ -d "$ICONS_DIR" ]]   && mv "$ICONS_DIR"   "${backup_dir}/" 2>/dev/null || true
        [[ -d "$SCRIPTS_DIR" ]] && mv "$SCRIPTS_DIR" "${backup_dir}/" 2>/dev/null || true
        [[ -d "$AMD_YML_DIR" ]] && mv "$AMD_YML_DIR" "${backup_dir}/" 2>/dev/null || true
        [[ -d "$INTEL_YML_DIR" ]] && mv "$INTEL_YML_DIR" "${backup_dir}/" 2>/dev/null || true

        # 重新创建空目录，方便后续下载/解压
        mkdir -p "$ICONS_DIR" "$SCRIPTS_DIR" "$AMD_YML_DIR" "$INTEL_YML_DIR"

        echo "[+] 备份完成（已从原位置剪切），备份目录：$backup_dir"
    else
        echo "[*] 不备份现有配置，将清空相关目录内容。"
        rm -rf "${ICONS_DIR:?}/"* \
               "${SCRIPTS_DIR:?}/"* \
               "${AMD_YML_DIR:?}/"* \
               "${INTEL_YML_DIR:?}/"*
        echo "[+] 目录内容已清空。"
    fi
}

download_and_extract() {
    local url="$1"
    local outfile="$2"
    local subdir="$3"   # 解压后期望的子目录名称（如 icons / scripts / amd / intel）
    local target_dir="$4"

    echo
    echo "[*] 正在下载：$subdir.tgz"
    echo "    源：$url"

    rm -f "${TMP_DIR:?}/${outfile}"
    wget -q -O "${TMP_DIR}/${outfile}" "$url"
    if [[ $? -ne 0 ]]; then
        echo "[-] 下载失败：$url"
        return 1
    fi

    echo "[+] 下载完成：${TMP_DIR}/${outfile}"

    # 解压到临时目录下的一个独立子目录
    local unpack_dir="${TMP_DIR}/unpack_${subdir}"
    rm -rf "$unpack_dir"
    mkdir -p "$unpack_dir"

    tar -xzf "${TMP_DIR}/${outfile}" -C "$unpack_dir"
    if [[ $? -ne 0 ]]; then
        echo "[-] 解压失败：${TMP_DIR}/${outfile}"
        return 1
    fi

    # 尝试识别实际内容目录：
    local src_dir
    if [[ -d "${unpack_dir}/${subdir}" ]]; then
        src_dir="${unpack_dir}/${subdir}"
    else
        src_dir="${unpack_dir}"
    fi

    echo "[*] 正在将解压内容同步到：$target_dir"
    mkdir -p "$target_dir"
    cp -a "${src_dir}/." "$target_dir/"

    echo "[+] $subdir 配置已更新。"
    return 0
}

install_configs() {
    echo
    echo "============================================================"
    echo " 10 - 安装 / 更新 EVE-NG 配置文件"
    echo " 当前下载源：$CURRENT_SOURCE"
    echo "============================================================"

    if ! check_requirements; then
        return 1
    fi

    backup_or_clean

    echo
    echo "[*] 创建临时工作目录：$TMP_DIR"
    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    # 依次下载并解压
    download_and_extract "$ICONS_URL"   "icons.tgz"      "icons"  "$ICONS_DIR"    || { echo "[-] icons 处理失败。"; rm -rf "$TMP_DIR"; return 1; }
    download_and_extract "$SCRIPTS_URL" "scripts.tgz"    "scripts" "$SCRIPTS_DIR" || { echo "[-] config_scripts 处理失败。"; rm -rf "$TMP_DIR"; return 1; }
    download_and_extract "$AMD_URL"     "yml-amd.tgz"    "amd"    "$AMD_YML_DIR"  || { echo "[-] yml-amd 处理失败。"; rm -rf "$TMP_DIR"; return 1; }
    download_and_extract "$INTEL_URL"   "yml-intel.tgz"  "intel"  "$INTEL_YML_DIR"|| { echo "[-] yml-intel 处理失败。"; rm -rf "$TMP_DIR"; return 1; }

    echo
    echo "[*] 正在调整 config_scripts 权限为 755 ..."
    if [[ -d "$SCRIPTS_DIR" ]]; then
        find "$SCRIPTS_DIR" -type f -exec chmod 755 {} \;
    fi

    echo "[*] 清理临时目录：$TMP_DIR"
    rm -rf "$TMP_DIR"

    echo
    echo "[+] 配置文件安装 / 更新完成。"
}

#========================#
#      锐捷镜像模块      #
#========================#

# 通用：下载 + 解压 + 复制到 QEMU_DIR
download_and_install_image_qemu() {
    local label="$1"     # 说明文案，例如 "锐捷防火墙"
    local url="$2"
    local outfile="$3"   # 下载后文件名，如 Ruijiefirewall-V1.03.tgz

    echo
    echo "------------------------------------------------------------"
    echo "[*] 正在处理：${label}"
    echo "    源：$url"
    echo "    输出文件：${TMP_DIR}/${outfile}"
    echo "------------------------------------------------------------"

    rm -f "${TMP_DIR:?}/${outfile}"

    # 使用 aria2c 多线程下载
    aria2c -x 8 -s 8 -k 1M -d "$TMP_DIR" -o "$outfile" "$url"
    if [[ $? -ne 0 ]]; then
        echo "[-] 下载失败：${label} ($url)"
        return 1
    fi

    # 简单检查是否误下成 HTML
    if head -c 15 "${TMP_DIR}/${outfile}" | grep -qi "<!DOCTYPE html"; then
        echo "[-] 下载到的似乎是 HTML 页面（可能是登录/错误页），无法解压：${label}"
        echo "    请检查该 URL 是否需要登录或有权限限制。"
        head -n 5 "${TMP_DIR}/${outfile}"
        return 1
    fi

    local unpack_dir="${TMP_DIR}/unpack_${outfile}"
    rm -rf "$unpack_dir"
    mkdir -p "$unpack_dir"

    echo "[*] 正在解压：${TMP_DIR}/${outfile}"
    if ! tar -xzf "${TMP_DIR}/${outfile}" -C "$unpack_dir"; then
        echo "[-] 解压失败：${TMP_DIR}/${outfile}"
        return 1
    fi

    echo "[*] 正在复制内容到：${QEMU_DIR}"
    mkdir -p "$QEMU_DIR"
    cp -a "${unpack_dir}/." "${QEMU_DIR}/"

    echo "[+] ${label} 安装完成。"
    return 0
}

install_ruijie_images() {
    echo
    echo "============================================================"
    echo " 20 - 安装锐捷设备镜像"
    echo " 当前下载源：$CURRENT_SOURCE"
    echo " 安装目标目录：$QEMU_DIR"
    echo "============================================================"

    if ! check_requirements_ruijie; then
        return 1
    fi

    echo "[*] 将安装以下锐捷镜像："
    echo "    1) 锐捷防火墙   (Ruijiefirewall-V1.03.tgz)"
    echo "    2) 锐捷路由器   (Ruijieroute-V1.06.tgz)"
    echo "    3) 锐捷交换机   (Ruijieswitch-V1.06.tgz)"
    echo
    read -rp "[?] 是否全部安装以上三个镜像？[Y/n]: " ans
    ans=${ans:-Y}
    if [[ ! "$ans" =~ ^[Yy]$ ]]; then
        echo "[*] 已取消锐捷镜像安装。"
        return 0
    fi

    echo
    echo "[*] 创建临时工作目录：$TMP_DIR"
    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    # 依次处理三个镜像
    download_and_install_image_qemu "锐捷防火墙 (Ruijiefirewall-V1.03)" \
        "$RUIJIE_FIREWALL_URL" "Ruijiefirewall-V1.03.tgz" \
        || { echo "[-] 锐捷防火墙镜像安装失败。"; rm -rf "$TMP_DIR"; return 1; }

    download_and_install_image_qemu "锐捷路由器 (Ruijieroute-V1.06)" \
        "$RUIJIE_ROUTE_URL" "Ruijieroute-V1.06.tgz" \
        || { echo "[-] 锐捷路由器镜像安装失败。"; rm -rf "$TMP_DIR"; return 1; }

    download_and_install_image_qemu "锐捷交换机 (Ruijieswitch-V1.06)" \
        "$RUIJIE_SWITCH_URL" "Ruijieswitch-V1.06.tgz" \
        || { echo "[-] 锐捷交换机镜像安装失败。"; rm -rf "$TMP_DIR"; return 1; }

    echo
    echo "[*] 清理临时目录：$TMP_DIR"
    rm -rf "$TMP_DIR"

    echo
    echo "[+] 锐捷设备镜像全部安装完成。"
    echo "    建议执行菜单 11：修复权限（平台检测 + fixpermissions）。"
}

#========================#
#      修复权限模块      #
#========================#

fix_permissions() {
    echo
    echo "============================================================"
    echo " 11 - 修复 EVE-NG 权限与平台配置"
    echo "============================================================"

    echo "[*] 检测 CPU 平台信息（intel / amd）..."

    local cpu_line vendor

    cpu_line=$(dmesg | grep -i cpu | grep -i -e intel -e amd | head -n 1)
    if [[ -z "$cpu_line" ]]; then
        echo "[-] 无法从 dmesg 中检测到 CPU 信息，请手动检查。"
    else
        vendor=$(echo "$cpu_line" | grep -oiE 'intel|amd' | tr 'A-Z' 'a-z')
        echo "[*] 检测到 CPU 类型：$vendor"

        if [[ "$vendor" == "intel" || "$vendor" == "amd" ]]; then
            echo "$vendor" > /opt/unetlab/platform
            echo "[+] 已写入 /opt/unetlab/platform：$vendor"
        else
            echo "[-] 未识别的 CPU 厂商：$vendor，请手动编辑 /opt/unetlab/platform"
        fi
    fi

    echo
    echo "[*] 正在执行权限修复：/opt/unetlab/wrappers/unl_wrapper -a fixpermissions"
    /opt/unetlab/wrappers/unl_wrapper -a fixpermissions

    if [[ $? -eq 0 ]]; then
        echo "[+] 权限修复完成。"
    else
        echo "[-] 权限修复命令执行失败，请检查 EVE-NG 安装情况。"
    fi
}

#========================#
#      菜单与主循环      #
#========================#

print_menu() {
    update_system_info

    cat <<EOF

================== EVE-NG 配置下载工具 ==================
 当前版本：${VERSION}
 当前系统：${SYSTEM_OS}
 CPU：${SYSTEM_CPU}
 架构：${SYSTEM_ARCH}
 当前下载源：${CURRENT_SOURCE}
--------------------------------------------------------
  1  安装必要组件（vim / sudo / curl / wget / aria2 / tar 等）
  2  切换为 Ubuntu 22 官方默认源
  3  切换为 Ubuntu 22 阿里云源
  4  切换为 Ubuntu 22 清华源
  5  切换为 Ubuntu 22 腾讯源

  6  切换为 hi168 配置/镜像下载源
  7  切换为 微软（SharePoint）配置/镜像下载源

 10  安装 / 更新 配置文件
 11  修复权限（平台检测 + fixpermissions）

 20  安装锐捷设备镜像
 21  安装设备镜像（预留）
 22  安装设备镜像（预留）
 23  安装设备镜像（预留）

 00  更新本脚本（预留）
  0  退出脚本
========================================================
EOF
}

main_loop() {
    while true; do
        print_menu
        read -rp "请输入选项编号并回车: " choice
        case "$choice" in
            1)
                install_necessary_components
                ;;
            2)
                switch_sources_official
                ;;
            3)
                switch_sources_aliyun
                ;;
            4)
                switch_sources_tsinghua
                ;;
            5)
                switch_sources_tencent
                ;;
            6)
                set_source_hi168
                ;;
            7)
                set_source_ms
                ;;
            10)
                install_configs
                ;;
            11)
                fix_permissions
                ;;
            20)
                install_ruijie_images
                ;;
            21|22|23)
                echo "[*] 该功能预留，后续版本将实现其他设备镜像一键安装。"
                ;;
            00)
                echo "[*] 脚本自更新功能预留，后续版本将实现。"
                ;;
            0)
                echo "[*] 已退出脚本，再见。"
                exit 0
                ;;
            *)
                echo "[-] 无效选项，请重新输入。"
                ;;
        esac
    done
}

#========================#
#          主程序        #
#========================#

print_disclaimer
check_root
check_directories
set_source_hi168   # 默认使用 hi168 源

main_loop
