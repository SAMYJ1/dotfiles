-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local english_input_source = "com.apple.keylayout.ABC"

local function switch_to_english_if_normal()
  if vim.fn.executable("macism") ~= 1 then
    return
  end

  if vim.api.nvim_get_mode().mode ~= "n" then
    return
  end

  vim.fn.jobstart({ "macism", english_input_source }, { detach = true })
end

local group = vim.api.nvim_create_augroup("user-input-method", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "VimEnter" }, {
  group = group,
  callback = switch_to_english_if_normal,
})
