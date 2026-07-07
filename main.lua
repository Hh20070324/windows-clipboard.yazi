--- @since 26.5.6

local M = {}

local get_state = ya.sync(function()
	local tab = cx.active
	local paths = {}

	for _, url in pairs(tab.selected) do
		paths[#paths + 1] = tostring(url)
	end

	if #paths == 0 then
		local hovered = tab.current.hovered
		if hovered then
			paths[#paths + 1] = tostring(hovered.url)
		end
	end

	return {
		cwd = tostring(tab.current.cwd),
		paths = paths,
	}
end)

local function plugin_dir()
	local appdata = os.getenv("APPDATA")

	if appdata and appdata ~= "" then
		return appdata .. "\\yazi\\config\\plugins\\windows-clipboard.yazi"
	end

	return "windows-clipboard.yazi"
end

local function notify(level, title, content)
	ya.notify({
		title = title,
		content = content,
		timeout = 5,
		level = level,
	})
end

local function trim(value)
	return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function output_message(output, fallback)
	local stderr = trim(output and output.stderr)
	if stderr ~= "" then
		return stderr
	end

	local stdout = trim(output and output.stdout)
	if stdout ~= "" then
		return stdout
	end

	return fallback
end

local function run_powershell(script, args)
	local command_args = {
		"-NoProfile",
		"-Sta",
		"-ExecutionPolicy",
		"Bypass",
		"-File",
		script,
	}

	for _, arg in ipairs(args) do
		command_args[#command_args + 1] = arg
	end

	local output, err = Command("pwsh"):arg(command_args):output()

	if err then
		return false, tostring(err)
	end

	if not output.status.success then
		return false, output_message(output, "PowerShell command failed.")
	end

	return true, output_message(output, "")
end

function M:entry(job)
	if ya.target_os() ~= "windows" then
		notify("error", "Windows Clipboard", "This plugin only supports Windows.")
		return
	end

	local action = job.args[1]
	local state = get_state()
	local root = plugin_dir()

	if action == "copy" or action == "cut" then
		if #state.paths == 0 then
			notify("warn", "Windows Clipboard", "No file is selected or hovered.")
			return
		end

		local args = { action }
		for _, path in ipairs(state.paths) do
			args[#args + 1] = path
		end

		local ok, message = run_powershell(root .. "\\scripts\\set-file-clipboard.ps1", args)
		if not ok then
			notify("error", "Windows Clipboard", message)
		end

		return
	end

	if action == "paste" then
		local ok, message = run_powershell(root .. "\\scripts\\paste-file-clipboard.ps1", { state.cwd })
		if not ok then
			notify("error", "Windows Clipboard", message)
		end

		return
	end

	if action == "archive" or action == "extract" then
		if #state.paths == 0 then
			notify("warn", "Windows Clipboard", "No file is selected or hovered.")
			return
		end

		local args = { state.cwd }
		for _, path in ipairs(state.paths) do
			args[#args + 1] = path
		end

		local script = action == "archive" and "archive.ps1" or "extract.ps1"
		local ok, message = run_powershell(root .. "\\scripts\\" .. script, args)
		if not ok then
			notify("error", "Windows Clipboard", message)
		end

		return
	end

	notify("error", "Windows Clipboard", "Unknown action: " .. tostring(action))
end

return M
