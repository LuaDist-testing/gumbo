local remove = table.remove
local _ENV = nil

local ChildNode = {}

function ChildNode:remove()
    local parent = self.parentNode
    if parent then
        local cnodes = parent.childNodes
        local n = #cnodes
        for i = 1, n do
            if cnodes[i] == self then
                if n == 1 then
                    parent.childNodes = nil
                else
                    remove(cnodes, i)
                end
            end
        end
    end
end

return ChildNode
