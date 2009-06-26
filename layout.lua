local layoutName = "cargBags_Smee"
local addon = CreateFrame"Frame"
_G[layoutName] = addon

local L = {}
local gl = GetLocale()
if gl == "enGB" or gl == "enUS" then
	L.Armor = "Armor"
	L.Weapon = "Weapon"
	L.Gem = "Gem"
	L.Trades = "Trade Goods"
	L.Consumables = "Consumable"
	L.Quest = "Quest"
	L.Potions = "Potion"
	L.Flasks = "Flask"
	L.Elixirs = "Elixir"
	L.Reagents = "Reagent"
elseif gl == "frFR" then
	L.Armor = "Armure"
	L.Weapon = "Arme"
	L.Gem = "Gemme"
	L.Trades = "Artisanat"
	L.Consumables = "Consommable"
	L.Quest = "Quête"
elseif gl == "ruRU" then
	L.Armor = "Доспехи"
	L.Weapon = "Оружие"
	L.Gem = "Самоцветы"
	L.Trades = "Хозяйственные товары"
	L.Consumables = "Расходуемые"
	L.Quest = "Задания"
elseif gl == "zhTW" then
	L.Armor = "護甲"
	L.Weapon = "武器"
	L.Gem = "珠寶"
	L.Trades = "商品"
	L.Consumables = "消耗品"
	L.Quest = "任務"
elseif gl == "zhCN" then
	L.Armor = "护甲"
	L.Weapon = "武器"
	L.Gem = "珠宝"
	L.Trades = "商品"
	L.Consumables = "消耗品"
	L.Quest = "任务"
elseif gl == "deDE" then
	L.Armor = "Rüstung"
	L.Weapon = "Waffe"
	L.Gem = "Juwelen"
	L.Trades = "Handwerkswaren"
	L.Consumables = "Verbrauchbar"
	L.Quest = "Quest"
end
	
local Split = function(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gmatch(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

-- This function is only used inside the layout, so the cargBags-core doesn't care about it
-- It creates the border for glowing process in UpdateButton()
local createGlow = function(button)
	local glow = button:CreateTexture(nil, "OVERLAY")
	glow:SetTexture"Interface\\Buttons\\UI-ActionButton-Border"
	glow:SetBlendMode"ADD"
	glow:SetAlpha(.8)
	glow:SetWidth(70)
	glow:SetHeight(70)
	glow:SetPoint("CENTER", button)
	button.Glow = glow
end

-- The main function for updating an item button,
-- the item-table holds all data known about the item the button is holding, e.g.
--   bagID, slotID, texture, count, locked, quality - from GetContainerItemInfo()
--   link - well, from GetContainerItemLink() ofcourse ;)
--   name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc - from GetItemInfo()
-- if you need cooldown item data, use self:RequestCooldownData()
local UpdateButton = function(self, button, item)
	button.Icon:SetTexture(item.texture)
	if IsAddOnLoaded("Tabard-O-Matic") then
		local slot = button:GetID()
		--local bag = button:GetBag()
		
		--local link = self.GetHandler().GetContainerItemLink(item.bagID, slot)
		link = item.link
		if (link) then
			local ItemID = tonumber(link:match("item:(%d+)"))
			item.itemID = itemID
			local TabardValue = TabardTextures[ItemID]
		
				if TabardValue then
					Tabard_O_Matic:SetTheButtons(button, TabardValue.ItemName)
				end
		end
	end	
	SetItemButtonCount(button, item.count)
	SetItemButtonDesaturated(button, item.locked, 0.5, 0.5, 0.5)

	-- Color the button's border based on the item's rarity / quality!
	if(item.rarity and item.rarity > 1) then
		if(not button.Glow) then createGlow(button) end
		button.Glow:SetVertexColor(GetItemQualityColor(item.rarity))
		button.Glow:Show()
	else
		if(button.Glow) then button.Glow:Hide() end
	end
end

-- Updates if the item is locked (currently moved by user)
--   bagID, slotID, texture, count, locked, quality - from GetContainerItemInfo()
-- if you need all item data, use self:RequestItemData()
local UpdateButtonLock = function(self, button, item)
	SetItemButtonDesaturated(button, item.locked, 0.5, 0.5, 0.5)
end

-- Updates the item's cooldown
--   cdStart, cdFinish, cdEnable - from GetContainerItemCooldown()
-- if you need all item data, use self:RequestItemData()
local UpdateButtonCooldown = function(self, button, item)
	if(button.Cooldown) then
		CooldownFrame_SetTimer(button.Cooldown, item.cdStart, item.cdFinish, item.cdEnable) 
	end
end

-- The function for positioning the item buttons in the bag object
local UpdateButtonPositions = function(self)
	local button
	local col, row = 0, 0
	self.empty = true
	for i, button in self:IterateButtons() do
		button:ClearAllPoints()

		local xPos,yPos = (col * 38), (-1 * row * 38)
		if(self.Caption) then yPos = yPos - 20 end	-- Spacing for the caption
		if(self.SearchBar and self.SearchBar:IsShown()) then 
			yPos = yPos - 20
		end	-- Spacing for the searchbar

		button:SetPoint("TOPLEFT", self, "TOPLEFT", xPos, yPos)	 
		if(col >= self.Columns-1) then col = 0; row = row + 1	 
		else	 col = col + 1	 
		end
		 self.empty = false
	end
	
	-- This variable stores the size of the item button container
	self.ContainerHeight = (row + (col>0 and 1 or 0)) * 38

	if(self.UpdateDimensions) then self:UpdateDimensions() end -- Update the bag's height
end

-- Function is called after a button was added to an object
-- We color the borders of the button to see if it is an ammo bag or else
-- Please note that the buttons are in most cases recycled and not new created
local PostAddButton = function(self, button, bag)
	if(not button.NormalTexture) then return end

	local bagType = cargBags.Bags[button.bagID].bagType
	if(button.bagID == KEYRING_CONTAINER) then
		button.NormalTexture:SetVertexColor(1, 0.7, 0)	-- Key ring
	elseif(bagType and bagType > 0 and bagType < 8) then
		button.NormalTexture:SetVertexColor(1, 1, 0)		-- Ammo bag
	elseif(bagType and bagType > 4) then
		button.NormalTexture:SetVertexColor(0, 1, 0)		-- Profession bags
	else
		button.NormalTexture:SetVertexColor(1, 1, 1)		-- Normal bags
	end
end

-- More slot buttons -> more space!
local UpdateDimensions = function(self)
	local height = 0			-- Normal margin space
	if(self.Space) then
		height = height + 16	-- additional info display space
	end
	if(self.Caption) then	-- Space for captions
		height = height + 20
	end
	if(self.BagBar and self.BagBar:IsShown()) then	-- Space for captions
		height = height + 35
	end
	if(self.SearchBar and self.SearchBar:IsShown()) then
		height = height + self.SearchBar.field:GetHeight()+4
	end	-- Spacing for the searchbar

	self:SetHeight(self.ContainerHeight + height)

	addon:UpdateAnchors(self)

end

local function createSmallButton(name, parent, ...)
	local button = CreateFrame("Button", nil, parent)
	button:SetPoint(...)
	button:SetNormalFontObject(GameFontNormalSmall)
	button:SetText(name)
	button:SetPoint"CENTER"
	button:SetWidth(20)
	button:SetHeight(20)
	button:SetScript("OnEnter", buttonEnter)
	button:SetScript("OnLeave", buttonLeave)
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	button:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	})
	button:SetBackdropColor(0, 0, 0, 1)
	button:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.7)
	return button
