#!/usr/bin/env lua

-- @app sac_ubus
local sac_ubus = {
    _APPNAME = "sac",
    _FILENAME = arg[0]:match("[^/]+$"),
    _VERSION = "2020082501",
    _GITHASH = "",                    -- Empty in developement mode
    _GITURL = "",                     -- Empty in developement mode
    _PROJECT = "Home Automatization",
    _CUSTOMER =  "Zokl",
    _DESCRIPTION = "Somfy Awning Controller System",
    _AUTHOR = "Zbynek Kocur [zokl@atlas.cz]",
    _LICENCE = "MIT"
}

-- required packages ----------------------------------------------------------
local ubus = require("ubus")
local uloop = require("uloop")
local uci = require("uci")
local os = require("os")
-- end required packages ------------------------------------------------------

-- global configuration constants ---------------------------------------------
local pool_interval = 100
local global_status_table = {}
local timestamp_old = 0
local motor_flag = true
local stop_flag = false
local last_target = 0
local sysfs_gpio_path = "/sys/class/gpio/"

-- configuration from uci -----------------------------------------------------
local function get_bool(conf)
    if conf == nil or type(conf) == 'string' and (conf == '0' or conf == 'false' or conf == 'off') then return false end
    return true
end

local function read_uci_configuration()
    local uci_section = "sac"

    local conf = {
    loglevel                = UCI_VALUE:get(uci_section, "logging", "level")                    or 'info',
    time_to_open            = UCI_VALUE:get(uci_section, "general", "time_to_open")             or 20,
    sysfs_active_low        = get_bool(UCI_VALUE:get(uci_section, "gpio", "active_low"))                  or 0,
    sysfs_gpio_up           = UCI_VALUE:get(uci_section, "gpio", "up")                          or nil,
    sysfs_gpio_down         = UCI_VALUE:get(uci_section, "gpio", "down")                        or nil,
    sysfs_gpio_stop         = UCI_VALUE:get(uci_section, "gpio", "stop")                        or nil,

    }

    return conf
end
-- end configuration from uci -------------------------------------------------

local function logger(level, msg)
    local level_table = {
        debug = 1,
        info  = 2,
        warn  = 3,
        error = 4,
        fatal = 5,
    }
    local tag = arg[0]:match("[^/]+$")

    if level_table[level] >= level_table[CONF.loglevel] then
        print(tag .. ": " .. tostring(msg))
    end
end

-- UNIX timestamp
local function gmtime()
    return os.time(os.date("!*t"));
end

local function sleep (a) 
    local sec = tonumber(os.clock() + a); 
    while (os.clock() < sec) do 
    end 
end

local function exists(filename)
    -- check if file exists
    local file = io.open(filename)
	if file then
	    io.close(file)
	    return true
	else
	    return false
	end
end

local function version (req, msg)
    logger("debug", "Ubus call to function version received.")
    UCONN:reply(req, {
        [sac_ubus._APPNAME] = sac_ubus._DESCRIPTION,
        version = sac_ubus._VERSION,
        filename = sac_ubus._FILENAME,
        }
    )
end

local function control (req, msg)
    logger("debug", "Ubus call to function control received.")
    local status = {}

    if msg.rolling == "stop" then
        global_status_table.TargetPosition = global_status_table.CurrentPosition

        status = { rolling = msg.rolling }
        stop_flag = true

    elseif msg.rolling == "up" then
        global_status_table.TargetPosition = 0

        status = { rolling = msg.rolling }
        motor_flag = true

    elseif msg.rolling == "down" then
        global_status_table.TargetPosition = 100

        status = { rolling = msg.rolling }
        motor_flag = true

    else
        UCONN:reply(req, {rolling = "Wrong command"})
        return
    end

    UCONN:reply(req, status)
end


