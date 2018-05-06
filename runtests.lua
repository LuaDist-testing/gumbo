local open, write, ipairs, loadfile = io.open, io.write, ipairs, loadfile
local xpcall, assert, tonumber, exit = xpcall, assert, tonumber, os.exit
local yield, wrap = coroutine.yield, coroutine.wrap
local debuginfo, traceback = debug.getinfo, debug.traceback
local _ENV = nil

local tests = {
    "test/dom/interfaces.lua",
    "test/dom/HTMLCollection-empty-name.lua",
    "test/dom/getElementsByClassName-01.lua",
    "test/dom/getElementsByClassName-02.lua",
    "test/dom/Element-getElementsByClassName.lua",
    "test/dom/Element-remove.lua",
    "test/dom/Element-childElementCount.lua",
    "test/dom/Comment-constructor.lua",
    "test/dom/Node-appendChild.lua",
    "test/dom/Node-insertBefore.lua",
    "test/dom/Node-constants.lua",
    "test/dom/outerHTML.lua",
    "test/misc.lua",
    "test/tostring.lua",
    "test/tree-construction.lua",
}

local function handler(err)
    local filename, linenumber = err:match("^(.*):([0-9]+): ")
    if not filename then return err end
    linenumber = assert(tonumber(linenumber))
    local level, info = 2
    while true do
        level = level + 1
        info = debuginfo(level, "Sl")
        if not info then return err end
        if info.short_src == filename and info.currentline == linenumber then
            break
        end
    end
    local file = open(filename)
    if not file then return err end
    local line
    for i = 1, linenumber do
        line = file:read()
        if not line then return err end
    end
    local s = "%s\n   --->  \27[33m%s\27[0m\n     %s"
    return s:format(err, line:match("^%s*(.-)%s*$"), traceback())
end

local function run(tests)
    local function iterate()
        for i, filename in ipairs(tests) do
            local loaded, loadError = loadfile(filename, "t")
            if loaded then
                local ok, runError = xpcall(loaded, handler)
                if ok then
                    yield(true, filename)
                else
                    yield(false, filename, runError)
                end
            else
                yield(false, filename, loadError)
            end
        end
    end
    return wrap(function() iterate() end)
end

local termfmt = function(s, c) return ("\27[%sm%s\27[0m"):format(c, s) end
local green = function(s) return termfmt(s, "32") end
local boldred = function(s) return termfmt(s, "1;31") end
local bold = function(s) return termfmt(s, "1") end

do
    local passed, failed = 0, 0
    write "\n"
    for ok, filename, err in run(tests) do
        if ok then
            passed = passed + 1
            write(" ", green "PASSED", "  ", filename, "\n")
        else
            failed = failed + 1
            write(" ", boldred "FAILED", "  ", err, "\n")
        end
    end
    write("\n ", bold "Passed:", " ", passed, "\n")
    if failed > 0 then
        write(" ", bold "Failed:", " ", boldred(failed), "\n\n")
        exit(1)
    else
        write "\n"
    end
end
