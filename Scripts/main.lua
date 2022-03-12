PROJECT = "EinkBook-LuatOS"
VERSION = "1.0.0"
MOD_TYPE = rtos.bsp()
log.info("MOD_TYPE", MOD_TYPE)
sys = require("sys")
wifiLib = require("wifiLib")
httpLib = require("httpLib")

tag = "EINKBOOK"
USE_SMARTCONFIG = false
serverAdress = "http://47.96.229.157:2333/"
-- serverAdress = "http://192.168.31.70:2333/"

waitHttpTask, waitDoubleClick = false, false
einkPrintTime = 0
PAGE, gpage = "LIST", 1
einkBooksTable, einkBooksIndex, einkBooksTableLen = {}, 1, 0
gBTN, gPressTime, gShortCb, gLongCb, gDoubleCb, gBtnStatus = 0, 1000, nil, nil, nil, "IDLE"

function printTable(tbl, lv)
    lv = lv and lv .. "\t" or ""
    print(lv .. "{")
    for k, v in pairs(tbl) do
        if type(k) == "string" then
            k = "\"" .. k .. "\""
        end
        if "string" == type(v) then
            local qv = string.match(string.format("%q", v), ".(.*).")
            v = qv == v and '"' .. v .. '"' or "'" .. v:toHex() .. "'"
        end
        if type(v) == "table" then
            print(lv .. "\t" .. tostring(k) .. " = ")
            printTable(v, lv)
        else

            print(lv .. "\t" .. tostring(k) .. " = " .. tostring(v) .. ",")
        end
    end
    print(lv .. "},")
end

