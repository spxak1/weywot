# How to boot directly to the Kernel (EFISTUB)
This is a quick guide on how to boot to Pop_OS without systemd_boot, or any other bootmanager, simply by loading directly the linux kernel.

## Why?
For fun, proof of concept and perhaps to shave a couple of seconds from your boot time. But mostly for the former two.

## Sources
* **Inspiration** came from [this redditt post](https://www.reddit.com/r/linuxquestions/comments/ska8ed/linux_kernel_as_efi_loader/hvjuf5c/?context=3), so thanks to /u/flechin.
* **Guides** used, as always the excellent [arch wiki](https://wiki.archlinux.org/title/EFISTUB#efibootmgr) and as always a bit of Google search for bits and bobs.

## Principle
The linux kernel can be loaded directly from UEFI, without the need for a boot manager such as *grub* or *systemd_boot* or *rEFInd*.

**Pop!_OS**, and the use of *systemd_boot* means that 
