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

function mkdir_if_not_exist() {
    local _dir=$1
    if [[ ! -d $_dir ]]; then
        mkdir -p $_dir
        echo "创建目录　$_dir"
    fi
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
