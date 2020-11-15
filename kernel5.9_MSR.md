# Kernel 5.9 and undervolting (with MSR)

Starting with kernel 5.9 (xanmod just updated to 5.9) the user-space writes to MSR are met with a warning (but are still allowed).

If you undervolt your CPU using MSR writes, you will find such warnings in your boot log:

~~~
kernel: msr: Write to unrecognized MSR 0x150 by wrmsr
                               Please report to x86@kernel.org
~~~

You can remove these by passing the kernel option ```msr.allow_writes=on```

More info [here](https://www.phoronix.com/scan.php?page=news_item&px=Linux-Filter-Tightening-MSRs)

I hope this helps.
