#!/usr/bin/python3

#https://docs.python.org/3/howto/urllib2.html

import urllib.request
import urllib.parse


url = 'https://wifi.ccoex.com:442/clogin'
#url = 'https://wifi.ccoex.com:6300/clogin'
values = {'USERNAME': 'XXXX.XXXXXX', 'PASSWORD' : 'XXXXXXXXX' }

data = urllib.parse.urlencode(values)
data = data.encode('ascii')
req = urllib.request.Request(url, data)
with urllib.request.urlopen(req) as response:
	the_page = response.read()

#webUrl = urllib.request.urlopen('https://wifi.ccoex.com:442/clogin')
#print("result code: " + str(webUrl.getcode()))
#data = webUrl.read()
#print (data)
