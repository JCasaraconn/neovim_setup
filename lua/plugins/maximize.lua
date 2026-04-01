return {
  {
    "declancm/maximize.nvim",
    config = function()
      require("maximize").setup({})

      -- State for regular maximize (editor-focused, sidebars handled via autocmds)
      local sidebar_state = {}
      -- State for Claude-focused maximize (bypasses maximize.nvim entirely)
      local claude_max_state = {}

      -- Close neo-tree if visible, returns true if it was open
      local function close_neo_tree()
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].filetype == "neo-tree" then
            pcall(vim.cmd, "Neotree close")
            return true
          end
        end
        return false
      end

      -- Save current editor window layout as a session script (excludes terminal/sidebar windows)
      local function save_editor_session()
        local save_sopts = vim.o.sessionoptions
        vim.o.sessionoptions = "blank,help,winsize"
        local save_this = vim.v.this_session

        local tmp = os.tmpname()
        vim.cmd.mksession({ tmp, bang = true })
        local f = assert(io.open(tmp, "rb"))
        local script = f:read("*all")
        f:close()
        os.remove(tmp)

        vim.v.this_session = save_this
        vim.o.sessionoptions = save_sopts
        return script
      end

      -- Maximize the Claude terminal: save editor layout, show only Claude
      local function maximize_claude(claude_term, claude_bufnr)
        local normal_count = 0
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if vim.api.nvim_win_get_config(win).relative == "" then
            normal_count = normal_count + 1
          end
        end
        if normal_count <= 1 then
          vim.notify("Already one window", vim.log.levels.WARN)
          return
        end

        local tab = vim.api.nvim_get_current_tabpage()
        local save_lazyredraw = vim.o.lazyredraw
        vim.o.lazyredraw = true

        claude_max_state[tab] = {
          claude_bufnr = claude_bufnr,
          claude_bufhidden = vim.bo[claude_bufnr].bufhidden,
          neo_tree = close_neo_tree(),
        }

        -- Protect Claude buffer from any deletion sweep
        vim.bo[claude_bufnr].bufhidden = ""

        -- Hide Claude window (keeps buffer + process alive)
        claude_term.simple_toggle()

        -- Save editor-only session (Claude and neo-tree are already hidden/closed)
        claude_max_state[tab].restore_script = save_editor_session()

        -- Close all editor windows, show Claude as the only window
        vim.cmd.only({ bang = true })
        vim.api.nvim_win_set_buf(0, claude_bufnr)
        vim.cmd("startinsert")

        vim.t.maximized = true
        vim.o.lazyredraw = save_lazyredraw
      end

      -- Restore from Claude-focused maximize
      local function restore_claude()
        local tab = vim.api.nvim_get_current_tabpage()
        local state = claude_max_state[tab]
        if not state then return end
        claude_max_state[tab] = nil

        local save_lazyredraw = vim.o.lazyredraw
        vim.o.lazyredraw = true

        -- Keep Claude buffer alive while we switch away from it
        if vim.api.nvim_buf_is_valid(state.claude_bufnr) then
          vim.bo[state.claude_bufnr].bufhidden = "hide"
        end

        local save_eventignore = vim.o.eventignore
        vim.opt.eventignore:append("SessionLoadPost")
        local save_this = vim.v.this_session

        -- Switch to temp buffer and source the saved editor session
        vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(false, true))
        vim.api.nvim_exec2(state.restore_script, { output = true })

        vim.v.this_session = save_this
        vim.o.eventignore = save_eventignore

        -- Restore Claude buffer's original bufhidden
        if vim.api.nvim_buf_is_valid(state.claude_bufnr) then
          vim.bo[state.claude_bufnr].bufhidden = state.claude_bufhidden or "hide"
        end

        -- Reopen sidebars
        if state.neo_tree then
          pcall(vim.cmd, "Neotree show")
        end

        local ok, claude_term = pcall(require, "claudecode.terminal")
        if ok and claude_term.ensure_visible then
          claude_term.ensure_visible()
        end

        vim.t.maximized = false
        vim.o.lazyredraw = save_lazyredraw
      end

      -- Autocmds for the regular maximize.nvim path (editor-focused with Claude as sidebar)
      vim.api.nvim_create_autocmd("User", {
        pattern = "WindowMaximizeStart",
        callback = function()
          local tab = vim.api.nvim_get_current_tabpage()
          sidebar_state[tab] = { neo_tree = close_neo_tree() }

          -- Preserve Claude terminal through maximize cycle
          local ok, claude_term = pcall(require, "claudecode.terminal")
          if ok and claude_term.get_active_terminal_bufnr then
            local bufnr = claude_term.get_active_terminal_bufnr()
            if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
              local info = vim.fn.getbufinfo(bufnr)
              local is_visible = info and #info > 0 and #info[1].windows > 0

              if is_visible then
                sidebar_state[tab].claude_visible = true
                claude_term.simple_toggle()
              end

              -- Temporarily clear bufhidden so maximize doesn't force-delete the buffer
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
          if not state then return end
          sidebar_state[tab] = nil

          local cur_win = vim.api.nvim_get_current_win()

          if state.neo_tree then
            pcall(vim.cmd, "Neotree show")
          end

          if state.claude_bufnr and vim.api.nvim_buf_is_valid(state.claude_bufnr) then
            vim.bo[state.claude_bufnr].bufhidden = state.claude_bufhidden or "hide"
          end

          if state.claude_visible then
            local ok, claude_term = pcall(require, "claudecode.terminal")
            if ok and claude_term.ensure_visible then
              claude_term.ensure_visible()
            end
          end

          if vim.api.nvim_win_is_valid(cur_win) then
            vim.api.nvim_set_current_win(cur_win)
          end
        end,
      })

      -- Main toggle: Claude-focused uses custom path, everything else uses maximize.nvim
      vim.keymap.set("n", "<Leader>z", function()
        local tab = vim.api.nvim_get_current_tabpage()

        -- Restoring from Claude-focused maximize
        if claude_max_state[tab] then
          restore_claude()
          return
        end

        -- If focused on Claude terminal, use custom maximize
        local ok, claude_term = pcall(require, "claudecode.terminal")
        if ok and claude_term.get_active_terminal_bufnr then
          local bufnr = claude_term.get_active_terminal_bufnr()
          if bufnr and vim.api.nvim_get_current_buf() == bufnr then
            maximize_claude(claude_term, bufnr)
            return
          end
        end

        -- Default: maximize.nvim handles it (autocmds manage sidebars)
        require("maximize").toggle()
      end, { noremap = true, silent = true })
    end,
  },
}
