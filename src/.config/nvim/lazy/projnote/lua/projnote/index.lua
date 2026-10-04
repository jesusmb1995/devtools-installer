-- projnote.index — reverse mapping (note filename -> relpath), no tree scans.
-- The UI layer appends one "<filename> <relpath>" line per note to
-- <project_dir>/index on note creation. Duplicates allowed, newest wins.
local M = {}

local function ensure_parent(path)
    local parent = tostring(path):match("^(.*)/[^/]+$")
    if parent and parent ~= "" then
        if vim and vim.fn and vim.fn.mkdir then
            pcall(vim.fn.mkdir, parent, "p")
        else
            os.execute("mkdir -p '" .. parent:gsub("'", "'\\''") .. "'")
        end
    end
end

-- Append "<note_filename> <relpath>" (duplicates allowed, newest wins).
function M.append(index_path, note_filename, relpath)
    ensure_parent(index_path)
    local f = io.open(index_path, "a")
    if not f then
        return false
    end
    f:write(tostring(note_filename) .. " " .. tostring(relpath) .. "\n")
    f:close()
    return true
end

-- {note_filename -> relpath} map; missing file -> {}. Newest entry wins.
function M.read(index_path)
    local map = {}
    local f = io.open(index_path, "r")
    if not f then
        return map
    end
    for line in f:lines() do
        local name, rel = line:match("^(%S+)%s+(.-)%s*$")
        if name and rel and name ~= "" and rel ~= "" then
            map[name] = rel
        end
    end
    f:close()
    return map
end

-- Relpath for a note filename, or "unknown:<filename>" when unlisted.
function M.resolve(index_path, note_filename)
    local rel = M.read(index_path)[note_filename]
    if rel then
        return rel
    end
    return "unknown:" .. tostring(note_filename)
end

return M
