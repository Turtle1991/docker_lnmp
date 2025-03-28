FROM my-centos
LABEL maintainer="Turtle"

# 修改配置
RUN cd /usr/local \
    && sed -i 's/bind 127.0.0.1/#bind 127.0.0.1/' /usr/local/redis_2.6.14/etc/redis_6379.conf \
    && sed -i 's/bind 127.0.0.1/#bind 127.0.0.1/' /usr/local/redis_2.6.14/etc/redis_6380.conf \
    && sed -i 's#port 6379#port 6380#' /usr/local/redis_2.6.14/etc/redis_6380.conf \
    && sed -i 's/bind 127.0.0.1/#bind 127.0.0.1/' /usr/local/redis_2.6.14/etc/redis_6381.conf \
    && sed -i 's#port 6379#port 6381#' /usr/local/redis_2.6.14/etc/redis_6381.conf

# 启动脚本
RUN printf "/usr/local/redis_2.6.14/bin/redis-server /usr/local/redis_2.6.14/etc/redis_6379.conf\n \
/usr/local/redis_2.6.14/bin/redis-server /usr/local/redis_2.6.14/etc/redis_6380.conf\n \
/usr/local/redis_2.6.14/bin/redis-server /usr/local/redis_2.6.14/etc/redis_6381.conf\n \
/usr/local/memcached/bin/memcached -d -m 100 -u root -l 0.0.0.0 -p 12000 -c 1024 -P /usr/local/memcached/memcached_12000.pid\n \
tail -f /dev/null\n" > /startup.sh

CMD ["bash", "/startup.sh"]