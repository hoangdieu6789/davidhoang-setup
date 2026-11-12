-- Install every Mason package listed in lua/config/mason.lua and wait until all are done.
-- install.sh runs it so language servers are ready before the first `nvim`:
--   nvim --headless -c "luafile tools/mason-install.lua"
-- Exit code 0 = all installed, 1 = something failed (details are printed).

local function say(msg)
  io.stdout:write(msg .. "\n")
end

local function finish(ok)
  vim.cmd(ok and "qa!" or "cquit 1")
end

require("lazy").load({ plugins = { "mason.nvim" } })
require("mason").setup()
local registry = require("mason-registry")
local names = require("config.mason").mason_packages

local refreshed, refresh_ok = false, false
registry.refresh(function(success)
  refreshed, refresh_ok = true, success
end)
if not vim.wait(180000, function()
  return refreshed
end, 200) or not refresh_ok then
  say("ERR  Mason registry download failed (network, proxy or TLS). See README: Mason registry.")
  return finish(false)
end

local pending, failed = 0, {}
for _, name in ipairs(names) do
  local ok, pkg = pcall(registry.get_package, name)
  if not ok then
    table.insert(failed, name .. " (not in the Mason registry)")
  elseif pkg:is_installed() then
    say("ok   " .. name .. " (already installed)")
  else
    pending = pending + 1
    say("...  installing " .. name)
    pkg:install({}, function(success, result)
      pending = pending - 1
      if success then
        say("ok   " .. name)
      else
        table.insert(failed, name .. ": " .. tostring(result))
      end
    end)
  end
end

vim.wait(1200000, function()
  return pending == 0
end, 500)
for _, msg in ipairs(failed) do
  say("ERR  " .. msg)
end
if pending > 0 then
  say("ERR  timed out waiting for " .. pending .. " package(s)")
end
finish(#failed == 0 and pending == 0)
