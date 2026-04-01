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
        vim.cmd("ClaudeCode")
        vim.defer_fn(function()
          if vim.bo.buftype == "terminal" and vim.api.nvim_get_mode().mode == "t" then
            vim.cmd("stopinsert")
          end
        end, 50)
      end,
      desc = "Toggle Claude",
    },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
    },
    -- Diff management
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
}
