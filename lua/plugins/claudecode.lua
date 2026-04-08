-- Claude Code integration for Neovim via coder/claudecode.nvim

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = true,
  opts = {
    -- Uncomment and set this if you used `claude migrate-installer`
    -- or installed the native binary (check with `which claude`)
    -- terminal_cmd = "~/.claude/local/claude",

    log_level = "info", -- change to "debug" if troubleshooting

    terminal = {
      split_side = "right",
      split_width_percentage = 0.30,
      provider = "native", -- uses snacks.nvim automatically
    },

    diff_opts = {
      auto_close_on_accept = true,
      vertical_split = true,
    },
  },
  keys = {
    { "<leader>a", nil, desc = "AI/Claude Code" },
    {
      "<leader>ac",
      function()
        -- If the terminal is the only window, open a blank split first
        -- so closing the terminal doesn't trigger E444 (cannot close last window).
        local wins = vim.api.nvim_tabpage_list_wins(0)
        local non_float_wins = vim.tbl_filter(function(w)
          return vim.api.nvim_win_get_config(w).relative == ""
        end, wins)
        if #non_float_wins == 1 and vim.bo.buftype == "terminal" then
          vim.cmd("vnew")
        end
        vim.cmd("ClaudeCode")
        vim.defer_fn(function()
          if vim.bo.buftype == "terminal" and vim.api.nvim_get_mode().mode == "t" then
            vim.cmd("stopinsert")
          end
        end, 50)
      end,
      desc = "[Claude] Toggle Claude",
    },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "[Claude] Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "[Claude] Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "[Claude] Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "[Claude] Select model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "[Claude] Add buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "[Claude] Send selection" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "[Claude] Add file",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
    },
    -- Diff management
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "[Claude] Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "[Claude] Deny diff" },
  },
}
