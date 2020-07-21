#Arquitecturas virtuales: prácticas con vsphere 5.1 ESXi
#by *egc Dic/2013

#Algunas funciones utiles

#Suposiciones: 
# - Evitar espacios y otros caracteres no alfanumericos en los nombres de las maquinas 

#Imprime la primera linea del listado de maquinas registradas que lista una maquina con nombre dado
list_vm() { vim-cmd vmsvc/getallvms | tail -n +2 | egrep "[[:digit:]]+[[:space:]]+$1[[:space:]]"; } #Uso: list_vm vm_name

#Chequea si una maquina existe, a partir de su nombre (usar en un if, o consultar $? inmediatamente tras su uso)
exist_vm() { list_vm $1 >/dev/null ; } #Uso: exist_vm vm_name

#Imprime el vmid a partir del nombre de la maquina (ojo! no poner blancos en los nombres de las maquinas)
get_vmid() { list_vm $1 | awk '{print $1}'; } #Uso: get_vmid vm_name

#Imprime el número de snapshots de una maquina
count_snapshots() { vim-cmd vmsvc/snapshot.get $1 | grep "Snapshot Id" | wc -l; } #Uso: count_snapshots vmid

#Imprime la ruta del datastore donde se encuentra la maquina 
get_vm_datastore_path() { vim-cmd vmsvc/get.datastores $1 | awk '/url/{print $2}'; } #Uso get_vm_datastore_path vmid

#Imprime el fichero vmx dentro del path del datastore 
get_vm_vmx_rel() { vim-cmd vmsvc/getallvms | tail -n +2 | awk '/^'$1'[[:space:]]/{print $4}'; } #Uso get_vm_vmx vmid

#Imprime el fichero vmx (de la forma "vmname.vmx")
get_vm_vmx() {  (vm_path=`get_vm_datastore_path $1` #Esto es la ruta del data store
                vm_vmx_rel=`get_vm_vmx_rel $1`      #Esto es de la forma "vmname/vmname.vmx" relativo al datastore 
                vm_vmxfull=$vm_path/$vm_vmx_rel     #Fichero vmname.vmx con el path absoluto completo
                vm_vmx=`basename $vm_vmxfull`       #Ahora esto es vmname.vmx 
		        echo $vm_vmx)
    	      } #Uso get_vm_vmx vmid

#Imprime la ruta absoluta donde esta el fichero .vmx (de la forma "/vmfs/.../vmname/")
get_vm_dir() {  (vm_path=`get_vm_datastore_path $1` #Esto es la ruta del data store
                vm_vmx_rel=`get_vm_vmx_rel $1`      #Esto es de la forma "vmname/vmname.vmx" relativo al datastore 
                vm_vmxfull=$vm_path/$vm_vmx_rel     #Fichero vmname.vmx con el path absoluto completo
                vm_dir=`dirname $vm_vmxfull`        #Directorio donde esta el fichero vmname.vmx
		        echo $vm_dir)
             } #Uso get_vm_dir vmid

#Coge el valor de un campo de un fichero de configuración ascii (ej. .vmx)
# que es de la forma: 
#   fieldName = "fieldValue"
# El nombre del campo puede ser una expresion regular 
# Si hay varios cogería el primero
# ej. get_value 'scsi.*fileName' config.vmx  
#
get_value() { awk -F '"' "/$1/ {print \$2; exit}" $2 ; } #Uso: get_value field file

#Borra una linea de un fichero que concuerde con una expresion regular usando sed
seddelete() { sed -i "/$1/d" $2; } # Uso: seddelete regexp file

#En un fichero, sustituye una cadena que concuerde con una expresion regular por otra cosa, usando sed
sedreplace() { sed -i "s/$1/$2/" $3; } # Uso: sedreplace regexp_needle replacement file

#En una cadena, sustituye una subcadena que concuerde con una expresion tipo glob (no regexp) por otra cosa e imprime el resultado
#ej. stringreplace 'hola mundo' mundo mundillo
#    imprime: hola mundillo
#ej. stringreplace 'hola mundo' 'm*' mundillo
#    imprime: hola mundillo
stringreplace() { (sin=$1; sout=${sin/$2/$3}; echo $sout;); } #Uso: stringreplace string_in expr_needle replacement 

