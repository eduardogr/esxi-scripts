# ESXi-tools
============

ESXi-tools is a set of scripts that use ***cli*** commands to manage a VMware ESXi 5.5 hypervisor through the ESXi console.


Tools
-----
- **[create_vm.sh](https://github.com/EduardoGR/ESXi-tools/blob/master/ESXi-tools/create_vm.sh)** creates a virtual machine with minimal features.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**-g , --guestSO**   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;set the guest SO.    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**-s , --size**  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;set the size of the virtual disk.
     
- **[delete_vm.sh](https://github.com/EduardoGR/ESXi-tools/blob/master/ESXi-tools/delete_vm.sh)** deletes an existing virtual machine.

- **[full_clone.sh](https://github.com/EduardoGR/ESXi-tools/blob/master/ESXi-tools/full_clone.sh)** creates a full clone of an existing virtual machine.
 
- **[linked_clone.sh](https://github.com/EduardoGR/ESXi-tools/blob/master/ESXi-tools/linked_clone.sh)**  creates a linked clone of an existing virtual machine.

Future improvements
-------------------
- [ ] Adding *.iso image to a virtual machine.
- [ ] Delete multiple virtual machines.
