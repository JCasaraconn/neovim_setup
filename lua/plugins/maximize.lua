return {
  {
    "declancm/maximize.nvim",
    config = function()
      require("maximize").setup({})

      -----------------------------------------------------------
      -- Panel type registry
      --
      -- Each entry defines how to detect, close, and restore a panel type.
      -- Required: name, detect, is_visible, close, show_fullscreen, show_normal
      -- Optional: show (autocmd restore), save_context, protect, unprotect
      --
      -- To add a new panel type, add an entry to this table.
      -----------------------------------------------------------
      local panel_types = {
        {
          name = "neo-tree",
          detect = function(buf)
            return vim.bo[buf].filetype == "neo-tree"
          end,
          is_visible = function()
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
                return true
              end
            end
            return false
          end,
          close = function()
            pcall(vim.cmd, "Neotree close")
          end,
          show = function()
            pcall(vim.cmd, "Neotree show")
          end,
          save_context = function()
            return {}
          end,
          -- NOTE: requires close_if_last_window = false in neo-tree config
          show_fullscreen = function()
            vim.cmd("Neotree focus")
            local cur_win = vim.api.nvim_get_current_win()
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              if win ~= cur_win and vim.api.nvim_win_get_config(win).relative == "" then
                pcall(vim.api.nvim_win_close, win, true)
              end
            end
          end,
          -- Uses "focus" instead of "show" because Neotree show schedules an async
          -- callback (via renderer vim.schedule) that restores focus to the editor
          show_normal = function()
            pcall(vim.cmd, "Neotree focus")
          end,
        },
        {
          name = "claude",
          detect = function(buf)
            local ok, ct = pcall(require, "claudecode.terminal")
            if ok and ct.get_active_terminal_bufnr then
              return ct.get_active_terminal_bufnr() == buf
            end
            return false
          end,
          is_visible = function()
            local ok, ct = pcall(require, "claudecode.terminal")
            if not ok or not ct.get_active_terminal_bufnr then return false end
            local bufnr = ct.get_active_terminal_bufnr()
            if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return false end
            local info = vim.fn.getbufinfo(bufnr)
            return info and #info > 0 and #info[1].windows > 0
          end,
          close = function()
            local ok, ct = pcall(require, "claudecode.terminal")
            if not ok or not ct.get_active_terminal_bufnr then return end
            local bufnr = ct.get_active_terminal_bufnr()
            if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return end
            local info = vim.fn.getbufinfo(bufnr)
            if info and #info > 0 and #info[1].windows > 0 then
              ct.simple_toggle()
            end
          end,
          show = function()
            local ok, ct = pcall(require, "claudecode.terminal")
            if ok and ct.ensure_visible then
              ct.ensure_visible()
            end
          end,
          save_context = function()
            local ok, ct = pcall(require, "claudecode.terminal")
            if not ok or not ct.get_active_terminal_bufnr then return {} end
            local bufnr = ct.get_active_terminal_bufnr()
            if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return {} end
            return { bufnr = bufnr }
          end,
          protect = function()
            local ok, ct = pcall(require, "claudecode.terminal")
            if not ok or not ct.get_active_terminal_bufnr then return nil end
            local bufnr = ct.get_active_terminal_bufnr()
            if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return nil end
            local saved = vim.bo[bufnr].bufhidden
            vim.bo[bufnr].bufhidden = ""
            return { bufnr = bufnr, bufhidden = saved }
          end,
          unprotect = function(saved)
            if saved and saved.bufnr and vim.api.nvim_buf_is_valid(saved.bufnr) then
              vim.bo[saved.bufnr].bufhidden = saved.bufhidden or "hide"
            end
          end,
          show_fullscreen = function(ctx)
            if ctx.bufnr and vim.api.nvim_buf_is_valid(ctx.bufnr) then
              vim.api.nvim_win_set_buf(0, ctx.bufnr)
            end
          end,
          show_normal = function()
            local ok, ct = pcall(require, "claudecode.terminal")
            if ok and ct.ensure_visible then
              ct.ensure_visible()
            end
          end,
        },
      }

      local function find_panel(name)
        for _, p in ipairs(panel_types) do
          if p.name == name then return p end
        end
        return nil
      end

      local function detect_panel(buf)
        for _, p in ipairs(panel_types) do
          if p.detect(buf) then return p end
        end
        return nil
      end

      -- State for panel-focused maximize (bypasses maximize.nvim entirely)
      local panel_max_state = {}
      -- State for editor-focused maximize (maximize.nvim path, panels managed via autocmds)
      local sidebar_state = {}

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

      -- Maximize any registered panel to fill the screen
      local function maximize_panel(panel)
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

        local state = {
          panel_name = panel.name,
          panel_ctx = panel.save_context and panel.save_context() or {},
          other_panels = {},
          protected = {},
        }

        -- Close/hide all OTHER visible panels
        for _, p in ipairs(panel_types) do
          if p.name ~= panel.name and p.is_visible and p.is_visible() then
            state.other_panels[p.name] = true
            if p.protect then
              state.protected[p.name] = p.protect()
            end
            p.close()
          end
        end

        -- Protect the target panel's buffer if needed (before closing)
        if panel.protect then
          state.protected[panel.name] = panel.protect()
        end

        -- Close the target panel (so it's excluded from editor session)
        panel.close()

        -- Save editor-only session (all panels now hidden/closed)
        state.restore_script = save_editor_session()

        -- Close all remaining editor windows
        vim.cmd.only({ bang = true })

        -- Show the panel full-screen
        panel.show_fullscreen(state.panel_ctx)

        -- vim.t.maximized is shared with maximize.nvim — the <Leader>z keymap must be
        -- the sole entry point to avoid conflicting state between the two paths
        vim.t.maximized = true
        panel_max_state[tab] = state
        vim.o.lazyredraw = save_lazyredraw
      end

      -- Restore from panel-focused maximize
      local function restore_panel()
        local tab = vim.api.nvim_get_current_tabpage()
        local state = panel_max_state[tab]
        if not state then return end
        panel_max_state[tab] = nil

        local save_lazyredraw = vim.o.lazyredraw
        vim.o.lazyredraw = true

        local panel = find_panel(state.panel_name)

        -- If the target panel's buffer was protected, set bufhidden = "hide"
        -- before switching away so the buffer survives becoming hidden
        local target_prot = state.protected[state.panel_name]
        if target_prot and target_prot.bufnr and vim.api.nvim_buf_is_valid(target_prot.bufnr) then
          vim.bo[target_prot.bufnr].bufhidden = "hide"
        end

        -- Create a safe window, then let the panel close its own window properly.
        -- (Avoids invalid window ID errors from plugins like neo-tree that manage
        -- their own window lifecycle and react badly to nvim_win_set_buf.)
        vim.cmd("botright new")
        if panel and panel.close then
          panel.close()
        end

        local save_eventignore = vim.o.eventignore
        vim.opt.eventignore:append("SessionLoadPost")
        local save_this = vim.v.this_session

        vim.api.nvim_exec2(state.restore_script, { output = true })

        vim.v.this_session = save_this
        vim.o.eventignore = save_eventignore

        -- Unprotect all buffers (restore original bufhidden values)
        for name, saved in pairs(state.protected) do
          local p = find_panel(name)
          if p and p.unprotect then
            p.unprotect(saved)
          end
        end

        -- Restore the target panel first, then focus it. Other panels are restored
        -- AFTER so that their async callbacks (e.g., neo-tree's vim.schedule in its
        -- renderer) save the target panel window as "current_win" and restore to it
        -- rather than stealing focus to the editor.
        if panel and panel.show_normal then
          panel.show_normal(state.panel_ctx)
        end

        -- Focus the target panel immediately
        if panel then
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if panel.detect(vim.api.nvim_win_get_buf(win)) then
              vim.api.nvim_set_current_win(win)
              break
            end
          end
        end

        -- Now restore other panels — they'll see the target panel as the current window
        for name, _ in pairs(state.other_panels) do
          local p = find_panel(name)
          if p and p.show then
            p.show()
          end
        end

        vim.t.maximized = false
        vim.o.lazyredraw = save_lazyredraw
      end

      -- Autocmds for the maximize.nvim path (editor-focused, panels managed via registry)
      vim.api.nvim_create_autocmd("User", {
        pattern = "WindowMaximizeStart",
        callback = function()
          local tab = vim.api.nvim_get_current_tabpage()
          local state = { panels = {}, protected = {} }

          for _, p in ipairs(panel_types) do
            if p.is_visible and p.is_visible() then
              state.panels[p.name] = true
              if p.protect then
                state.protected[p.name] = p.protect()
              end
              p.close()
            end
          end

          sidebar_state[tab] = state
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

          for name, saved in pairs(state.protected) do
            local p = find_panel(name)
            if p and p.unprotect then
              p.unprotect(saved)
            end
          end

          for name, _ in pairs(state.panels) do
            local p = find_panel(name)
            if p and p.show then
              p.show()
            end
          end

          if vim.api.nvim_win_is_valid(cur_win) then
            vim.api.nvim_set_current_win(cur_win)
          end
        end,
      })

      -- Main toggle: panel-focused uses custom path, editor-focused uses maximize.nvim
      vim.keymap.set("n", "<Leader>z", function()
        local tab = vim.api.nvim_get_current_tabpage()

        -- Restoring from panel-focused maximize
        if panel_max_state[tab] then
          restore_panel()
          return
        end

        -- Check if current buffer matches a registered panel type
        local panel = detect_panel(vim.api.nvim_get_current_buf())
        if panel then
          maximize_panel(panel)
          return
        end

        -- Default: maximize.nvim handles it (autocmds manage panels)
        require("maximize").toggle()
      end, { noremap = true, silent = true, desc = "[Windows] Maximize toggle" })
    end,
  },
}
