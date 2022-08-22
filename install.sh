#!/bin/bash
#
# Author: bwangel<bwangel.me@gmail.com>
# Date: 5,24,2020 16:38

function mkdir_if_not_exist() {
    local _dir=$1
    if [[ ! -d $_dir ]]; then
        mkdir -p $_dir
        echo "创建目录　$_dir"
    fi
}

function enable_apt_proxy()
{
    echo '打开 apt 代理'
    cat >> /etc/apt/apt.conf.d/proxy.conf <<EOF
Acquire {
    HTTP::proxy "http://10.8.0.1:8118";
    HTTPS::proxy "http://10.8.0.1:8118";
}
EOF
}

function disable_apt_proxy()
{
    echo "关闭 apt 代理"
    rm -v /etc/apt/apt.conf.d/proxy.conf
}

# ----------------------
# start setup the k8s node
# ----------------------
export DEBIAN_FRONTEND=noninteractive

function setup_apt() {
    echo "修改 apt 源"
    sed -i 's/http:\/\/archive.ubuntu.com/https:\/\/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

}

function setup_k8s_dns() {
    grep 'hostname config for k8s' /etc/hosts
    if [[ $? == 1 ]]; then
        echo '设置主机名的解析'
cat >> /etc/hosts <<EOF
# hostname config for k8s
192.168.56.11 k8s-node1
192.168.56.12 k8s-node2
192.168.56.13 k8s-node3
EOF
    fi
}

function apt_install_essential() {
    echo '安装必要的一些系统工具'
    apt-get update && apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2 gnupg lsb-release
}

function install_k8s() {
    echo '安装 Kubernetes'
    export HTTP_PROXY='10.8.0.1:8118' HTTPS_PROXY='10.8.0.1:8118'
    export NO_PROXY=localhost,127.0.0.0/8,10.0.0.0/8,172.17.0.0/16,192.168.0.0/24

    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    unset HTTP_PROXY HTTPS_PROXY
cat >/etc/apt/sources.list.d/kubernetes.list <<EOF
deb https://packages.cloud.google.com/apt/ kubernetes-xenial main
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

    enable_apt_proxy
    apt-get update && apt-get install -y kubelet kubeadm kubectl containerd.io
    echo '锁定 kubelet kubeadm kubectl 的版本'
    apt-mark hold kubelet kubeadm kubectl
    disable_apt_proxy
}

function disable_swap() {
    echo '关闭 Swap'
    swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab
}


# 这在 ubuntu 下不生效，ubuntu 似乎没有打开 selinux
function disable_selinux() {
    echo "关闭 selinux"
    setenforce 0
    sed -i s/SELINUX=enforcing/SELINUX=disabled/ /etc/selinux/config
}

# 存在一个报错
# sysctl: setting key "net.ipv4.conf.all.promote_secondaries": Invalid argument
# 但这似乎和我们增加的配置无关，暂时忽略它
function trans_iptables() {
    echo '将桥接的IPv4流量传递到iptables的链'

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

    modprobe overlay
    modprobe br_netfilter

cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
    sysctl --system
}

function install_containerd() {
    echo '卸载 apt containerd'
    apt-get remove -y containerd docker.io
    rm -vf /etc/systemd/system/containerd.service
    rm -rvf /etc/systemd/system/containerd.service.d

    echo '安装　containerd'
    cd /code/k8s/k8s-in-vagrant/containerd
    tar Cxzvf /usr/local containerd-1.6.8-linux-amd64.tar.gz

    echo '设置　containerd service 文件'
    cp -v containerd.service /etc/systemd/system/

    systemctl daemon-reload
    systemctl enable --now containerd
    systemctl restart containerd
}

function install_runc() {
    cd /code/k8s/k8s-in-vagrant/containerd

    echo '安装　runc'
    install -m 755 runc.amd64 /usr/local/sbin/runc

    echo '安装　cni 插件'
    mkdir -p /opt/cni/bin
    tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz
}

function setup_containerd_config() {
    echo '配置 containerd 的配置文件'

    mkdir_if_not_exist /etc/containerd
    cd /code/k8s/k8s-in-vagrant/containerd
    cp config.toml /etc/containerd/config.toml
    cp crictl.yaml /etc/crictl.yaml
    systemctl restart containerd
}

function pull_k8s_image() {
    echo '拉取　k8s 所需的镜像'
    kubeadm config images pull
}

# echo '启动k8s'
# if [[ $1 == 1 ]];then
#     sudo kubeadm init --apiserver-advertise-address 192.168.56.11 --pod-network-cidr=10.244.0.0/16
# fi

# 安装 calico
# https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart
# https://www.golinuxcloud.com/calico-kubernetes/
# k apply -f k8s-cni/calico.yaml
# $ kubectl creaet -f k8s-cni/nginx-pod.yaml
# $ kubectl get pods -o wide
# NAME    READY   STATUS    RESTARTS   AGE   IP               NODE        NOMINATED NODE   READINESS GATES
# nginx   1/1     Running   0          67s   10.244.169.129   k8s-node2   <none>           <none>

# 去掉　master 节点的　taint
# 让 pod 能够调度到控制平面上
# kubectl taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-

# 安装 ingress
# k apply -f ingress-nginx/deploy.yaml

# echo '安装 dashboard'
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml
# echo '创建用户'
# https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md#creating-sample-user

