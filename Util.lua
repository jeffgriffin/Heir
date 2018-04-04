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

-- Pooled Table Functions
local function tUnpack(self, from, to)
	if self.n then
		return unpack(self, from or 1, to or self.n)
	else
		return unpack(self, from, to)
	end
end

local tablePool = {}
Heir.tablePool = tablePool
local function tPool(self, from, to)
	tablePool[self] = self
	return tUnpack(self, from, to)
end
Heir.tPool = tPool

local function tInsert(self, value, pos)
	local n = self.n
	if not n and value then 
		if pos then return tinsert(self, pos, value) 
		else return tinsert(self, value)  end
	end
	
	local newN = (n and n+1) or #self+1
	if not pos then
		pos = newN
	end
	self.n = newN
	for i=self.n,pos+1,-1 do
		self[i] = self[i-1]
	end
  self[pos] = value
  return self
end

local function tInsertList(self, ...)
	local inputN = select("#", ...)
	local exisingN = self.n or #self
	local newN = inputN + exisingN
	for i=exisingN+1,newN do
		tInsert(self, (select(i-exisingN, ...)), i)
  end
  return self
end

local function tSetList(self, ...)
	wipe(self)
	InitTable(self)
  InsertList(self, ...)
  return self
end

local function InitTable(t)
  t.InsertList = tInsertList
  t.SetList = tSetList
	t.Insert = tInsert
	t.Pool = tPool
	t.Unpack = tUnpack
	return t
end

function Heir.GetCreateTable(...)
	local t = next(tablePool)
	if not t then
		t = {}
	else
		tablePool[t] = nil
	end
	wipe(t)
	InitTable(t)
	tInsertList(t, ...)
	return t
end