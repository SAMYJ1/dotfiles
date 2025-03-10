-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set("i", "<C-p>", "<C-r>0", { noremap = true, silent = true })
vim.keymap.set("i", "<C-u>", "<esc><C-u>", { noremap = true, silent = true })
vim.keymap.set("i", "<C-d>", "<esc><C-d>", { noremap = true, silent = true })
