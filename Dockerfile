# syntax=docker/dockerfile:1

FROM centos:7.9.2009
LABEL maintainer="Turtle"

# 设置时区
# kde-l10n-Chinese 中文字符集，解决中文乱码问题
# 设置容器编码格式
# 安装需要的包
# 设置vim的配置
# 清除yum缓存
RUN /bin/cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime  && echo 'Asia/Shanghai' >/etc/timezone \
    && yum -y install kde-l10n-Chinese \
    && localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 \
    && yum -y install telnet vim wget lsof unzip \
    && echo -e "\" 显示行号\nset nu\n\" 语法高亮\nsyntax on\n\" Tab键宽度4\nset tabstop=4\n\" 注释的颜色 1红色 2墨绿 3黄色 4蓝(即默认的颜色) 5粉色 6淡蓝色 7白色\nhi comment ctermfg=6" > ~/.vimrc \
    && yum clean all
ENV LC_ALL "zh_CN.UTF-8"

# 安装nginx
# 配置文件自己修改
COPY soft/nginx-1.25.0.tar.gz soft/pcre-8.38.tar.gz /usr/local/src/
RUN yum install -y gcc gcc-c++ autoconf automake zlib zlib-devel openssl openssl-devel pcre-devel \
    && groupadd nginx \
    && useradd -g nginx -s /sbin/nologin nginx \
    && cd /usr/local/src \
    && tar -zxf pcre-8.38.tar.gz \
    && tar -zxf nginx-1.25.0.tar.gz \
    && cd nginx-1.25.0 \
    && ./configure --prefix=/usr/local/nginx_1.25.0 \
               --conf-path=/usr/local/nginx_1.25.0/conf/nginx.conf \
               --error-log-path=/usr/local/nginx_1.25.0/logs/error.log \
               --pid-path=/usr/local/nginx_1.25.0/logs/nginx.pid \
               --user=nginx \
               --group=nginx \
               --with-http_ssl_module \
               --with-http_flv_module \
               --with-http_gzip_static_module \
               --http-log-path=/usr/local/nginx_1.25.0/logs/access.log \
               --http-client-body-temp-path=/usr/local/nginx_1.25.0/client \
               --http-proxy-temp-path=/usr/local/nginx_1.25.0/proxy \
               --http-fastcgi-temp-path=/usr/local/nginx_1.25.0/fcgi \
               --with-http_stub_status_module \
               --with-pcre=/usr/local/src/pcre-8.38 \
    && make && make install \
    && mkdir /usr/local/nginx_1.25.0/conf/vhosts \
    && localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 \
    && cd /usr/local/src \
    && rm -f nginx-1.25.0.tar.gz \
    && rm -rf nginx-1.25.0/ \
    && yum clean all

# https本地自签证书支持
RUN yum install -y ca-certificates && yum clean all

