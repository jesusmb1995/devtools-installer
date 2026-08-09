--- quicksheet.parse — PURE parser. No `vim` usage anywhere.
-- All functions are unit-tested in tests/parse_spec.lua.
local M = {}

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Split a cheat line on the FIRST "|", trimming both sides.
--- Returns (nil, nil) when there is no "|".
--- @param line string
--- @return string|nil, string|nil
function M.split_cheat(line)
  local pipe = line:find("|", 1, true)
  if not pipe then
    return nil, nil
  end
  local desc = line:sub(1, pipe - 1)
  local code = line:sub(pipe + 1)
  return trim(desc), trim(code)
end

--- True for empty or whitespace-only lines.
--- @param line string
--- @return boolean
function M.is_blank(line)
  return trim(line) == ""
end

--- True when the line starts with "#" but NOT "##".
--- @param line string
--- @return boolean
function M.is_comment(line)
  return line:sub(1, 1) == "#" and line:sub(1, 2) ~= "##"
end

--- True when the line starts with "##".
--- @param line string
--- @return boolean
function M.is_section(line)
  return line:sub(1, 2) == "##"
end

--- Section header text: the part after "## " up to the first " @tag".
--- Returns nil when the line is not a section header.
--- @param line string
--- @return string|nil
function M.section_name(line)
  if not M.is_section(line) then
    return nil
  end
  local rest
  if line:sub(1, 3) == "## " then
    rest = line:sub(4)
  else
    rest = line:sub(3)
  end
  local at = rest:find(" @", 1, true)
  local name
  if at then
    name = rest:sub(1, at - 1)
  else
    name = rest
  end
  return trim(name)
end

--- Tags of a section header, without the "@" sign.
--- @param line string
--- @return table
function M.section_tags(line)
  local tags = {}
  for tag in (line or ""):gmatch("@(%S+)") do
    tags[#tags + 1] = tag
  end
  return tags
end

--- Parse a whole sheet into an ordered list of entries.
--- Starts with section="default" and tags={}.
--- @param lines table array of strings
--- @return table
function M.parse_lines(lines)
  local entries = {}
  local section = "default"
  local tags = {}
  for i, line in ipairs(lines) do
    if M.is_section(line) then
      section = M.section_name(line)
      tags = M.section_tags(line)
    elseif not M.is_blank(line) and not M.is_comment(line) then
      local desc, code = M.split_cheat(line)
      if desc and code then
        entries[#entries + 1] = {
          section = section,
          tags = tags,
          description = desc,
          code = code,
          lineno = i,
        }
      end
    end
  end
  return entries
end

return M
