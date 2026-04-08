return {
  {
    name = "cheatsheet",
    dir = vim.fn.stdpath("data") .. "/cheatsheet",
    config = function()
      local buf = nil
      local win = nil

      local lines = {
        "         Neovim Cheat Sheet — Leader = Space",
        "",
        " MOTION                          │ DEBUGGING (DAP)",
        " C-d / C-u   Half-page ↓/↑       │ ⎵ db       Toggle breakpoint",
        " n / N       Next/prev match     │ ⎵ dc       Continue / start",
        " j / k       Move (wrap-aware)   │ ⎵ do / di  Step over / into",
        " v J / v K   Move selection ↓/↑  │ ⎵ dO / dq  Step out / terminate",
        "                                 │ ⎵ du       Toggle DAP UI",
        " WINDOWS & TABS                  │",
        " ⎵ h j k l   Focus pane ←↓↑→     │ GIT",
        " ⎵ z         Maximize toggle     │ ⎵ gd       Diff split (fugitive)",
        " ⎵ sb        Scroll bind toggle  │",
        " ⎵ rb        Reference block     │ COMPLETION (INSERT)",
        " ⎵ tn / tp   Next / prev tab     │ C-Space    Trigger completion",
        " ⎵ to / tc   Only / close tab    │ Tab/S-Tab  Next / prev item",
        "                                 │ CR / C-e   Confirm / abort",
        " TELESCOPE                       │ C-b / C-f  Scroll docs ↑/↓",
        " ⎵ sf        Search files        │",
        " ⎵ sg        Live grep           │ TERMINAL (FLOATERM)",
        " ⎵ sw        Grep current word   │ F7         New terminal",
        " ⎵ sd        Search diagnostics  │ F8 / F9    Prev / next terminal",
        " ⎵ sh        Search help         │ F12        Toggle terminal",
        " ⎵ ?         Recent files        │ F5         Run Python file",
        " ⎵ Space     Open buffers        │",
        " ⎵ /         Fuzzy in buffer     │ NEO-TREE",
        "                                 │ ⎵ nt       Toggle tree",
        " HARPOON                         │ ⎵ bf       Buffers float",
        " ⎵ ha / hh   Add / quick menu    │",
        " ⎵ 1-4       Jump to file 1–4    │ CLAUDE CODE",
        " C-S-P/C-S-N Prev / next file    │ ⎵ ac       Toggle Claude",
        "                                 │ ⎵ af / ar  Focus / resume",
        " LSP                             │ ⎵ aC / am  Continue / model",
        " gd / gD     Defn / declaration  │ ⎵ ab       Add buffer",
        " gr / gI     Refs / implement.   │ v ⎵ as     Send selection",
        " K / C-k     Hover / signature   │ ⎵ aa / ad  Accept / deny diff",
        " ⎵ rn        Rename              │",
        " ⎵ ca        Code action         │ EDITING",
        " ⎵ D         Type definition     │ gcc        Toggle comment line",
        " ⎵ ds        Document symbols    │ gc (vis)   Toggle comment",
        " ⎵ ws        Workspace symbols   │ cs\"'       Change surround",
        " ⎵ wa / wr   Add/rm ws folder    │ ds\"        Delete surround",
        " ⎵ wl        List ws folders     │ ysiw\"      Add surround",
        " ⎵ gf        Format              │",
        " ⎵ td        Toggle diagnostics  │ MISC",
        "                                 │ ⎵ kl       Keystroke log toggle",
      }

      local function toggle()
        if win and vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
          win = nil
          return
        end

        local width = 0
        for _, line in ipairs(lines) do
          width = math.max(width, vim.fn.strdisplaywidth(line))
        end
        local height = #lines

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

      vim.keymap.set("n", "<leader>cs", toggle, { silent = true, desc = "Toggle cheat sheet" })
    end,
  },
}
