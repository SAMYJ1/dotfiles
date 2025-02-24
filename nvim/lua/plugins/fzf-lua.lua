return {
  "ibhagwan/fzf-lua",
  opts = {
    buffers = {
      formatter = "path.filename_first",
    },
    previewers = {
      builtin = {
        title_fnamemodify = function(s)
          return vim.fn.fnamemodify(s, ":.")
        end,
      },
    },
  },
}
