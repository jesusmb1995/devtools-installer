--- quicksheet.update — dedup helpers are PURE (unit-tested); only gather() uses vim.
local M = {}

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Normalize a lhs: trim ends only (no lowercasing).
--- @param lhs string|nil
--- @return string
function M.normalize(lhs)
  return trim(lhs or "")
end

--- Default skip prefixes / patterns.
local DEFAULT_PREFIXES = { "<Plug>", "<SNR>" }
local DEFAULT_PATTERNS = {}

--- True when lhs is blank, starts with a skip prefix, or matches a skip pattern.
--- @param lhs string
--- @param opts table|nil { skip_lhs_prefixes=, skip_patterns= }
--- @return boolean
function M.is_skippable(lhs, opts)
  opts = opts or {}
  local prefixes = opts.skip_lhs_prefixes or DEFAULT_PREFIXES
  local patterns = opts.skip_patterns or DEFAULT_PATTERNS
  lhs = lhs or ""

  if M.normalize(lhs) == "" then
    return true
  end
  for _, prefix in ipairs(prefixes) do
    if lhs:sub(1, #prefix) == prefix then
      return true
    end
  end
  for _, pattern in ipairs(patterns) do
    if lhs:find(pattern) then
      return true
    end
  end
  return false
end

--- Keep candidates whose normalized lhs is not already in `existing`
--- (compared against normalized `.code`), not skippable, and not a duplicate
--- of an earlier kept candidate. Order is preserved; first wins on dupes.
--- @param existing table array of {code=}
--- @param candidates table array of {lhs=,desc=}
--- @param opts table|nil
--- @return table
function M.filter_new(existing, candidates, opts)
  opts = opts or {}

  local existing_set = {}
  for _, entry in ipairs(existing) do
    existing_set[M.normalize(entry.code)] = true
  end

  local seen = {}
  local result = {}
  for _, cand in ipairs(candidates) do
    local norm = M.normalize(cand.lhs)
    if not existing_set[norm] and not M.is_skippable(cand.lhs, opts) and not seen[norm] then
      result[#result + 1] = cand
      seen[norm] = true
    end
  end
  return result
end

--- Render a single candidate as a cheat line: "desc | lhs".
--- When desc is missing, synthesize "Mapping <lhs>".
--- @param candidate table {lhs=,desc=}
--- @return string
function M.to_cheat_line(candidate)
  local lhs = candidate.lhs
  local desc = candidate.desc or ("Mapping " .. lhs)
  return desc .. " | " .. lhs
end

--- Build the block to append to quicksheet.txt for new entries.
--- Returns "" when there is nothing to append.
--- @param new_cheats table array of {lhs=,desc=}
--- @param section string|nil defaults to "QuickUpdate"
--- @return string
function M.build_append_block(new_cheats, section)
  section = section or "QuickUpdate"
  if #new_cheats == 0 then
    return ""
  end
  local lines = { "## " .. section }
  for _, cand in ipairs(new_cheats) do
    lines[#lines + 1] = M.to_cheat_line(cand)
  end
  return table.concat(lines, "\n") .. "\n"
end

--- Gather keymap + user-command candidates from the running Neovim.
--- This is the only function here that uses `vim`.
--- @param opts table|nil collect options
--- @return table
function M.gather(opts)
  local config = require("quicksheet.config")
  opts = opts or config.options.collect
  local modes = opts.modes or config.options.collect.modes

  local candidates = {}
  for _, mode in ipairs(modes) do
    for _, mapping in ipairs(vim.api.nvim_get_keymap(mode)) do
      candidates[#candidates + 1] = {
        lhs = mapping.lhs,
        desc = mapping.desc or mapping.rhs,
      }
    end
  end

  local commands = vim.api.nvim_get_commands({})
  for name, _ in pairs(commands) do
    candidates[#candidates + 1] = {
      lhs = ":" .. name,
      desc = name .. " command",
    }
  end

  return candidates
end

return M
