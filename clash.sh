#!/bin/bash
# 定义仓库信息
REPO=Fndroid/clash_for_windows_pkg
GITHUB_URL=https://raw.githubusercontent.com/ZBrettonYe/Scripts/main/Clash
# 需要处理的文件名
FILES=("main-chinese.txt" "renderer-chinese.txt" "RemoveUpdate.txt" "RemoveADS.txt")

install_curl() {
  # Detect package manager
  if [ "$PM" = "pacman" ]; then
    sudo pacman -S --needed curl
  else
    # Default install
    sudo $PM install -y curl
  fi

  # Check install
  if ! command -v curl >/dev/null; then
    echo -e "\e[31mCurl install failed. Please install manually.\e[0m"
    exit 1
  fi
}

install_7z() {
  # Detect package manager
  if [ "$PM" = "apt" ]; then
    sudo apt install -y p7zip-full
  elif [ "$PM" = "yum" ]; then
    sudo yum install -y p7zip p7zip-plugins
  elif [ "$PM" = "pacman" ]; then
    sudo pacman -S --needed p7zip
  else
    # Default install
    sudo $PM install -y p7zip
  fi

  # Check install
  if ! command -v 7z >/dev/null; then
    echo -e "\e[31m7z install failed. Please install manually.\e[0m"
    exit 1
  fi
}

install_python() {
  # Detect package manager
  if [ "$PM" = "pacman" ]; then
    sudo pacman -S --needed python
  else
    # Default install
    sudo $PM install -y python3
  fi

  # Check install
  if ! command -v python3 >/dev/null; then
    echo -e "\e[31mPython install failed. Please install manually.\e[0m"
    exit 1
  fi
}

install_gh() {
  # Detect package manager
  if [ "$PM" = "apt" ]; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt update
    sudo apt install gh
  elif [ "$PM" = "yum" ]; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /etc/pki/rpm-gpg/RPM-GPG-KEY-githubcli-archive
    echo "[githubcli]
name=GitHub CLI
baseurl=https://cli.github.com/packages/rpm/stable
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-githubcli-archive
enabled=1" | sudo tee /etc/yum.repos.d/github-cli.repo
    sudo yum install gh
  elif [ "$PM" = "pacman" ]; then
    sudo pacman -S gh
  elif [ "$PM" = "zypper " ]; then
    sudo zypper install gh
  fi

  # Check install
  if ! command -v gh >/dev/null; then
    echo -e "\e[31mgh install failed. Please install manually.\e[0m"
    exit 1
  fi
}

install_nodejs() {
  # Detect package manager
  if [ "$PM" = "yum" ]; then
    curl -sL https://rpm.nodesource.com/setup_lts.x | sudo bash -
    sudo yum install -y nodejs
  elif [ "$PM" = "apt" ]; then
    sudo apt install -y nodejs npm
  elif [ "$PM" = "pacman" ]; then
    sudo pacman -S --needed nodejs npm
  elif [ "$PM" = "zypper" ]; then
    sudo zypper install -y nodejs8 npm
  else
    # Default install
    curl -sL https://deb.nodesource.com/setup_lts.x | sudo bash -
    sudo apt install -y nodejs
  fi

  # Check install
  if ! command -v node >/dev/null; then
    echo -e "\e[31mNodeJS install failed. Please install manually.\e[0m"
    exit 1
  fi
}

# 安装所需程序
install_dependencies() {
  # Detect package manager
  if [ -f /etc/redhat-release ]; then
    # RHEL/CentOS
    PM=yum
  elif [ -f /etc/debian_version ]; then
    # Debian/Ubuntu
    PM=apt
  elif [ -f /etc/arch-release ]; then
    # Arch Linux
    PM=pacman
  elif [ -f /etc/SuSE-release ]; then
    # OpenSUSE
    PM=zypper
  fi

  # Required tools
  if ! command -v 7z >/dev/null; then
    install_7z
  fi

  if ! command -v python3 >/dev/null; then
    install_python
  fi

  if ! command -v curl >/dev/null; then
    install_curl
  fi

  if ! command -v node >/dev/null; then
    install_nodejs
  fi

  if ! command -v gh >/dev/null; then
    install_gh
  fi

  if ! command -v asar >/dev/null; then
    sudo /usr/bin/npm install -g @electron/asar
  fi
}

