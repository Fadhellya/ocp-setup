# OpenShift Installation Guide (POC Setup)

## 📥 RHEL ISO Download Links
- **Helper/Bastion OS**:
  [RHEL 9.5 ISO](https://access.cdn.redhat.com/content/origin/files/sha256/0b/0bb7600c3187e89cebecfcfc73947eb48b539252ece8aab3fe04d010e8644ea9/rhel-9.5-x86_64-dvd.iso)
- **RHCOS for Master/Worker/Bootstrap**:
  [Download from Official RHCOS Repository](https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/)
- **Client For Manage OC**:
  [Download from Official Repository](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.19.0/)

---

## 🛠️ Bastion/Helper Configuration

### 🔧 Hardware
- 2 disks: 1 for OS, 1 for Registry

### 📡 Network
- Nameserver: IP Bastion
- Search Domain: `<cluster-name>.<base-domain>`
- Internet access required

### 📦 Required Packages
```bash
yum install -y bind bind-utils nfs-utils git haproxy httpd chrony
```

### 🔁 Clone Resource
```bash
git clone https://github.com/Fadhellya/ocp-setup.git
```

### 🔥 Disable Security Features (For POC)
```bash
systemctl disable firewalld --now
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
reboot
```

---

## 🧭 DNS Configuration
```bash
cp named.conf /etc/named.conf
cp named.conf.local /etc/named
mkdir -p /etc/named/zones
cp db* /etc/named/zones/
```
> Edit configuration files as needed:
> - `/etc/named.conf`
> - `/etc/named/named.conf.local`
> - `/etc/named/zones/db.ptr`
> - `/etc/named/zones/db.record`

```bash
systemctl enable named --now
```

---

## 🔀 HAProxy Configuration
```bash
cp haproxy.cfg /etc/haproxy/haproxy.cfg
# Edit /etc/haproxy/haproxy.cfg
systemctl enable haproxy --now
```

---

## 🕒 Chrony (NTP) Setup
```bash
vi /etc/chrony.conf
# Add `allow 0.0.0.0/0` and preferred NTP servers

systemctl enable chronyd --now
timedatectl
chronyc sources
```

---

## 💾 Disk Setup for Registry
```bash
lsblk
mkdir /storage
pvcreate /dev/sda
vgcreate storage /dev/sda
lvcreate -n nfs -L 299G storage
mkfs.xfs /dev/mapper/storage-nfs

# /etc/fstab
/dev/mapper/storage-nfs  /storage  xfs  defaults  0 0

mount -a
```

### 📡 NFS Setup
```bash
mkdir -p /storage/registry
# /etc/exports
/storage *(rw,root_squash)

systemctl enable nfs-server --now
exportfs -v
```

---

## 🔑 Generate SSH Key (For Injecting into Installer)
```bash
ssh-keygen
```

---

## 📦 OpenShift Installer
```bash
mkdir installer && cd installer
wget <openshift-client-url>
wget <openshift-installer-url>
tar xvf <downloads>
mv oc kubectl openshift-install /usr/local/bin
```

---

## 🧾 Install Config
```bash
mkdir /ocp
cp install-config.yaml /ocp
# Adjust /ocp/install-config.yaml accordingly
```

## 🚀 Create Manifests & Ignition Files
```bash
openshift-install create manifests --dir=/ocp
# Optional: Disable master node scheduling
vi /ocp/manifests/cluster-scheduler-02-config.yml
# Set `mastersSchedulable: false`

openshift-install create ignition-configs --dir=/ocp
cp *.ign /var/www/html
chmod 777 /var/www/html/*.ign
```

### ⚙️ Adjust Apache Port
```bash
sed -i 's/Listen 80/Listen 88/g' /etc/httpd/conf/httpd.conf
systemctl enable httpd --now
```

---

## 💻 Node VM Setup (Bootstrap, Master, Worker)
### 📌 Set IP, Gateway, DNS (Helper/Bastion IP), Search Domain

### Bootstrap:
```bash
coreos-installer install /dev/sda --copy-network --insecure-ignition --ignition-url http://<bastion-ip>:88/bootstrap.ign
reboot
```

### Master (Repeat 3 times):
```bash
coreos-installer install /dev/sda --copy-network --insecure-ignition --ignition-url http://<bastion-ip>:88/master.ign
reboot
```

### Worker:
```bash
coreos-installer install /dev/sda --copy-network --insecure-ignition --ignition-url http://<bastion-ip>:88/worker.ign
reboot
```

---

## 🔐 Join & Approve Nodes
```bash
export KUBECONFIG=/ocp/auth/kubeconfig
oc get csr | grep -i pending
oc adm certificate approve <csr-name>
oc get node
```

---

## 🔑 Console Access
```bash
oc whoami --show-console
cat /ocp/auth/kubeadmin-password
```

---

## 🔐 Create HTPasswd User
```bash
yum install htpasswd -y
touch users.htpasswd
htpasswd -c -B -b users.htpasswd admin P@ssw0rd
oc create secret generic <nama-secret> --from-file=htpasswd=<path> -n openshift-config
```

---

## ⚙️ Butane Installation
```bash
curl https://mirror.openshift.com/pub/openshift-v4/clients/butane/latest/butane --output butane
chmod +x butane
mv butane /usr/local/bin
```

### ✍️ Create Butane Files
```yaml
# 99-worker-ntp.bu
variant: openshift
version: 4.17.0
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
          server 0.id.pool.ntp.org iburst
          server 1.id.pool.ntp.org iburst
          server 2.id.pool.ntp.org iburst
          driftfile /var/lib/chrony/drift
          makestep 1.0 3
          rtcsync
          logdir /var/log/chrony
```

### 🔁 Copy for Master
```bash
cp 99-worker-ntp.bu 99-master-ntp.bu
# Edit label role menjadi: master
```

### 🔧 Convert Butane to YAML
```bash
butane 99-worker-ntp.bu -o ./99-worker-ntp.yaml
butane 99-master-ntp.bu -o ./99-master-ntp.yaml
oc apply -f 99-worker-ntp.yaml
oc apply -f 99-master-ntp.yaml
```

### 🔍 Cek Chrony Source di Bastion
```bash
chronyc sources
```

---


