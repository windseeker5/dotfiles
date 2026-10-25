-- Raspberry Pi (64-bit ARM): LuaJIT's compiler crashes Neovim there with
-- "illegal instruction" about half the time. Plain LuaJIT is stable and fast enough.
if jit and jit.arch == "arm64" then
  jit.off()
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