local function set (req, msg)
    logger("debug", "Ubus call to function set received.")
    local status = {}
    
    -- Somfy target possition setting
    if  msg.TargetPosition ~= nil then
        local TargetPosition = tonumber(msg.TargetPosition)

        if TargetPosition >= 0 and TargetPosition <= 100   then

            global_status_table.TargetPosition = TargetPosition
            global_status_table.timestamp = gmtime()
            logger ("info", "Received TargetPosition: " .. tostring(global_status_table.TargetPosition) .. " %")
            logger ("info", "CurrentPosition: " .. tostring(global_status_table.CurrentPosition) .. " %")
            
            status = {TargetPosition = TargetPosition}
        else
            status = {TargetPosition = "Wrong number"}
        end

    -- Somfy TargetVerticalTiltAngle setting
    elseif  msg.TargetVerticalTiltAngle ~= nil then
        local TargetVerticalTiltAngle = tonumber(msg.TargetVerticalTiltAngle)

        if  TargetVerticalTiltAngle >= -90 and TargetVerticalTiltAngle <= 90   then

            global_status_table.TargetVerticalTiltAngle = TargetVerticalTiltAngle
            logger ("info", "Received TargetVerticalTiltAngle: " .. tostring(global_status_table.TargetVerticalTiltAngle) .. " deg")
            
            status = {TargetVerticalTiltAngle = TargetVerticalTiltAngle}
        else
            status = {TargetVerticalTiltAngle = "Wrong number"}
        end

    -- Somfy TargetHorizontalTiltAngle setting
    elseif  msg.TargetHorizontalTiltAngle ~= nil then
        local TargetHorizontalTiltAngle = tonumber(msg.TargetHorizontalTiltAngle)

        if  TargetHorizontalTiltAngle >= -90 and TargetHorizontalTiltAngle <= 90   then

            global_status_table.TargetHorizontalTiltAngle = TargetHorizontalTiltAngle
            logger ("info", "Received TargetHorizontalTiltAngle: " .. tostring(global_status_table.TargetHorizontalTiltAngle) .. " deg")
            
            status = {TargetHorizontalTiltAngle = TargetHorizontalTiltAngle}
        else
            status = {TargetHorizontalTiltAngle = "Wrong number"}
        end

    end

    UCONN:reply(req, status)
end

local function get (req, msg)
    logger("debug", "Ubus call to function get received.")

    local answer = {}

    if msg.action == "TargetPosition" then
        answer = { TargetPosition=global_status_table.TargetPosition }

    elseif msg.action == "ObstructionDetected" then
        answer = { ObstructionDetected = global_status_table.ObstructionDetected }

    elseif msg.action == "CurrentPosition" then
        answer = { CurrentPosition = global_status_table.CurrentPosition }

    elseif msg.action == "TargetVerticalTiltAngle" then
        answer = { TargetVerticalTiltAngle = global_status_table.TargetVerticalTiltAngle }

    elseif msg.action == "TargetHorizontalTiltAngle" then
        answer = { TargetHorizontalTiltAngle = global_status_table.TargetHorizontalTiltAngle }

    elseif msg.action == "CurrentVerticalTiltAngle" then
        answer = { CurrentVerticalTiltAngle = global_status_table.CurrentVerticalTiltAngle }

    elseif msg.action == "CurrentHorizontalTiltAngle" then
        answer = { CurrentHorizontalTiltAngle = global_status_table.CurrentHorizontalTiltAngle }

    elseif msg.action == "All" then
        answer = { global_status_table }
    end

    UCONN:reply(req, answer)
end

local function status (req, msg)
    logger("debug", "Ubus call to function status received.")

        UCONN:reply(req, global_status_table)
end

local function write_to_sysfs (path, value)

    logger ("info", "Write '" .. value .. "' to '" .. path .."'")

    -- local file = io.open(path, 'w')
    -- file:write(value)
    -- file:close()
end

