local m, s, o

-- 修改标题为“通用运行器”
m = Map("generic_runner", translate("通用运行器"), translate("在这里管理通用运行器的配置与运行状态。"))

local s_tools = m:section(TypedSection, "generic_runner")
s_tools.anonymous = true
s_tools.template = "generic_runner/log_tools"

s = m:section(NamedSection, "global", "global", translate("全局设置"))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enabled", translate("启用通用运行器"))
o.rmempty = false


s = m:section(TypedSection, "program", translate("程序实例列表"))
s.anonymous = true
s.addremove = true
s.template = "cbi/tblsection"

o = s:option(Flag, "enabled", translate("启用"))
o.rmempty = false

o = s:option(Value, "name", translate("名称(Name)"))
o.rmempty = false

o = s:option(Value, "bin_path", translate("程序路径(Bin Path)"))
o.rmempty = false

o = s:option(Value, "extra_args", translate("启动参数(Extra Args)"))
o.rmempty = true

o = s:option(Value, "respawn_timeout", translate("重启超时(秒)"))
o.default = "5"
o.rmempty = true

o = s:option(Value, "respawn_retry", translate("重试次数"))
o.default = "5"
o.rmempty = true

return m
