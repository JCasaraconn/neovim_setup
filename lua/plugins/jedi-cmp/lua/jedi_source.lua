local uv = vim.loop
local cmp = require("cmp")

local M = {}
M.__index = M

-- Configuration
local LOG_ENABLED = false
local log_path = vim.fn.stdpath("config") .. "/jedi_source.log"
local python_cmd = vim.fn.trim(vim.fn.system("which python"))
local script_path = vim.fn.stdpath("config") .. "/lua/plugins/jedi-cmp/scripts/jedi_complete.py"

-- Logging utility
local function log(msg)
	if not LOG_ENABLED then
		return
	end
	local fd = uv.fs_open(log_path, "a", 438) -- 0o666
	if fd then
		uv.fs_write(fd, os.date("%Y-%m-%d %H:%M:%S") .. " - " .. msg .. "\n")
		uv.fs_close(fd)
	end
end

log("Using python at: " .. python_cmd)

-- Create a new Jedi completion source
function M.new()
	local self = setmetatable({}, M)
	self.stdin = uv.new_pipe(false)
	self.stdout = uv.new_pipe(false)
	self.stderr = uv.new_pipe(false)
	self.buf = ""
	self.pending_callback = nil

	log("Starting Python Jedi daemon: " .. python_cmd .. " " .. script_path)

	local function invoke_callback(items)
		if self.pending_callback then
			self.pending_callback({ items = items or {}, isIncomplete = false })
			self.pending_callback = nil
		end
	end

	local function decode_line(line)
		if line == "" then
			log("Skipping empty line")
			return
		end
		local ok, res = pcall(vim.json.decode, line)
		if not ok then
			log("JSON parse failed: " .. tostring(res))
			log("Offending line: " .. line)
			return
		end

		log("Received JSON response: " .. vim.inspect(res))
		local items = {}
		for _, c in ipairs(res) do
			table.insert(items, {
				label = c.name,
				kind = cmp.lsp.CompletionItemKind[c.type:sub(1, 1):upper() .. c.type:sub(2)]
						or cmp.lsp.CompletionItemKind.Text,
				-- detail = c.signature ~= "" and c.signature or nil,
				detail= c.docstring,
				documentation = { kind = "markdown", value = c.docstring },
				insertText = c.signature or c.name,
				insertTextFormat = cmp.lsp.InsertTextFormat.Snippet,
			})
		end
		invoke_callback(items)
		log("Completion callback invoked with " .. tostring(#items) .. " items")
	end

	-- Spawn the Python process
	self.handle = uv.spawn(python_cmd, {
		args = { script_path },
		stdio = { self.stdin, self.stdout, self.stderr },
	}, function(code, signal)
		log(string.format("Python Jedi daemon exited with code %d, signal %d", code, signal))
		invoke_callback()
		self.stdin:close()
		self.stdout:close()
		self.stderr:close()
		self.handle:close()
		self.handle = nil
	end)

	-- Handle stdout (line-based JSON messages)
	self.stdout:read_start(function(err, chunk)
		if err then
			log("Error reading stdout: " .. err)
			return invoke_callback()
		end
		if not chunk then
			return
		end
		self.buf = self.buf .. chunk
		while true do
			local nl_pos = self.buf:find("\n")
			if not nl_pos then
				break
			end
			local line = self.buf:sub(1, nl_pos - 1)
			self.buf = self.buf:sub(nl_pos + 1)
			decode_line(line)
		end
	end)

	-- Handle stderr
	self.stderr:read_start(function(_, chunk)
		if chunk then
			log("Python stderr: " .. chunk:gsub("\n", " "))
		end
	end)

	return self
end

-- Completion entry point
function M:complete(request, callback)
	local line = request.context.cursor_before_line
	log("Sending line to Jedi daemon: " .. line)
	self.pending_callback = callback
	self.stdin:write(line .. "\n")
end

-- Required methods for cmp source
function M:get_trigger_characters()
	return { "." }
end

function M:resolve(completion_item, callback)
	callback(completion_item)
end

function M:execute() end

return M
