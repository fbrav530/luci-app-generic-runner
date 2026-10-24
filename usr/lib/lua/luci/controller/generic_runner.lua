module("luci.controller.generic_runner", package.seeall)

local fs = require "nixio.fs"
local jsonc = require "luci.jsonc"

-- 二进制文件上传目录
local UPLOAD_DIR = "/root"
-- 上传后自动设置的权限
local UPLOAD_MODE = "755"

function index()
    if not nixio.fs.access("/etc/config/generic_runner") then
        return
    end

    entry({"admin", "services", "generic_runner"}, cbi("generic_runner"), _("通用运行器"), 60)

    entry({"admin", "services", "generic_runner", "export"}, call("action_export"), nil).leaf = true
    entry({"admin", "services", "generic_runner", "import"}, call("action_import"), nil).leaf = true
    entry({"admin", "services", "generic_runner", "get_log"}, call("action_get_log"), nil).leaf = true

    -- 新增：二进制文件上传（保存到 /root，自动 755）
    entry({"admin", "services", "generic_runner", "upload_bin"}, call("action_upload_bin"), nil).leaf = true
end

function action_export()
    luci.http.header('Content-Disposition', 'attachment; filename="generic_runner.config"')
    luci.http.prepare_content("application/octet-stream")
    luci.http.write(fs.readfile("/etc/config/generic_runner") or "")
end

function action_import()
    local file_content = ""

    luci.http.setfilehandler(
        function(meta, chunk, eof)
            if not meta then return end
            if meta.name == "upload" and chunk then
                file_content = file_content .. chunk
            end
        end
    )
    luci.http.formvalue("upload")

    if file_content ~= "" then
        fs.writefile("/etc/config/generic_runner", file_content)
        luci.sys.call("/etc/init.d/generic_runner restart >/dev/null 2>&1")
        luci.http.status(200, "OK")
    else
        luci.http.status(400, "Bad Request")
    end
end

-- 核心修改：新增 JSON 响应和按应用名称筛选日志
function action_get_log()
    local uci = require "luci.model.uci".cursor()
    local req_app = luci.http.formvalue("app") -- 接收前端传来的筛选参数
    local binaries = {}

    uci:foreach("generic_runner", "program", function(s)
        if s.enabled == "1" and s.bin_path and s.bin_path ~= "" then
            local basename = s.bin_path:match("([^/]+)$")
            if basename then
                -- 去重逻辑
                local exists = false
                for _, v in ipairs(binaries) do
                    if v == basename then exists = true break end
                end
                if not exists then table.insert(binaries, basename) end
            end
        end
    end)

    local log = ""
    if #binaries > 0 then
        if req_app and req_app ~= "" and req_app ~= "all" then
            -- 如果选择了特定的程序，只 grep 这个程序
            log = luci.sys.exec("logread | grep -E '" .. req_app .. "' | tail -n 100")
        else
            -- 否则 grep 所有的程序
            local grep_pattern = table.concat(binaries, "|")
            log = luci.sys.exec("logread | grep -E '" .. grep_pattern .. "' | tail -n 100")
        end
    end

    if not log or log == "" then
        log = "暂无日志信息...\n请确保全局及程序实例已启用，并且程序产生了终端输出。"
    end

    luci.http.prepare_content("application/json")
    luci.http.write(jsonc.stringify({
        apps = binaries,
        log = log
    }))
end

-- ============================================================
-- 二进制文件上传
-- ============================================================

-- 过滤文件名：只保留路径最后一段，并剔除非安全字符，防止目录穿越
local function sanitize_name(fname)
    if not fname or fname == "" then return nil end

    fname = tostring(fname):gsub("\\", "/")
    fname = fname:match("([^/]+)$") or fname
    -- 允许：字母数字、UTF-8 多字节字符、点、下划线、中划线、加号
    fname = fname:gsub("[^\128-\255%w%._%-%+]", "_")
    fname = fname:gsub("^[%.]+", "")

    if fname == "" or fname == "." or fname == ".." then return nil end
    if #fname > 120 then fname = fname:sub(-120) end

    return fname
end

local function json_out(tbl)
    luci.http.prepare_content("application/json")
    luci.http.write(jsonc.stringify(tbl))
end

-- 接收上传的二进制，写入 /root 并 chmod 755
function action_upload_bin()
    local fh, target, saved, err

    luci.http.setfilehandler(
        function(meta, chunk, eof)
            if meta then
                -- 新的表单分片开始
                if not target and meta.name == "upload" then
                    saved = sanitize_name(meta.file or meta.filename)
                    if saved then
                        target = UPLOAD_DIR .. "/" .. saved
                        fh = io.open(target, "wb")
                        if not fh then
                            err = "无法写入文件：" .. target
                        end
                    else
                        err = "文件名不合法"
                    end
                end
            end

            if fh then
                if chunk then fh:write(chunk) end
                if eof then
                    fh:close()
                    fh = nil
                end
            end
        end
    )

    -- 触发 multipart 解析，文件内容以流的方式写入磁盘，不会占用大量内存
    luci.http.formvalue("upload")

    if target and fs.access(target) then
        -- 权限 755，属主 root:root
        luci.sys.call("chmod " .. UPLOAD_MODE .. " '" .. target .. "' >/dev/null 2>&1")
        luci.sys.call("chown root:root '" .. target .. "' >/dev/null 2>&1")

        local size = tonumber(fs.stat(target, "size")) or 0
        if size <= 0 then
            fs.remove(target)
            json_out({ ok = false, msg = "上传失败：文件内容为空" })
            return
        end

        json_out({
            ok   = true,
            path = target,
            name = saved,
            size = size,
            mode = UPLOAD_MODE
        })
    else
        json_out({ ok = false, msg = err or "上传失败：未接收到文件" })
    end
end
