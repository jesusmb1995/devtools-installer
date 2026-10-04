-- projnote — in-place project notes (standalone local plugin).
--
-- Scopes (same surface as the retired quicknote.nvim spec):
--   qn  note at current line  -> <store>/<proj16>/<stem>_<line>_<hash4>.md
--   qN  the project note      -> <store>/<proj16>/project.md (create if missing)
--   qo  open note at line     (readable names only)
--   qd  delete note at line   (readable names only)
--   ql  all notes in project  -> bottom panel, jump or open
--   qL  notes in this file    -> bottom panel, jump or open
--   q]  next note in file / q[ prev note in file (wrap around)
--   qt  toggle note signs (on by default, via our own scanner)
--
-- Project root: `jj root`, else `git rev-parse --show-toplevel`, else cwd.
-- No branch keying, no plenary dependency, no full-tree scans ever:
-- project-wide listing resolves sources from the <project_dir>/index file,
-- and signs/file-scoped lists use single-dir globs only.
local filename = require("projnote.filename")
local storage = require("projnote.storage")
local pindex = require("projnote.index")
local plines = require("projnote.lines")

local M = {}

local SIGN_GROUP = "ProjNoteSigns"
local signs_on = true

local function base()
    return M._base or storage.default_base()
end

-- Project root for a buffer: resolved from the BUFFER's directory, not the
-- process cwd — one nvim session can hold files from several workspaces.
-- `jj root`, else git toplevel, else the legacy cwd-based detection.
local function project_root(bufname)
    local start = (bufname and bufname ~= "") and vim.fn.fnamemodify(bufname, ":h") or vim.fn.getcwd()
    local dir = vim.fs.normalize(start)
    while dir and dir ~= "" do
        if vim.fn.isdirectory(dir .. "/.jj") == 1 then
            return dir
        end
        local parent = vim.fn.fnamemodify(dir, ":h")
        if parent == dir then
            break
        end
        dir = parent
    end
    local git_root = vim.fn.systemlist({ "git", "-C", start, "rev-parse", "--show-toplevel" })
    if vim.v.shell_error == 0 and git_root[1] and git_root[1] ~= "" then
        return vim.fs.normalize(git_root[1])
    end
    for _, cmd in ipairs({ { "jj", "root" }, { "git", "rev-parse", "--show-toplevel" } }) do
        local out = vim.fn.systemlist(cmd)
        if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
            return vim.fs.normalize(out[1])
        end
    end
    return vim.fs.normalize(vim.fn.getcwd())
end

local function index_path_for(root)
    return storage.project_dir(base(), root) .. "/index"
end

local function note_path_for(bufname, line, root)
    root = root or project_root(bufname)
    local dir = storage.notes_dir(base(), root)
    local rel = storage.relpath(root, bufname)
    local name = filename.line_filename(bufname, line, storage.suffix(rel))
    return dir .. "/" .. name, dir
end

-- Note filenames in `files` that belong to bufname: same stem AND same
-- path suffix (same-named files in other dirs share the stem, not the hash).
local function this_file_names(files, bufname, root)
    local stem = filename.stem(bufname)
    local suffix = storage.suffix(storage.relpath(root, bufname))
    local out = {}
    for _, f in ipairs(files) do
        local name = vim.fn.fnamemodify(f, ":t")
        local parts = filename.split(name)
        if parts and parts.stem == stem and parts.hash == suffix then
            out[#out + 1] = name
        end
    end
    return out
end

local function first_line(path)
    local ok, lines = pcall(vim.fn.readfile, path, "", 1)
    if ok and lines and lines[1] then
        return lines[1]
    end
    return ""
end

local function note_body(path)
    local ok, lines = pcall(vim.fn.readfile, path)
    if ok and lines then
        return table.concat(lines, "\n")
    end
    return ""
end

-- Signs: scan the flat project dir, place only this file's notes.
local function refresh_signs(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    pcall(vim.fn.sign_unplace, SIGN_GROUP, { buffer = buf })
    if not signs_on then
        return
    end
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
        return
    end
    local bufname = vim.api.nvim_buf_get_name(buf)
    if bufname == "" then
        return
    end
    local root = project_root(bufname)
    local dir = storage.notes_dir(base(), root)
    local files = vim.fn.glob(dir .. "/*.md", true, true) or {}
    local maxline = vim.api.nvim_buf_line_count(buf)
    local seen = {}
    for _, name in ipairs(this_file_names(files, bufname, root)) do
        local line = filename.parse_line(name)
        if line and line >= 1 and line <= maxline and not seen[line] then
            seen[line] = true
            pcall(vim.fn.sign_place, 0, SIGN_GROUP, "ProjNote", buf, { lnum = line })
        end
    end
end

M.refresh_signs = refresh_signs

-- qn: new note at the current line; records <scope-hash> <relpath> in index.
function M.new_note()
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname == "" then
        vim.notify("projnote: save the file first", vim.log.levels.WARN)
        return
    end
    local root = project_root(bufname)
    local rel = storage.relpath(root, bufname)
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local path, dir = note_path_for(bufname, line, root)
    vim.fn.mkdir(dir, "p")
    if vim.fn.filereadable(path) == 0 then
        vim.fn.writefile({ "# " .. rel .. " (line " .. line .. ")", "" }, path)
    end
    pindex.append(index_path_for(root), vim.fn.fnamemodify(path, ":t"), rel)
    refresh_signs(0)
    vim.cmd("edit " .. vim.fn.fnameescape(path))
end

-- qN: project note (create if missing). No input prompt.
function M.project_note()
    local root = project_root()
    local path = storage.project_note_path(base(), root)
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    if vim.fn.filereadable(path) == 0 then
        vim.fn.writefile({ "# " .. vim.fn.fnamemodify(root, ":t"), "" }, path)
    end
    vim.cmd("edit " .. vim.fn.fnameescape(path))
end

-- qo: open the readable note at the current line.
function M.open_note()
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname == "" then
        vim.notify("projnote: save the file first", vim.log.levels.WARN)
        return
    end
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local path = note_path_for(bufname, line)
    if vim.fn.filereadable(path) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(path))
    else
        vim.notify("projnote: no note at line " .. line .. " (qn to create)", vim.log.levels.WARN)
    end
end

-- qd: delete the readable note at the current line.
function M.delete_note()
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname == "" then
        vim.notify("projnote: save the file first", vim.log.levels.WARN)
        return
    end
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local path = note_path_for(bufname, line)
    if vim.fn.filereadable(path) == 1 then
        vim.fn.delete(path)
        vim.notify("projnote: deleted " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
        refresh_signs(0)
    else
        vim.notify("projnote: no note at line " .. line, vim.log.levels.WARN)
    end
end

-- Bottom panel listing. <CR> jumps to the noted line, <C-e> opens the note.
-- Line notes sort numerically first, then named notes alphabetically.
-- Preview shows the first 60 lines as markdown.
local function pick(title, items)
    if #items == 0 then
        vim.notify("No notes yet — qn for this line, qN for the project", vim.log.levels.WARN)
        return
    end
    table.sort(items, function(a, b)
        local wa, wb = a.ws or "", b.ws or ""
        if wa ~= wb then
            return wa < wb
        end
        if a.line and b.line then
            if a.line ~= b.line then
                return a.line < b.line
            end
            return a.text < b.text
        end
        if a.line then
            return true
        end
        if b.line then
            return false
        end
        return a.text < b.text
    end)

    local ok_snacks, Snacks = pcall(require, "snacks")
    if not (ok_snacks and Snacks and Snacks.picker) then
        for _, it in ipairs(items) do
            print(it.text)
        end
        return
    end
    Snacks.picker.pick({
        title = title,
        layout = { preset = "ivy", position = "bottom" },
        items = items,
        format = "text",
        win = { input = { keys = { ["<c-e>"] = { "note_open", mode = { "n", "i" } } } } },
        preview = function(ctx)
            if not ctx.item then
                return false
            end
            local lines = vim.split(ctx.item.body or "", "\n")
            if #lines > 60 then
                vim.list_extend(lines, { "-- (" .. (#lines - 60) .. " more lines)" })
                lines = vim.list_slice(lines, 1, 60)
            end
            ctx.preview:set_lines(#lines > 0 and lines or { "(empty note)" })
            ctx.preview:highlight({ ft = "markdown" })
            return true
        end,
        actions = {
            note_open = function(picker, item)
                if not item then
                    return
                end
                picker:close()
                vim.cmd("split " .. vim.fn.fnameescape(item.file))
            end,
        },
        confirm = function(picker, item)
            if not item then
                return
            end
            picker:close()
            if item.src and vim.fn.filereadable(item.src) == 1 then
                vim.cmd("edit " .. vim.fn.fnameescape(item.src))
                if item.line and item.line > 0 then
                    pcall(vim.api.nvim_win_set_cursor, 0, { item.line, 0 })
                    vim.cmd("normal! zz")
                end
            elseif item.file then
                vim.cmd("split " .. vim.fn.fnameescape(item.file))
            end
        end,
    })
end

local function item_for(file, src, rel, ws)
    local name = vim.fn.fnamemodify(file, ":t")
    local line = filename.parse_line(name)
    local label = rel or (src and vim.fn.fnamemodify(src, ":~:.") or name)
    if ws then
        label = "[" .. ws .. "] " .. label
    end
    local first = first_line(file)
    return {
        file = file,
        line = line,
        ws = ws,
        src = (src and vim.fn.filereadable(src) == 1) and src or nil,
        text = (line and ("line " .. line) or name) .. "  " .. label .. (first ~= "" and ("  — " .. first) or ""),
        body = note_body(file),
    }
end

-- qL: notes in this file (flat project dir, filtered to this file).
function M.pick_file()
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname == "" then
        vim.notify("projnote: save the file first", vim.log.levels.WARN)
        return
    end
    local root = project_root(bufname)
    local dir = storage.notes_dir(base(), root)
    local files = vim.fn.glob(dir .. "/*.md", true, true) or {}
    local items = {}
    for _, name in ipairs(this_file_names(files, bufname, root)) do
        items[#items + 1] = item_for(dir .. "/" .. name, bufname)
    end
    pick("Notes in this file  ·  <CR> jump  ·  <C-e> open", items)
end

-- ql: all notes in the project. Flat dir, one glob; each note's source
-- resolves from the index file ("unknown:<filename>" when unlisted).
-- No tree scans.
function M.pick_project()
    local bufname = vim.api.nvim_buf_get_name(0)
    local root = (bufname ~= "" and project_root(bufname)) or project_root()
    pick("Notes in project  ·  <CR> jump  ·  <C-e> open", collect_store(root, root, nil))
end

-- Sibling workspace roots of the same jj repo (authoritative, any naming).
-- Returns { {name, path}, ... } excluding the current root; empty outside jj.
local function sibling_workspaces(root)
    if vim.fn.executable("jj") == 0 then
        return {}
    end
    local out = vim.fn.systemlist("cd " .. vim.fn.shellescape(root) .. " && jj workspace list")
    if vim.v.shell_error ~= 0 or not out then
        return {}
    end
    local cur = vim.fs.normalize(root)
    local ws = {}
    for _, line in ipairs(out) do
        local name, path = line:match("^(%S+):%s+(%S+)")
        if name and path then
            -- (parens: gsub returns 2 values, normalize takes 1.)
            local abs = vim.fs.normalize((vim.fn.fnamemodify(root .. "/" .. path, ":p"):gsub("/$", "")))
            if abs ~= cur and vim.fn.isdirectory(abs) == 1 then
                ws[#ws + 1] = { name = name, path = abs }
            end
        end
    end
    return ws
end

-- Items for one note store: flat *.md glob, sources from that store's own
-- index. ws tags the workspace (nil = current); src points into that
-- workspace's checkout so <CR> jumps there.
local function collect_store(store_root, ws)
    local pdir = storage.project_dir(base(), store_root)
    local map = pindex.read(pdir .. "/index")
    local items = {}
    for _, f in ipairs(vim.fn.glob(pdir .. "/*.md", true, true) or {}) do
        local name = vim.fn.fnamemodify(f, ":t")
        if name == "project.md" then
            items[#items + 1] = item_for(f, store_root, vim.fn.fnamemodify(store_root, ":~:.") .. " (project)", ws)
        else
            local rel = map[name]
            local src = rel and (store_root .. "/" .. rel) or nil
            items[#items + 1] = item_for(f, src, rel or ("unknown:" .. name), ws)
        end
    end
    return items
end

-- qw: all notes in this project AND every sibling workspace.
function M.pick_all()
    local bufname = vim.api.nvim_buf_get_name(0)
    local root = (bufname ~= "" and project_root(bufname)) or project_root()
    local items = collect_store(root, nil)
    for _, w in ipairs(sibling_workspaces(root)) do
        for _, it in ipairs(collect_store(w.path, w.name)) do
            items[#items + 1] = it
        end
    end
    pick("Notes everywhere  ·  <CR> jump  ·  <C-e> open", items)
end

-- qW: this file's notes across this project and every sibling workspace.
-- Same relpath => same stem + suffix, so the current file's filter applies
-- to every store verbatim.
function M.pick_file_all()
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname == "" then
        vim.notify("projnote: save the file first", vim.log.levels.WARN)
        return
    end
    local root = project_root(bufname)
    local items = {}
    local function add_from(store_root, ws)
        local dir = storage.notes_dir(base(), store_root)
        local map = pindex.read(storage.project_dir(base(), store_root) .. "/index")
        local files = vim.fn.glob(dir .. "/*.md", true, true) or {}
        for _, name in ipairs(this_file_names(files, bufname, root)) do
            local f = dir .. "/" .. name
            local rel = map[name]
            local src = rel and (store_root .. "/" .. rel) or bufname
            items[#items + 1] = item_for(f, src, rel or name, ws)
        end
    end
    add_from(root, nil)
    for _, w in ipairs(sibling_workspaces(root)) do
        add_from(w.path, w.name)
    end
    pick("Notes for this file, all workspaces  ·  <CR> jump  ·  <C-e> open", items)
end

local function jump(dirn)
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname == "" then
        return
    end
    local root = project_root(bufname)
    local dir = storage.notes_dir(base(), root)
    local globbed = vim.fn.glob(dir .. "/*.md", true, true) or {}
    local names = this_file_names(globbed, bufname, root)
    local cur = vim.api.nvim_win_get_cursor(0)[1]
    local count = vim.api.nvim_buf_line_count(0)
    local target
    if dirn > 0 then
        target = plines.next_line(plines.from_filenames(names), cur, count)
    else
        target = plines.prev_line(plines.from_filenames(names), cur, count)
    end
    if target then
        pcall(vim.api.nvim_win_set_cursor, 0, { target, 0 })
        vim.cmd("normal! zz")
    else
        vim.notify("projnote: no notes in this file", vim.log.levels.WARN)
    end
end

-- q]: next note in file (wraps around).
function M.jump_next()
    jump(1)
end

-- q[: previous note in file (wraps around).
function M.jump_prev()
    jump(-1)
end

-- qt: toggle note signs.
function M.toggle_signs()
    signs_on = not signs_on
    if not signs_on then
        pcall(vim.fn.sign_unplace, SIGN_GROUP)
    else
        refresh_signs(0)
    end
    vim.notify("projnote: signs " .. (signs_on and "on" or "off"), vim.log.levels.INFO)
end

function M.setup(opts)
    opts = opts or {}
    M._base = opts.base
    vim.fn.sign_define("ProjNote", { text = opts.sign_text or vim.fn.nr2char(0xf0ae), texthl = "ProjNote" })
    vim.api.nvim_set_hl(0, "ProjNote", { default = true, link = "Special" })

    local map = vim.keymap.set
    map("n", "<leader>qn", M.new_note, { desc = "Note: new at current line (project+file+line)" })
    map("n", "<leader>qN", M.project_note, { desc = "Note: go to project note (create if missing)" })
    map("n", "<leader>qo", M.open_note, { desc = "Note: open at current line" })
    map("n", "<leader>qd", M.delete_note, { desc = "Note: delete at current line" })
    map("n", "<leader>ql", M.pick_project, { desc = "Note: list project notes (jump/open)" })
    map("n", "<leader>qL", M.pick_file, { desc = "Note: list this file's notes (jump/open)" })
    map("n", "<leader>qw", M.pick_all, { desc = "Note: list all notes incl. other workspaces" })
    map("n", "<leader>qW", M.pick_file_all, { desc = "Note: list this file's notes incl. other workspaces" })
    map("n", "<leader>q]", M.jump_next, { desc = "Note: jump to next note in file" })
    map("n", "<leader>q[", M.jump_prev, { desc = "Note: jump to previous note in file" })
    map("n", "<leader>qt", M.toggle_signs, { desc = "Note: toggle note signs (on by default)" })

    -- Signs ON by default via our own scanner over the single note dir.
    -- The spec lazy-loads on the first q* keypress, so the current buffer
    -- is marked on load; BufEnter covers switching later.
    local group = vim.api.nvim_create_augroup("ProjNoteSigns", { clear = true })
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufEnter" }, {
        group = group,
        callback = function(ev)
            refresh_signs(ev.buf)
        end,
    })
    vim.api.nvim_create_autocmd({ "VimEnter", "BufWinEnter" }, {
        group = group,
        callback = function()
            refresh_signs(0)
        end,
    })
    refresh_signs(0)
    vim.schedule(function()
        refresh_signs(0)
    end)
end

return M
