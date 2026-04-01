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

          -- Preserve Claude terminal through the maximize cycle.
          -- The buffer has bufhidden="hide" which makes maximize force-delete it.
          -- We hide the window (keeping buffer + process alive) and temporarily
          -- clear bufhidden so the buffer survives the deletion sweep.
          local ok, claude_term = pcall(require, "claudecode.terminal")
          if ok and claude_term.get_active_terminal_bufnr then
            local bufnr = claude_term.get_active_terminal_bufnr()
            if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
              local info = vim.fn.getbufinfo(bufnr)
              local is_visible = info and #info > 0 and #info[1].windows > 0

              if is_visible then
                sidebar_state[tab].claude_visible = true
                sidebar_state[tab].claude_focused = (vim.api.nvim_get_current_buf() == bufnr)
                -- Hide window but keep buffer + process alive (vs close() which destroys state)
                claude_term.simple_toggle()
              end

              -- Protect buffer from maximize's force-delete by temporarily clearing bufhidden
              sidebar_state[tab].claude_bufnr = bufnr
              sidebar_state[tab].claude_bufhidden = vim.bo[bufnr].bufhidden
              vim.bo[bufnr].bufhidden = ""
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

          -- Restore Claude terminal buffer properties and visibility
          if state.claude_bufnr and vim.api.nvim_buf_is_valid(state.claude_bufnr) then
            vim.bo[state.claude_bufnr].bufhidden = state.claude_bufhidden or "hide"
          end

          if state.claude_visible then
            local ok, claude_term = pcall(require, "claudecode.terminal")
            if ok then
              if state.claude_focused then
                claude_term.open() -- reopens with focus
              elseif claude_term.ensure_visible then
                claude_term.ensure_visible() -- reopens without focus
              end
            end
          end

          -- Restore focus to the editor window (unless Claude was focused)
          if not state.claude_focused and vim.api.nvim_win_is_valid(cur_win) then
            vim.api.nvim_set_current_win(cur_win)
          end
        end,
      })

      vim.keymap.set("n", "<Leader>z", "<Cmd>lua require('maximize').toggle()<CR>", { noremap = true, silent = true })
    end,
  },
}

