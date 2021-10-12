-- @module SitePackage

require("strict")

local Exec     = require("Exec")
local FrameStk = require("FrameStk")
local hook     = require("Hook")

local loads = {}

local function load_hook(t)
  local frameStk = FrameStk:singleton()
  if frameStk:atTop() then
    loads[#loads+1] = frameStk:userName()
  end
end

hook.register("load", load_hook)

local function finalize_hook(t)
  if t ~= "load" or #loads == 0 then
    return
  end
  local cmd = {"/usr/local/sbin/elklogger -m lmod -M"}
  local l = FrameStk:singleton():mt():list("fullName", "any")
  for i = 1, #l do
    cmd[#cmd+1] = l[i].fullName:multiEscaped()
  end
  cmd[#cmd+1] = "--"
  for i = 1, #loads do
    cmd[#cmd+1] = loads[i]:multiEscaped()
  end
  local exec = Exec:exec()
  exec:register(table.concat(cmd, " "))
end

hook.register("finalize", finalize_hook)

function avail_hook(t)
  local availStyle = masterTbl().availStyle
  if availStyle == "grouped" then
    for k,v in pairs(t) do
      if k:find('^/cm/shared/sw/nix/store/.*$') then
        t[k] = "Modules"
      elseif k == '/cm/shared/sw/modules' then
        t[k] = "Traditional"
      end
    end
  end
end

hook.register("avail",avail_hook)
