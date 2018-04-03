local _
HeirAddonName, Heir = ...
local Heir, HeirAddonName, HeirUI = Heir, HeirAddonName, HeirUI

--Heir.Debug = 1

local function IsHeir()
    return not HeirCharacterDB.Heirs
end

local heirs = {}
local benefactor = nil
local nameWhitelist = nil
local commWhitelist = nil
local function IsBenefactor()
  return HeirCharacterDB.Heirs and next(HeirCharacterDB.Heirs)~=nil
end
Heir.IsBenefactor = IsBenefactor

local function EnrollToBenefactor(name)
  Heir.DebugFormat("EnrollToBenefactor", "name", name)
  ChatThrottleLib:SendAddonMessage("NORMAL", HeirAddonName, "add", "WHISPER", name)
end

local function MessageFamily(...)
  local priority = ...
  if priority~="NORMAL" and priority~="BULK" and priority~="ALERT" then
    MessageFamily("NORMAL", strjoin(" ", ...))
  else
    if benefactor then
      ChatThrottleLib:SendAddonMessage(priority, HeirAddonName, strjoin(" ", select(2, ...)), "WHISPER", benefactor)
    else
      for key in pairs(heirs) do
        ChatThrottleLib:SendAddonMessage(priority, HeirAddonName, strjoin(" ", select(2, ...)), "WHISPER", key)
      end
    end
  end
end

local function SynchronizeToFamily()
  for name in pairs(HeirDB.Names) do
    MessageFamily("BULK", "wlname", name)
  end
  for rqn in pairs(HeirDB.Players) do
    MessageFamily("BULK", "wlcomm", rqn)
  end
end

function Heir.AddHeir(name)  
  if not IsBenefactor() then --mazel tov!
    HeirUI.SetBenefactorMenu()
  end
  heirs = heirs or {}
  heirs[name] = 1
  HeirCharacterDB.Heirs = HeirCharacterDB.Heirs or {}
  HeirCharacterDB.Heirs[name] = 1
  ChatThrottleLib:SendAddonMessage("NORMAL", HeirAddonName, "ackAdd", "WHISPER", name)
  SynchronizeToFamily()
end

local function HandleWhitelistName(name)
  nameWhitelist = nameWhitelist or {}
  nameWhitelist[name] = 1
end

local function HandleBlacklistName(name)
  nameWhitelist = nameWhitelist or {}
  nameWhitelist[name] = nil
end

local function HandleWhitelistForCommunication(rqn)
  commWhitelist = commWhitelist or {}
  commWhitelist[rqn] = 1
end

local function HandleBlacklistForCommunication(rqn)
  commWhitelist = commWhitelist or {}
  commWhitelist[rqn] = nil
  DEFAULT_CHAT_FRAME.historyBuffer:Clear()
end

local function GetRealmQualifiedName(name, realm)
  return strjoin("-", name, realm)
end

local function ChatFormatName(name, unit, realm, forcePlayer)
  Heir.DebugFormat("ChatFormatName", "name", name, "unit", unit, "realm", realm, "forcePlayer", forcePlayer)
  local chatId = name
  if realm then
    chatId = GetRealmQualifiedName(name, realm)
  end
  Heir.DebugFormat("ChatFormatName", "chatId", chatId)
  if forcePlayer or (unit and UnitIsPlayer(unit)) then
    return format("|Hplayer:%s:%s|h[%s]|h", chatId, chatId, name)
  else
    return format("\"%s\"", name)
  end
end

function Heir.WhitelistName(...)
  local name, unit, realm, forcePlayer = ...
  HeirDB.Names[name] = 1
  MessageFamily("wlname", name)
  print(format("|cffff8000 Whitelisted the name %s.|r  This name can now appear your heir's unit frames, tooltips and name plates.", ChatFormatName(...)))
end

function Heir.BlacklistCommunication(...)
  local name, unit, realm, forcePlayer = ...
  local rqn = GetRealmQualifiedName(name, realm)
  HeirDB.Players[rqn] = nil
  MessageFamily("ALERT", "blcomm", rqn)
  print(format("|cffdd2222 Blacklisted the player %s for interaction.|r  This player's chat content will not appear in your heir's chat window and group invites from the player will be automatically declined.", ChatFormatName(...)))
end

