local util = require "gumbo.dom.util"
local Text = require "gumbo.dom.Text"
local assertions = require "gumbo.dom.assertions"
local assertComment = assertions.assertComment
local constructor = assert(getmetatable(Text))
local setmetatable = setmetatable
local _ENV = nil

local Comment = util.merge("CharacterData", {
    type = "comment",
    nodeName = "#comment",
    nodeType = 8
})

Comment.__index = util.indexFactory(Comment)

function Comment:__tostring()
    assertComment(self)
    return "<!--" .. self.data .. "-->"
end

function Comment:cloneNode()
    assertComment(self)
    return setmetatable({data = self.data}, Comment)
end

return setmetatable(Comment, constructor)
