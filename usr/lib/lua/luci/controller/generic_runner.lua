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
    local upload = luci.http.formvalue("upload")
    if upload and upload ~= "" then
        fs.writefile("/etc/config/generic_runner", upload)
        luci.sys.call("/etc/init.d/generic_runner restart >/dev/null 2>&1")
    end
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "generic_runner"))
end

function action_get_log()
    local uci = require "luci.model.uci".cursor()
    local binaries = {}
    
    -- 动态遍历配置文件，找出所有启用的程序
    uci:foreach("generic_runner", "program", function(s)
        if s.enabled == "1" and s.bin_path and s.bin_path ~= "" then
            -- 提取二进制文件名 (例如从 /usr/bin/frpc 提取出 frpc)
            local basename = s.bin_path:match("([^/]+)$")
            if basename then
                table.insert(binaries, basename)
            end
        end
    end)
    
    local log = ""
    if #binaries > 0 then
        -- 拼接 grep 多关键字匹配，例如: "frpc|myapp|testbin"
        local grep_pattern = table.concat(binaries, "|")
        -- 抓取包含这些文件名的最新 100 行日志
        log = luci.sys.exec("logread | grep -E '" .. grep_pattern .. "' | tail -n 100")
    end
    
    if not log or log == "" then
        log = "暂无日志信息...\n请确保全局及程序实例已启用，并且程序产生了终端输出。"
    end
    
    luci.http.prepare_content("text/plain; charset=utf-8")
    luci.http.write(log)
end
