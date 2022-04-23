# Configure top button of Lenovo Active Pen 2
This is a blatant rip off of [this](https://forum.manjaro.org/t/activepen2-top-button/54556), so all credit goes to the author of that post. 
I have made changes to the script so that I understand it.


## The pen
Lenovo's Active Pen 2, has a top button which connects bia BT. This is completely separate from the other two buttons that appear as part of the laptop's touchscreen (stylus and eraser respectively).

The pen has the following part numbers: GX80N07825 and 4X80N95873 and FRU01FJ170. It must be the same device, but only Lenovo knows. 
Mine had the FRU on the sticker on the pen, and the second P/N on the box (but no FRU). Go figure.

## The top button
Holding the top button for a few seconds makes the led blink and you can now pair with your laptop's BT. Once this is done, everytime the top button is pressed once, it connects to the laptop, it gives a set of keypresses, and then disconnects. It is **not** always connected and that's a problem (also a good thing for the battery).

I Windows, the Lenovo app, allows you to customise the top button for a single and double press. A similar pen (from HP) can be seen configured in Windows [here](https://youtu.be/h5R8GoPceCE?t=36)
Because of the connect-disconnect process there is lag, so expect a good 2 seconds before you see a reaction.

In linux the top button is not supported by anything really, although there was a request a couple of years ago on gnome, [here](https://gitlab.gnome.org/GNOME/gnome-control-center/-/issues/638).

## 
  
