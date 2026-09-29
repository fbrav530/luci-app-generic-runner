module("luci.controller.generic_runner", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/generic_runner") then
        return
    end
    
    entry({"admin", "services", "generic_runner"}, cbi("generic_runner"), _("通用运行器"), 60)
    
    entry({"admin", "services", "generic_runner", "export"}, call("action_export"), nil).leaf = true
    entry({"admin", "services", "generic_runner", "import"}, call("action_import"), nil).leaf = true
    entry({"admin", "services", "generic_runner", "get_log"}, call("action_get_log"), nil).leaf = true
end

function action_export()
    local fs = require "nixio.fs"
    luci.http.header('Content-Disposition', 'attachment; filename="generic_runner.config"')
    luci.http.prepare_content("application/octet-stream")
    luci.http.write(fs.readfile("/etc/config/generic_runner") or "")
end

function action_import()
    local fs = require "nixio.fs"
    local file_content = ""
    
    luci.http.setfilehandler(
        function(meta, chunk, eof)
            if not meta then return end
            if meta.name == "upload" and chunk then
                file_content = file_content .. chunk
            end
        end
    )
    luci.http.formvalue("upload")
    
    if file_content ~= "" then
        fs.writefile("/etc/config/generic_runner", file_content)
        luci.sys.call("/etc/init.d/generic_runner restart >/dev/null 2>&1")
        luci.http.status(200, "OK")
    else
        luci.http.status(400, "Bad Request")
    end
end

-- 核心修改：新增 JSON 响应和按应用名称筛选日志
function action_get_log()
    local uci = require "luci.model.uci".cursor()
    local req_app = luci.http.formvalue("app") -- 接收前端传来的筛选参数
    local binaries = {}
    
    uci:foreach("generic_runner", "program", function(s)
        if s.enabled == "1" and s.bin_path and s.bin_path ~= "" then
            local basename = s.bin_path:match("([^/]+)$")
            if basename then
                -- 去重逻辑
                local exists = false
                for _, v in ipairs(binaries) do
                    if v == basename then exists = true break end
                end
                if not exists then table.insert(binaries, basename) end
            end
        end
    end)
    
    local log = ""
    if #binaries > 0 then
        if req_app and req_app ~= "" and req_app ~= "all" then
            -- 如果选择了特定的程序，只 grep 这个程序
            log = luci.sys.exec("logread | grep -E '" .. req_app .. "' | tail -n 100")
        else
            -- 否则 grep 所有的程序
            local grep_pattern = table.concat(binaries, "|")
            log = luci.sys.exec("logread | grep -E '" .. grep_pattern .. "' | tail -n 100")
        end
    end
    
    if not log or log == "" then
        log = "暂无日志信息...\n请确保全局及程序实例已启用，并且程序产生了终端输出。"
    end
    
    local jsonc = require "luci.jsonc"
    luci.http.prepare_content("application/json")
    luci.http.write(jsonc.stringify({
        apps = binaries,
        log = log
    }))
end
