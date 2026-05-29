module("luci.controller.generic_runner", package.seeall)

function index()
    -- 注册主菜单
    entry({"admin", "services", "generic_runner"}, cbi("generic_runner"), _("通用运行器"), 60).dependent = true
    
    -- 注册给 Ajax 读取日志用的 API 接口
    entry({"admin", "services", "generic_runner", "log"}, call("action_log")).dependent = true
end

function action_log()
    local uci = require("luci.model.uci").cursor()
    local log_path = uci:get("generic_runner", "main", "log_path") or "/var/log/generic_runner.log"
    
    luci.http.prepare_content("text/plain; charset=utf-8")
    
    -- 读取日志文件的最后 100 行
    local file = io.popen("tail -n 100 " .. luci.util.shellquote(log_path) .. " 2>&1")
    if file then
        while true do
            local line = file:read("*l")
            if not line then break end
            luci.http.write(line .. "\n")
        end
        file:close()
    else
        luci.http.write("无法读取日志文件。")
    end
end