end

--[[ Animation 
local f = CreateFrame"Frame"
local function OnShow(self)
	self:SetAlpha(0)
	self.Fade.min = 0
	self.Fade.max = 1
	self.Fade:Play()
	f.Show(self)
end
local function OnHide(self)
	self:SetAlpha(1)
	self.Fade.min = 1
	self.Fade.max = 0
	self.Fade:Play()
end

local function OnUpdate(self)
	self.Parent:SetAlpha(self.min + (self.max - self.min) * self:GetProgress())
end
local function OnFinished(self)
	if(self.max == 0) then f.Hide(self.Parent) end
end
--]]

local CreateSearchBar = function(self,dims)
	local searchBar = CreateFrame("Frame",nil,self)
	searchBar:SetBackdrop{ 
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\AddOns\\cargBags_Smee\\Media\\UI-Tooltip-Border", 
		tile = true, 
		tileSize = 8, 
		edgeSize =16, 
		insets = { left = 4,right = 4,top = 4,bottom = 4} 
	}
	searchBar:SetBackdropColor(unpack(self.db.options.backdrop))
	searchBar:SetBackdropBorderColor(.2,.2,.2)
	
	for index, anchor in pairs(dims.anchors)do
		searchBar:SetPoint(anchor.anchorFrom,anchor.anchorOn,anchor.anchorTo,anchor.anchorX,anchor.anchorY)
	end
	
	searchBar:SetHeight(dims.height)
	
	local field = CreateFrame("EditBox", nil, searchBar)
	field:SetPoint("TOPLEFT",searchBar,"TOPLEFT",5,0)
	field:SetPoint("BOTTOMLEFT",searchBar,"BOTTOMLEFT",5,0)
	field:SetPoint("TOPRIGHT",searchBar,"TOPRIGHT",-5,0)
	field:SetPoint("BOTTOMRIGHT",searchBar,"BOTTOMRIGHT",-5,0)
	field:SetAutoFocus(false)
	field:SetFontObject("GameFontHighlight")
	field:SetTextColor(1,1,1)
	field:SetText(addon.defaultSearchText)
	field:SetAltArrowKeyMode()
	field:SetScript("OnTextChanged", function()
	addon.searchCount = 0

		filterName(field:GetText(), self)
		if addon.searchCount == 0 and field:GetText() ~= "" and field:GetText() ~= addon.defaultSearchText then 
			field:SetTextColor(1,0.38,0.38)
			filterName("", self)
		elseif field:GetText() == "" or field:GetText() == addon.defaultSearchText then
			field:SetTextColor(1,1,1)
			filterName("", self)
		else
			field:SetTextColor(0.38,1,0.38)
		end
	end)
	field:SetScript("OnEditFocusGained", function()
		if field:GetText() ~= addon.defaultSearchText then
			if addon.searchCount == 0 and field:GetText() ~= "" then 
				field:SetTextColor(1,0.38,0.38)
				filterName("", self)
			elseif field:GetText() == "" then
				field:SetTextColor(1,1,1)
			else
				field:SetTextColor(0.38,1,0.38)
			end
			field:HighlightText()
		else
			field:SetText("")
		end
	end)
	field:SetScript("OnEditFocusLost", function()
		field:HighlightText(0,0)
		field:SetTextColor(1,1,1)
		if field:GetText() == "" then
			field:SetText(addon.defaultSearchText)
		end
	end)
	field:SetScript("OnEnterPressed", function()
		field:ClearFocus()
	end)
	field:SetScript("OnEscapePressed", function() 
		field:SetText(""); 
		field:ClearFocus()
	end)

	searchBar.field = field
	return searchBar
