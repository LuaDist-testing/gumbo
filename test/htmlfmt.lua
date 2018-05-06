#!/usr/bin/env lua
local gumbo = require "gumbo"
local serialize = require "gumbo.serialize.html"

local outfile = arg[2] and assert(io.open(arg[2], "a")) or io.stdout
local tree = assert(gumbo.parseFile(arg[1] ~= "-" and arg[1] or io.stdin))
serialize(tree, outfile)
