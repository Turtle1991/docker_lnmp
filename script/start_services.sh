#!/bin/bash

function color() {
  blue="\033[0;36m"
  red="\033[0;31m"
  green="\033[0;32m"
  close="\033[m"
  case $1 in
  blue)
    echo -e "$blue $2 $close"
    ;;
  red)
    echo -e "$red $2 $close"
    ;;
  green)
    echo -e "$green $2 $close"
    ;;
  *)
    echo "Input color error!!"
    ;;
  esac
}

function checkPort() {
  port=$1
  loop_num=5
  while [ $loop_num -gt 0 ]; do
    color blue "[$loop_num]检查端口：$port"
    if [[ $(lsof -i:$port | wc -l) -gt 0 ]]; then
      color green "启动成功，监听端口：$port"
      return 0
    fi
    ((loop_num--))
    sleep 2
  done
  return 1
}

function checkProcess() {
  process=$1
  loop_num=5
  while [ $loop_num -gt 0 ]; do
    color blue "[$loop_num]检查进程：$process"
    if [[ $(ps -ef | grep $process | grep -v grep | wc -l) -gt 0 ]]; then
      color green "启动成功"
      return 0
    fi
    ((loop_num--))
    sleep 2
  done
  return 1
}

color green "🌟[Nginx]启动..."
exit
/usr/local/nginx_1.25.0/sbin/nginx
checkPort 80
if [[ $? == 1 ]]; then
  color red "启动失败"
fi

color green "🌟[php5.6]启动..."
/usr/local/php56/sbin/php-fpm
checkPort 9000
if [[ $? == 1 ]]; then
  color red "启动失败"
fi
color green "🌟[php8]启动..."
/usr/local/php8/sbin/php-fpm
checkPort 9002
if [[ $? == 1 ]]; then
  color red "启动失败"
fi
color green "🌟[php8.1]启动..."
/usr/local/php8.1/sbin/php-fpm
checkPort 9003
if [[ $? == 1 ]]; then
  color red "启动失败"
fi

color green "🌟[redis]启动..."
/usr/local/redis_2.6.14/bin/redis-server /usr/local/redis_2.6.14/etc/redis_6379.conf
checkPort 6379
if [[ $? == 1 ]]; then
  color red "启动失败"
fi
color green "🌟[redis]启动..."
/usr/local/redis_2.6.14/bin/redis-server /usr/local/redis_2.6.14/etc/redis_6380.conf
checkPort 6380
if [[ $? == 1 ]]; then
  color red "启动失败"
fi
color green "🌟[redis]启动..."
/usr/local/redis_2.6.14/bin/redis-server /usr/local/redis_2.6.14/etc/redis_6381.conf
checkPort 6381
if [[ $? == 1 ]]; then
  color red "启动失败"
fi

color green "🌟[memcached]启动..."
/usr/local/memcached/bin/memcached -d -m 100 -u root -l 127.0.0.1 -p 12000 -c 1024 -P /usr/local/memcached/memcached_12000.pid
checkPort 12000
if [[ $? == 1 ]]; then
  color red "启动失败"
fi

color green "🌟[elasticsearch]启动..."
su - elasticsearch -c "/usr/local/elasticsearch-6.8.2/bin/elasticsearch -d -p /usr/local/elasticsearch-6.8.2/pid"
checkProcess elasticsearch-6.8.2
if [[ $? == 1 ]]; then
  color red "启动失败"
fi

color green "🌟[zookeeper]启动..."
/usr/local/apache-zookeeper-3.6.3-bin/bin/zkServer.sh start
checkPort 2181
if [[ $? == 0 ]]; then
  sleep 5
  color green "🌟[kafka]启动..."
  # 自动启动这里有时候会失败，日志：tail -f /usr/local/kafka_2.12-2.2.0/logs/server.log
  retry_num=2
  while [[ $retry_num -gt 0 ]]; do
    /usr/local/kafka_2.12-2.2.0/bin/kafka-server-start.sh -daemon /usr/local/kafka_2.12-2.2.0/config/server.properties
    checkPort 9092
    if [[ $? == 0 ]]; then
      break
    else
      ((retry_num--))
      if [[ $retry_num == 0 ]]; then
        color red "启动失败，请查看日志，并尝试手动启动"
        break
      fi
      color red "[$retry_num]启动失败，再重试启动..."
      sleep 2
    fi
  done
else
  color red "启动失败"
fi

color green "💪所有服务启动完成"
