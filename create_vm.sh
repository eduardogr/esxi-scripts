#!/bin/sh

# Author: Eduardo García Ruiz

# create_vm.sh:
# This script creates a new virtual machine with minimal features.

# Datastore path of the virtual machines of the ESXi
# DATASTOREPATH=/vmfs/volumes/datastore22/myfolder
DATASTOREPATH=/vmfs/volumes/datastore1

help(){
    echo Usage:
    echo \ \  $0 vmName -g guestSO -s diskSize
    echo
    echo Creates a new virtual machine with minimal features, capable of being power on/off from vSphere client .
    echo
    echo Options:
    echo \ \ -g \| --guestSO : specific operating system for the guest.
    echo 
    echo \ \ -s \| --size    : size of virtual disk, it must be greater than 1M.
    echo
    echo \ \ -h \| --help    : shows the usage.
    echo
}

# if there is no arguments specified, the usage is shown.
if [ "$#" -eq 0 ];then
    echo Insufficient arguments.
    help
    exit
fi

# if the user requests help, the usage is shown.
if [ "$1" == "--help" -o "$1" == "-h" ];then
    help
    exit
fi

#
# GETTING ARGUMENTS ...
#
VM_NAME=$1; shift
guestGET=0
sizeGET=0

# Checking if the arguments are invalid
if [ $(($# % 2)) -ne 0 ]; then
    echo Incorrect number of arguments.
    help 
    exit

elif [ 0 -eq 0 ]; then
    checks=0
    for i in $@
    do
        val=$(echo $i | awk -F [a-zA-Z] '{print $1 }')
        if [ "$val" == "-" ]; then
            checks=$((checks+1))
        else
            checks=0
        fi
        
        if [ $checks -gt 1 ]; then
            echo Two consecutive flags.
            echo \ \ \ You have to set flag values!
            help
            exit
        fi
    done
fi


while [ $# -gt 0 ]; do
case "$1" in
    
    -g|--guestSO)
    shift # past argument=value
    guestSO=$1; shift
    guestGET=1
    ;;
    -s|--size)
    shift # past argument=value
    diskSize=$1; shift
    sizeGET=1
    ;;
    *)
    # unknown option avoiding
    echo Avoiding invalid flag: $1 $2
    shift; shift
    ;;
esac
done

# Incluir funciones que se proporcionan
source utilities.sh

# Comprobar si existe una maquina con el mismo nombre
if ( ! exist_vm $VM_NAME ); then
    echo "Creating Virtual Machine..."

    # Crear la nueva máquina (sugerencia: usar vim-cmd vmsvc/createdummyvm)
    vim-cmd vmsvc/createdummyvm $VM_NAME $DATASTOREPATH > /dev/null

    # Hay que añadir al fichero de configuración (.vmx) algún(os) campo(s) que es(son)
    # imprescindible(S) para arrancar la máquina
    # Sugerencia: intenta arrancar la máquina una vez creada y busca en el fichero
    #
    #	wmware.log por qué ha fallado el arranque
    # El campo que es necesario para arrancar la maquina es guestOS
    # en ocasiones este parametro ya es creado en el fichero $VM_NAME.vmx
    seddelete guestOS $VM_NAME/$VM_NAME.vmx
    echo 'guestOS="other"' >> $VM_NAME/$VM_NAME.vmx
     
    # Specifying guestSO
    if [ "$guestGET" == "1" ]; then
        sedreplace 'guestOS="other"' guestOS=\"$guestSO\" $VM_NAME/$VM_NAME.vmx                                       
        echo "Virtual machine created."                                                             
    fi
    
    # Extending disk size
    if [ "$sizeGET" == "1" ]; then    # minimum disk size 1048900
        path=$DATASTOREPATH/$VM_NAME/$VM_NAME.vmdk
        vmkfstools -X $diskSize $path -d eagerzeroedthick
    fi
    
    # Listar todas las maquinas para comprobar que se ha creado
    vim-cmd vmsvc/getallvms

else
    echo "Virtual machine already exists!"

fi

# Para terminar comprobar que la nueva máquina se puede arrancar
# desde el cliente de vSphere
