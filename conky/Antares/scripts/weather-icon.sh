#!/bin/bash

theme=$1
weather_code=$2
cp -r ~/.conky/Antares/icons/${theme}/${weather_code}.png ~/.cache/eleg-weather-icon.png
