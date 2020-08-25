#!/bin/sh
######################################################
# Project: Somfy Awning Controller Homebridge Wrapper
#
# Type: shell wrapper for ubus
# Author: Zbynek Kocur (zokl@atlas.cz)
#
# Copyright (C) 2020 zokl@2020
# License: MIT
######################################################

ACCESSORY="Somfy_Awning"

case $1 in 
    Set)
        if [ $2 == $ACCESSORY ]; then
            case $3 in
                TargetPosition) 
                    ubus call somfy set "{\"TargetPosition\":$4}" | jsonfilter -e "@.TargetPosition"
                    exit 0
                ;;
                TargetVerticalTiltAngle) 
                    ubus call somfy set "{\"TargetVerticalTiltAngle\":$4}" | jsonfilter -e "@.TargetVerticalTiltAngle"
                    exit 0
                ;;
                TargetHorizontalTiltAngle) 
                    ubus call somfy set "{\"TargetHorizontalTiltAngle\":$4}" | jsonfilter -e "@.TargetHorizontalTiltAngle"
                    exit 0
                ;;
            esac
            
        fi
    ;;
    Get)
        if [ $2 == $ACCESSORY ]; then
            case $3 in
                TargetPosition) 
                    ubus call somfy get "{\"action\":\"TargetPosition\"}" | jsonfilter -e "@.TargetPosition"
                    exit 0
                ;;
                CurrentPosition) 
                    ubus call somfy get "{\"action\":\"CurrentPosition\"}" | jsonfilter -e "@.CurrentPosition"
                    exit 0
                ;;
                TargetVerticalTiltAngle) 
                    ubus call somfy get "{\"action\":\"TargetVerticalTiltAngle\"}" | jsonfilter -e "@.TargetVerticalTiltAngle"
                    exit 0
                ;;
                TargetHorizontalTiltAngle) 
                    ubus call somfy get "{\"action\":\"TargetHorizontalTiltAngle\"}" | jsonfilter -e "@.TargetHorizontalTiltAngle"
                    exit 0
                ;;
                CurrentVerticalTiltAngle) 
                    ubus call somfy get "{\"action\":\"CurrentVerticalTiltAngle\"}" | jsonfilter -e "@.CurrentVerticalTiltAngle"
                    exit 0
                ;;
                CurrentHorizontalTiltAngle) 
                    ubus call somfy get "{\"action\":\"CurrentHorizontalTiltAngle\"}" | jsonfilter -e "@.CurrentHorizontalTiltAngle"
                    exit 0
                ;;
                ObstructionDetected) 
                    ubus call somfy get "{\"action\":\"ObstructionDetected\"}" | jsonfilter -e "@.ObstructionDetected"
                    exit 0
                ;;
            esac
            
        fi
    ;;
esac


exit 0
