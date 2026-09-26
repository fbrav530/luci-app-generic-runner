module("luci.controller.generic_runner", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/generic_runner") then
        return
    end
    
    -- 主页面
    entry({"admin", "services", "generic_runner"}, cbi("generic_runner"), _("Generic Runner"), 60)
    
    -- 导入、导出、获取日志的后端接口 (leaf=true 表示不生成菜单，仅作为接口)
    entry({"admin", "services", "generic_runner", "export"}, call("action_export"), nil).leaf = true
    entry({"admin", "services", "generic_runner", "import"}, call("action_import"), nil).leaf = true
    entry({"admin", "services", "generic_runner", "get_log"}, call("action_get_log"), nil).leaf = true
end

-- 处理导出
function action_export()
    local fs = require "nixio.fs"
    luci.http.header('Content-Disposition', 'attachment; filename="generic_runner.config"')
    luci.http.prepare_content("application/octet-stream")
    luci.http.write(fs.readfile("/etc/config/generic_runner") or "")
end

-- 处理导入
function action_import()
    local fs = require "nixio.fs"
    local upload = luci.http.formvalue("upload")
    if upload and upload ~= "" then
        fs.writefile("/etc/config/generic_runner", upload)
        luci.sys.call("/etc/init.d/generic_runner restart >/dev/null 2>&1")
    end
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "generic_runner"))
end

-- 处理日志抓取
function action_get_log()
    -- 默认从系统日志中抓取包含 "generic_runner" 关键字的最新 100 行记录
    -- 如果你的程序日志输出到了独立文件，可改为 fs.readfile("/var/log/generic_runner.log")
    local log = luci.sys.exec("logread -e generic_runner | tail -n 100")
    if not log or log == "" then
        log = "暂无日志信息...\n请确保程序已启动并在 init.d 中开启了 stdout 日志输出。"
    end
    luci.http.prepare_content("text/plain; charset=utf-8")
    luci.http.write(log)
end
