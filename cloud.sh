#!/bin/bash


mkdir /var/lib/vz/images/9999 

cd /var/lib/vz/images/9999

wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

export IMAGES_PATH="/var/lib/vz/images/9999"

virt-customize --install qemu-guest-agent -a "${IMAGES_PATH}/debian-12-generic-amd64.qcow2" 

# export IMAGES_PATH="/var/lib/vz/images/9999" # defines the path where the images will be stored and change the path to it.

cd ${IMAGES_PATH}

## Debian 12 (bookworm)

## https://cloud-images.ubuntu.com/

# wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

export QEMU_CPU_MODEL="host" # Specifies the CPU model to be used for the VM according your environment and the desired CPU capabilities.
export VM_CPU_SOCKETS=1
export VM_CPU_CORES=4
export VM_MEMORY=4098
export VM_STORAGE="local" # Assigns the VM to a specific resource pool for management.

export CLOUD_INIT_USER="root" # Specifies the username to be created using Cloud-init.
export CLOUD_INIT_SSHKEY="/root/.ssh/id_rsa.pub" # Provides the path to the SSH public key for the user.
export CLOUD_INIT_IP="dhcp"
#export CLOUD_INIT_NAMESERVER="192.168.1.1"
#export CLOUD_INIT_SEARCHDOMAIN=".lan"

export TEMPLATE_ID=9999
export VM_NAME="debian12-cloud"
export VM_DISK_IMAGE="${IMAGES_PATH}/debian-12-generic-amd64.qcow2"

####

# Create VM. Change the cpu model
qm create ${TEMPLATE_ID} --name ${VM_NAME} --cpu ${QEMU_CPU_MODEL} --sockets ${VM_CPU_SOCKETS} --cores ${VM_CPU_CORES} --memory ${VM_MEMORY} --numa 1 --net0 virtio,bridge=vmbr0 --ostype l26 -machine q35 --agent 1 --scsihw virtio-scsi-single

# Start at boot
qm set ${TEMPLATE_ID} -onboot 1

# Import Disk
qm set ${TEMPLATE_ID} --scsi0 ${VM_STORAGE}:0,discard=on,ssd=1,format=qcow2,import-from=${VM_DISK_IMAGE}

# Add Cloud-Init CD-ROM drive. This enables the VM to receive customization instructions during boot.
qm set ${TEMPLATE_ID} --ide2 ${VM_STORAGE}:cloudinit --boot order=scsi0

# Cloud-init network-data
qm set ${TEMPLATE_ID} --ipconfig0 ip=${CLOUD_INIT_IP} #--nameserver ${CLOUD_INIT_NAMESERVER} --searchdomain ${CLOUD_INIT_SEARCHDOMAIN}

# Cloud-init user-data
qm set ${TEMPLATE_ID} --ciupgrade 1 --ciuser ${CLOUD_INIT_USER} --sshkeys ${CLOUD_INIT_SSHKEY}

#Resize the disk to 10G
qm disk resize ${TEMPLATE_ID} scsi0 10G

# Cloud-init regenerate ISO image, ensuring that the VM will properly initialize with the desired parameters.
qm cloudinit update ${TEMPLATE_ID}

#####

qm set ${TEMPLATE_ID} --name "${VM_NAME}-Template"

qm template ${TEMPLATE_ID}