local function gpio_init (pin)

    logger("info", "Initialization of GPIO pin '" .. pin .."'")
    if not exists (sysfs_gpio_path .. "gpio" .. pin) then
        -- Enable GPIO PIN
        write_to_sysfs (sysfs_gpio_path .. "export" , pin)
        -- Set GPIO Out Direction
        write_to_sysfs (sysfs_gpio_path .. "gpio" .. pin .. "/direction", "out")
        -- Change permissions to homebridge user
        os.execute("chown homebridge ".. sysfs_gpio_path .. "gpio" .. pin .. "/value")
    end
end


local function set_gpio (pin, value)

    if CONF.sysfs_active_low == true then
        logger("info", "Swaping value bit on pin " .. pin)
        if value == '1' or value == 1 then
            value = '0'
        elseif value == '0' or value == 0 then
            value = '1'
        end
    end

    write_to_sysfs (sysfs_gpio_path .. "gpio" .. pin .. "/value", value)
end

local function clear_gpio_signal ()
    set_gpio (CONF.sysfs_gpio_down, '0')
    set_gpio (CONF.sysfs_gpio_up, '0')
    set_gpio (CONF.sysfs_gpio_stop, '0')
end

local function somfy_device_rolling_up ()
    logger("info", "*** Markyza se zatahuje ***")
    set_gpio (CONF.sysfs_gpio_up, '1')
    sleep(0.5)
    clear_gpio_signal ()
    
end

local function somfy_device_rolling_down ()
    logger("info", "*** Markyza se vytahuje ***")
    set_gpio (CONF.sysfs_gpio_down, '1')
    sleep(0.5)
    clear_gpio_signal ()
end

local function somfy_device_rolling_stop ()

    set_gpio (CONF.sysfs_gpio_stop, '1')
    sleep(0.5)
    clear_gpio_signal ()

    if global_status_table.TargetPosition == 0 then

        logger("info", "Somfy device stopped at the BEGINNING")

    elseif global_status_table.TargetPosition == 100 then

        logger("info", "Somfy device stopped at the END")

    else

        logger("info", "Somfy device STOP rolling")

    end
end



local function somfy_init ()
    logger ("info", sac_ubus._APPNAME .. " (" .. sac_ubus._VERSION .. ")")
    logger ("info", sac_ubus._DESCRIPTION)
    logger("info", "------------------------------------")
    logger("info", "Loading configuration:")
    logger("info", "   Loging level: " .. CONF.loglevel)
    logger("info", "   Somfy device time to open: " .. CONF.time_to_open .. " s")
    logger("info", "   Somfy device GPIO UP: " .. CONF.sysfs_gpio_up)
    logger("info", "   Somfy device GPIO DOWN: " .. CONF.sysfs_gpio_down)
    logger("info", "   Somfy device GPIO STOP: " .. CONF.sysfs_gpio_stop)
    logger("info", "   GPIO Hi/Lo swap: " .. tostring(CONF.sysfs_active_low))
    logger("info", "------------------------------------")

    -- GPIO INIT
    gpio_init (CONF.sysfs_gpio_up)
    gpio_init (CONF.sysfs_gpio_down)
    gpio_init (CONF.sysfs_gpio_stop)

    -- Somfy device 0th possition initialization
    logger("info", "Reseting Somfy device possition")
    somfy_device_rolling_up ()
    sleep(CONF.time_to_open)

    -- Create global table
    global_status_table = { 
        TargetPosition = 0, 
        CurrentPosition = 0,
        TargetVerticalTiltAngle = 0,
        TargetHorizontalTiltAngle = 0,
        CurrentVerticalTiltAngle = 0,
        CurrentHorizontalTiltAngle = 0,
        ObstructionDetected = false, 
        timestamp = gmtime()
    }

end


