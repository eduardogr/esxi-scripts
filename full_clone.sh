#!/bin/sh

# Author: Eduardo Garc�a Ruiz

# full_clone.sh:
# This script create a full clone of an existing virtual machine.

# Datastore path of the virtual machines of the ESXi
#DATASTOREPATH=/vmfs/volumes/datastore22/myfolder
DATASTOREPATH=/vmfs/volumes/datastore1

help(){
    echo Usage:
    echo \ \ $0 source_VM_name VMClon_Name
    echo
    echo Creates a full clone of an existing virtual machine.
    echo
    echo Options:
    echo \ \ -h \| --help : shows the usage.                               
    echo
}

fullCloneFromLinkedClone(){
    SOURCE_VM=$1
    VM_CLON=$2
    snapshot=$3
    
    mkdir $DATASTOREPATH/$VM_CLON
      
    vmkfstools -i $DATASTOREPATH/$SOURCE_VM/$SOURCE_VM-00000$snapshot.vmdk $DATASTOREPATH/$VM_CLON/$VM_CLON.vmdk -d eagerzeroedthick

    touch $DATASTOREPATH/$VM_CLON/$VM_CLON.vmsd # empty file
    
    cp $DATASTOREPATH/$SOURCE_VM/$SOURCE_VM.vmx  $DATASTOREPATH/$VM_CLON/$VM_CLON.vmx
    cp $DATASTOREPATH/$SOURCE_VM/$SOURCE_VM.vmxf $DATASTOREPATH/$VM_CLON/$VM_CLON.vmxf
    
    sedreplace "displayName = \"$SOURCE_VM\"" "displayName = \"$VM_CLON\""  "$VM_CLON/$VM_CLON.vmx"                                                   
    sedreplace "extendedConfigFile = \"$SOURCE_VM.vmxf\"" "extendedConfigFile = \"$VM_CLON.vmxf\""  "$VM_CLON/$VM_CLON.vmx"                           
    sedreplace "scsi0:0.fileName = \"$SOURCE_VM-00000$snapshot.vmdk\"" "scsi0:0.fileName = \"$VM_CLON.vmdk\""  "$VM_CLON/$VM_CLON.vmx"                               
    sedreplace "nvram = \"$SOURCE_VM.nvram\"" "nvram = \"$VM_CLON.nvram\"" "$VM_CLON/$VM_CLON.vmx"                                                    
    sedreplace "\"$SOURCE_VM-flat.vmdk\"" "\"$VM_CLON-flat.vmdk\"" "$VM_CLON/$VM_CLON.vmdk"

}

fullClone(){
    SOURCE_VM=$1
    VM_CLON=$2
    # Copiar recursivamente el directorio de la máquina origen a su destino (clon)   
    cp -R $DATASTOREPATH/$SOURCE_VM $DATASTOREPATH/$VM_CLON
    
    mv "$VM_CLON/$SOURCE_VM-flat.vmdk" "$VM_CLON/$VM_CLON-flat.vmdk"
    mv "$VM_CLON/$SOURCE_VM.vmdk" "$VM_CLON/$VM_CLON.vmdk"                                                                                        
    mv "$VM_CLON/$SOURCE_VM.vmsd" "$VM_CLON/$VM_CLON.vmsd"                                                                                        
    mv "$VM_CLON/$SOURCE_VM.vmx"  "$VM_CLON/$VM_CLON.vmx"                                                                                         
    mv "$VM_CLON/$SOURCE_VM.vmxf" "$VM_CLON/$VM_CLON.vmxf"

    sedreplace "displayName = \"$SOURCE_VM\"" "displayName = \"$VM_CLON\""  "$VM_CLON/$VM_CLON.vmx"                                               
    sedreplace "extendedConfigFile = \"$SOURCE_VM.vmxf\"" "extendedConfigFile = \"$VM_CLON.vmxf\""  "$VM_CLON/$VM_CLON.vmx"                       
    sedreplace "scsi0:0.fileName = \"$SOURCE_VM.vmdk\"" "scsi0:0.fileName = \"$VM_CLON.vmdk\""  "$VM_CLON/$VM_CLON.vmx"                           
    sedreplace "nvram = \"$SOURCE_VM.nvram\"" "nvram = \"$VM_CLON.nvram\"" "$VM_CLON/$VM_CLON.vmx"                                                
    sedreplace "\"$SOURCE_VM-flat.vmdk\"" "\"$VM_CLON-flat.vmdk\"" "$VM_CLON/$VM_CLON.vmdk"

}

