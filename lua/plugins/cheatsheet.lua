return {
  {
    name = "cheatsheet",
    dir = vim.fn.stdpath("data") .. "/cheatsheet",
    config = function()
      local buf = nil
      local win = nil

      -- Ordered list of categories for display
      local category_order = {
        "Motion",
        "Windows",
        "Tabs",
        "Telescope",
        "Harpoon",
        "LSP",
        "Diagnostics",
        "Debugging",
        "Git",
        "Formatting",
        "Completion",
        "Terminal",
        "Neo-tree",
        "Claude",
        "Editing",
        "Treesitter",
        "Misc",
      }

      -- Static fallback for keymaps not discoverable via nvim_get_keymap()
      -- (set by plugins internally, not through vim.keymap.set)
      local static_keymaps = {
        { cat = "Completion", lhs = "C-Space", desc = "Trigger completion" },
        { cat = "Completion", lhs = "Tab/S-Tab", desc = "Next / prev item" },
        { cat = "Completion", lhs = "CR / C-e", desc = "Confirm / abort" },
        { cat = "Completion", lhs = "C-b / C-f", desc = "Scroll docs" },
        { cat = "Editing", lhs = "gcc", desc = "Toggle comment line" },
        { cat = "Editing", lhs = "gc (vis)", desc = "Toggle comment" },
        { cat = "Editing", lhs = 'cs"\'', desc = "Change surround" },
        { cat = "Editing", lhs = 'ds"', desc = "Delete surround" },
        { cat = "Editing", lhs = 'ysiw"', desc = "Add surround" },
        { cat = "Terminal", lhs = "F7", desc = "New terminal" },
        { cat = "Terminal", lhs = "F8", desc = "Prev terminal" },
        { cat = "Terminal", lhs = "F9", desc = "Next terminal" },
        { cat = "Terminal", lhs = "F12", desc = "Toggle terminal" },
        { cat = "Treesitter", lhs = "af / if", desc = "Select outer/inner function" },
        { cat = "Treesitter", lhs = "ac / ic", desc = "Select outer/inner class" },
        { cat = "Treesitter", lhs = "]m / [m", desc = "Next / prev function start" },
        { cat = "Treesitter", lhs = "]] / [[", desc = "Next / prev class start" },
      }

      -- Format a keymap LHS for display (human-readable)
      local function format_lhs(lhs)
        -- Normalize common patterns
        lhs = lhs:gsub("<leader>", "⎵ ")
        lhs = lhs:gsub("<Leader>", "⎵ ")
        lhs = lhs:gsub("<CR>", "CR")
        lhs = lhs:gsub("<Esc>", "Esc")
        lhs = lhs:gsub("<C%-", "C-"):gsub(">", "")
        lhs = lhs:gsub("<S%-", "S-"):gsub(">", "")
        lhs = lhs:gsub("<M%-", "M-"):gsub(">", "")
        lhs = lhs:gsub("<F(%d+)>", "F%1")
        return lhs
      end

      -- Parse "[Category] Description" from a desc string
      local function parse_tag(desc)
        if not desc or desc == "" then
          return nil, nil
        end
        local cat, text = desc:match("^%[(.-)%]%s*(.+)$")
        if cat and text then
          return cat, text
        end
        return nil, nil
      end

      -- Collect all keymaps from the API, grouped by category
      local function collect_keymaps()
        local categories = {}
        local seen = {} -- track "mode:lhs" to deduplicate

        -- Helper to process a keymap entry
        local function process(km, is_buffer_local)
          local desc = km.desc
          if not desc or desc == "" then
            return
          end

          local cat, text = parse_tag(desc)
          if not cat then
            return
          end

          local mode = km.mode or "n"
          local lhs = km.lhs or ""
          local key = mode .. ":" .. lhs

          -- Buffer-local overrides global
          if seen[key] and not is_buffer_local then
            return
          end
          seen[key] = true

          if not categories[cat] then
            categories[cat] = {}
          end

          -- Prefix with mode if not normal
          local display_lhs = format_lhs(lhs)
          if mode == "v" or mode == "x" then
            display_lhs = "v " .. display_lhs
          elseif mode == "i" then
            display_lhs = "i " .. display_lhs
          end

          table.insert(categories[cat], {
            lhs = display_lhs,
            desc = text,
          })
        end

        -- Query buffer-local keymaps first (they take priority)
        for _, mode in ipairs({ "n", "v", "x", "i", "s" }) do
          local ok, buf_maps = pcall(vim.api.nvim_buf_get_keymap, 0, mode)
          if ok then
            for _, km in ipairs(buf_maps) do
              process(km, true)
            end
          end
        end

        -- Query global keymaps
        for _, mode in ipairs({ "n", "v", "x", "i", "s" }) do
          for _, km in ipairs(vim.api.nvim_get_keymap(mode)) do
            process(km, false)
          end
        end

        -- Add static fallback keymaps (only if category doesn't already have that lhs)
        for _, entry in ipairs(static_keymaps) do
          if not categories[entry.cat] then
            categories[entry.cat] = {}
          end
          table.insert(categories[entry.cat], {
            lhs = entry.lhs,
            desc = entry.desc,
          })
        end

        return categories
      end

      -- Render categories into display lines
      local function render(categories)
        local lines = { "         Neovim Cheat Sheet — Leader = Space", "" }

        -- Render each category
        for _, cat_name in ipairs(category_order) do
          local entries = categories[cat_name]
          if entries and #entries > 0 then
            -- Sort entries by lhs for consistency
            table.sort(entries, function(a, b)
              return a.lhs < b.lhs
            end)

            table.insert(lines, " " .. string.upper(cat_name))

            for _, entry in ipairs(entries) do
              -- Pad lhs to align descriptions
              local padded_lhs = string.format(" %-14s", entry.lhs)
              table.insert(lines, padded_lhs .. entry.desc)
            end

            table.insert(lines, "")
          end
        end

        -- Remove trailing blank line
        if lines[#lines] == "" then
          table.remove(lines)
        end

        return lines
      end

      local function toggle()
        if win and vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
          win = nil
          return
        end

        local categories = collect_keymaps()
        local lines = render(categories)

        local width = 0
        for _, line in ipairs(lines) do
          width = math.max(width, vim.fn.strdisplaywidth(line))
        end
        local height = #lines

        -- Clamp to editor dimensions
        local max_height = vim.o.lines - 4
        local max_width = vim.o.columns - 4
        height = math.min(height, max_height)
        width = math.min(width, max_width)

        local row = math.floor((vim.o.lines - height) / 2)
        local col = math.floor((vim.o.columns - width) / 2)

        buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].modifiable = false
        vim.bo[buf].bufhidden = "wipe"

        win = vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          row = row,
          col = col,
          width = width + 2,
          height = height,
          style = "minimal",
          border = "rounded",
          title = " Cheat Sheet ",
          title_pos = "center",
        })

        vim.wo[win].winhl = "Normal:NormalFloat"

        local close = function()
          if win and vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
            win = nil
          end
        end

        vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
        vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
        vim.keymap.set("n", "<leader>cs", close, { buffer = buf, nowait = true })
      end

      vim.keymap.set("n", "<leader>cs", toggle, { silent = true, desc = "[Misc] Toggle cheat sheet" })
    end,
  },
}
