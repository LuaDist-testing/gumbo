local util = require "gumbo.dom.util"
local _ENV = nil

local CharacterData = util.merge("Node", "ChildNode")

function CharacterData.getters:length()
    return #self.data
end

return CharacterData
