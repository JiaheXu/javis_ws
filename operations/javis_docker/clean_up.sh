sudo -i
mkdir -p /external/var/lib/docker
cp -r /var/lib/docker/* /external/var/lib/docker

chown javis:javis /external/var/lib/docker
mv /var/lib/docker /var/lib/docker_old
ln -s /external/var/lib/docker /var/lib/docker
