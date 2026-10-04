-- projnote.storage — note store layout formulas, flattened.
--   <base>/<sha256(root):sub(1,16)>/<stem>_<line>_<hash4>.md
--   <base>/<sha256(root):sub(1,16)>/project.md   (fixed name)
--   <base>/<sha256(root):sub(1,16)>/index        (<filename> <relpath>)
-- No scope subdirs: <hash4> is the last 4 hex chars of sha1(relpath), so
-- same-named files in different dirs still land on distinct note names.
-- Default base: ~/.local/share/projnote.
local M = {}

local function sha256_hex(s)
    if vim and vim.fn and vim.fn.sha256 then
        local ok, out = pcall(vim.fn.sha256, s)
        if ok and type(out) == "string" and #out >= 1 then
            return out:lower()
        end
    end
    local esc = "'" .. tostring(s):gsub("'", "'\\''") .. "'"
    for _, cmd in ipairs({ "sha256sum", "shasum -a 256" }) do
        local h = io.popen("printf '%s' " .. esc .. " | " .. cmd .. " 2>/dev/null")
        if h then
            local out = h:read("*l")
            h:close()
            local hex = out and out:match("^(%x+)")
            if hex and #hex >= 64 then
                return hex:sub(1, 64):lower()
            end
        end
    end
    return nil
end

-- Short disambiguator: last 4 hex chars of sha1(relpath).
-- This environment's Neovim has no vim.fn.sha1, so hash exact bytes
-- (no trailing newline) via shell sha1sum (fallback shasum -a 1).
local function shell_escape(s)
    if vim and vim.fn and vim.fn.shellescape then
        local ok, out = pcall(vim.fn.shellescape, s)
        if ok and type(out) == "string" then
            return out
        end
    end
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function sha1_hex(s)
    for _, cmd in ipairs({ "sha1sum", "shasum -a 1" }) do
        local h = io.popen("printf '%s' " .. shell_escape(s) .. " | " .. cmd .. " 2>/dev/null")
        if h then
            local out = h:read("*l")
            h:close()
            local hex = out and out:match("^(%x+)")
            if hex and #hex >= 40 then
                return hex:sub(1, 40):lower()
            end
        end
    end
    return nil
end

function M.default_base()
    if vim and vim.fn and vim.fn.expand then
        return vim.fn.expand("~/.local/share/projnote")
    end
    return (os.getenv("HOME") or "~") .. "/.local/share/projnote"
end

-- "<base>/<sha256(root):sub(1,16)>".
function M.project_dir(base, root)
    base = base or M.default_base()
    root = root or ""
    return base .. "/" .. sha256_hex(root):sub(1, 16)
end

-- Lowercase last-4 of sha1 hex of the project-root-relative path.
function M.suffix(relpath)
    local hex = sha1_hex(relpath or "")
    if not hex then
        return nil
    end
    return hex:sub(-4):lower()
end

-- Project-root-relative path for an absolute path ("." at the root itself;
-- unchanged when outside the root).
function M.relpath(root, abspath)
    root = (root or ""):gsub("/+$", "")
    abspath = abspath or ""
    if root ~= "" then
        if abspath == root then
            return "."
        end
        local prefix = root .. "/"
        if abspath:sub(1, #prefix) == prefix then
            return abspath:sub(#prefix + 1)
        end
    end
    return abspath
end

-- Flat note dir: all notes sit directly under the project dir.
function M.notes_dir(base, root)
    return M.project_dir(base, root)
end

-- "<project_dir>/project.md" (fixed name).
function M.project_note_path(base, root)
    return M.project_dir(base, root) .. "/project.md"
end

return M
