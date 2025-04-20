rhel download link for bastion/helper
https://access.cdn.redhat.com/content/origin/files/sha256/0b/0bb7600c3187e89cebecfcfc73947eb48b539252ece8aab3fe04d010e8644ea9/rhel-9.5-x86_64-dvd.iso?user=4c386a3b681895c19e7f5543fcdd2276&_auth_=1745159631_ae56ba0108456f0205f30218cb4a3536

rhel core-os link for master/worker/bootsrap

bastion/helper configuration
2 disk 1 os 1 registry
check disk for registry

nameserver : ip helper
search domain: <ocpname>.<basedomain>
akses internet
package req:
yum install -y bind bind-utils nfs-utils git haproxy httpd chrony
clone resource install : 
git clone https://github.com/Fadhellya/ocp-setup.git
matikan firewall
systemctl disable firewalld --now
matikan selinux
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
reboot

dns config
cp named.conf /etc/named.conf
cp named.conf.local /etc/named
mkdir -p /etc/named/zones
cp db* /etc/named/zones/

/etc/named.conf config adjust
/etc/named/named.conf.local config adjust
/etc/named/zones/db.ptr config adjust
/etc/named/zones/db.record config adjust

aktifkan dns
systemctl enable named --now

haproxy config
cp haproxy.cfg /etc/haproxy/haproxy.cfg
/etc/haproxy/haproxy.cfg config adjust

aktifkan haproxy
systemctl enable haproxy --now

ping google.com

chrony config
vi /etc/chrony.conf adjust config (allow 0.0.0.0/0 dan <serverindo> iburst)

aktifkan chrony
systemctl enable chronyd --now
timedatectl
chrony source

disk config for registry
lsblk (output disk kosong /dev/sda)
mkdir /storage
pvcreate /dev/sda (disk kosong)
vgcreate storage /dev/sda
lvcreate -n nfs -L 299G storage
mkfs.xfs /dev/mapper/storage-nfs
/etc/fstab adjust config (/dev/mapper/storage-nfs  storage  xfs  defaults  0 0)
mount -a

nfs config for registry
mkdir -p /storage/registry
/etc/exports adjust config ( /storage *(rw,root_squash) )
systemctl enable nfs-server --now
exportsfs -v

private key config untuk inject di installer
ssh-keygen

oc execute install
mkdir installer
cd installer
wget mirror openshift installer dan client dari link (https://mirror.openshift.com/pub/openshift-v4/clients/ocp/) adjust version
tar xvf openshift-client dan openshift-installer
echo $PATH
mv oc kubectl openshift-install /usr/local/bin

konfigurasi install-config
mkdir /ocp
cp install-config.yaml /ocp
cd /ocp
/ocp/install-config.yaml adjust config

install openshift
openshift-install create manifests --dir=/ocp
/ocp/manifests/cluster-scheduler adjust config (masterSchedule = false jika tidak ingin pod apps di running di masternode)
openshift-install create ignition-configs --dir=/ocp
cp *.ign /var/www/html
chmod 777 /var/www/html/*.ign

httpd config
sed -i 's/Listen 80/Listen 88/g' /etc/httpd/conf/httpd.conf
systemctl enable httpd --now

disetiap vm node terutama odf tambahkan parameter (diskEnableUUID = TRUE)

bootstrap vm config
ip
gateway
nameserver : helper/bastion ip
searchdomain: <cluster-name>.<basedomain>
bash
ping google.com
sudo coreos-installer install /dev/sda --copy-network --insecure-ignition --ignition-url http://<ipbastion/helper>:88/bootstrap.ign
reboot

check haproxy (ip bastion/helper:9000)

masternode untuk tiga2nya
ip
gateway
nameserver : helper/bastion ip
searchdomain: <cluster-name>.<basedomain>
bash
ping google.com
sudo coreos-installer install /dev/sda --copy-network --insecure-ignition --ignition-url http://<ipbastion/helper>:88/master.ign
ulangi
reboot serentak master

tunggu up 3 master check di haproxy

login ocp
export KUBECONFIG=/ocp/auth/kubeconfig
oc get node
oc get co
oc get csr

workernode
ip
gateway
nameserver : helper/bastion ip
searchdomain: <cluster-name>.<basedomain>
bash
ping google.com
sudo coreos-installer install /dev/sda --copy-network --insecure-ignition --ignition-url http://<ipbastion/helper>:88/worker.ign
reboot


di bastion
oc get csr | grep -i pending
oc get csr for approve
oc get node
oc whoami --show-console
login kubeadm
pw = cat /ocp/auth/kubeadmin-password
yum install htpasswd -y
touch users.htpasswd
htpasswd -c -B -b users.htpasswd admin P@ssw0rd
oc create secret generic <nama_secret> --from-file=htpasswd=<path_to_users.htpasswd> -n openshift-config


butane installation
curl https://mirror.openshift.com/pub/openshift-v4/clients/butane/latest/butane --output butane
chmod +x butane
cp butane /usr/local/bin


create butane file : 
vi 99-worker-ntp.bu
script : 

variant: openshift
version: 4.17.0 <adjust version>
metadata:
  name: 99-worker-ntp
  labels:
    machineconfiguration.openshift.io/role: worker
openshift:
  kernel_arguments:
    - loglevel=7
storage:
  files:
    - path: /etc/chrony.conf
      mode: 0644
      overwrite: true
      contents:
        inline: |
          <sesuai ntp server indo> iburst (bsa 3)
          driftfile /var/lib/chrony/drift
          makestep 1.0 3
          rtcsync
          logdir /var/log/chrony

untuk master cukup di copy saja file worker
cp 99-worker-ntp.bu 99-master-ntp.bu 
edit file master dan cukup ganti role saja menjadi master

butane 99-worker-ntp.bu -o ./99-worker-ntp.yaml
butane 99-master-ntp.bu -o ./99-master-ntp.yaml

oc apply -f 99-worker-ntp.yaml
oc apply -f 99-master-ntp.yaml

oc get nodes

config chrony di bastion/helper
chronyc sources



