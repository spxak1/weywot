Steps
# 1. Check what partuuid is used:

```mount /dev/sda1 /mnt````

~~~
cat /mnt/loader/entries/Pop_OS-current.conf 

title Pop!_OS
linux /EFI/Pop_OS-b415d6c4-baec-4924-9b7f-5567aa9588e6/vmlinuz.efi
initrd /EFI/Pop_OS-b415d6c4-baec-4924-9b7f-5567aa9588e6/initrd.img
options root=UUID=b415d6c4-baec-4924-9b7f-5567aa9588e6 ro quiet loglevel=0 systemd.show_status=false splash
~~~

So the old partuuid is ```b415d6c4-baec-4924-9b7f-5567aa9588e6```

Check this is indeed what you want.

First open ```gparted```, open encryption then activate (this will make the lvm appear under the crypt).

~~~
lsblk -o name,uuid,partuuid

NAME            UUID                                   PARTUUID
loop0                                                  
sda                                                    
├─sda1          84EE-7B43                              d75b32cc-499f-465a-aefb-b8a1b4b3e258
├─sda2          84EE-7AC5                              883809f8-44df-4384-a884-21480618c80a
├─sda3          07e2bade-3894-4a92-9b84-5c36b691529c   a8e059fe-e5cb-4241-a6e9-b37884efe16e
│ └─sda3_crypt  EYR01o-Ngqx-MHrj-FNrT-Ezc6-1E9N-tyaFRJ 
│   └─data-root b415d6c4-baec-4924-9b7f-5567aa9588e6   
└─sda4          0829c7ef-cbbd-4731-9971-709bdbb80885   22619a0e-ff58-47ea-a904-21433c17339d
sdb                                                    
├─sdb1          73C6-D5A0                              58b6aea4-01
│ └─ventoy                                             
└─sdb2          2021-10-12-15-29-53-00       
~~~

You can see that partuuid in ```sda3----sda3_crypt----data-root````.

First resie the Filesystem in that lvm.

```
e2fsck -f /dev/mapper/data-root
````

Then 

```
resize2fs /dev/mapper/data-root 40G
````

This will reduce it to 40G