function Heir.BlacklistName(...)
  local name, unit, realm, forcePlayer = ...
  if forcePlayer or (unit and UnitIsPlayer(unit)) then
    Heir.BlacklistCommunication(...)
  end
  HeirDB.Names[name] = nil
  MessageFamily("ALERT", "blname", name)
  print(format("|cffdd2222 Blacklisted the name %s.|r  This name will not appear in your heir's unit frames, tooltips and name plates.", ChatFormatName(...)))
end

function Heir.WhitelistCommunication(...)
  local name, unit, realm, forcePlayer = ...
  if forcePlayer or (unit and UnitIsPlayer(unit)) then
    Heir.WhitelistName(...)
  end
  local rqn = GetRealmQualifiedName(name, realm)
  HeirDB.Players[rqn] = 1
  MessageFamily("wlcomm", rqn)
  print(format("|cffff8000 Whitelisted the player %s for interaction.|r  Your heir can now see the player's chat content and join their group.", ChatFormatName(...)))
end

local function Command(cmd, source, ...)
  Heir.DebugFormat("Command", "cmd", cmd, "source", source, "...", {...})
  local sourceName, sourceRealm = strsplit("-", source)
  if sourceRealm and sourceRealm~=GetRealmName() then return end
  if not cmd then
  elseif cmd=="enroll" then
    EnrollToBenefactor(sourceName)
  elseif cmd=="add" then
    if HeirCharacterDB.Heirs[sourceName] then
      Heir.AddHeir(sourceName)
    else
      HeirUI.ShowAddHeir(sourceName)
    end
  elseif cmd=="ackAdd" then
    benefactor = sourceName
    HeirCharacterDB.LastBenefactor = sourceName
    HeirCharacterDB.Heirs = nil
    print(format("|cffff8000 Heir:|r Successfully enrolled to %s.", sourceName))
  elseif cmd=="wlname" then
    HandleWhitelistName(...)
  elseif cmd=="blname" then
    HandleBlacklistName(...)
  elseif cmd=="wlcomm" then
    HandleWhitelistForCommunication(...)
  elseif cmd=="blcomm" then
    HandleBlacklistForCommunication(...)
  end
end

SlashCmdList["HEIR"] = function(msg)
  local tokens = select(3, strfind(msg, "^%s*(.*)%s*$"))
  Command(strsplit(" ", tokens))
end
SLASH_HEIR1 = '/heir'

