# Change DNS in Pop 20.10

The old ```resolv.conf``` is now a symlink so you cannot edit.
Instead Pop (and Ubuntu) use **systemd-resolve**

You can view the current DNS setup by issuing:

```sudo systemd-resolve --status```

You can change the DNS server **only per interface**. 

As such you can issue:

```sudo systemd-resolve --set-dns=8.8.8.8 --interface=enp0s31f6```

To change the DNS for Ethernet (look for your ethernet device using ```ifconfig```).

You can flush all your local cashes using

```sudo systemd-resolve --flush-caches```.

Done.
