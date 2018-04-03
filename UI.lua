local _
_, Heir = ...
HeirUI = {}
local Heir, HeirUI = Heir, HeirUI
setmetatable(HeirUI, Heir.lodMetatable)

local loaded = false
function HeirUI.AssureLoaded()
  if loaded then return end
  loaded = true
  
  StaticPopupDialogs["HEIR_REGISTER_DIALOG"] = {
    button1 = "Yes",
    button2 = "No",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
  }
  
  function HeirUI.ShowAddHeir(name)
    StaticPopupDialogs["HEIR_REGISTER_DIALOG"].text = name.." claims to be your charge.  Is this true?"
    StaticPopupDialogs["HEIR_REGISTER_DIALOG"].OnAccept = function()
      Heir.AddHeir(name)
    end
    StaticPopup_Show("HEIR_REGISTER_DIALOG")
  end
  
  function HeirUI.SetBenefactorMenu()
    local heirSubsectionId, heirMenuText, heirWlNameId, heirWlNameText, heirBlNameId, heirBlNameText, heirWlGuildId, heirWlGuildText, heirBlGuildId, heirBlGuildText, heirWlCommId, heirWlCommText, heirBlCommId, heirBlCommText = 
      "HEIR_MENU", "Heir to the Pwn", "HEIR_WL_NAME", "Add name to whitelist", "HEIR_BL_NAME", "Remove name from whitelist","HEIR_WL_GUILD", "Add guild name to whitelist", "HEIR_BL_GUILD", "Remove guild name from whitelist", 
      "HEIR_WL_COMMUNICATION", "Allow interaction from this character", "HEIR_BL_COMMUNICATION", "Ban interaction from this character"
    local function HeirButton_OnClick(self)
      local UIDROPDOWNMENU_INIT_MENU = UIDROPDOWNMENU_INIT_MENU
      local name, unit, server = UIDROPDOWNMENU_INIT_MENU.name, UIDROPDOWNMENU_INIT_MENU.unit, UIDROPDOWNMENU_INIT_MENU.server
      server = server or (unit and select(2, UnitFullName(unit))) or GetRealmName()
      local isChat = UIDROPDOWNMENU_INIT_MENU.chatFrame~=nil
      if self.value==heirWlNameId then
        Heir.WhitelistName(name, unit, server, isChat)
      elseif self.value==heirBlNameId then
        Heir.BlacklistName(name, unit, server, isChat)
      elseif self.value==heirWlGuildId then
        Heir.WhitelistName(GetGuildInfo(unit))
      elseif self.value==heirBlGuildId then
          Heir.BlacklistName(GetGuildInfo(unit))
      elseif self.value==heirWlCommId then
        Heir.WhitelistCommunication(name, unit, server, isChat)
      elseif self.value==heirBlCommId then
        Heir.BlacklistCommunication(name, unit, server, isChat)
      end
    end
    local UnitPopupMenus, UnitPopupButtons = UnitPopupMenus, UnitPopupButtons
    local function AddUnitPopupSubsectionTitle(subsectionId, titleText)
      UnitPopupButtons[subsectionId] = { text = titleText, dist = 0, isTitle = true, isUninteractable = true, isSubsection = true, isSubsectionTitle = true, isSubsectionSeparator = true, };
    end
    local function AddPopupButton(buttonId, titleText)
      UnitPopupButtons[buttonId] = { text = titleText, dist = 0 }
    end
    local function AddHeirMenu(menuType, addPlayerOptions)
      tinsert(UnitPopupMenus[menuType], heirSubsectionId)
      tinsert(UnitPopupMenus[menuType], heirWlNameId)
      tinsert(UnitPopupMenus[menuType], heirBlNameId)
      if menuType ~= "OTHERPET" then
        if menuType ~= "FRIEND" then
          tinsert(UnitPopupMenus[menuType], heirWlGuildId)
          tinsert(UnitPopupMenus[menuType], heirBlGuildId)
        end
        tinsert(UnitPopupMenus[menuType], heirWlCommId)
        tinsert(UnitPopupMenus[menuType], heirBlCommId)
      end
    end
    AddUnitPopupSubsectionTitle(heirSubsectionId, heirMenuText)
    AddPopupButton(heirWlNameId, heirWlNameText)
    AddPopupButton(heirBlNameId, heirBlNameText)
    AddPopupButton(heirWlGuildId, heirWlGuildText)
    AddPopupButton(heirBlGuildId, heirBlGuildText)
    AddPopupButton(heirWlCommId, heirWlCommText)
    AddPopupButton(heirBlCommId, heirBlCommText)
    AddHeirMenu("PLAYER")
    AddHeirMenu("OTHERPET")
    AddHeirMenu("PARTY")
    AddHeirMenu("FRIEND")
    hooksecurefunc("UnitPopup_OnClick", HeirButton_OnClick)
  end
end