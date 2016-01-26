#!/bin/sh

# Author: Eduardo García Ruiz

# linked_clone.sh:
# This script creates a linked clone of an existing virtual machine.

# Datastore path of the virtual machines of the ESXi
#DATASTOREPATH=/vmfs/volumes/datastore22/myfolder
DATASTOREPATH=/vmfs/volumes/datastore1

help(){
    echo Usage:
    echo \ \ $0 source_VN_Name VMClon_Name
    echo
    echo Creates a linked clone of an existing virtual machine.
    echo 
    echo Options:     
    echo \ \ -h \| --help : shows the usage.
    echo
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
      
# Comprobar si existe una maquina origen con el mismo nombre
if ( exist_vm $SOURCE_VM ); then

    # Encontrar la ubicacion e identificadores de la maquina a copiar
    
    # Comprobar que no existe la maquina clon
    if ( ! exist_vm $VM_CLON );then
        
        vmid=$(get_vmid $SOURCE_VM)
        if ( vim-cmd vmsvc/power.getstate $vmid | grep on > /dev/null); then
        
            echo You can\'t clone a powered-on virtual machine.
            read -p "Do you want to poweroff this virtual machine? [Y/N] " yn
            if [ "$yn" != "Y" -a "$yn" != "y"  ]; then
                exit
            fi
            # Powering off the virtual machine to start to clone it.
            vim-cmd vmsvc/power.off $vmid
        fi
        echo Cloning virtual machine...
        
        # Comprobar que la maquina origen tiene uno y solo un snapshot
        vmid=$(get_vmid $SOURCE_VM) 
        numSnapshot=$(count_snapshots $vmid)
        next=$((numSnapshot+1))
        
        # Crear snapshot de la maquina origen
        vim-cmd vmsvc/snapshot.create $vmid $VM_CLON "snapshot generated" 1 1 
        
        # Creamos la carpeta del futuro linked clone
        mkdir $DATASTOREPATH/$VM_CLON
         
        # Copiar los ficheros de definicion de la maquina origen a la maquina clon:
        #  - fichero de configuracion: .vmx,
        #  - fichero de definición del disco: .vmdk
        #  - fichero delta del snapshot
        #  Nota: es necesario averiguar los nombres de estos ficheros
        #   a partir del fichero de configuración
        cp $DATASTOREPATH/$SOURCE_VM/$SOURCE_VM.vmx $DATASTOREPATH/$VM_CLON/$VM_CLON.vmx
        cp $DATASTOREPATH/$SOURCE_VM/$SOURCE_VM-00000$next-delta.vmdk $DATASTOREPATH/$VM_CLON/$VM_CLON-000001-delta.vmdk
        cp $DATASTOREPATH/$SOURCE_VM/$SOURCE_VM-00000$next.vmdk $DATASTOREPATH/$VM_CLON/$VM_CLON-000001.vmdk
       
        # Sustituir los nombres de ficheros y sus respectivas referencias dentro de
        # estos por el nombre clon
        # ¡Atenion! Esto requiere un pequeño parsing del contenido
        # para sustituir aquellos campos de los ficheros de configuracion que hacen
        # referencias a los ficheros
        sedreplace "extendedConfigFile = \"$SOURCE_VM.vmxf\"" "extendedConfigFile = \"$VM_CLON.vmxf\""  "$DATASTOREPATH/$VM_CLON/$VM_CLON.vmx"
        sedreplace "displayName = \"$SOURCE_VM\"" "displayName = \"$VM_CLON\""  "$DATASTOREPATH/$VM_CLON/$VM_CLON.vmx"
        sedreplace "scsi0:0.fileName = \"$SOURCE_VM-00000$next.vmdk\"" "scsi0:0.fileName = \"$VM_CLON-000001.vmdk\""  "$DATASTOREPATH/$VM_CLON/$VM_CLON.vmx"
        sedreplace "nvram = \"$SOURCE_VM.nvram\"" "nvram = \"$VM_CLON.nvram\""  "$DATASTOREPATH/$VM_CLON/$VM_CLON.vmx"
        
        # Cambiar la referencia del “parent disk” del ficherodefinicion del disco
        # que debe de apuntar al de la maquina origen (en el directorio ..)
        # Dependiendo de si este es el primer Snapshot del disco o no, el "parent disk" sera de una manera u otra
        if [ $next -eq 1 ]; then
            sed -i "s|$SOURCE_VM.vmdk|$DATASTOREPATH\/$SOURCE_VM\/$SOURCE_VM.vmdk|g" $DATASTOREPATH/$VM_CLON/$VM_CLON-000001.vmdk
        else
            sed -i "s|$SOURCE_VM-00000$numSnapshot.vmdk|$DATASTOREPATH\/$SOURCE_VM\/$SOURCE_VM-00000$numSnapshot.vmdk|g" $DATASTOREPATH/$VM_CLON/$VM_CLON-000001.vmdk
        fi
        sedreplace "$SOURCE_VM-00000$next-delta.vmdk" "$VM_CLON-000001-delta.vmdk" $DATASTOREPATH/$VM_CLON/$VM_CLON-000001.vmdk
         
        # Generar un fichero .vmsd (con nombre del clon) en el que se indica que
        # es una maquina clonada.
        #
        # Coge un fichero .vsmd de un clon generado con VMware Workstation para ver
        # el formato de este archivo
        #
        # Si no se genera el fichero .vmsd, al destruir el clon tambien se borra el
        # disco base del snapshot, lo cual no es deseable ya que pertenece a la maquina
        # origen
        touch $DATASTOREPATH/$VM_CLON/$VM_CLON.vmsd
        echo .encoding = \"UTF-8\" >> $DATASTOREPATH/$VM_CLON/$VM_CLON.vmsd 
        echo cloneOf0 = \"$DATASTOREPATH/$SOURCE_VM/$SOURCE_VM.vmx\" >> $DATASTOREPATH/$VM_CLON/$VM_CLON.vmsd 
        echo numCloneOf = \"1\" >> $DATASTOREPATH/$VM_CLON/$VM_CLON.vmsd 
        echo sentinel0 = \"$DATASTOREPATH/$VM_CLON/$VM_CLON.vmdk\" >> $DATASTOREPATH/$VM_CLON/$VM_CLON.vmsd   
        echo numSentinels = \"1\" >> $DATASTOREPATH/$VM_CLON/$VM_CLON.vmsd 
        
        # Una vez que el directorio clon contiene todos los ficheros necesarios
        # hay que registrar la máquina clon (ESTO ES IMPRESCINDIBLE)
        vim-cmd solo/registervm $DATASTOREPATH/$VM_CLON/$VM_CLON.vmx > /dev/null
         
        # Listar todas las máquinas para comprobar que el clon esa disponible
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
    echo Virtual machine \"$SOURCE_VM\"  does not exist.
fi
#Para terminar arranca el clon desde el cliente de vSphere