local function poller()
    --logger("debug", "Ubus call to function pooler received.")

    -- if gmtime () - timestamp_old >= 1 then

        if global_status_table.TargetPosition ~= global_status_table.CurrentPosition then

            local current_position_time = global_status_table.CurrentPosition * CONF.time_to_open / 100
            local target_position_time = global_status_table.TargetPosition * CONF.time_to_open / 100

            -- Show info about variables
            if gmtime () - timestamp_old >= 1 then

                logger ("debug", "CurrentPosition: " .. tostring(current_position_time) .. " s, perc: " .. tostring(global_status_table.CurrentPosition) .. " %")
                logger ("debug", "TargetPosition: " .. tostring(target_position_time) .. " s, perc: " .. tostring(global_status_table.TargetPosition) .. " %")

            end

            -- Somfy device is rolling DOWN
            if global_status_table.TargetPosition >= global_status_table.CurrentPosition then

                if motor_flag == true then

                    -- markyza_down
                    somfy_device_rolling_down()

                    motor_flag = false
                    stop_flag = true
                    last_target = global_status_table.TargetPosition
                end

                global_status_table.CurrentPosition = global_status_table.CurrentPosition + (gmtime () - timestamp_old) * 100 / CONF.time_to_open

                if global_status_table.CurrentPosition >= global_status_table.TargetPosition then
                    global_status_table.CurrentPosition = global_status_table.TargetPosition
                end

            -- Somfy device is rolling UP
            elseif global_status_table.TargetPosition <= global_status_table.CurrentPosition then

                if motor_flag == true then

                    -- markyza_up
                    somfy_device_rolling_up ()

                    motor_flag = false
                    stop_flag = true
                end

                global_status_table.CurrentPosition = global_status_table.CurrentPosition - (gmtime () - timestamp_old) * 100 / CONF.time_to_open

                if global_status_table.CurrentPosition <= global_status_table.TargetPosition then
                    global_status_table.CurrentPosition = global_status_table.TargetPosition
                end

            end

            if  last_target < global_status_table.TargetPosition then
                motor_flag = true
            end

        else
            -- STOP Somfy device rolling
            if stop_flag == true then

                somfy_device_rolling_stop ()

                stop_flag = false
                motor_flag = true

                logger ("info", "CurrentPosition: " .. tostring(global_status_table.CurrentPosition) .. " %")
                logger ("info", "TargetPosition: " .. tostring(global_status_table.TargetPosition) .. " %")
            end
        end

        timestamp_old = gmtime ()
    -- end

    TIMER:set(pool_interval)
end

function sac_ubus.main()
    UCONN:add({
        somfy = {
            set = {
                set, {
                    TargetPosition  = ubus.STRING,
                    TargetVerticalTiltAngle = ubus.STRING,
                    TargetHorizontalTiltAngle = ubus.STRING
                }
            },
            control = {
                control, {
                    rolling = ubus.STRING,
                }
            },
            get = {
                get, {
                    action = ubus.STRING,
                }
            },
            status = { status, {}},
            version = { version, {}},
          }
    })
end
-- end local functions --------------------------------------------------------
-- end functions --------------------------------------------------------------

-- main logic here ------------------------------------------------------------
-- uci initialization to read system-wide configuration
UCI_VALUE = uci.cursor()
-- read configuration needed for system to work
CONF = read_uci_configuration()

-- Somfy interface init
somfy_init ()

-- initiate a new loop
logger("info", "Initiating uloop.")
uloop.init()

-- connect to ubus and throw an error if connection fails
-- uconn needs to be global, since I cannot pass it as argument in the reference
logger("info", "Connecting to ubus.")
UCONN = ubus.connect()
if not UCONN then
	logger("fatal", "Failed to connect to ubus. Exiting.")
    os.exit()
end

-- register ubus call methods
logger("info", "Registering ubus methods.")
sac_ubus.main()

TIMER = uloop.timer(poller, pool_interval)

-- run infinite loop
logger("info", "Running uloop.")
uloop.run()

-- when done close ubus connection
logger("info", "Closing ubus connection.")
UCONN:close()
-- end main logic -------------------------------------------------------------