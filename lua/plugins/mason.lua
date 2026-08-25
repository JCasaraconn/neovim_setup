return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {},
  },
  {
    "jay-babu/mason-null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
  },
}
