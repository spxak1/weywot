# Add blink to your sudo

![image](https://github.com/spxak1/weywot/blob/main/assets/2024-06-05_10-36_1.png)

Quick guide:

* Add ```/etc/sudoers/lecture``` with content:
  ~~~
  Defaults  lecture=always
  Defaults  lecture_file=/etc/groot.txt
  ~~~
* Download [grout weclome lecture file](https://github.com/spxak1/weywot/blob/main/guides/groot.txt) and place it in ```/etc```.
* Reboot
