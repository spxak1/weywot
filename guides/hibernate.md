# How to configure Hibernation in Pop 
This guid does **not** include encryption and uses a swap **file**.

## 1.0 Sources
This guide is a shameless copy of this: https://abskmj.github.io/notes/posts/pop-os/enable-hibernate/
All credit goes to that author.

## 2.0 Principle of operation (very basic description)
When the computer suspends, the RAM is kept powered to maintain its content. So the rest of the system can be powered off, and when resumed, the OS is in the same state it was before suspension.

Hibernation, takes the contents of the RAM and dumps them to the disk. The disk is not volatile and the contents persist after a complete power off of the system.
Effectively the system, when powered back on, it goes through POST in the same way as whe it boots, but whe the kernel is loaded, rather than a fresh boot, the OS is instructed to read from the disk the contents of the RAM saved there previously, load them into RAM and as such appear in the same state it was before it was put in hibernation mode.

## 3.0 Steps
1. Create a swapfile to dump the RAM conents to
2. Configure the swapfile as swap to the system
3. Configure the kernel to load the swap conents after resuming from hibernate
4. Add the function to hibernate to the system
5. Add a hibernate button to the power meny




