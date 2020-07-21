<h1 align="center"> esxi-scripts </h1> <br>


**esxi-scripts** is a set of scripts that use ***cli*** commands to manage a VMware ESXi 5.5 hypervisor through the ESXi console.

# Scripts

- **[create_vm.sh](./scripts/create_vm.sh)** creates a virtual machine with minimal features.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**-g , --guestSO**   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;set the guest SO.    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**-s , --size**  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;set the size of the virtual disk.
     
- **[delete_vm.sh](./scripts/delete_vm.sh)** deletes an existing virtual machine.

- **[full_clone.sh](./scripts/full_clone.sh)** creates a full clone of an existing virtual machine.
 
- **[linked_clone.sh](./scripts/linked_clone.sh)**  creates a linked clone of an existing virtual machine.

# Future improvements

- [ ] Adding *.iso image to a virtual machine.
- [ ] Delete multiple virtual machines.
- [ ] Adding network card to a virtual machine.
- [ ] To control that the deletion of a linked clone doesn't damage the parent virtual machine.
- [ ] Adding the posibility to create a linked clone of a linked clone.


# License

This project is under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.  

A copy of this license is included in the file [LICENSE](https://github.com/eeuardogr/esxi-scripts/blob/master/LICENSE).
