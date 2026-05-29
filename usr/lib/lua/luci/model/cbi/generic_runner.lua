-- 显式引入 LuCI 翻译函数，完美兼容 OpenWrt 22.03+ (ucode 架构)
local _ = luci.i18n.translate

local m, s, o

m = Map("generic_runner", _("多程序通用运行器"), _("你可以在此页面自由添加多个不同的二进制程序，并为它们分别指定独立的运行路径与参数。"))

-- ------------------ 1. 全局总开关 ------------------
s = m:section(NamedSection, "global", "generic_runner", _("全局控制"))
s.anonymous = true

o = s:option(Flag, "enabled", _("启用所有程序"))
o.default = "0"
o.rmempty = false


-- ------------------ 2. 多程序动态表格列表 ------------------
s = m:section(TypedSection, "program", _("程序运行列表"))
s.anonymous = true
s.addremove = true            -- 开启网页前端的【添加】和【删除】按钮
s.template = "cbi/tblsection" -- 将列表渲染为紧凑、直观的表格样式

-- 第一列：程序备注名
o = s:option(Value, "name", _("程序名称(备注)"))
o.placeholder = "例如：节点A"
o.rmempty = false

-- 第二列：二进制路径
o = s:option(Value, "bin_path", _("二进制文件绝对路径"))
o.datatype = "file"
o.placeholder = "/usr/bin/custom-app"
o.rmempty = false

-- 第三列：自定义启动参数
o = s:option(Value, "extra_args", _("启动参数"))
o.placeholder = "-c /etc/config.json"
o.rmempty = true

-- 页面点击“保存&应用”按钮后，自动调用后台 init 脚本重启服务
s.setsavehook = function()
    luci.sys.call("/etc/init.d/generic_runner restart >/dev/null 2>&1")
end

return m
