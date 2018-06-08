local assertions = require "gumbo.dom.assertions"
local assertNode = assertions.assertNode
local remove = table.remove
local _ENV = nil
local ChildNode = {}

function ChildNode:remove()
    assertNode(self)
    local parent = self.parentNode
    if parent then
        parent:removeChild(self)
    end
end

-- TODO: function ChildNode:before(...)
-- TODO: function ChildNode:after(...)
-- TODO: function ChildNode:replace(...)

return ChildNode
