
## 说明

通过Dockerfile编译镜像，你可以获得一个本地开发环境

## 编译镜像

在当前目录下执行，会根据Dockerfile编译生成镜像
```
docker build -t my-centos .
```

## 根据镜像启动容器

如果没有容器，需要根据镜像启动一个容器
```
docker run --name 容器名称 -it -p 80:80  -p 443:443 -v "主机想要共享到容器的目录:容器里对应的目录" my-centos /bin/bash

如：
docker run --name demo -it -p 80:80  -p 443:443 -v "/Users/turtle/turtleWork:/turtle" my-centos /bin/bash
```
注意：因为是本地，所以用了80端口，线上环境不建议这么用，暴露80端口，会不安全。

如果之前已经有容器了，那直接启动就行了
```
docker start 容器名称
```

登入容器
```
docker exec -it 容器名称 bash
```

## 首次容器启动后，需要做到事情：

#### nginx需要自己修改下配置
```
vim /usr/local/nginx_1.25.0/conf/nginx.conf
新增：
include /usr/local/nginx_1.25.0/conf/vhosts/host_*.conf;
```

#### 重新设置MySQL的密码

如果mysql启动了，需要先关闭。执行以下命令

```
/usr/local/mysql/bin/mysqld_safe --skip-grant-tables --skip-networking &
```
这样便可以越过权限表，跳过密码认证过程来登入。

新开一个终端，通过 ```mysql -uroot -p``` 登入。

开始设置密码
```
mysql> use mysql;
mysql> update user set authentication_string=PASSWORD('nidemima') where User='root';
mysql> flush privileges;
```

再启动mysql服务，通过命令和密码就可以登进去了。

可能会遇到的问题：
```
退出后重新登入 可以进 可是当我 show databases; 的时候 提示：

mysql> show databases;
ERROR 1820 (HY000): You must reset your password using ALTER USER statement before executing this statement.

解决方法：
mysql> set password=password('nidemima');
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> alter user 'root'@'localhost' password expire never;
Query OK, 0 rows affected (0.00 sec)

mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)

mysql> exit;

重新登入 可以了
```

## 服务启动、关闭、重启等命令

#### nginx

```
/usr/local/nginx_1.25.0/sbin/nginx
/usr/local/nginx_1.25.0/sbin/nginx -t
/usr/local/nginx_1.25.0/sbin/nginx -s reload
```

#### php

```
启动：
/usr/local/php56/sbin/php-fpm
/usr/local/php8/sbin/php-fpm

关闭：
kill -INT `cat /usr/local/php56/var/run/php-fpm.pid`

重启：
kill -USR2 `cat /usr/local/php56/var/run/php-fpm.pid`
```

#### mysql

```
/usr/local/mysql/support-files/mysql.server start
```

#### redis

默认支持了6379、6380、6381三个端口，根据需要启动。

```
/usr/local/redis_2.6.14/bin/redis-server /usr/local/redis_2.6.14/etc/redis_6379.conf
/usr/local/redis_2.6.14/bin/redis-server /usr/local/redis_2.6.14/etc/redis_6380.conf
/usr/local/redis_2.6.14/bin/redis-server /usr/local/redis_2.6.14/etc/redis_6381.conf
```

#### mc

```
/usr/local/memcached/bin/memcached -d -m 100 -u root -l 127.0.0.1 -p 12000 -c 1024 -P /usr/local/memcached/memcached_12000.pid
```

## 日志

php报错日志：/tmp/php.log