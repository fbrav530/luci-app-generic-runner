local m, s, o

m = Map("generic_runner", _("通用程序运行器"), _("这是一个通用的 LuCI 界面，允许你自定义任意二进制文件的路径、启动参数并查看日志。"))

s = m:section(TypedSection, "generic_runner", _("全局设置"))
s.anonymous = true

-- 1. 启用开关
o = s:option(Flag, "enabled", _("启用"))
o.default = "0"
o.rmempty = false

-- 2. 自定义二进制路径
o = s:option(Value, "bin_path", _("二进制文件路径"))
o.datatype = "file"
o.placeholder = "/usr/bin/your-binary"
o.rmempty = false
o._description = _("请输入您想运行的二进制程序的绝对路径，例如 /usr/bin/v2ray 或 /usr/sbin/nginx")

-- 3. 自定义启动参数
o = s:option(Value, "extra_args", _("自定义启动参数"))
o.rmempty = true
o._description = _("参数之间请用空格分隔，例如：-c /etc/config.json --daemon")

-- 4. 日志路径
o = s:option(Value, "log_path", _("日志文件路径"))
o.default = "/var/log/generic_runner.log"
o.rmempty = false

-- ------------------ 实时日志查看模块 ------------------
local log_title = s:option(DummyValue, "_log_title", _("运行日志"))

local log_view = s:option(DummyValue, "_log_view")
log_view.rawhtml = true
log_view.value = [[
<textarea class="cbi-input-textarea" style="width: 100%; font-family: monospace;" id="log_content" rows="15" readonly="readonly" wrap="off">正在加载日志...</textarea>
<script type="text/javascript">//<![CDATA[
    function fetch_log() {
        XHR.get(']] .. luci.dispatcher.build_url("admin", "services", "generic_runner", "log") .. [[', null,
            function(x, data) {
                var textarea = document.getElementById('log_content');
                if (textarea && data) {
                    textarea.value = data;
                    // 自动滚动到最底部
                    textarea.scrollTop = textarea.scrollHeight;
                }
            }
        );
    }
    // 每 3 秒自动刷新一次日志
    window.setInterval(fetch_log, 3000);
    // 页面加载时立即执行一次
    document.addEventListener("DOMContentLoaded", fetch_log);
//]]></script>
]]

-- 页面提交后自动应用并重启服务
s.setsavehook = function()
    luci.sys.call("/etc/init.d/generic_runner restart >/dev/null 2>&1")
end

return m
