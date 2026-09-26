m = Map("generic_runner", translate("Generic Runner"), translate("在此管理 Generic Runner 的配置与运行状态。"))

-- 【关键】挂载我们在 View 中创建的工具栏和日志模块
local s_tools = m:section(TypedSection, "generic_runner")
s_tools.anonymous = true
s_tools.template = "generic_runner/log_and_tools"

-- 下面是你原本的参数配置区域
s = m:section(TypedSection, "generic_runner", translate("基本设置"))
s.anonymous = true
s.addremove = false

-- 配置示例：启用开关
local enable = s:option(Flag, "enable", translate("启用服务"))
enable.rmempty = false

-- 配置示例：端口设置
local port = s:option(Value, "port", translate("监听端口"))
port.datatype = "port"
port.default = "8080"

return m