# if the user requests help, the usage is shown.
if [ "$1" == "--help" -o "$1" == "-h" ];then
    help
    exit
fi

# if there is no arguments specified, the usage is shown.
if [ "$#" -le 1 ];then
   echo Insufficient arguments.
   help  
   exit
fi

#
# GETTING ARGUMENTS
#
SOURCE_VM=$1; shift
VM_CLON=$1; shift

# Incluir funciones que se proporcionan
source utilities.sh

# Comprobar si existe una maquina con el mismo nombre
if ( exist_vm $SOURCE_VM ); then

    # Encontrar la ubicación e identificadores de la máquina a copiar

    # Comprobar que existe la máquina origen a clonar
    # ... inutil, ya sabemos que existe en este punto, innecesario volver a comprobar
    # existe maquina con ese nombre => existe la m�quina origen a clonar !!
    
    # Comprobar que no existe la maquina clon
    if ( ! exist_vm $VM_CLON );then
        
        vmid=$(get_vmid $SOURCE_VM)
        deleted="N"
        if ( vim-cmd vmsvc/power.getstate $vmid | grep on > /dev/null); then
        
            echo You can\'t clone a powered-on virtual machine.
            read -p "Do you want to poweroff this virtual machine? [Y/N] " yn
            if [ "$yn" != "Y" -a "$yn" != "y"  ]; then
                echo 
                exit
            fi
            # Powering off virtual machine to create the full- clone
            vim-cmd vmsvc/power.off $vmid
            deleted="Y" 
        fi
        
        # Getting information about the SOURCE_VM to know the way we have to clone 
        wc $DATASTOREPATH/$SOURCE_VM/$SOURCE_VM.vmsd > answer.txt
        read lines words characters filename < answer.txt; rm answer.txt
        count=$(count_snapshots $vmid) 
       
        echo Cloning virtual machine... 
        
        if [ $count -gt 0 ]; then
        
            fullCloneFromLinkedClone $SOURCE_VM $VM_CLON $count
        
        elif [ $characters -gt 0  ]; then
        
            fullCloneFromLinkedClone $SOURCE_VM $VM_CLON 1
        
        else
        
            fullClone $SOURCE_VM $VM_CLON
        fi
       
        if [ "$deleted" == "Y" ]; then
            rm $DATASTOREPATH/$VM_CLON/*.log
        fi 
        
        # Registar la máquina clon (ESTO ES IMPRESCINDIBLE)                            
        vim-cmd solo/registervm $DATASTOREPATH/$VM_CLON/$VM_CLON.vmx > /dev/null
                                                                                                                                                                
        # Listar todas las maquinas para comprobar que el clon esta disponible        
        vim-cmd vmsvc/getallvms 
        
        # Powering on virtual machine to answer "I Copied It"
        vmid=$(get_vmid $VM_CLON)
        
        vim-cmd vmsvc/power.on $vmid &
        
        sleep 0.3
        
        msg=$(vim-cmd vmsvc/message $vmid)
        
        msgid=$(echo $msg | awk -F [:\ ] '{print $4}')
        
        vim-cmd vmsvc/message $vmid $msgid 2
        
        vim-cmd vmsvc/power.off $vmid
        
    else
        echo Virtual machine \"$VM_CLON\" already exists.
    fi
else
    echo Virtual machine \"$SOURCE_VM\" does not exist.
fi

