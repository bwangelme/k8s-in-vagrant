## Repo

https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner

## 通过 helm 安装 nfs-provisioner

```shell
切换到 nfs-storage namespace
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=192.168.56.13 --set nfs.path=/ssd/provisioner
```

```shell
ø> helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=192.168.56.13 --set nfs.path=/ssd/provisioner
NAME: nfs-subdir-external-provisioner
LAST DEPLOYED: Fri Apr  7 16:39:10 2023
NAMESPACE: nfs-storage
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

## 测试 provisioner 是否安装成功

- 安装测试的 pvc 和 pod

```shell
ø> k create -f test-claim.yaml -f test-pod.yaml
persistentvolumeclaim/test-claim created
pod/test-pod created
```

- 在 nfs server 的目录内检查文件是否创建成功

```shell
vagrant@k8s-node3:/ssd/provisioner$ ls -al nfs-storage-test-claim-pvc-7fe49895-05b1-4743-b435-aee943953b6f/
total 8
drwxrwxrwx 2 root    root    4096 Apr  7 08:48 .
drwxr-xr-x 3 vagrant vagrant 4096 Apr  7 08:48 ..
-rw-r--r-- 1 root    root       0 Apr  7 08:48 SUCCESS
```

- 查看测试 pod 及 pvc

```shell
ø> k get pod test-pod
NAME                                               READY   STATUS      RESTARTS   AGE
test-pod                                           0/1     Completed   0          2m38s
ø> k get pvc
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
test-claim   Bound    pvc-7fe49895-05b1-4743-b435-aee943953b6f   1Mi        RWX            nfs-client     3m
```

- 删除测试资源

```shell
ø> k delete -f test-pod.yaml -f test-claim.yaml
pod "test-pod" deleted
persistentvolumeclaim "test-claim" deleted
```