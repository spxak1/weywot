# Understand how kernelstub works to pass options to the kernel at boot

Kernel options are passed during boot from the loader entry file, e.g ```/boot/efi/loader/entries/Pop_OS-current.conf```

This file, however **should not** be directly edited as any changes will be overwritten after a kernel update (or other update that calls for a rewrite of the entry file).

Instead all kernel options are passed using the ```kernelstub```. It requires **root** privilege, so you either run it with **sudo** or as root.

The three options you need to know for it are:

* ```kernelstub -a "option"``` inserts the option between the quotes (quotes required).
* ```kernelstbu -d "option"``` removes the option between the quotes (quotes required).
* ```kernelstub -p```` prints the current setup.

Here's mine for example:

~~~
otheos@weywot:~$ sudo kernelstub -p 
kernelstub.Config    : INFO     Looking for configuration...
kernelstub           : INFO     System information: 

    OS:..................Pop!_OS 20.10
    Root partition:....../dev/nvme0n1p6
    Root FS UUID:........f18aecac-b409-4946-8b59-4d7210f60060
    ESP Path:............/boot/efi
    ESP Partition:......./dev/nvme0n1p2
    ESP Partition #:.....2
    NVRAM entry #:.......-1
    Boot Variable #:.....0000
    Kernel Boot Options:.splash mitigations=off resume=UUID=f18aecac-b409-4946-8b59-4d7210f60060 loglevel=0 resume_offset=31633408 mem_sleep_default=deep
    Kernel Image Path:.../boot/vmlinuz-5.8.0-7630-generic
    Initrd Image Path:.../boot/initrd.img-5.8.0-7630-generic
    Force-overwrite:.....False

kernelstub           : INFO     Configuration details: 

   ESP Location:................../boot/efi
   Management Mode:...............True
   Install Loader configuration:..True
   Configuration version:.........3
~~~

You can see the line that starts with ```Kernel Boot Options:```

And this is the output of ```cat /boot/efi/loader/entries/Pop_OS-current.conf ```

~~~
title Pop!_OS
linux /EFI/Pop_OS-f18aecac-b409-4946-8b59-4d7210f60060/vmlinuz.efi
initrd /EFI/Pop_OS-f18aecac-b409-4946-8b59-4d7210f60060/initrd.img
options root=UUID=f18aecac-b409-4946-8b59-4d7210f60060 ro splash mitigations=off resume=UUID=f18aecac-b409-4946-8b59-4d7210f60060 loglevel=0 resume_offset=31633408 mem_sleep_default=deep
~~~

You can see they're identical after the ```ro``` point. 

It would appear that either editing the loader file ```Pop_OS-current.conf``` has the same effect, and indeed it does, but only until an upgrade (or other call) runs kernelstub internally, in which case the loader file is overwritten, with whatever kernelstub has stored.

You can verify this, simply by addint an kernel option to the loader file, and then using ```kernelstub -p``` to verify it's not there. 

When ```kernelstub``` is run, it interfaces with its configuration file in ```/etc/kernelstub/configuration```. 

All the options you pass with ```kernelstub -a``` are stored under the *user* section.

For example, my ```/etc/kernelstub/configuration``` is like so:

~~~
{
  "default": {
    "kernel_options": [
      "quiet",
      "splash"
    ],
    "esp_path": "/boot/efi",
    "setup_loader": false,
    "manage_mode": false,
    "force_update": false,
    "live_mode": false,
    "config_rev": 3
  },
  "user": {
    "kernel_options": [
      "splash",
      "mitigations=off",
      "resume=UUID=f18aecac-b409-4946-8b59-4d7210f60060",
      "loglevel=0",
      "resume_offset=31633408",
      "mem_sleep_default=deep"
    ],
    "esp_path": "/boot/efi",
    "setup_loader": true,
    "manage_mode": true,
    "force_update": false,
    "live_mode": false,
    "config_rev": 3
  }
~~~

You can see in the *user* section all the options I have passed and have appeared in the output of the ```kernelstub -p``` command.

So, three different places for kernel options? No! Just one: the configuration file. You write to it using the ```kernelstub``` command, either with ```-a``` to add to the user section, or ```-d``` to remove an option from the user section. Or, if you wish, you can edit the file directly.

Once kernelstub knows what options you want your kernels to **always** have, it creates the loader file with these options.

If you instead edit the loader file, it's the same as adding those options at boot by editing (with ```e```) the boot options. This means ```kernelstub``` doesn't know them, and when it rewrites the loader (when required after e.g an update), all your options are gone.

