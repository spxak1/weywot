# Add mathematical symbols to the keyboard layout using the compose key

This assumes you use Gnome 48+.

## Enable the compose key in the settings

I like setting it to the PrtSc (between right Alt and right Ctrl) on my ThinkPads.

## Add the "recipes"

You will need to create a file in your root:

```pico ~/.XCompose```

And add the recipes there:

~~~
include "%L"

<Multi_key> <s> <r> : "√" U221A # Square Root
<Multi_key> <p> <r> : "∝" U221D # Proportionality
<Multi_key> <d> <e> : "°" U00B0 # Degree symbol
<Multi_key> <p> <m> : "±" U00B1 # Plus/Minus
<Multi_key> <equal> <equal> : "≈" U2248 # Approximately equal
<Multi_key> <slash> <equal> : "≠" U2260 # Not equal
<Multi_key> <period> <period> : "·" U00B7 # Dot product / multiplication dot
<Multi_key> <x> <x>         : "×" U00D7 # Proper multiplication sign
<Multi_key> <caret> <minus> : "⁻" U207B # Superscript minus (for s⁻¹)
~~~

It's self explanatory what you get and how. You can also see the unicode. Restart Gnome and you're good to go.

So to type the square root symbol, press compose and you see a <u>.</u> blinking. Release and type the recipe, ```s``` and ```r```. When ```r``` is released you see the √.

The full list of predefined recipes is found in ```/usr/share/X11/locale/en_US.UTF-8/Compose``` but it doesn't have all unicodes.

## The Unicode method

This is an alternative way which doesn't use the compose key.
Instead you type ```ctrl+shift+U``` and the prompt turns to <u>u</u> afte which (you release the keys and) you type the code, e.g. ```221a``` and space to see the √.

For a list of unicodes go to https://en.wikipedia.org/wiki/Mathematical_Operators_(Unicode_block)

Finally don't forget Gnome's Character app which includes all (and can select whatever you want, including emojis).

