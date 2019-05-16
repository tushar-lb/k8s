#!/bin/sh
#
# Script installs the Kubernetes CRI cluster  (i.e. no docker, only containerd support)
 
set -euf
 
# EDIT to select containerd's version.
# TODO: Specify IPs of ALL nodes in your cluster (including local)
HOSTS="node-1-ip-addr node-2-ip-addr node-3-ip-addr node-4-ip-addr"
NET=flannel    # or weave (see below)
 
# see available versions via: curl -fsSL https://storage.googleapis.com/cri-containerd-release/ | xmllint -format - | tr '<>' :: | awk -F: '/:Key:cri-containerd-cni-[0-9]/{print $3}'
#CONTAINERD_VERSION=1.1.0-rc.0  # default
CONTAINERD_VERSION=1.1.3
 
myIP=$(hostname -I | xargs -n1 | egrep -v "^10.|^172.|^127." | head -1)
PATH=$PATH:/usr/local/bin
SUDO=sudo ; [ $(id -u) -eq 0 ] && SUDO=""
 
# Set up passwordless SSH (local)
umask 077
[ ! -f $HOME/.ssh/id_rsa ] && ssh-keygen -b 2048 -t rsa -N "" -f $HOME/.ssh/id_rsa
grep -f $HOME/.ssh/id_rsa.pub $HOME/.ssh/authorized_keys >/dev/null 2>&1 || cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
ssh -o StrictHostKeyChecking=no $myIP echo
umask 022
# .. spread SSH-conf to other nodes  (expect password-prompts)
for h in $HOSTS; do
    [ "x$h" = "x$myIP" ] || rsync -avzPp -e 'ssh -o StrictHostKeyChecking=no' $HOME/.ssh $h:$HOME/
done
# .. validate working OK + resync known_hosts  (expect no password-prompts this time)
for h in $HOSTS; do
    [ "x$h" = "x$myIP" ] || rsync -avzPp $HOME/.ssh $h:$HOME/
done
 
# Get Ansible (see https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
if [ -d /etc/apt/sources.list.d ]; then # ----> Ubuntu/Debian distro
    $SUDO apt-get install -y software-properties-common
    $SUDO apt-add-repository -y ppa:ansible/ansible
    $SUDO apt-get update
    $SUDO apt-get install -y ansible git
 
elif [ -d /etc/yum.repos.d ]; then      # ----> CentOS/RHEL distro
    # $SUDO yum clean all ; $SUDO yum makecache all
    $SUDO yum install -y ansible git
 
else    # ------------------------------------> (unsuported)
    echo "Your platform is not supported" >&2
    exit 1
fi
 
# Get CRI-O ansible pre-setup (see https://github.com/containerd/cri/blob/v1.11.1/contrib/ansible/README.md)
if [ ! -f ./cri_git/contrib/ansible/hosts ]; then
    git clone https://github.com/containerd/cri cri_git
    echo $HOSTS | xargs -n1 > ./cri_git/contrib/ansible/hosts
    sed -i.orig -e "s/containerd_release_version: .*/containerd_release_version: $CONTAINERD_VERSION/" \
        cri_git/contrib/ansible/vars/vars.yaml
else
    echo "File ./cri_git/contrib/ansible/hosts exists -- skipping git clone"
fi
 
cd cri_git/contrib/ansible
$SUDO ansible-playbook -i hosts cri-containerd.yaml
 
# Wipe kubelet env-file, so it does not mess up $KUBELET_EXTRA_ARGS from /etc/systemd/system/kubelet.service.d/10-kubeadm.conf (by ansible)
# :>! /etc/default/kubelet
$SUDO cat /dev/null > /etc/default/kubelet
 
KUBEADM_OPTS="--ignore-preflight-errors=all" # "--skip-preflight-checks"
KUBEADM_INIT_OPTS="$KUBEADM_OPTS"
NET_URL=""
 
case "$NET" in
    flannel)
        KUBEADM_INIT_OPTS="$KUBEADM_INIT_OPTS --pod-network-cidr=10.244.0.0/16"
        NET_URL=https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
        ;;
 
    weave)
        myCIDR=$(echo $myIP | awk -F. '{print $1"."$2"."$3".0/24"}')
        KUBEADM_INIT_OPTS="$KUBEADM_INIT_OPTS --pod-network-cidr $myCIDR"
        NET_URL="https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
        ;;
 
    *)
        echo "$0: No support for network-type '$NET'" >&2
        exit 1 ;;
esac
 
# turn off swap ( if any )
if grep -q swap /etc/fstab; then
    awk '/swap/{print $1}' /etc/fstab | xargs -n1 swapoff || /bin/true
    sed -i -e 's/.*swap.*/# \0  # VAGRANT/' /etc/fstab
fi
 
# Install master
$SUDO kubeadm init $KUBEADM_INIT_OPTS --apiserver-advertise-address $myIP --cri-socket=/run/containerd/containerd.sock
 
$SUDO install -D -m 600 -o $(id -u) -g $(id -g) /etc/kubernetes/admin.conf $HOME/.kube/config
 
# Set up network
kubectl apply -n kube-system -f "$NET_URL"
 
# Set up others
TOK=$($SUDO kubeadm token list | awk '/authentication/{print $1}' | tail -1)
for h in $HOSTS; do
    if [ "x$h" != "x$myIP" ]; then
        echo ":: installing node $h ..."
        ssh $h "$SUDO cat /dev/null > /etc/default/kubelet ; $SUDO kubeadm join $myIP:6443 --token $TOK $KUBEADM_OPTS --discovery-token-unsafe-skip-ca-verification --cri-socket=/run/containerd/containerd.sock"
        tar cfPp - $HOME/.kube/config | ssh $h tar xfvPp -
    fi
done
 
# Validate running CRI
kubectl get nodes -o wide
for h in $HOSTS; do
    ssh $h $SUDO crictl ps 2>&1 | sed -e "s/^/$h | /"
done