end


--[[ place with filters ]]
local searchName = function(item)
    local isMatch,filters,argument,attrib,term
    if addon.searchFilter:lower() == addon.defaultSearchText:lower() then return end
    
    if item.texture ~= nil and addon.searchCount then

    	if addon.searchFilter:find(",")~=nil then
    		filters = Split(addon.searchFilter,",")
    	else
    		filters = { (not addon.searchFilter:find(":") and "name:" or "")..addon.searchFilter }
    	end
    	
    	for index,search in pairs(filters)do
    		attrib,term = unpack(Split(search,":"))
			value =  tostring(attrib=="id" and item.link:match("item:(%d+)") or item[attrib])

    		if not isMatch and value~=nil and term~=nil then
	   			isMatch = not isMatch and strfind(value:lower(), term:lower()) ~= nil or false
   			    if isMatch then addon.searchCount = addon.searchCount + 1 end
   			end
   			
    	end		 
    	       
    else
    	isMatch = false
    end
    return isMatch
end

--[[ place after bag objects are declared ]]
function filterName(str, frame)
	local hasText = (str ~= "")
    addon.searchFilter = hasText and str or nil
    frame:SetFilter(searchName, hasText)
end

function button_OnEnter(self,...)
  GameTooltip_SetDefaultAnchor( GameTooltip, UIParent )
  GameTooltip:SetText(self.toolTipText)
  GameTooltip:Show()
end

function button_OnLeave()
  GameTooltip:Hide()
end

local function createButton(label,func,parent,dims,toolTipText)
	local button = CreateFrame("CheckButton", nil, parent)
			button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
			button:SetWidth(dims.width)
			button:SetHeight(dims.height)			button:SetPoint(dims.anchorFrom,dims.anchorOn,dims.anchorTo,dims.anchorX,dims.anchorY)
			button:RegisterForClicks("LeftButtonUp")
			button:SetScript("OnClick", func)
			button.toolTipText = toolTipText
			button:SetScript("OnEnter", button_OnEnter)
			button:SetScript("OnLeave", button_OnLeave)
			button.icon = nil
			button.text = nil

	if(label.type=="text")then
		local text = button:CreateFontString(nil, "OVERLAY")
		text:SetPoint("CENTER", button)
		text:SetFontObject(GameFontNormalSmall)
		text:SetText(label.text)
		button.text = text
	elseif(label.type == "icon")then
		local icon = button:CreateTexture(nil, "OVERLAY")
		icon:SetTexture(label.texture)
		icon:SetPoint("TOPLEFT", button)
		icon:SetPoint("BOTTOMRIGHT", button)
		icon:SetTexCoord(0, 1, 0, 1)
		icon:Show()
		button.icon = icon
	end
	
	return button
end
function SetFrameMovable(obj,saveLayout)
		obj:SetMovable(true)
		obj:SetUserPlaced(saveLayout)
		obj:RegisterForClicks("LeftButton", "RightButton");
		obj:SetScript("OnMouseDown", function() 
		        obj:ClearAllPoints() 
		        obj:StartMoving() 
		end)
		obj:SetScript("OnMouseUp",  obj.StopMovingOrSizing)
		obj:SetScript("OnHide", obj.StopMovingOrSizing) 
end

-- Style of the bag and its contents
local func = function(settings, self, name)
	self.UpdateDimensions = UpdateDimensions
	self.UpdateButtonPositions = UpdateButtonPositions
	self.UpdateButton = UpdateButton
	self.UpdateButtonLock = UpdateButtonLock
	self.UpdateButtonCooldown = UpdateButtonCooldown
	self.PostAddButton = PostAddButton
	self:EnableMouse(true)
	self:SetFrameStrata("HIGH")
	tinsert(UISpecialFrames, self:GetName()) -- Close on "Esc"
	local captionOffset = 0
	
	self.db = addon.db.bags[tonumber(name:gmatch(layoutName .. "(.*)" )())]
	
