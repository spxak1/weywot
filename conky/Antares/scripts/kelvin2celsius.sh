#!/bin/bash

kelvin=$(cut -d. -f1 <<< $1)
base=273
celsius=$(($kelvin - $base))
echo $celsius