function getTableLen(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

function longTimerCb()
    gBtnStatus = "LONGPRESSED"
    gLongCb()
end

function btnHandle(val)
    if val == 0 then
        if waitDoubleClick == true then
            sys.timerStop(gShortCb)
            gDoubleCb()
            waitDoubleClick = false
            return
        end
        sys.timerStart(longTimerCb, gPressTime)
        gBtnStatus = "PRESSED"
    else
        sys.timerStop(longTimerCb)
        if gBtnStatus == "PRESSED" then
            sys.timerStart(gShortCb, 500)
            waitDoubleClick = true
            gBtnStatus = "IDLE"
        elseif gBtnStatus == "LONGPRESSED" then
            gBtnStatus = "IDLE"
        end
    end
end

function btnSetup(gpioNumber, pressTime, shortCb, longCb, doubleCb)
    gpio.setup(gpioNumber, btnHandle, gpio.PULLUP)
    gPressTime = pressTime
    gShortCb = shortCb
    gLongCb = longCb
    gDoubleCb = doubleCb
end

function showBookList(books, index)
    gpage = 1
    einkShowStr(0, 16, "图书列表", 0, eink.font_opposansm12_chinese, true)
    local ifShow = false
    local len = getTableLen(books)
    if len == 0 then
        -- TODO 显示无图书
        return
    end
    local i = 1
    for k, v in pairs(books) do
        local bookName = k
        local bookSize = tonumber(v["size"]) / 1024 / 1024
        if i == len then
            ifShow = true
        end
        if i == index then
            eink.rect(0, 16 * i, 200, 16 * (i + 1), 0, 1, nil, ifShow)
            einkShowStr(0, 16 * (i + 1), bookName .. "      " .. string.format("%.2f", bookSize) .. "MB", 1,
                eink.font_opposansm12_chinese, nil, ifShow)
        else
            einkShowStr(0, 16 * (i + 1), bookName .. "      " .. string.format("%.2f", bookSize) .. "MB", 0,
                eink.font_opposansm12_chinese, nil, ifShow)
        end
        i = i + 1
    end
end

function showBook(bookName, bookUrl, page)
    sys.taskInit(function()
        waitHttpTask = true
        for i = 1, 3 do
            local result, code, data = httpLib.request("GET", bookUrl .. "/" .. page)
            log.info("SHOWBOOK", result, code)
            if result == false or code == -1 or code == 0 then
                log.error("SHOWBOOK", "获取图书内容失败 ", data)
            else
                local bookLines = json.decode(data)
                for k, v in pairs(bookLines) do
                    if k == 1 then
                        einkShowStr(0, 16 * k, v, 0, eink.font_opposansm12_chinese, true, false)
                    elseif k == #bookLines then
                        einkShowStr(0, 16 * k, v, 0, eink.font_opposansm12_chinese, false, false)
                    else
                        einkShowStr(0, 16 * k, v, 0, eink.font_opposansm12_chinese, false, false)
                    end
                end
                einkShowStr(60, 16 * 12 + 2, page .. "/" .. einkBooksTable[bookName]["pages"], 0,
                    eink.font_opposansm12_chinese, false, true)
                break
            end
        end
        waitHttpTask = false
    end)
end

function btnShortHandle()
    if waitHttpTask == true then
        waitDoubleClick = false
        return
    end
    if PAGE == "LIST" then
        if einkBooksIndex == einkBooksTableLen then
            einkBooksIndex = 1
        else
            einkBooksIndex = einkBooksIndex + 1
        end
        showBookList(einkBooksTable, einkBooksIndex)
    else
        local i = 1
        local bookName = nil
        for k, v in pairs(einkBooksTable) do
            if i == einkBooksIndex then
                bookName = k
            end
            i = i + 1
        end
        local thisBookPages = tonumber(einkBooksTable[bookName]["pages"])
        if thisBookPages == gpage then
            waitDoubleClick = false
            return
        end
        gpage = gpage + 1
        showBook(bookName, serverAdress .. string.urlEncode(bookName), gpage)
    end
    waitDoubleClick = false
end

function btnLongHandle()
    if waitHttpTask == true then
        return
    end
    if PAGE == "LIST" then
        PAGE = "BOOK"
        local i = 1
        local bookName = nil
        for k, v in pairs(einkBooksTable) do
            if i == einkBooksIndex then
                bookName = k
            end
            i = i + 1
        end
        showBook(bookName, serverAdress .. string.urlEncode(bookName), 1)
    elseif PAGE == "BOOK" then
        PAGE = "LIST"
        showBookList(einkBooksTable, einkBooksIndex)
    end
end

function btnDoublehandle()
    if waitHttpTask == true then
        return
    end
    if PAGE == "LIST" then
        if einkBooksIndex == 1 then
            einkBooksIndex = einkBooksTableLen
        else
            einkBooksIndex = einkBooksIndex - 1
        end
        showBookList(einkBooksTable, einkBooksIndex)
    else
        if gpage == 1 then
            return
        end
        gpage = gpage - 1
        local i = 1
        local bookName = nil
        for k, v in pairs(einkBooksTable) do
            if i == einkBooksIndex then
                bookName = k
            end
            i = i + 1
        end
        showBook(bookName, serverAdress .. string.urlEncode(bookName), gpage)
    end
end

function einkShowStr(x, y, str, colored, font, clear, show)
    if einkPrintTime == 10 then
        einkPrintTime = 0
        eink.clear()
        eink.rect(0, 0, 200, 200, 0, 1)
        eink.show(0, 0, true)
        eink.clear()
        eink.rect(0, 0, 200, 200, 1, 1)
        eink.show(0, 0, true)
    end
    if clear == true then
        eink.clear()
    end
    eink.print(x, y, str, colored, font)
    if show == true then
        einkPrintTime = einkPrintTime + 1
        eink.show(0, 0, true)
    end
end

sys.taskInit(function()
    eink.model(eink.MODEL_1in54)
    if MOD_TYPE == "air101" then
        eink.setup(1, 0, 16, 19, 17, 20)
    elseif MOD_TYPE == "ESP32C3" then
        eink.setup(1, 2, 11, 10, 6, 7)
    end
    eink.setWin(200, 200, 0)
    eink.clear()
    eink.rect(0, 0, 200, 200, 0, 1)
    eink.show(0, 0, true)
    eink.clear()
    eink.rect(0, 0, 200, 200, 1, 1)
    if USE_SMARTCONFIG == true then
        einkShowStr(0, 16, "开机中 等待配网...", 0, eink.font_opposansm12_chinese, false, true)
        local connectRes = wifiLib.connect()
        if connectRes == false then
            einkShowStr(0, 16, "配网失败 重启中...", 0, eink.font_opposansm12_chinese, true, true)
            rtos.reboot()
        end
    else
        einkShowStr(0, 16, "开机中...", 0, eink.font_opposansm12_chinese, false, true)
        local connectRes = wifiLib.connect("Xiaomi_AX6000", "Air123456")
        if connectRes == false then
            einkShowStr(0, 16, "联网失败 重启中...", 0, eink.font_opposansm12_chinese, true, true)
            rtos.reboot()
        end
    end

    for i = 1, 5 do
        local result, code, data = httpLib.request("GET", serverAdress .. "getBooks")
        if result == false or code == -1 or code == 0 then
            log.error(tag, "获取图书列表失败 ", data)
            if i == 5 then
                einkShowStr(0, 16, "连接图书服务器失败 正在重启", 0, eink.font_opposansm12_chinese, true,
                    true)
                rtos.reboot()
            end
        else
            einkBooksTable = json.decode(data)
            printTable(einkBooksTable)
            einkBooksTableLen = getTableLen(einkBooksTable)
            showBookList(einkBooksTable, 1)
            btnSetup(9, 1000, btnShortHandle, btnLongHandle, btnDoublehandle)
            break
        end
        sys.wait(1000)
    end

end)

sys.run()

