module("luci.controller.generic_runner", package.seeall)

function index()
    -- 在“服务 (services)”菜单下注册名为“通用运行器”的页面
    entry({"admin", "services", "generic_runner"}, cbi("generic_runner"), _("通用运行器"), 60).dependent = true
end
