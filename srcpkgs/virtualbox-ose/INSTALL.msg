In kernel 6.12, KVM initializes virtualization on module loading by default.
This prevents VirtualBox VMs from starting.
In order to avoid this, either add "kvm.enable_virt_at_load=0" parameter
into kernel command line or unload corresponding kvm_XXX module.

