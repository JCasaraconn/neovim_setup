return {
  {
    "declancm/maximize.nvim",
    config = function()
      require("maximize").setup({})

      -- Track sidebar visibility per tab so maximize/restore can reopen them
      local sidebar_state = {}

      vim.api.nvim_create_autocmd("User", {
        pattern = "WindowMaximizeStart",
        callback = function()
          local tab = vim.api.nvim_get_current_tabpage()
          sidebar_state[tab] = {}

          -- Close neo-tree if visible (its buffer is non-restorable and gets force-deleted otherwise)
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype == "neo-tree" then
              sidebar_state[tab].neo_tree = true
              pcall(vim.cmd, "Neotree close")
              break
            end
          end

          -- Close Claude terminal if visible (its buffer gets destroyed during maximize)
          local ok, claude_term = pcall(require, "claudecode.terminal")
          if ok and claude_term.get_active_terminal_bufnr then
            local bufnr = claude_term.get_active_terminal_bufnr()
            if bufnr then
              local info = vim.fn.getbufinfo(bufnr)
              if info and #info > 0 and #info[1].windows > 0 then
                sidebar_state[tab].claude = true
                claude_term.close()
              end
            end
          end
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "WindowRestoreEnd",
        callback = function()
          local tab = vim.api.nvim_get_current_tabpage()
          local state = sidebar_state[tab]
          if not state then
            return
          end
          sidebar_state[tab] = nil

          local cur_win = vim.api.nvim_get_current_win()

          if state.neo_tree then
            pcall(vim.cmd, "Neotree show")
          end

          if state.claude then
            local ok, claude_term = pcall(require, "claudecode.terminal")
            if ok and claude_term.ensure_visible then
              claude_term.ensure_visible()
            end
          end

          -- Restore focus to the editor window
          if vim.api.nvim_win_is_valid(cur_win) then
            vim.api.nvim_set_current_win(cur_win)
          end
        end,
      })

      vim.keymap.set("n", "<Leader>z", "<Cmd>lua require('maximize').toggle()<CR>", { noremap = true, silent = true })
    end,
  },
}