--[[ Animation part II
	local anim = self:CreateAnimationGroup()
	local fade = anim:CreateAnimation("Animation")
			fade:SetDuration(.25)
			fade:SetSmoothing("IN_OUT")
			fade.Parent = self
			fade:SetScript("OnUpdate", OnUpdate)
			fade:SetScript("OnFinished", OnFinished)
			self.Show = OnShow
			self.Hide = OnHide
			self.Fade = fade
--]]

		-- Make bags movable
	SetFrameMovable(self,self.db.customAnchor)
	
	if(self.db.isBank or self.db.isMainBag) then
		
		-----------
		-- MONEY --
		if self.db.isMainBag then 
			local money = self:SpawnPlugin("Money")
			if(money) then money:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10,-2) end
		end
		
		------------
		-- FILTERS --
		-- 1. create toggle button
		-- 2. create toggle function
		--  2a. expand parentBag
		--  2b. show filter button panel
		-- 3. step through bag.db
		-- 4. create 1 button for each entry where bag.isBackPack = true
		
		 -- A nice bag bar for changing/toggling bags
		self.bagToggle = createButton({type = "text",text = "Bags"},function()
			if(self.BagBar:IsShown()) then 
				self.BagBar:Hide()
			else
				self.BagBar:Show()
			end
			self:UpdateButtonPositions()
		end,self,{
			anchorFrom		= "BOTTOMRIGHT",
			anchorOn		= self,
			anchorTo		= "BOTTOMRIGHT",
			anchorX			= 0,
			anchorY			= 0,
			width			= 40,
			height			= 15},
			"Toggle the bag bar")
			
		local bagButtons = self:SpawnPlugin("BagBar", self.db.isMainBag and "bags" or "bank")
		if(bagButtons) then
			bagButtons:SetPoint("BOTTOMRIGHT", self.bagToggle, "TOPRIGHT", -5, 4)
			local backdrop = CreateFrame("Frame",nil,bagButtons)
			backdrop:SetBackdrop{ 
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\AddOns\\cargBags_Smee\\Media\\UI-Tooltip-Border", 
				tile = true, 
				tileSize = 8, 
				edgeSize =16, 
				insets = { left = 4,right = 4,top = 4,bottom = 4} 
				}
			bagButtons:SetScale(0.75)
			bagButtons:SetFrameStrata("DIALOG")
			bagButtons:Hide()
			self.bagButtons = bagButtons

			-- main window gets a fake bag button for toggling key ring
			if(self.db.isMainBag) then
				local keytoggle = bagButtons:CreateKeyRingButton()
				keytoggle:SetScript("OnClick", function()
					local keyring = addon.KeyRing.object
					if keyring:IsShown() then
						keyring:Hide()
						keytoggle:SetChecked(0)
					else
						keyring:Show()
						keytoggle:SetChecked(1)
					end
				end)
			end
		end

		-- For purchasing bank slots
		if(self.db.isBank) then
			local purchase = self:SpawnPlugin("Purchase")
			if(purchase) then
				purchase:SetText(BANKSLOTPURCHASE)
				purchase:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 20)
				if(self.BagBar) then purchase:SetParent(self.BagBar) end

				purchase.Cost = self:SpawnPlugin("Money", "static")
				purchase.Cost:SetParent(purchase)
				purchase.Cost:SetPoint("BOTTOMRIGHT", purchase, "TOPRIGHT", 0, 2)
			end
		end

		----------------
		-- FREE SPACE --
		local space = self:SpawnPlugin("Space", "[free] / [max] free")
		if(space) then
			space:SetPoint("BOTTOMLEFT", self,"BOTTOMLEFT", 4, 0)
			space:SetJustifyH"LEFT"
		end		

		local anywhere = self:SpawnPlugin("Anywhere")
		if(anywhere) then
			anywhere:SetPoint("TOPLEFT",self,"TOPLEFT",captionOffset,2)
			anywhere:GetNormalTexture():SetDesaturated(1)
			self.anywhere = anywhere
			captionOffset = captionOffset + 25
		end
		
		
	end

	if(self.db.options.searchbar)then
		self.searchToggle = createButton({type = "icon",texture = "Interface\\ICONS\\INV_Misc_Spyglass_03"},function()
			if(self.SearchBar:IsShown()) then 
				self.SearchBar:Hide()
			else
				self.SearchBar:Show()
			end
			self:UpdateButtonPositions()
		end,self,{
			anchorFrom		= "TOPLEFT",
			anchorOn			= self,
			anchorTo			= "TOPLEFT",
			anchorX			= captionOffset,
			anchorY			= 0,
			width				= 20,
			height				= 20},
			"Toggle the search bar.")
		
		self.SearchBar = CreateSearchBar(self,{
			anchors = {
				{
					anchorFrom		= "TOPLEFT",
					anchorOn		= self,
					anchorTo		= "TOPLEFT",
					anchorX			= 0,
					anchorY			= -20,
				},{
					anchorFrom		= "TOPRIGHT",
					anchorOn		= self,
					anchorTo		= "TOPRIGHT",
					anchorX			= 0,
					anchorY			= -20,
				}
			},
			height			= 22})
		self.SearchBar:Hide()
		captionOffset = captionOffset + 25
	end
	
	self:SetScale(self.db.options.scale)
	self.Columns = self.db.options.columns
	self.ContainerHeight = 0
	self:UpdateDimensions()
	self:SetWidth(38*self.Columns)	-- Set the frame's width based on the columns


	-- And the frame background!
	local backdrop = CreateFrame("Frame",nil,self)
	backdrop:SetBackdrop{ 
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\AddOns\\cargBags_Smee\\Media\\UI-Tooltip-Border", 
		tile = true, 
		tileSize = 8, 
		edgeSize =16, 
		insets = { left = 4,right = 4,top = 4,bottom = 4} 
	}
	backdrop:SetBackdropColor(unpack(self.db.options.backdrop))
	backdrop:SetBackdropBorderColor(.2,.2,.2)
	backdrop:SetFrameStrata("HIGH")
	backdrop:SetPoint("TOPLEFT",-6,6)
	backdrop:SetPoint("BOTTOMRIGHT",6,-6)

	-- Caption and close button
	local caption = backdrop:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if(caption) then
		caption:SetText(self.db.caption or name)
		caption:SetPoint("TOPLEFT",captionOffset+ 5, -8)
		self.Caption = caption

		local close = CreateFrame("Button", nil, self, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", 5, 8)
		close:SetScript("OnClick", function(self) self:GetParent():Hide() end)
		

	end

	return self
end

-- Register the style with cargBags
cargBags:RegisterStyle("Smee", setmetatable({}, {__call = func}))


local INVERTED = -1 -- with inverted filters (using -1), everything goes into this bag when the filter returns false

function addon:GetItemID(item)
	return item.link:match("item:(%d+)")
end

function addon:ItemFitsCategory(category,item)
	local matchesID = category.itemid[addon:GetItemID(item)] 
	local matchesType = category.type[item.type]
	local matchesSubType = category.type[item.subType]

	return matchesID or matchesType or matchesSubType
end


--------------------
--General filters
--------------------

local onlyToys = function(item)
	return item.link and addon.db.items.toys.itemid[addon:GetItemID(item)] or false
end

local onlyBags = function(item) return item.bagID >= 0 and item.bagID <= 4 end
local onlyKeyring = function(item) return item.type == "Key" or item.bagID == -2 end
local onlyBank = function(item) return item.bagID == -1 or item.bagID >= 5 and item.bagID <= 11 end

----------------
-- Bag filters
----------------

-- Stuff filter

local onlyArmor = function(item) return item.type and (item.equipLoc~='' or item.type == L.Armor) end
local onlyWeapon = function(item) return item.type and (item.equipLoc~='' or item.type == L.Weapon) end

local filterGear = function(item) 
	if(onlyToys(item))then return false end
	return (onlyWeapon(item) or onlyArmor(item)) and addon:ItemIsPartOfSet(item)
end 
local filterLegendary = function(item) return item.rarity and item.rarity == 4 end
local filterEpic = function(item) return item.rarity and item.rarity == 3 end
local filterRare = function(item) return item.rarity and item.rarity == 2 end

local hideJunk = function(item) return not item.rarity or item.rarity > 0 end
local hideEmpty = function(item) return item.texture ~= nil end 
local onlyQuest = function(item) return item.type and item.type == L.Quest end
local onlyConsumables = function(item) return item.type and item.type == L.Consumables end
	local onlyReagents = function(item) return onlyConsumables(item) and item.subType == L.Reagents	end
	local onlyPotions = function(item) 	return onlyConsumables(item) and  item.subType == L.Potions 	end
	local onlyFlasks = function(item) return onlyConsumables(item) and  item.subType == L.Flasks end
	local onlyElixirs = function(item) return onlyConsumables(item) and  item.subType == L.Elixirs end
	local onlyDrugs = function(item)
		return onlyFlasks(item) or onlyElixirs(item) or onlyPotions(item)
	end


local onlyTradeGoods = function(item) 	return item.type and item.type == L.Trades end
local onlyEnchanting = function(item) 	
	return item.type and addon:ItemFitsCategory(addon.db.items.enchanting,item)
end

local onlyGems = function(item) return item.type and item.type == L.Gem end
local onlyJewelcrafting = function(item)
	return item.type and addon:ItemFitsCategory(addon.db.items.jewelcrafting,item)
end

local nothing = function(item) return false end


-----------------
-- Bank filters
-----------------local onlyBankArmor = function(item) return item.bagID == -1 or (item.bagID >= 5 and item.bagID <= 11) and item.type and item.type == L.Armor end
local onlyBankWeapons = function(item) return item.bagID == -1 or (item.bagID >= 5 and item.bagID <= 11) and item.type and item.type == L.Weapon end
local onlyBankConsumables = function(item) return item.bagID == -1 or (item.bagID >= 5 and item.bagID <= 11) and item.type and item.type == L.Consumables end

	-- Opening / Closing Functions
	function OpenCargBags()
		local isEmpty,isShown
		for index,bag in pairs(addon.db.bags)do
			isEmpty = addon:IsBagEmpty(bag.object) == 0
			isShown = bag.object:IsShown()
			addon:Debug(bag.caption, isEmpty, isShown)

			if(bag.isBackPack and not isEmpty)then
				bag.object:Show()
			end

		end
	end

	function CloseCargBags()
		for index,bag in pairs(addon.db.bags)do
			if(not bag.object.ExplicitlyOpened)then
				bag.object:Hide()
				if bag.object.bagButtons and bag.object.bagButtons:IsShown() then 
					bag.object.bagButtons:Hide()
					bag.object:UpdateDimensions()
				end
			end
		end
	end

	function ToggleCargBags(forceopen)
		if(addon.MainBag.object:IsShown() and not forceopen) then 
			CloseCargBags()
		else
			OpenCargBags()
		end
	end
	
	function addon:ToggleBag(bag)
		if(not bag)then return end
		local isShown = bag:IsShown()
		if  isShown then
			bag.ExplicitlyOpened = false
			bag:Hide()
		else
			bag.ExplicitlyOpened = true
			bag:Show()
		end
	end

	function addon:FindBagByName(name)
		local bag = self.namedIndex[name]
		return bag and bag.object
	end
	
	function addon:FindBagByIndex(index)
		local bag = self.numericIndex[index] or nil
		return bag and bag.object
	end
	
	function addon:FindBag(search)
		local bag
		if(type(tonumber(search))=="number")then 
			return self.numericIndex[tonumber(search)]
		else
			for index,data in pairs(self.namedIndex)do
				if(not bag and index:gmatch(search)())then bag = data end
			end
			return bag
		end		
	end
	
	function addon:IsBagEmpty(bag)
		local count = 0
		for index,button in bag:IterateButtons() do
			count = index
		end
		return count
	end
	
	function addon:UpdateAnchors(frame)
		if not frame.ChildFrames then return end

		local childFrom,childOn,childTo,childX,childY
		local frameFrom,frameOn,frameTo,frameX,frameY = frame:GetPoint()
		
		for child,isChild in pairs(frame.ChildFrames) do
			childPos = child.db.position
			child:ClearAllPoints()
			if(frame.empty)then		
				child:SetPoint(frameFrom,frameOn,frameTo,frameX,frameY)
			else
				self:PositionBag(child,child.db)
			end			
		end
		
		local count = addon:IsBagEmpty(frame)
		print(frame.db.caption, count, (count>=1 and "showing" or "hiding"))

		if( count >= 1)then		
			frame:Show()
		else
			frame:Hide()
		end

	end

	function addon:CreateAnchorInfo(parent,child,dir)
		child.AnchorTo = parent
		child.AnchorDir = dir
		if parent then
		    if not parent.ChildFrames then parent.ChildFrames = {} end
		    parent.ChildFrames[child] = true
		end
	end

function addon:ItemIsPartOfSet(item)
	local found = false
	local itemId = addon:GetItemID(item)
	if itemId then
		for index,id in pairs(self.EquipmentSets)do			
			if(not found and tonumber(itemId) == tonumber(id)) then
				 found = true
			end			
		end
	end
	return found
end

function addon:indexEquipmentProfiles()
	local sets,list = nil,{}
	local blizzardSets = GetNumEquipmentSets()
	
	if IsAddOnLoaded("SaleRack") and SaleRack.profile~=nil then
		self:Print("SaleRack : parsing EquipmentSets")
		for setName,setTable in pairs(SaleRack.profile) do
			if type(setTable) == "table" then
				for slotId,itemId in pairs(setTable) do
					if(itemId) then table.insert(list, itemId) end
				end
			end
		end

	elseif(blizzardSets)then
		self:Print("Blizzard Equipment Manager : parsing EquipmentSets")
		for index=1,blizzardSets do
				for slotId,itemId in pairs(GetEquipmentSetItemIDs(GetEquipmentSetInfo(index))) do 
					if(itemId and itemId>0) then table.insert(list, itemId) end
				end
		end
	else
		self:Print("No Equipment Manager",'debug')
		list = nil
	end

	return list
end

function addon:EQUIPMENT_SETS_CHANGED()
	cargBags_Smee.EquipmentSets = nil
	cargBags_Smee.EquipmentSets = cargBags_Smee:indexEquipmentProfiles()
end



function addon:ADDON_LOADED()
	if IsAddOnLoaded("SaleRack") then
		self:Print("SaleRack Loaded : Hooking EquipmenSet Update Event.")
		SaleRack:HookEvent("EQUIPMENT_SETS_CHANGED",cargBags_Smee.EQUIPMENT_SETS_CHANGED)
	end
	self.EquipmentSets =self:indexEquipmentProfiles()
end

function addon:PositionBag(bag,db)
		local anchorObject
		if(type(db.position.anchorOn) == "function")then
			anchorObject = db.position.anchorOn()
		elseif(type(db.position.anchorOn) == "number")then
			anchorObject = self.db.bags[db.position.anchorOn].object
		elseif(db.position.anchorOn == nil)then
			anchorObject = UIParent
		end
		
		bag:SetPoint(
			db.position.anchorFrom,
			anchorObject,
			db.position.anchorTo,
			db.position.anchorX,
			db.position.anchorY)

end
function addon:CreateBag(index,bag)
	bag.object = cargBags:Spawn(layoutName..index)
	local record = {name = bag.caption, object = bag.object, id = index }

	self.numericIndex[index] = record
	self.namedIndex[bag.caption:lower()] = record

	if(bag.isBank)then self.Bank = bag end
	if(bag.isMainBag)then self.MainBag = bag end
	if(bag.isKeyRing)then self.KeyRing = bag end		
end
function addon:AnchorBag(bag)
	self:PositionBag(bag.object,bag)

	if(bag.ChildAnchorPoints)then
		for _,anchor in pairs(bag.ChildAnchorPoints) do
			 self:CreateAnchorInfo(nil,bag.object,anchor)
		end
	else
		-- addon:CreateAnchorInfo(parent,child,dir)
		self:CreateAnchorInfo(bag.position.anchorOn(), bag.object, bag.position.anchorTo)
	end
		
	for filter,func in ipairs(bag.filters)do
		bag.object:SetFilter(func, true)
	end
end

function addon:VARIABLES_LOADED()
	self.Bank = nil
	self.MainBag = nil
	self.KeyRing = nil
	self.defaultSearchText= "Search"
	self.EnableDebugMessages = false
	
	-- Frames Spawns
	self.db = {}
	self.db.items = {
		toys = {
			itemid = {
				['43499'] = true,		-- iron boot flask
				['44606'] = true,		-- toy train set
				['36862'] = true,		-- worn troll dice
				['45057'] = true,		-- Wind-Up Train Wrecker
				['37710'] = true,		-- Crashin' Thrashin' Racer Controller
				['43824'] = true,		-- The Schools of Arcane Magic : Mastery
				['44430'] = true,		-- Titanium Seal of Dalaran	
				['44817'] = true,		-- Titanium Seal of Dalaran	
				['44228'] = true,		-- Baby Spice
				['35275'] = true,		-- Orb of the Sin'dorei
				['15778'] = true,		-- Mechanical Yeti
				['46765'] = true,		-- Blue Battle Fuel
				['46766'] = true,		-- Red Battle Fuel
			},
			type = {
			
			}
		},
		enchanting = {
			itemid = {
				["34055"] = true,
			},
			type = {
				['Enchanting'] = true,
				['Elemental'] = true,
				
			}
		},
		jewelcrafting = {
			itemid ={
				["44943"] = true, --Icey Prism
			},
			type = {
				["Metal & Stone"] = true,
				["Gem"] = true,
			}			
		}
	}
	
	
	self.db.bags = {
		{ -- 1
			caption = "KeyRing",
			options = {
				columns	= 8,
				scale		= 0.6,
				backdrop	= {0,180/255,1},
				searchbar = true,
			},
			filters = {onlyKeyring, hideEmpty},
			position = {
				anchorFrom = "BOTTOMRIGHT",
				anchorOn = function() return addon.MainBag.object end,
				anchorTo = "BOTTOMLEFT",
				anchorX = -10,
				anchorY = 0,
			},
			isKeyRing = true,
			},{-- 2
			caption = "Gear",
			options = {
				columns	= 8,
				scale		= 0.75,
				backdrop	= {0,180/255,1},
				searchbar = true,
			},
			filters = {onlyBags,filterGear, hideEmpty},
			position = {
				anchorFrom = "TOPRIGHT",
				anchorOn = function() return addon.MainBag.object end,
				anchorTo = "BOTTOMRIGHT",
				anchorX = 0,
				anchorY = -10,
			},
			isBackPack = true,
		},	{ -- 3
			caption = "Toys",
			options = {
				columns	= 8,
				scale		= 0.75,
				backdrop	= {0,180/255,1},
				searchbar = true,
			},
			filters = {onlyBags,onlyToys, hideEmpty},
			position = {
				anchorFrom = "TOPRIGHT",
				anchorOn =function() return addon.namedIndex['gear'].object end,
				anchorTo = "BOTTOMRIGHT",
				anchorX = 0,
				anchorY = -10,
			},
			isBackPack = true,
		},	{ -- 4
			caption = "Enchanting",
			options = {
				columns	= 8,
				scale		= 0.75,
				backdrop	= {0,180/255,1},
				searchbar = true,
			},
			filters = {onlyBags,onlyEnchanting, hideEmpty},
			position = {
				anchorFrom = "TOPRIGHT",
				anchorOn =function() return addon.namedIndex['jewelcrafting'].object end,
				anchorTo = "BOTTOMRIGHT",
				anchorX = 0,
				anchorY = -10,
			},
			isBackPack = true,
		},	{ -- 5
			caption = "JewelCrafting",
			options = {
				columns	= 8,
				scale		= 0.75,
				backdrop	= {0,180/255,1},
				searchbar = true,
			},
			filters = {onlyBags,onlyJewelcrafting, hideEmpty},
			position = {
				anchorFrom = "TOPRIGHT",
				anchorOn =function() return addon.namedIndex['trade goods'].object end,
				anchorTo = "BOTTOMRIGHT",
				anchorX = 0,
				anchorY = -10,
			},
			isBackPack = true,
		},	{ -- 6
			caption = "Trade Goods",
			options = {
				columns	= 8,
				scale		= 0.75,
				backdrop	= {0,180/255,1},
				searchbar = true,
			},
			filters = {onlyBags,onlyTradeGoods, hideEmpty},
			position = {
				anchorFrom = "TOPRIGHT",
				anchorOn = function() return addon.MainBag.object end,
				anchorTo = "TOPLEFT",
				anchorX = -10,
				anchorY = 0,
			},
			isBackPack = true,
		},	{ -- 7
			caption = "Quest Items",
			options = {
				columns	= 8,
				scale		= 0.75,
				backdrop	= {0,180/255,1},
				searchbar = true,
			},
			filters = {onlyBags,onlyQuest, hideEmpty},
			position = {
				anchorFrom = "TOPRIGHT",
				anchorOn =function() return addon.namedIndex['toys'].object end,
				anchorTo = "BOTTOMRIGHT",
				anchorX = 0,
				anchorY = -10,
			},
			isBackPack = true,
		},{-- 8
			caption = "Drugs",
			options = {
				columns	= 8,
				scale		= 0.75,
				backdrop	= {0,180/255,1},
				searchbar = true,
			},
			filters = {onlyBags,onlyDrugs, hideEmpty},
			position = {
				anchorFrom = "BOTTOMRIGHT",
				anchorOn =function() return addon.namedIndex['consumables'].object end,
				anchorTo = "TOPRIGHT",
				anchorX = 0,
				anchorY = 10,
			},
			isBackPack = true,
			customAnchor = true,
		},	{-- 9
			caption = "Consumables",
			options = {
				columns	= 8,
				scale		= 0.75,
				backdrop	= {0,180/255,1},
				searchbar = true,
			},
			filters = {onlyBags,onlyConsumables,hideEmpty},
			position = {
				anchorFrom = "BOTTOMRIGHT",
				anchorOn =function() return addon.namedIndex['main bag'].object end,
				anchorTo = "TOPRIGHT",
				anchorX = 0,
				anchorY = 10,
			},
			isBackPack = true,
		--]]
		},	{ -- 10
			caption = "Main Bag",
			options = {
				columns		= 8,
				scale		= 0.75,
				backdrop	= {0,180/255,1},
				buttons		= {
					x = 0,
					y = -1,
				},
				searchbar = true,
			},
			filters = {onlyBags},
			position = {
				anchorFrom = "RIGHT",
				anchorOn = nil,
				anchorTo = "RIGHT",
				anchorX = -30,
				anchorY = 0,
			},
			ChildAnchorPoints = {
				"LEFT",
				"TOP",
				"BOTTOM",
			},
			isBackPack = true,
			isMainBag = true,
			customAnchor = true,
		},	{
			caption = "Bank",
			options = {
				columns		= 12,
				scale		= 0.75,
				backdrop 	= {0,0,0},
				buttons 	= {
					x = 0,
					y = -1,
				},
				searchbar = true,
			},
			filters = {onlyBank},
			position = {
				anchorFrom = "TOPLEFT",
				anchorOn = nil,
				anchorTo = "TOPLEFT",
				anchorX = 15,
				anchorY = -35,
			},
			ChildAnchorPoints = {
				"RIGHT"
			},
			isBank = true,
			customAnchor = true,
		},
	}

	self.namedIndex = {}
	self.numericIndex = {}
	self.HiddenBags = {}
	local record
	for index,bag in ipairs(self.db.bags)do
		addon:CreateBag(index,bag)		
	end
	
	local anchorObject
	for index,bag in ipairs(self.db.bags)do		
		addon:AnchorBag(bag)
	end

	-- To toggle containers when entering / leaving a bank
	local bankToggle = CreateFrame"Frame"
			bankToggle:RegisterEvent"BANKFRAME_OPENED"
			bankToggle:RegisterEvent"BANKFRAME_CLOSED"
			bankToggle:SetScript("OnEvent", function(self, event)
				if(event == "BANKFRAME_OPENED") then
					addon.Bank.object:Show()
				else
					addon.Bank.object:Hide()
				end
			end)
			-- Close real bank frame when our bank frame is hidden
			self.Bank.object:SetScript("OnHide", CloseBankFrame)
			-- Hide the original bank frame
			BankFrame:UnregisterAllEvents()

	-- Blizzard Replacement Functions
	ToggleBackpack = ToggleCargBags
	ToggleBag = function() ToggleCargBags() end
	OpenAllBags = ToggleBag
	CloseAllBags = CloseCargBags
	OpenBackpack = OpenCargBags
	CloseBackpack = CloseCargBags

	-- Set Anywhere as the default handler if it exists
	if(cargBags.Handler["Anywhere"]) then
		cargBags:SetActiveHandler("Anywhere")
	end

