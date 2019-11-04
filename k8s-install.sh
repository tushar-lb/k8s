setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

swapoff -a

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum install kubeadm-1.14.1 kubelet-1.14.1 kubernetes-cni-0.6.0

systemctl start kubelet && systemctl enable kubelet
systemctl status kubelet

kubelet_status=`systemctl status kubelet | grep "running" | wc -l`
echo "$kubelet_status"
if [ $kubelet_status == 1 ]; then
   echo "Kubelet installed and running .."
else
   echo "Kubelet installed but not running.."
fi

