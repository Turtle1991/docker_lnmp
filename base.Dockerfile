FROM ubuntu:24.04
LABEL maintainer="Turtle"

# 设置环境变量，避免交互式安装时出现问题
ENV DEBIAN_FRONTEND=noninteractive

# 设置时区为上海（中国时区）并安装中文语言包和字体
# 安装需要的常用包
# 设置vim的配置
# 清理缓存，减小镜像体积
RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata language-pack-zh-hans fonts-wqy-microhei && \
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    update-locale LANG=zh_CN.UTF-8 && \
    apt-get install -y --no-install-recommends \
          telnet \
          vim \
          wget \
          lsof \
          unzip \
          jq \
          curl \
          iputils-ping \
    && printf "\" 显示行号\nset nu\n\" 语法高亮\nsyntax on\n\" Tab键宽度4\nset tabstop=4\n\" 注释的颜色 1红色 2墨绿 3黄色 4蓝(即默认的颜色) 5粉色 6淡蓝色 7白色\nhi comment ctermfg=6" > ~/.vimrc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 设置默认语言为中文
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8

# 安装编译工具
# build-essential 包含 make、gcc、g++ 等工具
# pkg-config 在编译安装的时候，有时候需要通过 PKG_CONFIG_PATH 指定配置
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        autoconf \
        automake \
        zlib1g \
        zlib1g-dev \
        libssl-dev \
        libpcre3-dev \
        pkg-config && \
    apt-get clean && rm -rf /var/lib/apt/lists/*