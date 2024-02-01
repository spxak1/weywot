# Change the temperature of white colour

Taken from [here](https://www.debugpoint.com/adjust-color-temperature-ubuntu-terminal/)

## Ubuntu/Pop

~~~
sudo apt install sct
sct [temperature]
sct 7500
~~~

No temperature resets to default: 6500.

## Fedora

~~~
sudo dnf copr enable dmoerner/sct
sudo dnf update
sudo dnf install sct
~~~

Done. 
