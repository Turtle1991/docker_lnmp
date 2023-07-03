本地自签https证书

## 在容器里信任自签的根证书

1.安装必要的依赖（镜像中已经安装了，可以跳过这一步）

```
yum install -y ca-certificates
```

2.把自签用的根证书移动到下面目录

证书改了个名字 turtle_ca.crt ，方便识别，不然原先的 root.crt 时间久了估计都忘记是我自己加的证书了

```
cp out/root.crt /usr/share/pki/ca-trust-source/anchors/turtle_ca.crt
```

3.更新信任

```
update-ca-trust
```

以上信任更新后，在文件 /etc/ssl/certs/ca-bundle.crt 和 /etc/ssl/certs/ca-bundle.trust.crt 里就包含了新的自定义证书了。
查看文件，可以看到证书是 # Turtle ROOT CA 开头的，刚好是我们上面放到 /usr/share/pki/ca-trust-source/anchors/ 里面证书的名字。

4.根证书更新信任后，需要重启下nginx才能生效

5.主机也需要信任自签的根证书

6.配置对应的https，然后访问测试