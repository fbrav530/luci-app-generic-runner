module("luci.controller.generic_runner", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/generic_runner") then
        return
    end
    
    -- 主页面入口
    entry({"admin", "services", "generic_runner"}, cbi("generic_runner"), _("Generic Runner"), 60)
    
    -- 导入、导出、读取日志的后端接口
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
    -- 抓取系统日志中带有 generic_runner 标签的内容，取最新的 150 行
    local log = luci.sys.exec("logread -e generic_runner | tail -n 150")
    if not log or log == "" then
        log = "暂无日志信息...\n请确保 Generic Runner 已全局启用，且存在正在运行的程序实例。"
    end
    luci.http.prepare_content("text/plain; charset=utf-8")
    luci.http.write(log)
end
