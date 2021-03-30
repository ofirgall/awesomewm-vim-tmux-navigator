local awful = require("awful")
local glib = require("lgi").GLib
local unpack = unpack or table.unpack -- luacheck: globals unpack
local module = {}

local function new(args)
    local client, root, keygrabber = client, root, keygrabber -- luacheck: globals client root keygrabber
    local keys = args or {up = {"k", "Up"}, down = {"j", "Down"}, left = {"h", "Left"}, right = {"l", "Right"}}

    local mod = keys.mod or "Mod4"
    local mod_keysym = keys.mod_keysym or "Super_L"

    local tmux = {}
    tmux.left = function()
        root.fake_input("key_release", "Left")
        root.fake_input("key_press", "Left")
        root.fake_input("key_release", "Left")
    end
    tmux.right = function()
        root.fake_input("key_release", "Right")
        root.fake_input("key_press", "Right")
        root.fake_input("key_release", "Right")
    end
    tmux.up = function()
        root.fake_input("key_release", "Up")
        root.fake_input("key_press", "Up")
        root.fake_input("key_release", "Up")
    end
    tmux.down = function()
        root.fake_input("key_release", "Down")
        root.fake_input("key_press", "Down")
        root.fake_input("key_release", "Down")
    end
    tmux.navigate = function(dir)
        keygrabber.stop()
        root.fake_input("key_release", mod_keysym)
        root.fake_input("key_press", "Control_L")
        tmux[dir]()
        root.fake_input("key_release", "Control_L")
        root.fake_input("key_press", mod_keysym)
    end

    local vim = {}
    vim.left = function()
        root.fake_input("key_release", "h")
        root.fake_input("key_press", "h")
        root.fake_input("key_release", "h")
    end
    vim.right = function()
        root.fake_input("key_release", "l")
        root.fake_input("key_press", "l")
        root.fake_input("key_release", "l")
    end
    vim.up = function()
        root.fake_input("key_release", "k")
        root.fake_input("key_press", "k")
        root.fake_input("key_release", "k")
    end
    vim.down = function()
        root.fake_input("key_release", "j")
        root.fake_input("key_press", "j")
        root.fake_input("key_release", "j")
    end
    vim.navigate = function(dir)
        keygrabber.stop()
        root.fake_input("key_release", mod_keysym)
        root.fake_input("key_release", "Control_L")
        root.fake_input("key_press", "Control_L")
        vim[dir]()
        root.fake_input("key_release", "Control_L")
        root.fake_input("key_press", mod_keysym)
    end

    local focus = function(dir)
        local c = client.focus
        local client_name = c and c.name or ""
        if string.find(client_name, "- N?VIM$") then
            vim.navigate(dir)
            return
        else
            if string.find(client_name, "- TMUX$") then
                tmux.navigate(dir)
                return
            else
                awful.client.focus.global_bydirection(dir)
            end
        end
    end

    -- experimental version that uses pstree to determine the running application
    if keys.experimental then
        focus = function(dir)
            local c = client.focus
            local pid = c and c.pid or -1
            awful.spawn.easy_async("pstree -A -T " .. pid, function(out)
                if string.find(out, "[^.*\n]%-tmux: client") then
                    tmux.navigate(dir)
                    return
                else
                    if string.find(out, "[^.*\n]%-n?vim$") or string.find(out, "[^.*\n]%-n?vim%-") or
                        string.find(out, "^gvim$") or string.find(out, "^gvim%-") then
                        vim.navigate(dir)
                        return
                    else
                        awful.client.focus.global_bydirection(dir)
                    end
                end
            end)
        end
    end

    keys.mod = nil
    keys.mod_keysym = nil
    keys.experimental = nil

    local aw = {}
    glib.idle_add(glib.PRIORITY_DEFAULT_IDLE, function()
        for k, v in pairs(keys) do
            for _, key_name in ipairs(v) do
                aw[#aw + 1] = awful.key({mod}, key_name, function()
                    focus(k)
                end, {description = "focus " .. k .. " window", group = "client"})
            end
        end
        root.keys(awful.util.table.join(root.keys(), unpack(aw)))
    end)
    return module
end

return setmetatable(module, {
    __call = function(_, ...)
        return new(...)
    end
})
