# 一个用于测试ansible的docker compose

## 快速开始
```bash
# 克隆仓库
git clone https://github.com/qiudeng7/ansible-demo.git && cd ansible-demo

# 启动ansible和node
docker compose up -d

# 进入ansible容器
docker compose exec -it ansible bash

# 进入容器之后可以使用ssh直接连接节点
ssh node-1
```

你可以用vscode在src目录编写你的ansible脚本，然后在容器内的`/ansible-demo/src`目录执行你的脚本。

## 工作方式
1. `docker compose up -d`会先启动ansible服务
   1. 构建Dockerfile.ansible: 基于python镜像，安装ansible和ssh
   2. 执行init_ansible.sh: 生成ssh秘钥，然后复制到宿主机
2. ansible的健康检查会轮询ansible容器的公钥是否生成
3. 公钥生成之后创建node容器
   1. 构建Dockerfile.node: 安装和配置ssh，启动sshd
   2. 执行init_node.sh: 把公钥复制粘贴到authorized_keys，允许ansible控制节点。

## 有必要吗？
1. ansible文档提供了构建ansible容器的工具，但是作为ansible初学者我并不需要构建很复杂的ansible。
2. ansible文档也说明了可以直接使用社区的镜像，但是也用了`ansible-navigator`这个工具。
3. 问题在于我不知道这些工具会如何影响我的宿主机环境，并且直接用宿主机控制node也容易失误，于是做了这个东西。

## 如何添加更多node
直接复制粘贴node-1，然后把服务改个名字即可，类似下面:
```yaml 
services:
  ansible:
    build:
      context: .
      dockerfile: Dockerfile.ansible
    volumes:
      - .:/ansible-demo
    healthcheck:
      test: ["CMD", "sh", "-c", "test -f /ansible-demo/pub_key || exit 1"]
      interval: 2s
      timeout: 2s
      retries: 3
      start_period: 1s
    command: bash /ansible-demo/init_ansible.sh
  
  node-1:
    build:
      context: .
      dockerfile: Dockerfile.node
    volumes:
      - .:/ansible-demo
    depends_on: 
      ansible:
        condition: service_healthy # 等待ansible健康检查通过再启动runner
    command: bash /ansible-demo/init_node.sh
  
  node-2:
    build:
      context: .
      dockerfile: Dockerfile.node
    volumes:
      - .:/ansible-demo
    depends_on: 
      ansible:
        condition: service_healthy # 等待ansible健康检查通过再启动runner
    command: bash /ansible-demo/init_node.sh
```