return {
  {
    name = "keystroke-log",
    dir = vim.fn.stdpath("config"),
    config = function()
      local ns = vim.api.nvim_create_namespace("keystroke_log")
      local log_path = vim.fn.stdpath("data") .. "/keystroke-log.jsonl"
      local buffer = {}
      local timer = nil
      local active = false

      local function flush()
        if #buffer == 0 then
          return
        end

        local dir = vim.fn.fnamemodify(log_path, ":h")
        vim.fn.mkdir(dir, "p")

        local file = io.open(log_path, "a")
        if not file then
          return
        end

        for _, entry in ipairs(buffer) do
          local ok, line = pcall(vim.fn.json_encode, entry)
          if ok then
            file:write(line .. "\n")
          end
        end
        file:close()
        buffer = {}
      end

      local function on_key(raw)
        if not raw or raw == "" then
          return
        end

        local ok, bt = pcall(function()
          return vim.bo.buftype
        end)
        if ok and bt == "terminal" then
          return
        end

        local key = vim.fn.keytrans(raw)
        if key == "" then
          return
        end

        local bufname = ""
        local filetype = ""
        pcall(function()
          bufname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
          filetype = vim.bo.filetype
        end)

        table.insert(buffer, {
          t = vim.fn.reltimefloat(vim.fn.reltime()) * 1000,
          ts = os.date("!%Y-%m-%dT%H:%M:%S") .. string.format(".%03d", (vim.loop or vim.uv).now() % 1000),
          k = key,
          m = vim.api.nvim_get_mode().mode,
          ft = filetype,
          buf = bufname,
        })
      end

      local function start()
        active = true
        vim.on_key(on_key, ns)

        local uv = vim.loop or vim.uv
        timer = uv.new_timer()
        timer:start(3000, 3000, vim.schedule_wrap(flush))

        vim.notify("Keystroke logging ON", vim.log.levels.INFO)
      end

      local function stop()
        active = false
        vim.on_key(nil, ns)

        if timer then
          timer:stop()
          timer:close()
          timer = nil
        end

        flush()
        vim.notify("Keystroke logging OFF (" .. log_path .. ")", vim.log.levels.INFO)
      end

      local function toggle()
        if active then
          stop()
        else
          start()
        end
      end

      vim.keymap.set("n", "<leader>kl", toggle, { silent = true, desc = "[Misc] Toggle keystroke log" })

      -- Auto-start logging on launch (set vim.g.keystroke_log_autostart = false to disable)
      if vim.g.keystroke_log_autostart ~= false then
        start()
      end
    end,
  },
}