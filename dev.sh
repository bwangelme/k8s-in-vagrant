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
    unlink /etc/systemd/system/containerd.service

    echo '安装　containerd'
    cd /code/k8s/k8s-in-vagrant/package
    tar Cxzvf /usr/local containerd-1.6.8-linux-amd64.tar.gz
    cp containerd.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable --now containerd
}

function install_runc() {
    cd /code/k8s/k8s-in-vagrant/package

    echo '安装　runc'
    install -m 755 runc.amd64 /usr/local/sbin/runc

    echo '安装　cni 插件'
    mkdir -p /opt/cni/bin
    tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz
}

install_runc
