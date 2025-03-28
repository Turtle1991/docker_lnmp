FROM my-base
LABEL maintainer="Turtle"

# 安装Nginx
COPY soft/nginx-1.25.0.tar.gz soft/pcre-8.38.tar.gz /usr/local/src/
RUN groupadd nginx \
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
    && cd /usr/local/src \
    # 清理空间，减小镜像体积 \
    && rm -rf /usr/local/src/* \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 默认命令（可以根据需要修改）
CMD ["bash"]