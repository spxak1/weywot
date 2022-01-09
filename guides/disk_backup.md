# Old fashion disk backup

Make an image of a disk on another.

![image](https://user-images.githubusercontent.com/29977030/148694930-8c782953-0aa0-4a77-90bf-c74076154b02.png)


```dd if=/dev/nvme0n1 bs=1M status=progress | gzip > /mnt/Zeus_laptop.img.gz```

Then other terminals: 
```watch -n 10 "ls -lh Zeus_laptop.img.gz"```
```watch -n 5 "sensors | grep -e 'Sensor\|Composite'"```
```sudo intel-undervolt measure```
```progress -M```
