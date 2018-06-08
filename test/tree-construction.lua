-- Test runner for the html5lib tree-construction test suite.
-- Runs quiet by default to avoid clobbering test runner output.
-- Run with VERBOSE=1 in the environment for full output.

local gumbo = require "gumbo"
local Buffer = require "gumbo.Buffer"
local Indent = require "gumbo.serialize.Indent"
local parse = gumbo.parse
local ipairs, assert, sort = ipairs, assert, table.sort
local open, popen, write = io.open, io.popen, io.write
local clock, exit = os.clock, os.exit
local verbose = os.getenv "VERBOSE"
local _ENV = nil
local ELEMENT_NODE, TEXT_NODE, COMMENT_NODE = 1, 3, 8
local filenames = {}

local function serialize(document)
    local buf = Buffer()
    local indent = Indent(2)
    local function writeNode(node, depth)
        local type = node.nodeType
        if type == ELEMENT_NODE then
            local i1, i2 = indent[depth], indent[depth+1]
            buf:write("| ", i1, "<")
            local namespace = node.namespace
            if namespace ~= "html" then
                buf:write(namespace, " ")
            end
            buf:write(node.localName, ">\n")

            -- The html5lib tree format expects attributes to be sorted by
            -- name, in lexicographic order. Instead of sorting in-place or
            -- copying the entire table, we build a lightweight, sorted index.
            local attr = node.attributes
            local attrLength = #attr
            local attrIndex = {}
            for i = 1, attrLength do
                attrIndex[i] = i
            end
            sort(attrIndex, function(a, b)
                return attr[a].name < attr[b].name
            end)
            for i = 1, attrLength do
                local a = attr[attrIndex[i]]
                local prefix = a.prefix and (a.prefix .. " ") or ""
                buf:write("| ", i2, prefix, a.name, '="', a.value, '"\n')
            end

            local childNodes
            if node.type == "template" then
                buf:write("| ", i2, "content\n")
                depth = depth + 1
                childNodes = node.content.childNodes
            else
                childNodes = node.childNodes
            end

            local n = #childNodes
            for i = 1, n do
                if childNodes[i].type == "text" and childNodes[i+1]
                   and childNodes[i+1].type == "text"
                then
                    -- Merge adjacent text nodes, as expected by the
                    -- spec and the html5lib tests
                    -- TODO: Why doesn't Gumbo do this during parsing?
                    local text = childNodes[i+1].data
                    childNodes[i+1] = childNodes[i]
                    childNodes[i+1].data = childNodes[i+1].data .. text
                else
                    writeNode(childNodes[i], depth + 1)
                end
            end
        elseif type == TEXT_NODE then
            buf:write("| ", indent[depth], '"', node.data, '"\n')
        elseif type == COMMENT_NODE then
            buf:write("| ", indent[depth], "<!-- ", node.data, " -->\n")
        end
    end
    local doctype = document.doctype
    if doctype then
        buf:write("| <!DOCTYPE ", doctype.name)
        local publicId, systemId = doctype.publicId, doctype.systemId
        if publicId ~= "" or systemId ~= "" then
            buf:write(' "', publicId, '" "', systemId, '"')
        end
        buf:write(">\n")
    end
    local childNodes = document.childNodes
    for i = 1, #childNodes do
        writeNode(childNodes[i], 0)
    end
    return buf:tostring()
end

local function parseTestData(filename)
    local file = assert(open(filename, "rb"))
    local text = assert(file:read("*a"))
    file:close()
    local tests = {[0] = {}}
    local buffer = Buffer()
    local field = false
    local testnum, linenum = 0, 0
    for line in text:gmatch "([^\n]*)\n" do
        linenum = linenum + 1
        if line:sub(1, 1) == "#" then
            tests[testnum][field] = buffer:tostring():sub(1, -2)
            buffer = Buffer()
            field = line:sub(2, -1)
            if field == "data" then
                testnum = testnum + 1
                tests[testnum] = {line = linenum}
            end
        else
            buffer:write(line, "\n")
        end
    end
    assert(testnum > 0, "No test data found in " .. filename)
    tests[testnum][field] = buffer:tostring()
    return tests
end

do
    local pipe = assert(popen("echo test/tree-construction/*.dat"))
    local text = assert(pipe:read("*a"))
    pipe:close()
    assert(text:len() > 0, "No test data found")
    local i = 0
    for filename in text:gmatch("%S+") do
        i = i + 1
        filenames[i] = filename
    end
    assert(i > 0, "No test data found")
end

do
    local hrule = ("="):rep(76)
    local passed, failed, skipped = 0, 0, 0
    local start = clock()
    for _, filename in ipairs(filenames) do
        local tests = parseTestData(filename)
        for i, test in ipairs(tests) do
            local input = assert(test.data)
            if input:find("<noscript>") then
                skipped = skipped + 1
            else
                local expected = assert(test.document)
                assert(#expected > 0)
                local parsed, serialized
                local fragment = test["document-fragment"]
                if fragment then
                    local ns, tag = fragment:match("^([a-z]+) +([a-z-]+)$")
                    if ns then
                        parsed = assert(parse(input, nil, tag, ns))
                    else
                        parsed = assert(parse(input, nil, fragment))
                    end
                    serialized = assert(serialize(parsed.documentElement))
                else
                    parsed = assert(parse(input))
                    serialized = assert(serialize(parsed))
                end
                if serialized == expected then
                    passed = passed + 1
                else
                    failed = failed + 1
                    if verbose then
                        write (
                            hrule, "\n",
                            filename, ":", test.line,
                            ": Test ", i, " failed\n",
                            hrule, "\n\n",
                            "Input:\n", input, "\n\n",
                            "Expected:\n", expected, "\n",
                            "Received:\n", serialized, "\n"
                        )
                    end
                end
            end
        end
    end
    local stop = clock()
    if verbose or failed > 0 then
        write (
            "\nRan ", passed + failed, " tests in ",
            ("%.2fs"):format(stop - start), "\n\n",
            "Passed: ", passed, "\n",
            "Failed: ", failed, "\n",
            "Skipped: ", skipped, "\n\n"
        )
    end
    if failed > 0 then
        if not verbose then
            write "Re-run with VERBOSE=1 for a full report\n"
        end
        exit(1)
    end
end
