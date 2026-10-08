-- RISC-V assembly (.s / .S / .asm buffers): run, debug and disassemble with the `rv`
-- helper (dotfiles/scripts/rv.sh, installed by home.nix). RV32 by default;
-- <leader>x6 switches this buffer to RV64. LSP (asm-lsp) gives K = instruction docs,
-- completion and assembler errors inline.

-- GNU as for RISC-V uses '#' comments (gcc / gc toggles them).
vim.bo.commentstring = "# %s"

local function rv_cmd(sub)
  vim.cmd("silent update") -- run what's on screen, not the last save
  local cmd = { "rv" }
  if vim.b.rv64 then table.insert(cmd, "-64") end
  vim.list_extend(cmd, { sub, vim.api.nvim_buf_get_name(0) })
  return cmd
end

-- Run `cmd` in a terminal: `where` opens the window ("botright 12new" / "tabnew").
local function in_terminal(cmd, where)
  local dir = vim.fn.expand("%:p:h")
  vim.cmd(where)
  vim.fn.jobstart(cmd, { term = true, cwd = dir })
  vim.cmd("startinsert")
end

local function map(lhs, fn, desc)
  vim.keymap.set("n", lhs, fn, { buffer = true, desc = desc })
end

map("<leader>xr", function()
  in_terminal(rv_cmd("run"), "botright 12new")
end, "RISC-V: run (QEMU)")

-- gdb's TUI wants the whole screen: its own tab. si = step, c = continue, q = quit.
map("<leader>xd", function()
  in_terminal(rv_cmd("debug"), "tabnew")
end, "RISC-V: debug (gdb)")

-- Disassembly next to the source: machine code (hex) per instruction.
map("<leader>xo", function()
  local out = vim.fn.systemlist(rv_cmd("dump"))
  vim.cmd("vertical botright new")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, out)
  vim.bo.buftype, vim.bo.bufhidden, vim.bo.swapfile = "nofile", "wipe", false
  vim.bo.syntax = "asm"
  vim.bo.modifiable = false
end, "RISC-V: disassemble (objdump)")

map("<leader>x6", function()
  vim.b.rv64 = not vim.b.rv64 or nil
  vim.notify("RISC-V: " .. (vim.b.rv64 and "RV64" or "RV32") .. " for this buffer")
end, "RISC-V: toggle RV32/RV64")
