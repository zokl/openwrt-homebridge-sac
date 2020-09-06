# Somfy Awning Controller

A small program designed to control Somfy Telis RTS screening devices (blinds, awning etc). The program is written in LUA as a module in the UBUS infrastructure of the OpenWRT operating system. The program controls the Somfy Telis RTS driver using GPIO exported via SYSFS. RF Communication is only one-way.

## Installation

1. Add repository to OpenWRT *feeds.conf* (`src-git somfy https://github.com/zokl/openwrt-homebridge-sac.git`)
2. Run: `./script/feeds update somfy && ./script/feeds install sac`
2. Choose **sac** in menuconfig *Extra package*
3. Compile

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
logging
