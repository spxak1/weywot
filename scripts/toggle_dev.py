#https://www.reddit.com/r/linux/comments/m0z0rg/handy_ute_for_laptop_battery_saving_ultra_rapid/
#https://gitlab.com/wef/dotfiles/-/blob/master/bin/toggle-devices
#https://gitlab.com/wef/dotfiles/-/blob/master/.config/toggle-devices/config.json
#! /usr/bin/env python
from tkinter import *
from tkinter import ttk
import sys, os, json
config_file = os.getenv("HOME")+"/.config/toggle-devices/config.json"
# I don't like the .pyc cluttering things:
sys.dont_write_bytecode = True
debug=True
def system(cmd):
    if debug: print("system: command='%s'" % cmd, file=sys.stderr)
    retval = os.system(cmd)
    if debug: print("returning %d" % retval, file=sys.stderr)
    return(retval)
class Device:
    def __init__(self, name):
        self.name = name
        self.start_cmd = []
        self.stop_cmd = []
        self.status_cmd = []
    def add_start_cmd(self, cmd):
        self.start_cmd.append( cmd )
        return
    def add_stop_cmd(self, cmd):
        self.stop_cmd.append( cmd )
        return
    def add_status_cmd(self, cmd):
        self.status_cmd.append( cmd )
        return
    
    def status(self):
        for cmd in self.status_cmd:
            return(system(cmd) == 0)
    def start(self):
        i = 0
        if not self.status():
            for cmd in self.start_cmd:
                i = system(cmd)
        return i
    def stop(self):
        i = 0
        for cmd in self.stop_cmd:
            i = system(cmd)
        return i
        
class Top_level:
    def __init__(self, root):
        self.root = root
        root.title("Toggle devices")
        s=ttk.Style()
        s.theme_use('alt')
        self.mainframe = ttk.Frame(root, padding="3 3 12 12")
        self.mainframe.grid(column=0, row=0) # , sticky=(N, W, E, S))
        #root.columnconfigure(0, weight=1)
        #root.rowconfigure(0, weight=1)
        self.devices = []
        self.row=0
    def add_device(self, device):
        device.is_running = BooleanVar(value=device.status())
        button = ttk.Checkbutton(self.mainframe, text=device.name, variable=device.is_running)
        button.grid(row=self.row)
        self.row += 1
        self.devices.append( device )
        
    def add_devices(self):
        with open(config_file, "r") as fp:
            config = json.load(fp)
        for device in config:
            d = Device(device['name'])
            for cmd in device['status_cmds']:
                d.add_status_cmd(cmd)
            for cmd in device['start_cmds']:
                d.add_start_cmd(cmd)
            for cmd in device['stop_cmds']:
                d.add_stop_cmd(cmd)
            self.add_device(d)
            
        status_l = ttk.Label(self.mainframe, text='')
        status_l.grid(row=self.row, column=0)
        self.row += 1
        quit_b=ttk.Button(self.mainframe, text="Quit", command=self.quit)
        quit_b.grid(row=self.row, column=0)
        ok_b = ttk.Button(self.mainframe, text="OK", command=self.doit)
        ok_b.grid(row=self.row, column=1)
        self.row += 1
        for child in self.mainframe.winfo_children(): 
            child.grid_configure(padx=5, pady=5)
            child.grid_configure(sticky=(W))
    def print(self):
        for device in self.devices:
            print(device.name, "=", device.is_running.get())
    
    def quit(self):
        self.print()
        sys.exit(0)
    def doit(self):
        print("================ doit ================", file=sys.stderr)
        self.print()
        for device in self.devices:
            if device.is_running.get():
                device.start()
            else:
                device.stop()
# Here be main()!!
root = Tk()
top = Top_level(root)
top.add_devices()
root.mainloop()
# how I bootstrapped the config file from the hardcoded version:
from json import JSONEncoder
class DeviceEncoder(JSONEncoder):
    def default(self, o):
        if isinstance(o, Device):
            return o.__dict__
        if isinstance(o, BooleanVar):
            return
        return default(self, obj)
json.dump(top.devices, sys.stdout, cls=DeviceEncoder)
