-- projnote.lines — line extraction + next/prev cycling.
-- Only "<stem>_<n>.md" names count; project.md, bare numerics, non-md
-- and line 0 are dropped.
local M = {}

local filename = require("projnote.filename")

-- Sorted {lines} from note filenames.
function M.from_filenames(names)
    local out = {}
    if type(names) ~= "table" then
        return out
    end
    for _, name in ipairs(names) do
        local n = filename.parse_line(name)
        if n and n > 0 then
            out[#out + 1] = n
        end
    end
    table.sort(out)
    return out
end

local function in_range(lines, line_count)
    local out = {}
    for _, l in ipairs(lines or {}) do
        if l >= 1 and l <= line_count then
            out[#out + 1] = l
        end
    end
    return out
end

-- Strict next note line (cycles past the end); nil when none in range.
function M.next_line(lines, cur, line_count)
    local ls = in_range(lines, line_count)
    if #ls == 0 then
        return nil
    end
    local best, wrap = nil, nil
    for _, l in ipairs(ls) do
        if wrap == nil or l < wrap then
            wrap = l
        end
        if l > cur and (best == nil or l < best) then
            best = l
        end
    end
    return best or wrap
end

-- Strict previous note line (cycles before the start); nil when none in range.
function M.prev_line(lines, cur, line_count)
    local ls = in_range(lines, line_count)
    if #ls == 0 then
        return nil
    end
    local best, wrap = nil, nil
    for _, l in ipairs(ls) do
        if wrap == nil or l > wrap then
            wrap = l
        end
        if l < cur and (best == nil or l > best) then
            best = l
        end
    end
    return best or wrap
end

return M
