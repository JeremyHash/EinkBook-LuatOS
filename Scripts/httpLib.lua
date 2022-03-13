local httpLib = {}
-- printTable(esphttp)
-- {
-- 	"init" = function: 42020EA2,
-- 	"post_field" = function: 4202124A,
-- 	"perform" = function: 420212E6,
-- 	"status_code" = function: 420213A8,
-- 	"content_length" = function: 420213F6,
-- 	"read_response" = function: 420211C8,
-- 	"set_header" = function: 42021142,
-- 	"get_header" = function: 420210CC,
-- 	"cleanup" = function: 42021088,
-- 	"is_done" = function: 42021028,
-- 	"GET" = 0,
-- 	"POST" = 1,
-- 	"PUT" = 2,
-- 	"PATCH" = 3,
-- 	"DELETE" = 4,
-- 	"EVENT_ON_FINISH" = 5,
-- 	"EVENT_ERROR" = 0,
-- 	"EVENT_DISCONNECTED" = 6,
-- 	"EVENT_ON_DATA" = 4,
-- }

local methodTable = {
    GET = esphttp.GET,
    POST = esphttp.POST,
    PUT = esphttp.PUT,
    DELETE = esphttp.DELETE
}

function httpLib.request(method, url, head)
    local responseCode = 0
    local httpc = esphttp.init(methodTable[method], url)
    if httpc == nil then
        esphttp.cleanup(httpc)
        return false, responseCode, "create httpClient error"
    end
    if head ~= nil then
        for k, v in pairs(head) do
            esphttp.set_header(httpc, k, v)
        end
    end
    local ok, err = esphttp.perform(httpc, true)
    if ok then
        local response = ""
        while 1 do
            local result, c, ret, data = sys.waitUntil("ESPHTTP_EVT", 20000)
            -- log.info("ESPHTTP_EVT", result, c, ret, data)
            if result == false then
                esphttp.cleanup(httpc)
                return false, responseCode, "wait for http response timeout"
            end
            if c == httpc then
                if esphttp.is_done(httpc, ret) then
                    esphttp.cleanup(httpc)
                    return true, esphttp.status_code(httpc), response
                end
                if ret == esphttp.EVENT_ON_DATA then
                    response = response .. data
                end
            end
        end
    else
        esphttp.cleanup(httpc)
        return false, responseCode, "perform httpClient error " .. err
    end
end

return httpLib