end

function addon:Print(msg,type)
	local colour 
	print("|c"..(type~=nil and (type=="error" and "FFFF6600") or (type=="debug" and "FF66FF66") or "FF00FF00") ..layoutName.." : |r"..msg)
end

function addon:Debug(...)
	if(self.EnableDebugMessages) then
		local msg = {}
		for index,var in pairs({...})do
			table.insert(msg,tostring(index) .." : ".. tostring(var) )
		end
		self:Print(table.concat(msg,","))
	end
end

function addon:ProcessMacroConditional(conditional)
	local nomod,condition, validated = nil,nil

	for index,arg in pairs(Split(conditional,","))do
		condition = Split(arg,":")
		if(validated == nil and condition[1]:gmatch("mod")())then
			noMod = (condition[1]=="nomod")
			if 	condition[2] == "ctrl" then
				validated = noMod and not IsControlKeyDown() or IsControlKeyDown()
			elseif 	condition[2] == "alt" then
				validated = noMod and not IsAltKeyDown() or IsAltKeyDown()
			elseif 	condition[2] == "shift" then
				validated = noMod and not IsShiftKeyDown() or IsShiftKeyDown()
			else
				validated = noMod and (not IsShiftKeyDown() and not IsAltKeyDown() and not IsControlKeyDown())
			end
		end
	end
	return validated