Heir.RegisterEvent("ADDON_LOADED")
function Heir.ADDON_LOADED(event, name)
    Heir.DebugFormat("ADDON_LOADED", "name", name)
    if name~=HeirAddonName then return end
  
    HeirDB = HeirDB or {}
    HeirDB.Names = HeirDB.Names or {}
    HeirDB.Players = HeirDB.Players or {}
    HeirCharacterDB = HeirCharacterDB or {
        ["Heirs"] = nil
    }
  
    local function NameIsWhitelisted(name)
        return IsBenefactor() and HeirDB.Names[name]~=nil
    end

    local function PlayerIsWhitelistedForCommunication(name, realm)
        return IsBenefactor() and HeirDB.Players[GetRealmQualifiedName(name, realm)]~=nil
    end

    local function NameIsFriendOrGuildmate(name)
        if not name then end
        for i = 1, select(2, BNGetNumFriends()) do
            if name == select(5,BNGetFriendInfo(i)) then
                return true
            end
        end
        for i = 1, GetNumGuildMembers() do
            if name == GetGuildRosterInfo(i) then
                return true
            end
        end
    end

    local function NameIsAllowed(name)
        return NameIsFriendOrGuildmate(name) or (nameWhitelist and nameWhitelist[name])
    end

    local function PlayerIsAllowedForCommunication(name, realm)
        if realm == GetRealmName() then
            return NameIsFriendOrGuildmate(name) or (commWhitelist and commWhitelist[GetRealmQualifiedName(name, realm)])
        end
    end
    
    local function IsHiddenUnitName(unit)
        return not (UnitIsUnit(unit, "player") or NameIsAllowed(UnitFullName(unit)))
    end
    
    local function IsHiddenPlayerName(unit)
        return UnitIsPlayer(unit) and IsHiddenUnitName(unit)
    end
    
    local function IsHiddenPetName(unit)
        return UnitIsOtherPlayersPet(unit) and IsHiddenUnitName(unit)
    end
    
    local function GetFilteredUnitName(unit, useEmptyPlayer)
      if IsHiddenPlayerName(unit) then return useEmptyPlayer and "" or "Player"
      elseif IsHiddenPetName(unit) then 
        return UnitCreatureFamily(unit)
      end
    end
    
    local function PrepareWhitelistedName(name, fullName)
      --Heir.DebugFormat("PrepareWhitelistedName", "name", name)
      if NameIsWhitelisted(name) then
        return (fullName or name).." (whitelisted)"
      end
      return fullName or name
    end
    
    local function FilterNameFrame(frame)
      if frame.unit and IsHeir() then
        local genericName = GetFilteredUnitName(frame.unit, true)
        --Heir.DebugFormat("FilterNameFrame", "genericName", genericName)
        if genericName then
          frame.name:SetText(genericName)
          return
        end
      end
      --Heir.DebugFormat("FilterNameFrame", "frame.name:GetText()", (frame.name:GetText()), "UnitFullName(frame.unit)", (UnitFullName(frame.unit)))
      frame.name:SetText(PrepareWhitelistedName((UnitFullName(frame.unit)), frame.name:GetText()))
    end
    
    local function SetChatFilters()
      local filteredChats = {
        "CHAT_MSG_ACHIEVEMENT",
        "CHAT_MSG_BATTLEGROUND",
        "CHAT_MSG_BATTLEGROUND_LEADER",
        "CHAT_MSG_CHANNEL",
        "CHAT_MSG_EMOTE",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_RAID_WARNING",
        "CHAT_MSG_SAY",
        "CHAT_MSG_TEXT_EMOTE",
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_YELL"
      }
      local function NameIsYou(name)
        --Heir.DebugFormat("NameIsYou", "name", name, "UnitFullName", (UnitFullName("player")))
        return name == UnitFullName("player")
      end
      local function FilterChatMessage(chatFrame, event, msg, author, ...)
        --Heir.DebugFormat("FilterChatMessage", "event", event, "msg", msg, "author", author)
        if author=="" then return false, msg, author, ... end
        local guid = select(10, ...)
        if guid then
          local name, realm = select(6, GetPlayerInfoByGUID(guid))
          local rqn = nil
          if realm=="" then
            realm = GetRealmName()
            rqn = GetRealmQualifiedName(name, realm)
          end
          if PlayerIsAllowedForCommunication(name, realm) or NameIsYou(name) then
            return false, msg, author, ...
          elseif PlayerIsWhitelistedForCommunication(name, realm) then
            if rqn then author = rqn end
            author = PrepareWhitelistedName(name, author)
            return false, msg, author, ...
          end
        end
        if not IsHeir() then
          return false, msg, author, ...
        end
        return true
      end
      for _, channel in ipairs(filteredChats) do
        Heir.DebugFormat("SetChatFilters", "channel", channel)
        ChatFrame_AddMessageEventFilter(channel, FilterChatMessage)
      end
    end
    
    local function SetNamePlateFilter()
      hooksecurefunc("CompactUnitFrame_UpdateName", FilterNameFrame)
    end
    
    local function SetTooltipFilter()
        local function FilterTooltip(unit)
            --Heir.DebugFormat("GameTooltip_UnitColor", "unit", unit)
            local genericName = GetFilteredUnitName(unit)
            if not genericName or not IsHeir() then 
                GameTooltipTextLeft1:SetText(PrepareWhitelistedName((UnitFullName(unit)), GameTooltipTextLeft1:GetText()))
            else
                GameTooltipTextLeft1:SetText(genericName)
            end
            for i = 2, GameTooltip:NumLines() do
                local line = _G["GameTooltipTextLeft"..i];
                local guildName, _, _, realm = GetGuildInfo(unit)
                if guildName then
                    local pattern = guildName
                    if realm then
                        pattern = GetRealmQualifiedName(guildName, realm)
                    end
                    if line:GetText()==pattern then
                        if NameIsWhitelisted(guildName) then
                            line:SetText(PrepareWhitelistedName(guildName, pattern))
                        elseif IsHeir() and not NameIsAllowed(guildName) then
                            line:SetText("")
                        end
                    end
                end
            end
        end
        hooksecurefunc("GameTooltip_UnitColor", FilterTooltip)
    end
  
    local function SetUnitFrameFilter()
        hooksecurefunc("UnitFrame_Update", FilterNameFrame)
    end
    
    local function SetPartyInviteFilter()
        function Heir.PARTY_INVITE_REQUEST(event, name, tank, healer, damage, isXRealm, allowMultipleRoles, inviterGuid)
            if not NameIsAllowed(name) then
                DeclineGroup()
            end
        end
        Heir.RegisterEvent("PARTY_INVITE_REQUEST")
    end
    
    local function SetStaticOptions()
        if not IsHeir() then return end
        local staticOptions = {
            ["UnitNameFriendlyPlayerName"] = 0,
            ["UnitNameFriendlyMinionName"] = 0,
            ["UnitNameEnemyPlayerName"] = 0,
            ["UnitNameEnemyMinionName"] = 0,
            ["nameplateShowFriends"] = 1,
            ["nameplateShowFriendlyMinions"] = 1,
            ["nameplateShowEnemies"] = 1,
            ["nameplateShowEnemyMinions"] = 1,
            ["profanityFilter"] = 1,
            ["spamFilter"] = 1,
            ["blockChannelInvites"] = 1,
            ["showToastFriendRequest"] = 0,
            ["chatBubbles"] = 0
        }
        local alwaysShowNamePlateOptions = {
            ["nameplateShowFriends"] = 1,
            ["nameplateShowFriendlyMinions"] = 1,
            ["nameplateShowEnemies"] = 1,
            ["nameplateShowEnemyMinions"] = 1,
            ["profanityFilter"] = 1,
            ["spamFilter"] = 1,
            ["blockChannelInvites"] = 1,
            ["showToastFriendRequest"] = 0,
            ["chatBubbles"] = 0
        }
        local function SetAutoDeclineGuildInvitesCalled(value)
            if not IsHeir() then return end
            if value~=1 then
                SetAutoDeclineGuildInvitesCalled(1)
            end
        end
        local function GetAppropriateOptionSet()
          if GetCVar("nameplateShowAll")=="1" then
            return alwaysShowNamePlateOptions
          else
            return staticOptions
          end
        end
        local function FixAppropriateOptionSet()
          local options = GetAppropriateOptionSet()
          for key,value in pairs(options) do
            --Heir.DebugFormat("FixAppropriateOptionSet", "key", key, "value", value)
            SetCVar(key, value)
          end
        end
        local function SetCVarCalled(key, value)
            if not IsHeir() then return end
            if key=="nameplateShowAll" then
              FixAppropriateOptionSet()
              return
            end
            local options = GetAppropriateOptionSet()
            --Heir.DebugFormat("SetCVarCalled", "key", key, "value", value, "options[key]", options[key])
            if options[key]~=nil and options[key]~=value then
                SetCVar(key, options[key])
            end
        end
        hooksecurefunc("SetCVar", SetCVarCalled)
        hooksecurefunc("SetAutoDeclineGuildInvites", SetAutoDeclineGuildInvitesCalled)
        SetAutoDeclineGuildInvitesCalled(1)
        FixAppropriateOptionSet()
    end

    local function SetAddonMessageListener()
      local function InterleaveSource(source, cmd, ...)
        return cmd, source, ...
      end
      function Heir.CHAT_MSG_ADDON(event, prefix, message, type, sender)
          Heir.DebugFormat("CHAT_MSG_ADDON", "prefix", prefix, "message", message, "type", type, "sender", sender)
          if type=="WHISPER" then
              local tokens = select(3, strfind(message, "^%s*(.*)%s*$"))
              Command(InterleaveSource(sender, strsplit(" ", tokens)))
          end
      end
      RegisterAddonMessagePrefix(HeirAddonName)
      Heir.RegisterEvent("CHAT_MSG_ADDON")
    end

    local function SetReEnrollWatcher()
      local function TryReEnroll()
        if IsHeir() and HeirCharacterDB.LastBenefactor then
          EnrollToBenefactor(HeirCharacterDB.LastBenefactor)
        end
      end
      function Heir.FRIENDLIST_UPDATE()
        Heir.DebugFormat("FRIENDLIST_UPDATE")
        TryReEnroll()
      end
      TryReEnroll()
      Heir.RegisterEvent("FRIENDLIST_UPDATE")
    end
  
    SetStaticOptions()
    SetNamePlateFilter()
    SetTooltipFilter()
    SetUnitFrameFilter()
    SetPartyInviteFilter()
    SetChatFilters()
    SetAddonMessageListener()
    SetReEnrollWatcher()
    if IsBenefactor() then
        HeirUI.SetBenefactorMenu()
    end
end