download_file() {
  url=$1
  name=$2
  curl -fsSL $url -o ./Clash/$name || {
    echo -e "\e[31m下载 $name 失败\e[0m"
    exit 1
  }
  echo -e "\e[32m下载 $name 成功\e[0m"
}

handle_file() {
  name=$1
  # 下载规则文件
  if [ ! -f ./Clash/$name ]; then
    download_file "$GITHUB_URL/$name" $name
  fi

  # 判断处理哪个文件
  if [ "$name" = "main-chinese.txt" ]; then
    path="./appasar/dist/electron/main.js"
  else
    path="./appasar/dist/electron/renderer.js"
  fi

  # 处理文件
  curl -fsSL https://raw.githubusercontent.com/ZBrettonYe/Scripts/main/Clash/replace.py -o ./Clash/replace.py
  if [ ! -f ./Clash/replace.py ]; then
    download_file "$GITHUB_URL/replace.py" ./Clash/replace.py
  else
    echo -e "\e[32m处理 $name\e[0m"
    python3 ./Clash/replace.py $path ./Clash/$name
  fi
}

get_latest_version() {
  #获取最新版本号
  LATEST_TAG=$(curl -s https://api.github.com/repos/$REPO/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  # 添加参数校验
  if [ -z "$LATEST_TAG" ]; then
    echo -e "\e[31m处理 获取版本失败\e[0m"
    exit 1
  fi
  #构造固定文件名
  FILENAME="Clash.for.Windows-$LATEST_TAG-win.7z"
}

download_latest_release() {
  # 检查本地文件
  if [ -f Clash.for.Windows-*.7z ]; then
    # 获取本地版本号
    LOCAL_VERSION=$(find Clash.for.Windows-*.7z | sed -E 's/.*-([0-9.]+)-.*/\1/')
    # 对比版本号
    if [ "$LATEST_TAG" = "$LOCAL_VERSION" ]; then
      echo -e "\e[32m本地文件已是最新版本 $LATEST_TAG\e[0m"
      return
    else
      #下载最新文件
      echo -e "\e[32m本地版本: $LOCAL_VERSION | 最新版本: $LATEST_TAG\e[0m"
    fi
  fi

  curl -L -S https://github.com/$REPO/releases/download/$LATEST_TAG/$FILENAME -o $FILENAME
}

unpack_files() {
  #解压文件
  7z x $FILENAME -oclash
  #解压app.asar
  extract_app_asar
}

pack_files() {
  #重新压缩app.asar
  repack_app_asar
  #重新压缩最终文件
  7z u -m0=lzma2 -mx=9 $FILENAME ./clash/*
}

clean() {
  rm -rf ./appasar ./clash
}

release_github() {
  git tag $LATEST_TAG
  git push origin $LATEST_TAG
  #gh release create $LATEST_TAG -F release-note.md
  gh release create $LATEST_TAG
  gh release upload $LATEST_TAG ./clash/resources/app.asar
  gh release upload $LATEST_TAG ./FILENAME
}

# 解压app.asar函数
extract_app_asar() {
  asar extract ./clash/resources/app.asar ./appasar
}

# 重新打包app.asar函数
repack_app_asar() {
  asar pack ./appasar ./clash/resources/app.asar
}

# 主函数
main() {
  install_dependencies
  get_latest_version
  download_latest_release
  unpack_files
  mkdir -p ./Clash
  for file in ${FILES[@]}; do
    handle_file $file
  done
  pack_files
  release_github
  clean
  echo -e "\e[32m完成任务\e[0m"
}

main
