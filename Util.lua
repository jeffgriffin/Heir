local _
_, Heir = ...
local Heir = Heir

Heir.eventFrame = CreateFrame("Frame")

Heir.eventFrame:SetScript("OnEvent", function(self, event, ...)
  if Heir[event] then
    Heir[event](event, ...)
  end
end)

function Heir.RegisterEvent(event, ...)
  Heir.eventFrame:RegisterEvent(event)
end

Heir.lodMetatable = {
  __index = function(table, key)
    rawget(table, "AssureLoaded")()
    return rawget(table, key)
  end
}

function Heir.ArgsToStrings(first, ...)
  if not first then
    return
  else
    return tostring(first), Heir.ArgsToString(second, ...)
  end
end

function Heir.JoinArgsToString(delimiter, ...)
  return strjoin(delimiter, Heir.ArgsToStrings(...))
end