# 安装MySQL
# 数据库密码自己修改
COPY soft/mysql-5.7.23_turtle.tar.gz soft/cmake-3.4.1.tar.gz soft/boost_1_59_0.tar.gz config/mysql.cnf /usr/local/src/
RUN yum install -y bison bison-devel ncurses ncurses-devel \
    && cd /usr/local/src \
    && tar -zxf cmake-3.4.1.tar.gz \
    && cd cmake-3.4.1 \
    && ./bootstrap \
    && gmake && gmake install \
    && groupadd mysql \
    && useradd -g mysql -s /sbin/nologin mysql \
    && mkdir -p /usr/local/mysql/etc \
    && mkdir -p /usr/local/mysql/data \
    && chown -R mysql:mysql /usr/local/mysql/ \
    && cd /usr/local/src/ \
    && tar -zxf boost_1_59_0.tar.gz \
    && tar -zxf mysql-5.7.23_turtle.tar.gz \
    && cd mysql-5.7.23 \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
            -DSYSCONFDIR=/usr/local/mysql/etc \
            -DMYSQL_DATADIR=/usr/local/mysql/data \
            -DMYSQL_TCP_PORT=3306 \
            -DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
            -DEXTRA_CHARSETS=all \
            -DDEFAULT_CHARSET=utf8 \
            -DMYSQL_USER=mysql \
            -DWITH_READLINE=1 \
            -DWITH_INNOBASE_STORAGE_ENGINE=1 \
            -DWITH_MYISAM_STORAGE_ENGINE=1 \
            -DWITH_MEMORY_STORAGE_ENGINE=1 \
            -DWITH_PARTITION_STORAGE_ENGINE=1 \
            -DWITH_EMBEDDED_SERVER=1 \
            -DWITH_SSL=system \
            -DENABLED_LOCAL_INFILE=1 \
            -DENABLE_DOWNLOADS=1 \
            -DDEFAULT_COLLATION=utf8_general_ci \
            -DWITH_BOOST=/usr/local/src/boost_1_59_0 \
    && make && make install \
    && mv /usr/local/src/mysql.cnf /etc/my.cnf \
    && /usr/local/mysql/bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data \
    && ln -s /usr/local/mysql/lib/libmysqlclient.so /usr/local/mysql/lib/libmysqlclient_r.so \
    && cd /usr/local/src/ \
    && rm -f cmake-3.4.1.tar.gz \
    && rm -rf cmake-3.4.1/ \
    && rm -f boost_1_59_0.tar.gz \
    && rm -rf boost_1_59_0/ \
    && rm -f mysql-5.7.23.tar.gz \
    && rm -rf mysql-5.7.23/ \
    && yum clean all

