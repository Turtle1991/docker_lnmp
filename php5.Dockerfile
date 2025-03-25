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

# 安装PHP
COPY soft/bao/* /usr/local/src/
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-dev \
        libcurl4-openssl-dev \
        libxpm-dev \
        libfreetype6-dev \
        openssl \
        curl \
    && ln -s /usr/include/x86_64-linux-gnu/curl /usr/include/curl \
    && cd /usr/local/src \
    && tar -zxf libxml2-2.9.8.tar.gz \
    && cd libxml2-2.9.8 \
    && ./configure --prefix=/usr/local/libxml2 \
    && make && make install \
    && cd /usr/local/src \
    && tar -zxf zlib-1.2.11.tar.gz \
    && cd zlib-1.2.11 \
    && ./configure --prefix=/usr/local/zlib \
    && make && make install \
    && cd /usr/local/src \
    && tar -zxf libpng-1.6.35.tar.gz \
    && cd libpng-1.6.35 \
    && ./configure --prefix=/usr/local/libpng \
    && make && make install \
    && cd /usr/local/src \
    && tar -zxf freetype-2.5.3.tar.gz \
    && cd freetype-2.5.3 \
    && ./configure --prefix=/usr/local/freetype \
    && make && make install \
    && cd /usr/local/src \
    && mkdir /usr/local/jpeg9 \
    && mkdir /usr/local/jpeg9/bin \
    && mkdir /usr/local/jpeg9/lib \
    && mkdir /usr/local/jpeg9/include \
    && mkdir /usr/local/jpeg9/man \
    && mkdir /usr/local/jpeg9/man/man1 \
    && tar -zxf jpegsrc.v9c.tar.gz \
    && cd jpeg-9c/ \
    && ./configure --prefix=/usr/local/jpeg9/ --enable-shared --enable-static \
    && make && make install \
    && cd /usr/local/src \
    && tar -zxf libgd-2.1.1.tar.gz \
    && cd libgd-2.1.1 \
    && ./configure --prefix=/usr/local/gd --with-png=/usr/local/libpng/ --with-freetype=/usr/local/freetype/ --with-jpeg=/usr/local/jpeg9/ \
    && make && make install \
    && cd /usr/local/src \
    # 安装旧版OpenSSL，默认的版本太高了 \
    && tar -zxf openssl-1.0.2u.tar.gz \
    && cd openssl-1.0.2u \
    && ./config --prefix=/usr/local/openssl-1.0.2 \
    && make && make install \
    # 安装PHP \
    && cd /usr/local/src \
    && tar -zxf php-5.6.38.tar.gz \
    && mv php-5.6.38 php \
    && cd php \
    && ./configure --prefix=/usr/local/php \
                    --with-config-file-path=/usr/local/php/etc \
                    --with-libxml-dir=/usr/local/libxml2 \
                    --with-zlib-dir=/usr/local/zlib \
                    --with-gd=/usr/local/gd \
                    --with-jpeg-dir=/usr/local/jpeg9 \
                    --with-png-dir=/usr/local/libpng \
                    --with-freetype-dir=/usr/local/freetype \
                    --with-mysql \
                    --with-mysqli \
                    --with-openssl=/usr/local/openssl-1.0.2 \
                    --enable-gd-native-ttf \
                    --enable-mbstring \
                    --enable-ftp \
                    --enable-bcmath \
                    --enable-sockets \
                    --enable-zip \
                    --enable-soap \
                    --enable-calendar \
                    --with-curl \
                    --with-pdo-mysql \
                    --enable-xml \
                    --with-iconv \
                    --enable-maintainer-zts \
                    --without-pear \
                    --enable-fpm \
    && make && make install \
    # 配置 \
    && groupadd nobody \
    && cp /usr/local/src/php/php.ini-production /usr/local/php/etc/php.ini \
    && printf "\nerror_log = /tmp/php.log" >> /usr/local/php/etc/php.ini \
    && sed -i 's#;date.timezone =#date.timezone = Asia/Shanghai#' /usr/local/php/etc/php.ini \
    && cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf \
    && sed -i 's#;pid = run/php-fpm.pid#pid = run/php-fpm.pid#' /usr/local/php/etc/php-fpm.conf \
    # 只监听指定端口，方便容器间访问 \
    && sed -i 's#listen = 127.0.0.1:9000#listen = 9000#' /usr/local/php/etc/php-fpm.conf \
    # 安装扩展 \
    && cd /usr/local/src \
    && tar -zxf libmcrypt-2.5.8.tar.gz \
    && cd libmcrypt-2.5.8 \
    && ./configure && make && make install \
    && cd /usr/local/src \
    && tar -zxf mhash-0.9.9.9.tar.gz \
    && cd mhash-0.9.9.9 \
    && ./configure && make && make install \
    && cd /usr/local/src \
    && tar -zxf mcrypt-2.6.8.tar.gz \
    && cd mcrypt-2.6.8 \
    && LD_LIBRARY_PATH=/usr/local/lib ./configure \
    && make && make install \
    && cd /usr/local/src/php/ext/mcrypt/ \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config \
    && make && make install \
    && printf "\nextension=mcrypt.so" >> /usr/local/php/etc/php.ini \
    && cd /usr/local/src \
    && tar -zxf memcache-2.2.7.tgz \
    && cd memcache-2.2.7 \
    && ./configure --enable-memcache --with-php-config=/usr/local/php56/bin/php-config --with-zlib-dir=/usr/ \
    && make && make install \
    && printf "\nextension=memcache.so" >> /usr/local/php/etc/php.ini \
    && cd /usr/local/src \
    && apt-get install -y --no-install-recommends libmemcached-dev \
    && tar -zxf memcached-2.1.0.tgz \
    && cd memcached-2.1.0 \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config --with-libmemcached-dir=/usr \
    && make && make install \
    && printf "\nextension=memcached.so" >> /usr/local/php/etc/php.ini \
    && cd /usr/local/src \
    && unzip -q igbinary.zip \
    && cd igbinary-master/ \
    && /usr/local/php/bin/phpize \
    && ./configure CFLAGS="-O2 -g" --enable-igbinary --with-php-config=/usr/local/php/bin/php-config \
    && make && make install \
    && printf "\n; Load igbinary extension\nextension=igbinary.so\n; Use igbinary as session serializer\nsession.serialize_handler=igbinary\n; Enable or disable compacting of duplicate strings\n; The default is On.\nigbinary.compact_strings=On\n; Use igbinary as serializer in APC cache (3.1.7 or later)\n;apc.serializer=igbinary\n" >> /usr/local/php/etc/php.ini \
    && cd /usr/local/src \
    && unzip -q librdkafka-master.zip \
    && cd librdkafka-master \
    && ./configure && make && make install \
    && cd /usr/local/src \
    && tar -zxf php-rdkafka-4.0.0.tar.gz \
    && cd php-rdkafka-4.0.0 \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php56/bin/php-config \
    && make all -j 5 && make install \
    && printf "\nextension=rdkafka.so" >> /usr/local/php/etc/php.ini \
    && cd /usr/local/src \
    && unzip -q phpredis-master.zip \
    && cd phpredis-master \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config \
    && make && make install \
    && printf "\nextension=redis.so" >> /usr/local/php/etc/php.ini \
    # 清理空间，减小镜像体积 \
    && cd /usr/local/src \
    && rm -f ./*.tgz \
    && rm -f ./*.tar.gz \
    && rm -f ./*.zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 默认命令（可以根据需要修改）
CMD ["bash"]