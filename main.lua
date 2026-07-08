--- @since 26.5.6

local M = {}

local cached_powershell = nil

local function powershell()
	if cached_powershell then
		return cached_powershell
	end

	local candidates = {
		"pwsh",
		"powershell.exe",
	}

	for _, command in ipairs(candidates) do
		local _, err = Command(command):arg({ "-NoProfile", "-Command", "exit 0" }):output()
		if not err then
			cached_powershell = command
			return command
		end
	end

	return nil
end

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

local function temp_file()
	local directory = os.getenv("TEMP") or os.getenv("TMP") or "."
	local name = string.format("windows-clipboard-yazi-%d-%d.txt", os.time(), math.random(100000, 999999))

	return directory .. "\\" .. name
end

local function write_path_list(paths)
	local file = temp_file()
	local handle, err = io.open(file, "w")
	if not handle then
		return nil, err
	end

	handle:write("\239\187\191")

	for _, path in ipairs(paths) do
		handle:write(path, "\n")
	end

	handle:close()
	return file, nil
end

local function plugin_dir()
	local configured = os.getenv("YAZI_WINDOWS_CLIPBOARD_PLUGIN_DIR")
	if configured and configured ~= "" then
		return configured
	end

	local info = debug and debug.getinfo and debug.getinfo(1, "S")
	local source = info and info.source or ""
	if source:sub(1, 1) == "@" then
		local path = source:sub(2)
		local directory = path:match("^(.*)[/\\][^/\\]+$")
		if directory and directory ~= "" then
			return directory
		end
	end

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
	local shell = powershell()
	if not shell then
		return false, "PowerShell was not found. Install PowerShell 7 or use Windows PowerShell."
	end

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

	local output, err = Command(shell):arg(command_args):output()

	if err then
		return false, tostring(err)
	end

	if not output.status.success then
		return false, output_message(output, "PowerShell command failed.")
	end

	return true, output_message(output, "")
end

local function run_with_paths(script, args, paths)
	local list, err = write_path_list(paths)
	if not list then
		return false, "Failed to create path list: " .. tostring(err)
	end

	args[#args + 1] = "-PathList"
	args[#args + 1] = list

	local ok, message = run_powershell(script, args)
	os.remove(list)

	return ok, message
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

		local ok, message = run_with_paths(root .. "\\scripts\\set-file-clipboard.ps1", { action }, state.paths)
		if not ok then
			notify("error", "Windows Clipboard", message)
		elseif message ~= "" then
			notify("info", "Windows Clipboard", message)
		end

		return
	end

	if action == "paste" then
		notify("info", "Windows Clipboard", "Pasting files...")

		local ok, message = run_powershell(root .. "\\scripts\\paste-file-clipboard.ps1", { state.cwd })
		if not ok then
			notify("error", "Windows Clipboard", message)
		elseif message ~= "" then
			notify("info", "Windows Clipboard", message)
		end

		return
	end

	if action == "archive" or action == "extract" then
		if #state.paths == 0 then
			notify("warn", "Windows Clipboard", "No file is selected or hovered.")
			return
		end

		local script = action == "archive" and "archive.ps1" or "extract.ps1"
		local label = action == "archive" and "Archiving files..." or "Extracting archives..."
		notify("info", "Windows Clipboard", label)

		local ok, message = run_with_paths(root .. "\\scripts\\" .. script, { state.cwd }, state.paths)
		if not ok then
			notify("error", "Windows Clipboard", message)
		elseif message ~= "" then
			notify("info", "Windows Clipboard", message)
		end

		return
	end

	notify("error", "Windows Clipboard", "Unknown action: " .. tostring(action))
end

return M
