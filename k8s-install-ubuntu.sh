sudo apt-get update -y

sudo apt-get install -y openssh-server

apt-get update -y

apt-get update && apt-get install -y apt-transport-https curl

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update -y

apt-get install -y kubelet kubeadm kubectl

echo 'Environment="cgroup-driver=systemd/cgroup-driver=cgroupfs"' >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

systemctl daemon-reload

systemctl start kubelet && systemctl enable kubelet
systemctl status kubelet

kubelet_status=`systemctl status kubelet | grep "running" | wc -l`
echo "$kubelet_status"
if [ $kubelet_status == 1 ]; then
   echo "Kubelet installed and running .."
else
   echo "Kubelet installed but not running.."
fi
