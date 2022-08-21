## TODO

- 2022-08-17 安装的 kubeadm 版本是 1.24.3，此时默认的 cri 后端是 containerd，需要重新设置一下

https://mdnice.com/writing/3e3ec25bfa464049ae173c31a6d98cf8
https://kubernetes.io/zh-cn/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

下载　k8s 的镜像失败，尝试给　containerd 设置了　http 代理，但是拉取镜像依然失败。

可能存在其他的墙的策略，还是使用　azure 的代理镜像


containerd 拉取镜像是在客户端拉取的，所以代理的环境变量需要设置到客户端

## toread

https://cloud.tencent.com/developer/article/1922693

## containerd 设置代理

- [ctr 需要在客户端设置代理](https://github.com/containerd/cri/issues/1169#issuecomment-501376676)
- [containerd cli 说明](https://github.com/containerd/containerd/blob/main/docs/getting-started.md#interacting-with-containerd-via-cli)
