-- projnote.journal — per-directory journal identity.
-- Formula agrees byte-for-byte with user/repos/nvim/lua/mappings/notes-resources.lua:
--   hash = sha256(realpath -m normalized dir):sub(1,8):lower()
--   file = <slug>-<hash>.md (or <hash>.md when the slug is empty)
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

-- sha256(canon):sub(1,8):lower(); canon is realpath -m normalized by the caller.
function M.hash_for_path(canon)
    return sha256_hex(canon or ""):sub(1, 8):lower()
end

-- "<slug>-<hash>.md", or "<hash>.md" with no dangling dash.
function M.journal_name(slug, hash)
    slug = slug or ""
    hash = hash or ""
    if slug ~= "" then
        return slug .. "-" .. hash .. ".md"
    end
    return hash .. ".md"
end

-- "*-<hash>.md" matches in jdir, newest first (mtime desc, name asc tiebreak).
function M.candidates(jdir, hash)
    hash = hash or ""
    local files = {}
    if vim and vim.fn and vim.fn.glob then
        files = vim.fn.glob(jdir .. "/*-" .. hash .. ".md", true, true) or {}
    end
    local matches = {}
    for _, f in ipairs(files) do
        local base = f:match("([^/]+)$") or f
        if base:sub(-(#hash + 4)) == "-" .. hash .. ".md" then
            matches[#matches + 1] = f
        end
    end
    table.sort(matches, function(a, b)
        local ta, tb = vim.fn.getftime(a), vim.fn.getftime(b)
        if ta == tb then
            return a < b
        end
        return ta > tb
    end)
    return matches
end

return M