# 安装php5
COPY soft/php/* /usr/local/src/
RUN yum install -y python-devel curl-devel libXpm-devel freetype-devel \
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
    && tar -zxf php-5.6.38.tar.gz \
    && cd php-5.6.38 \
    && ./configure --prefix=/usr/local/php56 \
                --with-config-file-path=/usr/local/php56/etc \
                --with-libxml-dir=/usr/local/libxml2 \
                --with-zlib-dir=/usr/local/zlib \
                --with-gd=/usr/local/gd \
                --with-jpeg-dir=/usr/local/jpeg9 \
                --with-png-dir=/usr/local/libpng \
                --with-freetype-dir=/usr/local/freetype \
                --with-mysql=/usr/local/mysql \
                --with-mysqli=/usr/local/mysql/bin/mysql_config \
                --with-openssl \
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
    && cp /usr/local/src/php-5.6.38/php.ini-production /usr/local/php56/etc/php.ini \
#    && sed -i 's#display_errors = Off#display_errors = On#' /usr/local/php56/etc/php.ini \
    && echo -e "\nerror_log = /tmp/php.log" >> /usr/local/php56/etc/php.ini \
    && sed -i 's#;date.timezone =#date.timezone = Asia/Shanghai#' /usr/local/php56/etc/php.ini \
    && cp /usr/local/php56/etc/php-fpm.conf.default /usr/local/php56/etc/php-fpm.conf \
    && sed -i 's#;pid = run/php-fpm.pid#pid = run/php-fpm.pid#' /usr/local/php56/etc/php-fpm.conf \
#        && sed -i 's#;daemonize = yes#daemonize = no#' /usr/local/php56/etc/php-fpm.conf \
    && echo -e "<?php\nphpinfo();" > /usr/local/nginx_1.25.0/html/index.php \
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
    && cd /usr/local/src/php-5.6.38/ext/mcrypt/ \
    && /usr/local/php56/bin/phpize \
    && ./configure --with-php-config=/usr/local/php56/bin/php-config \
    && make && make install \
    && echo -e "\nextension=mcrypt.so" >> /usr/local/php56/etc/php.ini \
    && cd /usr/local/src \
    && tar -zxf libevent-2.0.21-stable.tar.gz \
    && cd libevent-2.0.21-stable \
    && ./configure --prefix=/usr/local/libevent && make && make install \
    && cd /usr/local/src \
    && tar -zxf memcached-1.4.17.tar.gz \
    && cd memcached-1.4.17 \
    && ./configure --prefix=/usr/local/memcached --with-libevent=/usr/local/libevent/ && make && make install \
    && cd /usr/local/src \
    && tar -zxf memcache-2.2.7.tgz \
    && cd memcache-2.2.7 \
    && /usr/local/php56/bin/phpize \
    && ./configure --enable-memcache --with-php-config=/usr/local/php56/bin/php-config --with-zlib-dir=/usr/ \
    && make && make install \
    && cd /usr/local/src \
    && tar -zxf libmemcached-1.0.18.tar.gz \
    && cd libmemcached-1.0.18 \
    && ./configure --prefix=/usr/local/libmemcached --with-memcached \
    && make && make install \
    && cd /usr/local/src \
    && tar -zxf memcached-2.1.0.tgz \
    && cd memcached-2.1.0 \
    && /usr/local/php56/bin/phpize \
    && ./configure --with-php-config=/usr/local/php56/bin/php-config --with-libmemcached-dir=/usr/local/libmemcached/ \
    && make && make install \
    && echo -e "extension=memcache.so\nextension=memcached.so" >> /usr/local/php56/etc/php.ini \
    && cd /usr/local/src \
    && unzip igbinary.zip \
    && cd igbinary-master/ \
    && /usr/local/php56/bin/phpize \
    && ./configure CFLAGS="-O2 -g" --enable-igbinary --with-php-config=/usr/local/php56/bin/php-config \
    && make && make install \
    && echo -e "\n; Load igbinary extension\nextension=igbinary.so\n; Use igbinary as session serializer\nsession.serialize_handler=igbinary\n; Enable or disable compacting of duplicate strings\n; The default is On.\nigbinary.compact_strings=On\n; Use igbinary as serializer in APC cache (3.1.7 or later)\n;apc.serializer=igbinary\n" >> /usr/local/php56/etc/php.ini \
    && cd /usr/local/src \
    && tar -zxf swoole-src-2.0.8.tar.gz \
    && cd swoole-src-2.0.8 \
    && /usr/local/php56/bin/phpize \
    && ./configure --with-php-config=/usr/local/php56/bin/php-config \
    && make && make install \
    && echo -e "extension=swoole.so" >> /usr/local/php56/etc/php.ini \
    && cd /usr/local/src \
    && unzip -q librdkafka-master.zip \
    && cd librdkafka-master \
    && ./configure && make && make install \
    && cd /usr/local/src \
    && unzip -q php-rdkafka-master.zip \
    && cd php-rdkafka-master \
    && /usr/local/php56/bin/phpize \
    && ./configure --enable-kafka --with-php-config=/usr/local/php56/bin/php-config \
    && make && make install \
    && echo -e "extension=rdkafka.so" >> /usr/local/php56/etc/php.ini \
    && cd /usr/local/src \
    && unzip -q phpredis-master.zip \
    && cd phpredis-master \
    && /usr/local/php56/bin/phpize \
    && ./configure --with-php-config=/usr/local/php56/bin/php-config \
    && make && make install \
    && echo -e "extension=redis.so" >> /usr/local/php56/etc/php.ini \
    && cd /usr/local/src \
    && rm -f ./*.tar.gz \
    && rm -f ./*.zip \
    && rm -f ./*.tgz \
    && yum clean all

# 安装redis
COPY soft/redis-2.6.14.tar.gz soft/tcl8.6.1-src.tar.gz /usr/local/src/
RUN cd /usr/local/src \
    && tar -zxf tcl8.6.1-src.tar.gz \
    && cd tcl8.6.1/unix/ \
    && ./configure --prefix=/usr --mandir=/usr/share/man --without-tzdata $([ $(uname -m) = x86_64 ] && echo --enable-64bit) \
    && make \
    && sed -e "s@^\(TCL_SRC_DIR='\).*@\1/usr/include'@" -e "/TCL_B/s@='\(-L\)\?.*unix@='\1/usr/lib@" -i tclConfig.sh \
    && make install \
    && make install-private-headers \
    && ln -v -sf tclsh8.6 /usr/bin/tclsh \
    && chmod -v 755 /usr/lib/libtcl8.6.so \
    && cd /usr/local/src \
    && tar -zxf redis-2.6.14.tar.gz \
    && cd redis-2.6.14 \
    && make MALLOC=libc \
    && make test \
    && make PREFIX=/usr/local/redis_2.6.14 install \
    && mkdir /usr/local/redis_2.6.14/etc \
    && mkdir -p /usr/local/redis_2.6.14/var/dump/6379 \
    && mkdir -p /usr/local/redis_2.6.14/var/dump/6380 \
    && mkdir -p /usr/local/redis_2.6.14/var/dump/6381 \
    && mkdir -p /usr/local/redis_2.6.14/var/run \
    && cp /usr/local/src/redis-2.6.14/redis.conf /usr/local/redis_2.6.14/etc/redis_6379.conf \
    && sed -i 's#pidfile /var/run/redis.pid#pidfile /usr/local/redis_2.6.14/var/run/redis_6379.pid#' /usr/local/redis_2.6.14/etc/redis_6379.conf \
    && sed -i 's#daemonize no#daemonize yes#' /usr/local/redis_2.6.14/etc/redis_6379.conf \
    && sed -i 's/# bind 127.0.0.1/bind 127.0.0.1/' /usr/local/redis_2.6.14/etc/redis_6379.conf \
    && sed -i 's#loglevel notice#loglevel verbose#' /usr/local/redis_2.6.14/etc/redis_6379.conf \
    && sed -i 's#dir ./#dir /usr/local/redis_2.6.14/var/dump/6379#' /usr/local/redis_2.6.14/etc/redis_6379.conf \
    && cp /usr/local/src/redis-2.6.14/redis.conf /usr/local/redis_2.6.14/etc/redis_6380.conf \
    && sed -i 's#pidfile /var/run/redis.pid#pidfile /usr/local/redis_2.6.14/var/run/redis_6380.pid#' /usr/local/redis_2.6.14/etc/redis_6380.conf \
    && sed -i 's#daemonize no#daemonize yes#' /usr/local/redis_2.6.14/etc/redis_6380.conf \
    && sed -i 's/# bind 127.0.0.1/bind 127.0.0.1/' /usr/local/redis_2.6.14/etc/redis_6380.conf \
    && sed -i 's#loglevel notice#loglevel verbose#' /usr/local/redis_2.6.14/etc/redis_6380.conf \
    && sed -i 's#dir ./#dir /usr/local/redis_2.6.14/var/dump/6380#' /usr/local/redis_2.6.14/etc/redis_6380.conf \
    && sed -i 's#port 6379#port 6380#' /usr/local/redis_2.6.14/etc/redis_6380.conf \
    && cp /usr/local/src/redis-2.6.14/redis.conf /usr/local/redis_2.6.14/etc/redis_6381.conf \
    && sed -i 's#pidfile /var/run/redis.pid#pidfile /usr/local/redis_2.6.14/var/run/redis_6381.pid#' /usr/local/redis_2.6.14/etc/redis_6381.conf \
    && sed -i 's#daemonize no#daemonize yes#' /usr/local/redis_2.6.14/etc/redis_6381.conf \
    && sed -i 's/# bind 127.0.0.1/bind 127.0.0.1/' /usr/local/redis_2.6.14/etc/redis_6381.conf \
    && sed -i 's#loglevel notice#loglevel verbose#' /usr/local/redis_2.6.14/etc/redis_6381.conf \
    && sed -i 's#dir ./#dir /usr/local/redis_2.6.14/var/dump/6381#' /usr/local/redis_2.6.14/etc/redis_6381.conf \
    && sed -i 's#port 6379#port 6381#' /usr/local/redis_2.6.14/etc/redis_6381.conf \
    && rm -f /usr/local/src/*tar.gz

# 安装php8
COPY soft/php8/* /usr/local/src/
RUN cd /usr/local/src \
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
    && tar -zxf php-8.0.9_turtle.tar.gz \
    && cd php-8.0.9 \
    && ./configure --prefix=/usr/local/php8 \
                   --with-config-file-path=/usr/local/php8/etc \
                   --with-libxml=/usr/local/libxml2 \
                   --with-zlib-dir=/usr/local/zlib \
                   --enable-gd \
                   --with-jpeg=/usr/local/jpeg9 \
                   --with-freetype=/usr/local/freetype \
                   --with-mysqli=/usr/local/mysql/bin/mysql_config \
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
    && cp /usr/local/src/php-8.0.9/php.ini-production /usr/local/php8/etc/php.ini \
#    && sed -i 's#display_errors = Off#display_errors = On#' /usr/local/php8/etc/php.ini \
    && echo -e "\nerror_log = /tmp/php.log" >> /usr/local/php8/etc/php.ini \
    && sed -i 's#;date.timezone =#date.timezone = Asia/Shanghai#' /usr/local/php8/etc/php.ini \
    && cp /usr/local/php8/etc/php-fpm.conf.default /usr/local/php8/etc/php-fpm.conf \
    && sed -i 's#;pid = run/php-fpm.pid#pid = run/php-fpm.pid#' /usr/local/php8/etc/php-fpm.conf \
    && cp /usr/local/php8/etc/php-fpm.d/www.conf.default /usr/local/php8/etc/php-fpm.d/www.conf \
    && sed -i 's#listen = 127.0.0.1:9000#listen = 127.0.0.1:9002#' /usr/local/php8/etc/php-fpm.d/www.conf \
    && cd /usr/local/src \
    && tar -zxf igbinary-3.2.6.tgz \
    && cd igbinary-3.2.6 \
    && /usr/local/php8/bin/phpize \
    && ./configure CFLAGS="-O2 -g" --enable-igbinary --with-php-config=/usr/local/php8/bin/php-config \
    && make && make install \
    && echo -e "\n; Load igbinary extension\nextension=igbinary.so\n; Use igbinary as session serializer\nsession.serialize_handler=igbinary\n; Enable or disable compacting of duplicate strings\n; The default is On.\nigbinary.compact_strings=On\n; Use igbinary as serializer in APC cache (3.1.7 or later)\n;apc.serializer=igbinary\n" >> /usr/local/php8/etc/php.ini \
    && cd /usr/local/src \
    && tar -zxf phpredis-5.3.4.tgz \
    && cd redis-5.3.4 \
    && /usr/local/php8/bin/phpize \
    && ./configure --with-php-config=/usr/local/php8/bin/php-config \
    && make && make install \
    && echo -e "extension=redis.so" >> /usr/local/php8/etc/php.ini \
    && cd /usr/local/src \
    && tar -zxf mcrypt-1.0.4.tgz \
    && cd mcrypt-1.0.4 \
    && /usr/local/php8/bin/phpize \
    && ./configure --with-php-config=/usr/local/php8/bin/php-config \
    && make && make install \
    && echo -e "extension=mcrypt.so" >> /usr/local/php8/etc/php.ini \
    && cd /usr/local/src \
    && tar -zxf memcache-8.0.tgz \
    && cd memcache-8.0 \
    && /usr/local/php8/bin/phpize \
    && ./configure --with-php-config=/usr/local/php8/bin/php-config --with-zlib-dir=/usr/local/zlib \
    && make && make install \
    && cd /usr/local/src \
    && tar -zxf memcached-3.1.5.tgz \
    && cd memcached-3.1.5 \
    && /usr/local/php8/bin/phpize \
    && ./configure --with-php-config=/usr/local/php8/bin/php-config --with-libmemcached-dir=/usr/local/libmemcached --with-zlib-dir=/usr/local/zlib --disable-memcached-sasl \
    && make && make install \
    && echo -e "extension=memcache.so\nextension=memcached.so" >> /usr/local/php8/etc/php.ini \
    && cd /usr/local/src \
    && rm -f ./*.tgz \
    && rm -f ./*.tar.gz

# 安装supervisor
COPY soft/supervisor-4.2.5.tar.gz /usr/local/src/
RUN yum install -y python-setuptools \
    && cd /usr/local/src \
    && tar -zxf supervisor-4.2.5.tar.gz \
    && cd supervisor-4.2.5 \
    && python setup.py install \
    && echo_supervisord_conf > /etc/supervisord.conf \
    && echo -e "[include]\nfiles = /etc/supervisord.d/*.ini" >> /etc/supervisord.conf \
    && mkdir /etc/supervisord.d \
    && cd /usr/local/src \
    && rm -f supervisor-4.2.5.tar.gz \
    && rm -rf supervisor-4.2.5/ \
    && yum clean all



