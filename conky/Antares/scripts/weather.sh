#!/bin/bash

api_key=df3e37ffc1cef2409e75a27d9bc9cd80
city_id=2640496
#city_id=2063523
#city_id=2220957
url="api.openweathermap.org/data/2.5/weather?id=${city_id}&appid=${api_key}"
curl ${url} -s -o ~/.cache/eleg-weather.json
