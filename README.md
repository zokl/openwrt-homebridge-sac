# Somfy Awning Controller

A small program designed to control Somfy Telis RTS screening devices (blinds, awning etc). The program is written in LUA as a module in the UBUS infrastructure of the OpenWRT operating system. The program controls the Somfy Telis RTS driver using GPIO exported via SYSFS.

The API is adapted for use with homebridge-cmd4 (https://www.npmjs.com/package/homebridge-cmd4).

The program is HW platform-independent. No RPI utils and programs need anymore :-).

## Installation

1. Add repository to OpenWRT *feeds.conf* (`src-git somfy https://github.com/zokl/openwrt-homebridge-sac.git`)
2. Run: `./script/feeds update somfy && ./script/feeds install sac`
2. Choose **sac** in menuconfig *Extra package*
3. Compile

## Deployment

OpenWRT deployment process. IMG or by opkg.

## Configuration

Application **sac** has a configuration file in `/etc/config/sac`. In a configuration file could be specified several parameters. The restart of the **sac** process is necessary after editing the configuration file. 

### Default configuration file
```
config section 'logging'
    option level 'info'

config section 'general'
    option time_to_open '10'

config section 'gpio'
    option active_low '1'
    option up '351'
    option down '361'
    option stop '371'
```
Configuration file items description:
* logging
  * level - logging level (info .. debug)
* general
  * time_to_open - time to device open in seconds
* gpio - gpio address in sysfs (`/sys/class/gpioXY/`)
  * active_low - switch 1/0 output polarity
  * up - GPIO port definition for UP key 
  * down - GPIO port definition for WORN key
  * stop - GPIO port definition for STOP key
  
### How to determine usable GPIO

A lot of Linux HW platforms have a different approach for GPIO identify and control. The mapping between physically GPIO pins and its system interpretation could be done by the reading of sysfs file by `cat /sys/kernel/debug/pinctrl/*/pinmux-pins`.


The actual GPIO configuration for Olimex A20 MICRO follows:
```
root@ZoklHomeBridge:~# cat /sys/kernel/debug/gpio
gpiochip0: GPIOs 0-287, parent: platform/1c20800.pinctrl, 1c20800.pinctrl:
 gpio-35  (                    |sysfs               ) out hi
 gpio-36  (                    |sysfs               ) out hi
 gpio-37  (                    |sysfs               ) out hi
 gpio-40  (                    |ahci-5v             ) out hi
 gpio-41  (                    |usb0-vbus           ) out lo
 gpio-225 (                    |cd                  ) in  lo IRQ ACTIVE LOW
 gpio-226 (                    |a20-olinuxino-micro:) out hi
 gpio-227 (                    |usb2-vbus           ) out hi
 gpio-228 (                    |usb0_id_det         ) in  hi IRQ
 gpio-229 (                    |usb0_vbus_det       ) in  lo IRQ
 gpio-230 (                    |usb1-vbus           ) out hi
 gpio-235 (                    |cd                  ) in  hi IRQ ACTIVE LOW

gpiochip1: GPIOs 413-415, parent: platform/axp20x-gpio, axp20x-gpio, can sleep:
```


## How it Works

The program controls the GPIO outputs of the platform, which are connected to the RF controller Somfy Trelis RTS. Communication with the controller is only one-way. It is not possible to determine the current position of the device. The position between the closed and open states is determined from the set motor run time (*time_to_open*). Therefore, if the running time of the motor is 10 seconds, the engine is running for 5 seconds when the 50% opening setting is set.

### UBUS Integration

UBUS parameters are compatible with Apple Homekit *Window Covering profile* served by homebridge-cmd4.

**sac** can be control by UBUS commands:
```
root@HomeBridge:~# ubus -v list somfy
'somfy' @0b015743
	"version":{}
	"set":{"TargetVerticalTiltAngle":"String","TargetPosition":"String","TargetHorizontalTiltAngle":"String"}
	"status":{}
	"control":{"rolling":"String"}
	"get":{"action":"String"}
 ```
 
#### Awning UP
Pulling out the awning.

* `ubus call somfy control '{"rolling":"up"}'`
 
#### Awning DOWN
Unfolding the awning.

* `ubus call somfy control '{"rolling":"down"}'`

#### Awning STOP
Stop moving of awning device.

* `ubus call somfy control '{"rolling":"down"}'`

#### Awning to 50%
* `ubus call somfy set '{"TargetPosition":50}'`

#### Read status of device
* `ubus call somfy status`


## homebridge-cmd4 integration

Apple's Homekit integration could be done by Homebridge plugin homebridge-cmd4 (https://www.npmjs.com/package/homebridge-cmd4). For that purpose, a special shell wrapper was made. The wrapper is stored in `/usr/share/sac/sac-homebridge-wrapper.sh`. UBUS works with root privileges. Homebridge shell wrapper must be run with sudo command. 

Homebridge cmd4 config template is stored in the followed location: `/usr/share/sac/homebridge-config.json.template` or https://github.com/zokl/openwrt-homebridge-sac/blob/master/sac/files/homebridge-config.json.template.

Openwrt Makefile for homebridge-cmd4 and its dependencies could be found here: https://github.com/zokl/openwrt-node-packages.

## Somfy Telis RTL hack

### Where to buy

Aliexppress - SOMFY Telis 4 RTS, Somfy Telis 4 Soliris RT garage door controller compatible 433,42Mhz rolling code clone (https://www.aliexpress.com/item/33008184741.html?spm=a2g0s.9042311.0.0.27424c4doDbRrK).

### How to clone original driver
1. While pressing the button 1 of the remote, press 4 times of the button 2. Release both buttons. Now the led emits a quick flash every 2 sec.
2. Press and hold the button 1 of the original remote control until our remote led will flashing every 1 second. Press the button 1 of our remote to save the code.
3. The copy has been successful, after copy success, active the remote on the receiver, this action should be close to the gate opener. Press the button 1 of our remote until the led flash and go off. Then your new remote is ready to work.

Please note: please don't use the original remote control before active the new remote.

### How to connect to GPIO bracket

**The button is push by grounding it. To activate the opposite logic, it is necessary to set the `active_low` parameter to `1` in the configuration file.**

**Do not put the battery inside the Somfy module if you use an external power source!!!**

List of GPIO pins:

* Black - GND
* White - Power source (3V3)
* Gray - UP
* Purple - DOWN
* Blue - FREE, unprogrammed, connected to maintain a fixed logic level
* Green - STOP

![Somfy Telis RTS4 interconnection](https://github.com/zokl/openwrt-homebridge-sac/blob/master/Somfy_Telis_RTS4.jpeg)
