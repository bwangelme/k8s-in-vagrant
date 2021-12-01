#!/bin/bash
#
# Author: bwangel<bwangel.me@gmail.com>
# Date: 5,24,2020 16:38

echo "设置 apt"
sed -i 's/http:\/\/archive.ubuntu.com/https:\/\/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

if [[ ! -f /etc/apt/apt.conf.d/proxy.conf ]];then
    echo '设置 apt 安装的代理'
    cat >> /etc/apt/apt.conf.d/proxy.conf <<EOF
Acquire {
    HTTP::proxy "http://10.8.0.1:8118";
    HTTPS::proxy "http://10.8.0.1:8118";
}
EOF
fi

grep 'hostname config for k8s' /etc/hosts
if [[ $? == 1 ]]; then

echo '设置主机名的解析'
cat >> /etc/hosts <<EOF
# hostname config for k8s
172.18.0.101 k8s-node1
172.18.0.102 k8s-node2
172.18.0.103 k8s-node3
EOF

fi

echo '安装Docker and k8s'
export DEBIAN_FRONTEND=noninteractive
echo '  安装必要的一些系统工具'
apt-get update && apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2
echo '  安装GPG证书'
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
echo '  写入 aliyun 软件源信息'
add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
echo '  安装 Kubernetes'
export HTTP_PROXY='10.8.0.1:8118' HTTPS_PROXY='10.8.0.1:8118'
export NO_PROXY=localhost,127.0.0.0/8,10.0.0.0/8,172.17.0.0/16,192.168.0.0/16
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
unset HTTP_PROXY HTTPS_PROXY
cat >/etc/apt/sources.list.d/kubernetes.list <<EOF
deb https://packages.cloud.google.com/apt/ kubernetes-xenial main
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update && apt-get install -y kubelet kubeadm kubectl docker.io
echo '锁定 kubelet kubeadm kubectl 的版本'
apt-mark hold kubelet kubeadm kubectl

echo '设置 Docker 的代理'
systemctl enable docker
[[ ! -d "/etc/systemd/system/docker.service.d" ]] && mkdir -p /etc/systemd/system/docker.service.d
if [[ ! -f "/etc/systemd/system/docker.service.d/http-proxy.conf" ]]; then

cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=10.8.0.1:8118"
Environment="HTTPS_PROXY=10.8.0.1:8118"
Environment="NO_PROXY=localhost,127.0.0.0/8,10.0.0.0/8,172.17.0.0/16,192.168.0.0/16"
EOF

fi

if [[ ! -f "/etc/docker/daemon.json" ]]; then

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

fi

echo '创建 Docker 用户组'
egrep "^docker" /etc/group >& /dev/null
if [ $? -ne 0 ]
then
  groupadd docker
fi
usermod -aG docker vagrant
echo '重启Docker'
systemctl daemon-reload
systemctl restart docker.service

echo '关闭 Swap'
swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab

echo '拉取 k8s 启动所需镜像'
kubeadm config images pull

# echo '启动k8s'
# if [[ $1 == 1 ]];then
#     sudo kubeadm init --apiserver-advertise-address 172.18.0.101  --pod-network-cidr=172.16.0.0/16 --service-cidr 172.15.0.0/16
# fi

# echo '安装网络插件'
# url="https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
# k apply -f conf/weave.yaml

# echo '安装 dashboard'
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml
# echo '创建用户'
# https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md#creating-sample-user

