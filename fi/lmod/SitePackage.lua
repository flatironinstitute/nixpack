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

local lmodRoot = '@LMOD@/lmod/lmod/modulefiles/Core'
local lmodRootPat = '^' .. lmodRoot:gsub('[.-]', '%%%1') .. '$'
local modRoot = '@MODS@'
local modRootPat = '^' .. modRoot:gsub('[.-]', '%%%1') .. '/(.*)$'
local availRepT = {
  trim = '%1',
  group = 'Modules'
}

local function avail_hook(t)
  local availStyle = masterTbl().availStyle
  local rep = availRepT[availStyle]
  if rep == nil then
    return
  end
  for k,v in pairs(t) do
    if k:find(lmodRootPat) then
      t[k] = 'lmod'
    elseif k == '/cm/shared/sw/modules' then
      t[k] = "Traditional"
    else
      t[k] = k:gsub(modRootPat, rep)
    end
  end
end

hook.register("avail",avail_hook)
