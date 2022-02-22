local wifiConnect = {}

local USE_SMARTCONFIG = false

function wifiConnect.connect(ssid, passwd)
    local tag = "einkBook"

    local waitRes, data
    if wlan.init() ~= 0 then
        log.error(tag .. ".init", "ERROR")
        einkShowStr(0, 16, "联网失败", 0, eink.font_opposansm12_chinese,
                    true, true)
        rtos.reboot()
    end
    if wlan.setMode(wlan.STATION) ~= 0 then
        log.error(tag .. ".setMode", "ERROR")
        einkShowStr(0, 16, "联网失败", 0, eink.font_opposansm12_chinese,
                    true, true)
        rtos.reboot()
    end

    if USE_SMARTCONFIG == true then
        if wlan.smartconfig() ~= 0 then
            log.error(tag .. ".connect", "ERROR")
            einkShowStr(0, 16, "联网失败", 0, eink.font_opposansm12_chinese,
                        true, true)
            rtos.reboot()
        end
        waitRes, data = sys.waitUntil("WLAN_STA_CONNECTED", 30000)
        log.info("WLAN_STA_CONNECTED", waitRes, data)
        if waitRes ~= true then
            log.error(tag .. ".wlan ERROR")
            einkShowStr(0, 16, "联网失败", 0, eink.font_opposansm12_chinese,
                        true, true)
            rtos.reboot()
        end
        log.info("smartconfigStop", wlan.smartconfigStop())
        waitRes, data = sys.waitUntil("IP_READY", 10000)
        if waitRes ~= true then
            log.error(tag .. ".wlan ERROR")
            einkShowStr(0, 16, "联网失败", 0, eink.font_opposansm12_chinese,
                        true, true)
            rtos.reboot()
        end
        log.info("IP_READY", waitRes, data)

        einkShowStr(0, 16, "联网成功", 0, eink.font_opposansm12_chinese,
                    true, true)
        return
    end

    if wlan.connect(ssid, passwd) ~= 0 then
        log.error(tag .. ".connect", "ERROR")
        einkShowStr(0, 16, "联网失败", 0, eink.font_opposansm12_chinese,
                    true, true)
        rtos.reboot()
    end
    waitRes, data = sys.waitUntil("WLAN_READY", 10000)
    if waitRes ~= true then
        log.error(tag .. ".wlan ERROR")
        einkShowStr(0, 16, "联网失败", 0, eink.font_opposansm12_chinese,
                    true, true)
        rtos.reboot()
    end
    log.info("WLAN_READY", waitRes, data)
    waitRes, data = sys.waitUntil("WLAN_STA_CONNECTED", 10000)
    if waitRes ~= true then
        log.error(tag .. ".wlan ERROR")
        einkShowStr(0, 16, "联网失败", 0, eink.font_opposansm12_chinese,
                    true, true)
        rtos.reboot()
    end
    log.info("WLAN_STA_CONNECTED", waitRes, data)
    waitRes, data = sys.waitUntil("IP_READY", 10000)
    if waitRes ~= true then
        log.error(tag .. ".wlan ERROR")
        einkShowStr(0, 16, "联网失败", 0, eink.font_opposansm12_chinese,
                    true, true)
        rtos.reboot()
    end
    log.info("IP_READY", waitRes, data)

    einkShowStr(0, 16, "联网成功", 0, eink.font_opposansm12_chinese, true,
                true)

    -- einkShowStr(0, 60, data, eink.font_opposansm12_chinese)
end

return wifiConnect
