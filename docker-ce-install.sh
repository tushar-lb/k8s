VERSION="18.03.0.ce"
echo "Installing docker $VERSION"

sudo yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine

existingdockercli=`rpm -qa | grep docker`
echo "Existing docker cli: $existingdockercli"

sudo rpm -e $existingdockercli

sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install -y docker-ce-$VERSION

systemctl enable docker
systemctl start docker
systemctl status docker 

docker_status=`systemctl status docker | grep "running" | wc -l`
echo "$docker_status"
if [ $docker_status == 1 ]; then
   echo "Docker installed and running .."
else
   echo "Docker installed but not running.."
fi

