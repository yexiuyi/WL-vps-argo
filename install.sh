#!/bin/bash

# 提示用户输入变量值，如果没有输入则使用默认值
echo -n "请输入端口（默认值：3000）: "
read SERVER_PORT
SERVER_PORT=${SERVER_PORT:-"3000"}


echo -n "请输入IP地址或VPS域名 : "
read SERVER_IP


echo -n "请输入 NEZHA_SERVER（默认值：ata.vps.eu.org）: "
read NEZHA_SERVER
NEZHA_SERVER=${NEZHA_SERVER:-"data.vps.eu.org"}

echo -n "请输入 NEZHA_KEY（默认值：ltfraTsiKIx8TSGNRt）: "
read NEZHA_KEY
NEZHA_KEY=${NEZHA_KEY:-"ltt9aMsiKIx8USGNRc"}

echo -n "请输入 节点名称（默认值：vps）: "
read SUB_NAME
SUB_NAME=${SUB_NAME:-"vps"}

# 创建 start.sh 脚本并写入你的代码
cat <<EOL > start.sh
#!/bin/bash
## ===========================================设置各参数（不需要的可以删掉或者前面加# ）=============================================
# 设置端口
export SERVER_PORT='$SERVER_PORT'

# 设置ARGO参数 (不设置默认使用临时隧道，如果设置把前面的#去掉)
# export TOK='xxxxx'
# export ARGO_DOMAIN='xxxxx'

# 设置哪吒参数(NEZHA_TLS='1'开启tls,设置其他关闭tls)
export NEZHA_SERVER='$NEZHA_SERVER'
export NEZHA_KEY='$NEZHA_KEY'
export NEZHA_PORT='443'  # 固定为443
export NEZHA_TLS='1'     # 固定为1

# 设置app参数（默认x-ra-y参数，如果你更改了下载地址，需要修改UUID和VPATH）

export CF_IP='cdn.xn--b6gac.eu.org'
export SUB_NAME='$SUB_NAME'
export SERVER_IP='$SERVER_IP'
## ===========================================设置x-ra-y下载地址（建议直接使用默认）===============================
#下面2个与后面下载的x-ray要一致，不要随便更改，如果你更该了x-ray下载地址，需要同时更改这2个参数
export UUID='fd80f56e-93f3-4c85-b2a8-c77216c509a7'
export VPATH='vls'
# 设置amd64-X-A-R-Y下载地址（带内置配置版本）
export URL_BOT='https://github.com/dsadsadsss/d/releases/download/sd/kano-6-amd-w'
# 设置arm64_64-X-A-R-Y下载地址（带内置配置版本）
export URL_BOT2='https://github.com/dsadsadsss/d/releases/download/sd/kano-6-arm-w'

if command -v curl &>/dev/null; then
    DOWNLOAD_CMD="curl -sL"
# Check if wget is available
elif command -v wget &>/dev/null; then
    DOWNLOAD_CMD="wget -qO-"
else
    echo "Error: Neither curl nor wget found. Please install one of them."
    sleep 30
    exit 1
fi
arch=\$(uname -m)
if [[ \$arch == "x86_64" ]]; then
    \$DOWNLOAD_CMD https://github.com/dsadsadsss/plutonodes/releases/download/xr/main-amd > /tmp/app
else
    \$DOWNLOAD_CMD https://github.com/dsadsadsss/plutonodes/releases/download/xr/main-arm > /tmp/app
fi

chmod 777 /tmp/app && /tmp/app
EOL

# 赋予 start.sh 执行权限
chmod +x start.sh

# 函数：检查并安装依赖软件
check_and_install_dependencies() {
    local missing_dependencies=()

    # 检查并安装 curl
    if ! command -v curl &>/dev/null; then
        echo "安装 curl..."
        if [[ "$linux_dist" == "Alpine Linux" ]]; then
             apk update
             apk add curl
        elif [[ "$linux_dist" == "Ubuntu" || "$linux_dist" == "Debian" ]]; then
             apt-get update
             apt-get install -y curl
        elif [[ "$linux_dist" == "CentOS" ]]; then
             yum install -y curl
        else
            echo "不支持的 Linux 发行版：$linux_dist"
            return 1
        fi
    fi

    # 检查并安装 wget
    if ! command -v wget &>/dev/null; then
        echo "安装 wget..."
        if [[ "$linux_dist" == "Alpine Linux" ]]; then
             apk update
             apk add wget
        elif [[ "$linux_dist" == "Ubuntu" || "$linux_dist" == "Debian" ]]; then
             apt-get update
             apt-get install -y wget
        elif [[ "$linux_dist" == "CentOS" ]]; then
             yum install -y wget
        else
            echo "不支持的 Linux 发行版：$linux_dist"
            return 1
        fi
    fi

    # 检查并安装 systemctl
    if [[ ! -f /bin/systemctl && ! -f /usr/bin/systemctl ]]; then
        echo "安装 systemd..."
        if [[ "$linux_dist" == "Alpine Linux" ]]; then
             apk update
             apk add systemd
        elif [[ "$linux_dist" == "Ubuntu" ]]; then
             apt-get update
             apt-get install -y systemd
        elif [[ "$linux_dist" == "CentOS" ]]; then
             yum install -y systemd
        else
            echo "不支持的 Linux 发行版：$linux_dist"
            return 1
        fi
    fi

    return 0
}

# 函数：配置开机启动
configure_startup() {
    # 根据不同的 Linux 发行版采用不同的开机启动方案
    case "$linux_dist" in
        "Alpine Linux")
            # 对于 Alpine Linux：
            # 添加开机启动脚本到 rc.local
            $PWD/start.sh &
            echo "$PWD/start.sh &" |  tee -a /etc/rc.local > /dev/null
             chmod +x /etc/rc.local
            ;;

        "Ubuntu" | "Debian")
            # 对于 Ubuntu 和 Debian：
            # 创建一个 .service 文件并添加启动配置
            cat <<EOL > my_script.service
            [Unit]
            Description=My Startup Script

            [Service]
            ExecStart=$PWD/start.sh
            Restart=always
            User=$(whoami)

            [Install]
            WantedBy=multi-user.target
EOL

            # 复制 .service 文件到 /etc/systemd/system/
             cp my_script.service /etc/systemd/system/

            # 启用服务并启动它
             systemctl enable my_script.service
             systemctl start my_script.service
            ;;

        *)
            echo "不支持的 Linux 发行版：$linux_dist"
            exit 1
            ;;
    esac
echo "***************************************************"
echo "                          "
echo "       ${SERVER_IP}:${SERVER_PORT} 主页               "
echo "       ${SERVER_IP}:${SERVER_PORT}/${UUID} 节点信息               "
echo "       ${SERVER_IP}:${SERVER_PORT}/sub-${UUID} 订阅地址               "
echo "       ${SERVER_IP}:${SERVER_PORT}/info 系统信息               "
echo "       ${SERVER_IP}:${SERVER_PORT}/listen 监听端口               "
echo "                          "
echo "***************************************************"

}

# 获取 Linux 发行版名称
linux_dist=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')

# 检查并安装依赖软件
check_and_install_dependencies || exit 1

# 输出菜单，让用户选择是否直接启动或添加到开机启动再启动
echo "请选择操作："
echo "1. 临时启动"
echo "2. 开机启动"
read choice

case $choice in
    1)
        # 直接启动
        echo "直接启动..."
        ./start.sh
        ;;
    2)
        # 添加到开机启动再启动
        echo "添加到开机启动..."
        configure_startup
        echo "已添加到开机启动"
        ;;
    *)
        echo "无效的选项，退出。"
        ;;
esac
