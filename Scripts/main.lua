PROJECT = "einkBook"
VERSION = "1.0.0"
MOD_TYPE = rtos.bsp()
log.info("MOD_TYPE", MOD_TYPE)
sys = require("sys")
wifiConnect = require("wifiConnect")
httpLib = require("httpLib")

function printTable(tbl, lv)
    lv = lv and lv .. "\t" or ""
    print(lv .. "{")
    for k, v in pairs(tbl) do
        if type(k) == "string" then k = "\"" .. k .. "\"" end
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

local PAGE, page = "LIST", 1
local einkBooksTable, einkBooksIndex = {}, 1
local gBTN, gPressTime, gShortCb, gLongCb, gDoubleCb, gBtnStatus = 0, 1000, nil,
                                                                   nil, nil,
                                                                   "IDLE"

function longTimerCb()
    gBtnStatus = "LONGPRESSED"
    gLongCb()
end

local waitDoubleClick = false

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
    einkShowStr(0, 16, "图书列表", 0, eink.font_opposansm12_chinese, true)
    local ifShow = false
    for i = 1, #books do
        if i == #books then ifShow = true end
        if i == index then
            eink.rect(0, 16 * i, 200, 16 * (i + 1), 0, 1, nil, ifShow)
            einkShowStr(0, 16 * (i + 1), books[i], 1,
                        eink.font_opposansm12_chinese, nil, ifShow)
        else
            einkShowStr(0, 16 * (i + 1), books[i], 0,
                        eink.font_opposansm12_chinese, nil, ifShow)
        end
    end
end

function showBook(bookUrl, page)
    sys.taskInit(function()
        while true do
            local result, code, data = httpLib.request("GET",
                                                       bookUrl .. "/" .. page)
            log.info("SHOWBOOK", result, code, data)
            if result == false then
                log.error("SHOWBOOK", "获取图书内容失败 ", data)
                sys.wait(100)
            else
                local bookLines = json.decode(data)
                -- printTable(bookLines)
                for k, v in pairs(bookLines) do
                    if k == 1 then
                        einkShowStr(0, 16 * k, v, 0,
                                    eink.font_opposansm12_chinese, true, false)
                    elseif k == #bookLines then
                        einkShowStr(0, 16 * k, v, 0,
                                    eink.font_opposansm12_chinese, false, true)
                    else
                        einkShowStr(0, 16 * k, v, 0,
                                    eink.font_opposansm12_chinese, false, false)
                    end
                end
                break
            end
        end
    end)
end

function btnShortHandle()
    if PAGE == "LIST" then
        if einkBooksIndex == #einkBooksTable then
            einkBooksIndex = 1
        else
            einkBooksIndex = einkBooksIndex + 1
        end
        showBookList(einkBooksTable, einkBooksIndex)
    else
        page = page + 1
        showBook("http://192.168.31.70:2333/" ..
                     string.urlEncode(einkBooksTable[einkBooksIndex]), page)
    end
    waitDoubleClick = false
end

function btnLongHandle()
    if PAGE == "LIST" then
        PAGE = "BOOK"
        log.info("当前书", einkBooksTable[einkBooksIndex])
        log.info("当前书URLENCODE",
                 string.urlEncode(einkBooksTable[einkBooksIndex]))
        showBook("http://192.168.31.70:2333/" ..
                     string.urlEncode(einkBooksTable[einkBooksIndex]), 1)
    elseif PAGE == "BOOK" then
        PAGE = "LIST"
        page = 1
        showBookList(einkBooksTable, einkBooksIndex)
    end
end

function btnDoublehandle()
    if PAGE == "LIST" then
        if einkBooksIndex == 1 then
            einkBooksIndex = #einkBooksTable
        else
            einkBooksIndex = einkBooksIndex - 1
        end
        showBookList(einkBooksTable, einkBooksIndex)
    else
        if page == 1 then return end
        page = page - 1
        showBook("http://192.168.31.70:2333/" ..
                     string.urlEncode(einkBooksTable[einkBooksIndex]), page)
    end
end

function einkShowStr(x, y, str, colored, font, clear, show)
    if clear == true then eink.clear() end
    -- eink.print(0, 12, PROJECT, 0, eink.font_opposansm12)
    -- eink.print(0, 20, "联网成功", 0, eink.font_opposansm12_chinese)
    eink.print(x, y, str, colored, font)
    if show == true then eink.show(0, 0, true) end
end

function einkBook()
    eink.model(eink.MODEL_1in54)
    if MOD_TYPE == "air101" then
        eink.setup(0, 0, 16, 19, 17, 20)
    elseif MOD_TYPE == "ESP32C3" then
        eink.setup(0, 2, 11, 10, 6, 7)
    end
    local width, height, rotate = 200, 200, 0
    eink.setWin(width, height, rotate)
    wifiConnect.connect("Xiaomi_AX6000", "Air123456")
    local result, code, data = httpLib.request("GET",
                                               "http://192.168.31.70:2333/getBooks")
    if result == false then
        log.error(tag, "获取图书列表失败 ", data)
    else
        einkBooksTable = json.decode(data)
        showBookList(einkBooksTable, 1)
    end
end

btnSetup(9, 1000, btnShortHandle, btnLongHandle, btnDoublehandle)

sys.taskInit(einkBook)

sys.run()

