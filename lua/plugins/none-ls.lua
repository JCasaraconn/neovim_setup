return {
  "nvimtools/none-ls.nvim",
  config = function()
    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.stylua,     -- Lua formatter
        null_ls.builtins.formatting.black,   -- Python formatter
        null_ls.builtins.formatting.isort,      -- Python import sorter
        null_ls.builtins.formatting.prettier,   -- Formatter for various files
        -- null_ls.builtins.formatting.beautysh,   -- Shell script formatter
        -- null_ls.builtins.diagnostics.flake8,    -- Python linter
        null_ls.builtins.diagnostics.yamllint,  -- YAML linter
        null_ls.builtins.diagnostics.mypy, -- Python typechecker
        null_ls.builtins.diagnostics.pylint, -- Python linter
        -- null_ls.builtins.diagnostics.shellcheck -- Shell script linter
      },
    })

    -- Example key mapping for formatting
    vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, { desc = "Format code with LSP"})
  end,
}

