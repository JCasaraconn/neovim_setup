return {
  {
    "declancm/maximize.nvim",
    opts = {},
    config = function()
      vim.keymap.set("n", "<Leader>z", "<Cmd>lua require('maximize').toggle()<CR>", { noremap = true, silent = true })
    end,
  },
}

