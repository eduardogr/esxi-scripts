#!/bin/sh

# Author: Eduardo García Ruiz

# delete_vm.sh:
# This script deletes an existing virtual machine.

# Datastore path of the virtual machines of the ESXi
# DATASTOREPATH=/vmfs/volumes/datastore22/myfolder
DATASTOREPATH=/vmfs/volumes/datastore1

help(){
    echo Usage:
    echo \ \ $0 vmName
    echo
    echo It deletes a existing virtual machine.
    echo 
    echo Options:
    echo \ \ -h \| --help : shows the usage.
    echo
}

# If there is no argument specified, the usage is shown.
if [ "$#" -eq 0 ];then
    echo Insufficient arguments.
    help
    exit
fi

# If the user requests help, the usage is shown.
if [ "$1" == "--help" -o "$1" == "-h" ];then
    help
    exit
fi

#
# GETTING ARGUMENTS ...
#
VM_NAME=$1; shift
                                                               
# Incluir funciones que se proporcionan
source utilities.sh

# Comprobar si existe la máquina en cuestión
if ( exist_vm $VM_NAME ); then

    # Solicitar confirmacion de borrado
    read -p "Do you wish to delete this virtual machine? [Y/N] " yn
    if [ "$yn" != "Y" -a "$yn" != "y"  ]; then
        echo The virtual machine was not deleted.
        echo
        exit
    fi
    
    vmid=$(get_vmid $VM_NAME)

    # Powering off virtual machine
    if ( vim-cmd vmsvc/power.getstate $vmid | grep on > /dev/null ); then
        vim-cmd vmsvc/power.off $vmid
    fi
    
    echo Deleting virtual machine...
    vim-cmd vmsvc/destroy $vmid
    
    # Showing the list of the existing virtual machines.
    vim-cmd vmsvc/getallvms
    
else
    echo "Virtual Machine \"$VM_NAME\" does not exist!"
fi
