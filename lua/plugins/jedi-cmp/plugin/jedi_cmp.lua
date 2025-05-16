-- ~/.config/nvim/lua/plugins/jedi-cmp/plugin/jedi-cmp.lua

local cmp = require("cmp")
local jedi_source = require("plugins.jedi-cmp.lua.jedi_source").new()

cmp.register_source("jedi", jedi_source)
