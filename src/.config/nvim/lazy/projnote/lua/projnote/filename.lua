-- projnote.filename — readable per-line note filenames, flattened.
-- Standalone plugin: notes are "<stem>_<line>_<hash4>.md" (e.g.
-- "examplefile_1_dn5f.md"), where <hash4> is the last 4 hex chars of the
-- sha1 of the project-relative path — short, and it keeps apart same-named
-- files in different dirs. There are no legacy bare-numeric names anywhere.
local M = {}

local function basename(path)
    if path == nil or path == "" then
        return ""
    end
    local p = tostring(path):gsub("\\", "/")
    return p:match("([^/]+)$") or p
end

-- Basename without extension; never hidden, never empty.
--   "" -> "untitled"; leading dots become "_" (".env" -> "_env");
--   only [A-Za-z0-9_.-] kept; all-dot/empty falls back to "note".
function M.stem(bufname)
    if bufname == nil or bufname == "" then
        return "untitled"
    end
    local base = basename(bufname)
    if base == "" then
        return "untitled"
    end
    -- Strip one extension: the last dot after the first char.
    -- Dotfiles (".env", dot at position 1) keep their name.
    local dotpos = base:match(".*()%.[^%.]*$")
    if dotpos and dotpos > 1 then
        base = base:sub(1, dotpos - 1)
    end
    if base == "" or base:match("^%.+$") then
        return "note"
    end
    -- Notes must never be hidden: rewrite leading dots to underscores.
    base = base:gsub("^%.+", function(s)
        return string.rep("_", #s)
    end)
    -- Keep only the safe set.
    base = base:gsub("[^A-Za-z0-9_.-]", "_")
    if base == "" or base:match("^%.+$") then
        return "note"
    end
    return base
end

-- "<stem>_<line>_<hash4>.md", e.g. "foo.c",12,"dn5f" -> "foo_12_dn5f.md".
function M.line_filename(bufname, line, suffix)
    return M.stem(bufname) .. "_" .. tostring(line) .. "_" .. tostring(suffix) .. ".md"
end

-- Split "<stem>_<n>_<hash4>.md" into {stem, line, hash}; nil otherwise.
-- Greedy stem so names containing "_<digits>_" still parse at the tail.
-- The hash slot accepts any 4 alphanumerics (generator writes hex, but the
-- parse stays liberal so hand-made names like examplefile_1_dn5f.md work).
function M.split(name)
    if type(name) ~= "string" then
        return nil
    end
    local stem, num, hash = name:match("^(.*)_(%d+)_([0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Za-z])%.md$")
    if not stem or stem == "" or not num then
        return nil
    end
    return { stem = stem, line = tonumber(num), hash = hash }
end

-- Line number from "<stem>_<n>_<hash4>.md" ONLY; nil for anything else
-- ("project.md", bare "12.md", suffix-less "foo_12.md", non-".md").
function M.parse_line(name)
    local parts = M.split(name)
    if parts then
        return parts.line
    end
    return nil
end

return M
