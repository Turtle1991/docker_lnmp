FROM my-base
LABEL maintainer="Turtle"

COPY soft/bao/* /usr/local/src/
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-dev \
        libcurl4-openssl-dev \
        libxpm-dev \
        libfreetype6-dev \
        openssl \
        curl \
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
    # 安装PHP \
    && export PKG_CONFIG_PATH=/usr/local/libxml2/lib/pkgconfig:$PKG_CONFIG_PATH \
    && export PKG_CONFIG_PATH=/usr/local/jpeg9/lib/pkgconfig:$PKG_CONFIG_PATH \
    && tar -zxf sqlite-autoconf-3360000.tar.gz \
    && cd sqlite-autoconf-3360000 \
    && ./configure --prefix=/usr/local/sqlite3 \
    && make && make install \
    && export PKG_CONFIG_PATH=/usr/local/sqlite3/lib/pkgconfig:$PKG_CONFIG_PATH \
    && cd /usr/local/src \
    && tar -zxf onig-6.9.7.1.tar.gz \
    && cd onig-6.9.7 \
    && ./configure --prefix=/usr/local/oniguruma-6.9.7 \
    && make && make install \
    && export PKG_CONFIG_PATH=/usr/local/oniguruma-6.9.7/lib/pkgconfig:$PKG_CONFIG_PATH \
    && cd /usr/local/src \
    && tar -zxf libzip-1.2.0.tar.gz \
    && cd libzip-1.2.0 \
    && ./configure --prefix=/usr/local/libzip-1.2.0 \
    && make && make install \
    && export PKG_CONFIG_PATH=/usr/local/libzip-1.2.0/lib/pkgconfig:$PKG_CONFIG_PATH \
    && cd /usr/local/src \
    && tar -zxf php-8.1.28.tar.gz \
    && mv php-8.1.28 php \
    && cd php \
    && ./configure --prefix=/usr/local/php \
                    --with-config-file-path=/usr/local/php/etc \
                    --with-libxml=/usr/local/libxml2 \
                    --with-zlib \
                    --enable-gd \
                    --with-jpeg=/usr/local/jpeg9 \
                    --with-freetype=/usr/local/freetype \
                    --with-mysqli \
                    --with-openssl \
                    --enable-mbstring \
                    --enable-ftp \
                    --enable-bcmath \
                    --enable-sockets \
                    --with-zip \
                    --enable-soap \
                    --enable-calendar \
                    --with-curl \
                    --with-pdo-mysql \
                    --enable-xml \
                    --with-iconv \
                    --without-pear \
                    --enable-fpm \
                    --enable-pdo \
    && make && make install \
    # 配置 \
    && groupadd nobody \
    && cp /usr/local/src/php/php.ini-production /usr/local/php/etc/php.ini \
    && printf "\nerror_log = /tmp/php.log" >> /usr/local/php/etc/php.ini \
    && sed -i 's#;date.timezone =#date.timezone = Asia/Shanghai#' /usr/local/php/etc/php.ini \
    && cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf \
    && sed -i 's#;pid = run/php-fpm.pid#pid = run/php-fpm.pid#' /usr/local/php/etc/php-fpm.conf \
    && cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf \
    # 只监听指定端口，方便容器间访问 \
    && sed -i 's#listen = 127.0.0.1:9000#listen = 9000#' /usr/local/php/etc/php-fpm.d/www.conf \
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
    && tar -zxf mcrypt-1.0.4.tgz \
    && cd mcrypt-1.0.4 \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config \
    && make && make install \
    && printf "\nextension=mcrypt.so" >> /usr/local/php/etc/php.ini \
    && cd /usr/local/src \
    && tar -zxf igbinary-3.2.15.tgz \
    && cd igbinary-3.2.15 \
    && /usr/local/php/bin/phpize \
    && ./configure CFLAGS="-O2 -g" --enable-igbinary --with-php-config=/usr/local/php/bin/php-config \
    && make && make install \
    && printf "\n; Load igbinary extension\nextension=igbinary.so\n; Use igbinary as session serializer\nsession.serialize_handler=igbinary\n; Enable or disable compacting of duplicate strings\n; The default is On.\nigbinary.compact_strings=On\n; Use igbinary as serializer in APC cache (3.1.7 or later)\n;apc.serializer=igbinary\n" >> /usr/local/php/etc/php.ini \
    && cd /usr/local/src \
    && tar -zxf phpredis-5.3.4.tgz \
    && cd redis-5.3.4 \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config \
    && make && make install \
    && printf "\nextension=redis.so" >> /usr/local/php/etc/php.ini \
    && cd /usr/local/src \
    && tar -zxf memcache-8.0.tgz \
    && cd memcache-8.0 \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config --with-zlib-dir=/usr/local/zlib \
    && make && make install \
    && printf "\nextension=memcache.so" >> /usr/local/php/etc/php.ini \
    && cd /usr/local/src \
    && apt-get update && apt-get install -y --no-install-recommends libmemcached-dev \
    && tar -zxf memcached-3.1.5.tgz \
    && cd memcached-3.1.5 \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config --with-libmemcached-dir=/usr --with-zlib-dir=/usr/local/zlib --disable-memcached-sasl \
    && make && make install \
    && printf "\nextension=memcached.so" >> /usr/local/php/etc/php.ini \
    && cd /usr/local/src \
    && unzip -q librdkafka-master.zip \
    && cd librdkafka-master \
    && ./configure && make && make install \
    && cd /usr/local/src \
    && unzip -q php-rdkafka-6.x.zip \
    && cd php-rdkafka-6.x \
    && /usr/local/php/bin/phpize \
    && ./configure --with-php-config=/usr/local/php/bin/php-config \
    && make all -j 5 && make install \
    && printf "\nextension=rdkafka.so" >> /usr/local/php/etc/php.ini \
    # 清理空间，减小镜像体积 \
    && cd /usr/local/src \
    && rm -f ./*.tgz \
    && rm -f ./*.tar.gz \
    && rm -f ./*.zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 默认命令（可以根据需要修改）
CMD ["bash"]
