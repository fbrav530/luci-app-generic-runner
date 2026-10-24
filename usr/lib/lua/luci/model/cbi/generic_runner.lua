local fs  = require "nixio.fs"
local sys = require "luci.sys"

-- 映射 UCI 配置文件 (对应 /etc/config/generic_runner)
m = Map("generic_runner", translate("Generic Runner"), translate("在此处管理并上传你的二进制程序，文件将自动保存并授权至 /root/ 目录。"))

-- 使用 TypedSection 支持动态添加多个实例
s = m:section(TypedSection, "runner", translate("程序实例"))
s.anonymous = true
s.addremove = true  -- 允许动态添加和删除

-- 启用开关
e = s:option(Flag, "enable", translate("启用"))
e.rmempty = false

-- 实例名称
name = s:option(Value, "name", translate("名称/备注"))
name.rmempty = true

-- 【核心修改】：文件上传控件
bin = s:option(FileUpload, "bin_path", translate("程序路径 / 上传"), translate("请上传二进制文件。每次添加新项都可单独上传。"))
bin.rmempty = false

-- 重写 write 方法来处理上传后的文件存放与提权
function bin.write(self, section, value)
    -- value 是上传后系统暂存的路径或用户手动输入的路径
    if value and fs.access(value) then
        -- 提取文件名
        local filename = fs.basename(value)
        -- 拼接目标路径为 /root/xxx
        local target_path = "/root/" .. filename
        
        -- 如果临时文件不在目标位置，则移动文件
        if value ~= target_path then
            fs.rename(value, target_path)
        end
        
        -- 赋予可执行权限 (chmod +x)
        fs.chmod(target_path, 755)
        
        -- 将新的路径写入到 UCI 配置中
        Value.write(self, section, target_path)
    else
        -- 如果没有实际文件传入，直接写入用户输入的字符串
        Value.write(self, section, value)
    end
end

-- 运行参数
args = s:option(Value, "args", translate("运行参数"))
args.rmempty = true

return m
