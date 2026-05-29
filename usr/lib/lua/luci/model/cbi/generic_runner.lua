local _ = luci.i18n.translate

local m, s, o

m = Map("generic_runner", _("多程序通用运行器"), _("你可以在此页面自由添加多个不同的二进制程序，并可以单独控制它们的启停状态。"))

-- ------------------ 1. 全局总开关 ------------------
s = m:section(NamedSection, "global", "generic_runner", _("全局控制"))
s.anonymous = true

o = s:option(Flag, "enabled", _("启用所有程序"))
o.default = "0"
o.rmempty = false


-- ------------------ 2. 多程序动态表格列表 ------------------
s = m:section(TypedSection, "program", _("程序运行列表"))
s.anonymous = true
s.addremove = true
s.template = "cbi/tblsection"

-- 第一列：单程序启用开关（核心新增 ⭐️）
o = s:option(Flag, "enabled", _("启用"))
o.default = "1"
o.rmempty = false

-- 第二列：程序备注名
o = s:option(Value, "name", _("程序名称(备注)"))
o.placeholder = "例如：节点A"
o.rmempty = false

-- 第三列：二进制路径
o = s:option(Value, "bin_path", _("二进制绝对路径"))
o.datatype = "file"
o.placeholder = "/usr/bin/custom-app"
o.rmempty = false

-- 第四列：自定义启动参数
o = s:option(Value, "extra_args", _("启动参数"))
o.placeholder = "-c /etc/config.json"
o.rmempty = true

-- 第五列：守护 - 重启间隔时间
o = s:option(Value, "respawn_timeout", _("守护间隔(秒)"))
o.datatype = "integer"
o.default = "5"
o.rmempty = false

-- 第六列：守护 - 连续失败最大重试次数
o = s:option(Value, "respawn_retry", _("最大重试次数"))
o.datatype = "integer"
o.default = "5"
o.rmempty = false

s.setsavehook = function()
    luci.sys.call("/etc/init.d/generic_runner restart >/dev/null 2>&1")
end

return m
