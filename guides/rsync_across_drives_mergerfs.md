# Use multiple small drive to backup larger ones

This is an attempt at using ```mergerfs```. 

## Install mergerfs

Fedora doesn't provide a package at its repositories, but the maintainer provides an ```rpm``` file anyway.

Download the package from the releases [here](https://github.com/trapexit/mergerfs/releases). Open the link, and dowload the latest.

Install it with ```sudo dnf install ./mergerfs-2.38.0-1.fc39.x86_64.rpm```.

sudo mergerfs -o cache.files=partial,dropcacheonclose=true,category.create=mfs /media/sd\*:/zeta /mergecs

Some more info [here](https://fedoramagazine.org/using-mergerfs-to-increase-your-virtual-storage/).
