local uv = vim.loop
local cmp = require("cmp")

local M = {}
M.__index = M

local LOG_ENABLED = true -- Set to false to disable logging
local log_path = vim.fn.stdpath("config") .. "/jedi_source.log"

local function log(msg)
	if not LOG_ENABLED then
		return
	end
	local fd = uv.fs_open(log_path, "a", 438) -- 438 = 0o666 permissions
	if fd then
		uv.fs_write(fd, os.date("%Y-%m-%d %H:%M:%S") .. " - " .. msg .. "\n")
		uv.fs_close(fd)
	end
end

local python_cmd = vim.fn.trim(vim.fn.system("which python"))

log("Using python at: " .. python_cmd)

local script_path = vim.fn.stdpath("config") .. "/lua/scripts/jedi_complete.py"
function M.new()
	local self = setmetatable({}, M)

	self.stdin = uv.new_pipe(false)
	self.stdout = uv.new_pipe(false)
	self.stderr = uv.new_pipe(false)
	self.handle = nil
	self.buf = ""
	self.pending_callback = nil

	log("Starting Python Jedi daemon: " .. python_cmd .. " " .. script_path)

	self.handle = uv.spawn(python_cmd, {
		args = { script_path },
		stdio = { self.stdin, self.stdout, self.stderr },
	}, function(code, signal)
		log(string.format("Python Jedi daemon exited with code %d, signal %d", code, signal))
		if self.pending_callback then
			self.pending_callback({ items = {}, isIncomplete = false })
			self.pending_callback = nil
		end
		self.stdin:close()
		self.stdout:close()
		self.stderr:close()
		self.handle:close()
		self.handle = nil
	end)

	self.stdout:read_start(function(err, chunk)
		if err then
			log("Error reading stdout: " .. err)
			if self.pending_callback then
				self.pending_callback({ items = {}, isIncomplete = false })
				self.pending_callback = nil
			end
			return
		end
		if chunk then
			self.buf = self.buf .. chunk
			while true do
				local nl_pos = self.buf:find("\n")
				if not nl_pos then
					log("No newline yet, waiting for more data...")
					break
				end
				local line = self.buf:sub(1, nl_pos - 1)
				self.buf = self.buf:sub(nl_pos + 1)

				-- line = line:match("^%s*(.-)%s*$")

				if line == "" then
					log("Skipping empty line")
				else
					local ok, res = pcall(vim.json.decode, line)
					if ok then
						log("Received JSON completion response: " .. vim.inspect(res))
						if self.pending_callback then
							local items = {}
							for _, c in ipairs(res) do
								table.insert(items, {
									label = c.name,
									kind = cmp.lsp.CompletionItemKind.Text,
									detail = c.description or "",
								})
							end
							self.pending_callback({ items = items, isIncomplete = false })
							log("Completion callback invoked with " .. tostring(#items) .. " items")
							self.pending_callback = nil
						else
							log("No pending callback for the completion response")
						end
					else
						log("JSON parse failed: " .. tostring(res))
						log("Offending line: " .. line)
					end
				end
			end
		end
	end)

	self.stderr:read_start(function(err, chunk)
		if chunk then
			log("Python stderr: " .. chunk:gsub("\n", " "))
		end
	end)

	return self
end

function M:complete(request, callback)
	local line = request.context.cursor_before_line

	local cursor_col = request.context.cursor.col

	-- Only trigger when the last typed character before the cursor is "."
	if not line:sub(cursor_col - 1, cursor_col - 1):match("%.") then
		return callback() -- skip completion unless "." was typed
	end

	log("this is the line: " .. line)

	if line == "" or not self.handle then
		log("No input or daemon not running; returning empty completion")
		callback({ items = {}, isIncomplete = false })
		return
	end

	if self.pending_callback then
		log("Previous completion request still pending; dropping this one")
		callback({ items = {}, isIncomplete = false })
		return
	end

	log("Sending completion request for prefix: " .. line)
	self.pending_callback = callback
	self.stdin:write(line .. "\n")
end

function M:get_trigger_characters()
	return { "." }
end

function M:resolve() end

function M:execute() end

return M