end

addon:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
addon:RegisterEvent"VARIABLES_LOADED"
addon:RegisterEvent"ADDON_LOADED"
addon:RegisterEvent"EQUIPMENT_SETS_CHANGED"

SLASH_CARGBAGSSMEE1 = "/cargbags";
SlashCmdList["CARGBAGSSMEE"] = function(cmd)
	if cmd == "" or not cmd then return end
	local tokens = {}
	local bag
	for token in cmd:gmatch("%S+") do table.insert(tokens, token) end

	local conditional = tokens[1]:gmatch("[[](.*)[]]")()
	if conditional then 
		local validated = addon:ProcessMacroConditional(conditional)
		table.remove(tokens, 1)
		if(not validated)then
			return
		end
	end

	({
		["toggle"] = function(args)
			-- toggle a bag from the layout.db
			bag = addon:FindBag(table.concat(args , " " , 2 ))
			if(bag and bag.object)then
				addon:ToggleBag(bag.object)
			end			

		end,
		["create"] = function(args)
			local filters = args[3]
			
			local bag = {
				caption =  args[2],
				options = {
					columns		= 12,
					scale			= 0.75,
					backdrop 	= {0,0,0},
					buttons 		= {
						x = 0,
						y = -1,
					},
					searchbar = true,
				},
				filters = {onlyBank},
				position = {
					anchorFrom 	= args[4] or "CENTER",
					anchorOn 		= nil,
					anchorTo 		= args[5] or "CENTER",
					anchorX 			= args[6] or 0,
					anchorY 			= -args[7] or 0,
				}
			}
			
			addon:CreateBag(#addon.numericIndex,bag)		
			addon:AnchorBag(bag)			
			
		end,
		["list"] = function(args)
			for index,data in pairs(addon.numericIndex)do
				addon:Print(index.." : "..data.name);
			end
		end,
		["find"] = function(args)
			bag = addon:FindBag(table.concat(args , " " , 2 ))
			addon:Print( bag and bag.name or "Not Found" )
		end,
		["debug"] = function(args)
			addon.EnableDebugMessages = not addon.EnableDebugMessages
			addon:Print( "Debug ".. (addon.EnableDebugMessages and "En" or "Dis").."abled")
		end,		
	})[tokens[1]](tokens)
end
