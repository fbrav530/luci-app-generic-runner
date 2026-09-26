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

-- 核心修复：使用 setfilehandler 处理流文件并返回 HTTP 状态码
function action_import()
    local fs = require "nixio.fs"
    local file_content = ""
    
    -- 注册文件处理器，接收传进来的二进制流
    luci.http.setfilehandler(
        function(meta, chunk, eof)
            if not meta then return end
            if meta.name == "upload" and chunk then
                file_content = file_content .. chunk
            end
        end
    )
    
    -- 触发 formvalue 解析，这一步会执行上面的 setfilehandler
    luci.http.formvalue("upload")
    
    if file_content ~= "" then
        fs.writefile("/etc/config/generic_runner", file_content)
        luci.sys.call("/etc/init.d/generic_runner restart >/dev/null 2>&1")
        luci.http.status(200, "OK")
    else
        luci.http.status(400, "Bad Request")
    end
end

function action_get_log()
    local uci = require "luci.model.uci".cursor()
    local binaries = {}
    
    uci:foreach("generic_runner", "program", function(s)
        if s.enabled == "1" and s.bin_path and s.bin_path ~= "" then
            local basename = s.bin_path:match("([^/]+)$")
            if basename then
                table.insert(binaries, basename)
            end
        end
    end)
    
    local log = ""
    if #binaries > 0 then
        local grep_pattern = table.concat(binaries, "|")
        log = luci.sys.exec("logread | grep -E '" .. grep_pattern .. "' | tail -n 100")
    end
    
    if not log or log == "" then
        log = "暂无日志信息...\n请确保全局及程序实例已启用，并且程序产生了终端输出。"
    end
    
    luci.http.prepare_content("text/plain; charset=utf-8")
    luci.http.write(log)
end
