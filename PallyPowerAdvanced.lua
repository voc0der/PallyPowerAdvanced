local addonName = ...

local PPA = _G.PallyPowerAdvanced or {}
_G.PallyPowerAdvanced = PPA
PPA.peerSpecs = PPA.peerSpecs or {}

local Unpack = unpack or table.unpack

local BUFF_WISDOM = 1
local BUFF_MIGHT = 2
local BUFF_KINGS = 3
local BUFF_SALVATION = 4
local BUFF_LIGHT = 5
local BUFF_SANCTUARY = 6

local AURA_DEVOTION = 1
local AURA_RETRIBUTION = 2
local AURA_CONCENTRATION = 3
local AURA_SANCTITY = 7

local BUFF_WARNING_SECONDS = 60
local BUFF_WARNING_SCAN_INTERVAL = 10
local BUFF_WARNING_SOUND_COOLDOWN = 30
local BUFF_WARNING_RESTORE_DELAY = 2
local BUFF_WARNING_SOUND_CHANNEL = "Master"
local BUFF_WARNING_SOUNDKIT = "UI_PROFESSIONS_NEW_RECIPE_LEARNED_TOAST"
local BUFF_WARNING_SOUNDKIT_FALLBACK = "IG_MAINMENU_OPTION_CHECKBOX_ON"
local ASSIGNMENT_CONFLICT_WINDOW_SECONDS = 5
local ASSIGNMENT_CONFLICT_BURST_SECONDS = 1

local PPA_SPEC_PREFIX = "PPA"
local PPA_SPEC_VERSION = 2

local SIMULATION_ROSTER_SIZE = 25
local SIMULATION_LOCAL_PALADIN = "PpaSimHoly"

local ROLE_TANK = "TANK"
local ROLE_HEALER = "HEALER"
local ROLE_DAMAGER = "DAMAGER"
local ROLE_NONE = "NONE"

local CLASS_ID = {
	WARRIOR = 1,
	ROGUE = 2,
	PRIEST = 3,
	DRUID = 4,
	PALADIN = 5,
	HUNTER = 6,
	MAGE = 7,
	WARLOCK = 8,
	SHAMAN = 9,
}

local CLASS_FILES_BY_ID = {
	[1] = "WARRIOR",
	[2] = "ROGUE",
	[3] = "PRIEST",
	[4] = "DRUID",
	[5] = "PALADIN",
	[6] = "HUNTER",
	[7] = "MAGE",
	[8] = "WARLOCK",
	[9] = "SHAMAN",
}

local CLASS_NAMES = {
	[1] = "Warrior",
	[2] = "Rogue",
	[3] = "Priest",
	[4] = "Druid",
	[5] = "Paladin",
	[6] = "Hunter",
	[7] = "Mage",
	[8] = "Warlock",
	[9] = "Shaman",
}

local CLASS_PLURAL_NAMES = {
	[1] = "Warriors",
	[2] = "Rogues",
	[3] = "Priests",
	[4] = "Druids",
	[5] = "Paladins",
	[6] = "Hunters",
	[7] = "Mages",
	[8] = "Warlocks",
	[9] = "Shamans",
}

local BUFF_NAMES = {
	[BUFF_WISDOM] = "Wisdom",
	[BUFF_MIGHT] = "Might",
	[BUFF_KINGS] = "Kings",
	[BUFF_SALVATION] = "Salvation",
	[BUFF_LIGHT] = "Light",
	[BUFF_SANCTUARY] = "Sanctuary",
}

local LONG_BUFF_NAMES = {
	[BUFF_WISDOM] = "Blessing of Wisdom",
	[BUFF_MIGHT] = "Blessing of Might",
	[BUFF_KINGS] = "Blessing of Kings",
	[BUFF_SALVATION] = "Blessing of Salvation",
	[BUFF_LIGHT] = "Blessing of Light",
	[BUFF_SANCTUARY] = "Blessing of Sanctuary",
}

local AURA_NAMES = {
	[AURA_DEVOTION] = "Devotion Aura",
	[AURA_RETRIBUTION] = "Retribution Aura",
	[AURA_CONCENTRATION] = "Concentration Aura",
	[AURA_SANCTITY] = "Sanctity Aura",
}

local ROLE_LABELS = {
	TANK = "Tank",
	HEALER = "Healer",
	DAMAGER = "DPS",
	NONE = "Unassigned",
}

local DEFAULT_CLASS_ORDER = {
	CLASS_ID.WARRIOR,
	CLASS_ID.ROGUE,
	CLASS_ID.PRIEST,
	CLASS_ID.DRUID,
	CLASS_ID.PALADIN,
	CLASS_ID.HUNTER,
	CLASS_ID.MAGE,
	CLASS_ID.WARLOCK,
	CLASS_ID.SHAMAN,
}

local TRACKED_AURAS = {
	AURA_DEVOTION,
	AURA_RETRIBUTION,
	AURA_CONCENTRATION,
	AURA_SANCTITY,
}

local TRACKED_AURA_SET = {}
for _, aura in ipairs(TRACKED_AURAS) do
	TRACKED_AURA_SET[aura] = true
end

local GENERAL_TIE_ORDER = {
	[BUFF_KINGS] = 1,
	[BUFF_SALVATION] = 2,
	[BUFF_WISDOM] = 3,
	[BUFF_MIGHT] = 4,
	[BUFF_SANCTUARY] = 5,
	[BUFF_LIGHT] = 6,
}

local PVP_REMOVED_BLESSINGS = {
	[BUFF_SALVATION] = true,
}

local PVP_LOW_PRIORITY_BLESSINGS = {
	[BUFF_SANCTUARY] = true,
}

local MANUAL_CHOICES = {
	WARRIOR = {
		{label = "Damage", role = ROLE_DAMAGER},
		{label = "Tank", role = ROLE_TANK},
	},
	PRIEST = {
		{label = "Healing", role = ROLE_HEALER},
		{label = "Shadow", role = ROLE_DAMAGER, spec = "SHADOW"},
	},
	DRUID = {
		{label = "Feral DPS", role = ROLE_DAMAGER, spec = "FERAL"},
		{label = "Balance", role = ROLE_DAMAGER, spec = "BALANCE"},
		{label = "Tank", role = ROLE_TANK, spec = "FERAL_TANK"},
		{label = "Healing", role = ROLE_HEALER, spec = "RESTORATION"},
	},
	SHAMAN = {
		{label = "Enhancement", role = ROLE_DAMAGER, spec = "ENHANCEMENT"},
		{label = "Elemental", role = ROLE_DAMAGER, spec = "ELEMENTAL"},
		{label = "Healing", role = ROLE_HEALER, spec = "RESTORATION"},
	},
	PALADIN = {
		{label = "DPS", role = ROLE_DAMAGER},
		{label = "Healer", role = ROLE_HEALER},
		{label = "Tank", role = ROLE_TANK},
	},
}

local ASSUMED_MISSING_CLASS_UNITS = {
	[CLASS_ID.WARRIOR] = {role = ROLE_DAMAGER},
	[CLASS_ID.ROGUE] = {role = ROLE_DAMAGER},
	[CLASS_ID.PRIEST] = {role = ROLE_DAMAGER},
	[CLASS_ID.DRUID] = {role = ROLE_DAMAGER, spec = "FERAL"},
	[CLASS_ID.PALADIN] = {role = ROLE_DAMAGER},
	[CLASS_ID.HUNTER] = {role = ROLE_DAMAGER},
	[CLASS_ID.MAGE] = {role = ROLE_DAMAGER},
	[CLASS_ID.WARLOCK] = {role = ROLE_DAMAGER},
	[CLASS_ID.SHAMAN] = {role = ROLE_DAMAGER, spec = "ENHANCEMENT"},
}

local function AddUnique(list, value)
	if not value then
		return
	end
	for _, existing in ipairs(list) do
		if existing == value then
			return
		end
	end
	list[#list + 1] = value
end

local function DeepCopy(value, seen)
	if type(value) ~= "table" then
		return value
	end
	seen = seen or {}
	if seen[value] then
		return seen[value]
	end
	local copy = {}
	seen[value] = copy
	for key, item in pairs(value) do
		copy[DeepCopy(key, seen)] = DeepCopy(item, seen)
	end
	return copy
end

local function BuildPriority(includeLight, ...)
	local list = {}
	local count = select("#", ...)
	for index = 1, count do
		local value = select(index, ...)
		if value ~= BUFF_LIGHT or includeLight then
			AddUnique(list, value)
		end
	end
	return list
end

local function SafeNumber(value, fallback)
	value = tonumber(value)
	if value == nil then
		return fallback or 0
	end
	return value
end

local function NormalizeRole(role)
	if role == "MAINTANK" then
		return ROLE_TANK
	end
	if role == "MAINASSIST" then
		return ROLE_DAMAGER
	end
	if role == ROLE_TANK or role == ROLE_HEALER or role == ROLE_DAMAGER then
		return role
	end
	return ROLE_NONE
end

local function RoleText(role)
	return ROLE_LABELS[NormalizeRole(role)] or ROLE_LABELS.NONE
end

local function BuffText(buff)
	return BUFF_NAMES[buff] or ("Unknown(" .. tostring(buff) .. ")")
end

local function LongBuffText(buff)
	return LONG_BUFF_NAMES[buff] or BuffText(buff)
end

local function ReportBuffText(buff)
	local spell = _G.PallyPower and _G.PallyPower.Spells and _G.PallyPower.Spells[buff]
	if spell and spell ~= "" then
		return spell
	end
	return LongBuffText(buff)
end

local function AuraText(aura)
	return AURA_NAMES[aura] or ("Aura " .. tostring(aura))
end

local function ClassText(classID)
	return CLASS_NAMES[classID] or ("Class " .. tostring(classID))
end

local function ClassPluralText(classID)
	return CLASS_PLURAL_NAMES[classID] or (ClassText(classID) .. "s")
end

local function JoinList(list)
	return table.concat(list or {}, ", ")
end

local function IsLiveClient()
	return type(_G.CreateFrame) == "function" and _G.UIParent ~= nil
end

local function PaladinHasImprovedWisdom(paladin)
	if type(paladin) ~= "table" or type(paladin.skills) ~= "table" then
		return false
	end
	local wisdom = paladin.skills[BUFF_WISDOM]
	return type(wisdom) == "table" and SafeNumber(wisdom.talent, 0) > 0
end

local function PaladinHasImprovedMight(paladin)
	if type(paladin) ~= "table" or type(paladin.skills) ~= "table" then
		return false
	end
	local might = paladin.skills[BUFF_MIGHT]
	return type(might) == "table" and SafeNumber(might.talent, 0) > 0
end

local function ContextHasImprovedWisdom(context)
	if type(context) ~= "table" then
		return false
	end
	if context.improvedWisdomPaladinPresent ~= nil then
		return context.improvedWisdomPaladinPresent == true
	end
	for _, paladin in ipairs(context.paladins or {}) do
		if PaladinHasImprovedWisdom(paladin) then
			return true
		end
	end
	return false
end

local function ContextAlwaysPreferWisdomOnHealers(context)
	if type(context) == "table" and context.alwaysPreferWisdomOnHealers ~= nil then
		return context.alwaysPreferWisdomOnHealers == true
	end
	local db = _G.PallyPowerAdvancedDB
	if type(db) == "table" and db.alwaysPreferWisdomOnHealers ~= nil then
		return db.alwaysPreferWisdomOnHealers == true
	end
	local legacyOpt = _G.PallyPower and _G.PallyPower.opt
	return type(legacyOpt) == "table" and legacyOpt.AlwaysPreferWisdomOnHealers == true
end

local function ContextAlwaysPreferWisdomOnPaladinTanks(context)
	if type(context) == "table" and context.alwaysPreferWisdomOnPaladinTanks ~= nil then
		return context.alwaysPreferWisdomOnPaladinTanks == true
	end
	local db = _G.PallyPowerAdvancedDB
	if type(db) == "table" and db.alwaysPreferWisdomOnPaladinTanks ~= nil then
		return db.alwaysPreferWisdomOnPaladinTanks == true
	end
	local legacyOpt = _G.PallyPower and _G.PallyPower.opt
	return type(legacyOpt) == "table" and legacyOpt.AlwaysPreferWisdomOnPaladinTanks == true
end

local function UnitNamesMatch(left, right)
	if not left or not right then
		return false
	end
	if left == right then
		return true
	end
	return string.match(left, "^([^-]+)") == string.match(right, "^([^-]+)")
end

local function FindContextPaladin(context, name)
	for _, paladin in ipairs(context and context.paladins or {}) do
		if UnitNamesMatch(paladin.name, name) or UnitNamesMatch(paladin.fullName, name) then
			return paladin
		end
	end
	return nil
end

local function Print(message)
	if _G.DEFAULT_CHAT_FRAME and _G.DEFAULT_CHAT_FRAME.AddMessage then
		_G.DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99PPA|r: " .. tostring(message))
	elseif _G.print then
		_G.print("PPA: " .. tostring(message))
	end
end

local function Now()
	return (_G.GetTime and _G.GetTime()) or (_G.time and _G.time()) or 0
end

local function JoinBuffs(list)
	local names = {}
	for _, buff in ipairs(list or {}) do
		names[#names + 1] = BuffText(buff)
	end
	return table.concat(names, " > ")
end

function PPA:EnsureDB()
	if type(_G.PallyPowerAdvancedDB) ~= "table" then
		_G.PallyPowerAdvancedDB = {}
	end
	local db = _G.PallyPowerAdvancedDB
	if type(db.specs) ~= "table" then
		db.specs = {}
	end
	if db.debug == nil then
		db.debug = false
	end
	if db.assignmentTrace == nil then
		db.assignmentTrace = false
	end
	if db.buffWarningSound == nil then
		db.buffWarningSound = true
	end
	if db.advancedOptionsMigrated ~= true then
		local legacyOpt = _G.PallyPower and _G.PallyPower.opt
		if type(legacyOpt) == "table" then
			if legacyOpt.AlwaysPreferWisdomOnHealers ~= nil then
				db.alwaysPreferWisdomOnHealers = legacyOpt.AlwaysPreferWisdomOnHealers == true
			end
			if legacyOpt.AlwaysPreferWisdomOnPaladinTanks ~= nil then
				db.alwaysPreferWisdomOnPaladinTanks = legacyOpt.AlwaysPreferWisdomOnPaladinTanks == true
			end
			db.advancedOptionsMigrated = true
		end
	end
	if db.alwaysPreferWisdomOnHealers == nil then
		db.alwaysPreferWisdomOnHealers = false
	end
	if db.alwaysPreferWisdomOnPaladinTanks == nil then
		db.alwaysPreferWisdomOnPaladinTanks = false
	end
	self.db = db
	return db
end

function PPA:IsDebugEnabled()
	local db = self:EnsureDB()
	return db.debug == true
end

function PPA:Debug(message)
	if self:IsDebugEnabled() then
		Print(message)
	end
end

function PPA:IsAssignmentTraceEnabled()
	local db = self:EnsureDB()
	return db.assignmentTrace == true
end

function PPA:GetManualChoice(unit)
	local db = self:EnsureDB()
	if not unit then
		return nil
	end
	return db.specs[unit.key] or db.specs[unit.name]
end

function PPA:SaveManualChoice(unit, choice)
	if not unit or not choice then
		return
	end
	local db = self:EnsureDB()
	db.specs[unit.key or unit.name] = {
		role = choice.role,
		spec = choice.spec,
		label = choice.label,
	}
end

function PPA:GetChoiceList(unit)
	if not unit then
		return nil
	end
	return MANUAL_CHOICES[unit.class]
end

function PPA:ApplyManualChoice(unit)
	local choice = self:GetManualChoice(unit)
	if type(choice) ~= "table" then
		if type(choice) == "string" then
			unit.spec = choice
		end
		return false
	end
	if choice.role then
		unit.role = NormalizeRole(choice.role)
	end
	if choice.spec then
		unit.spec = choice.spec
	end
	unit.manual = true
	return true
end

function PPA:ApplyGuess(unit)
	if not unit then
		return
	end
	local originalRole = NormalizeRole(unit.role)
	if unit.mainTank then
		unit.role = ROLE_TANK
	end

	if unit.class == "WARRIOR" then
		if originalRole == ROLE_NONE then
			unit.role = unit.mainTank and ROLE_TANK or ROLE_DAMAGER
			unit.guessed = true
		end
	elseif unit.class == "PRIEST" then
		if originalRole == ROLE_NONE then
			unit.role = ROLE_DAMAGER
			unit.guessed = true
		end
	elseif unit.class == "DRUID" then
		if originalRole == ROLE_NONE then
			unit.role = ROLE_DAMAGER
			unit.spec = "FERAL"
			unit.guessed = true
		elseif originalRole == ROLE_DAMAGER and not unit.spec then
			unit.spec = "FERAL"
			unit.guessed = true
		end
	elseif unit.class == "SHAMAN" then
		if originalRole == ROLE_NONE then
			unit.role = ROLE_DAMAGER
			unit.spec = "ENHANCEMENT"
			unit.guessed = true
		elseif originalRole == ROLE_DAMAGER and not unit.spec then
			unit.spec = "ENHANCEMENT"
			unit.guessed = true
		end
	elseif unit.class == "PALADIN" then
		if originalRole == ROLE_NONE then
			unit.role = ROLE_DAMAGER
			unit.guessed = true
		end
	elseif originalRole == ROLE_NONE then
		unit.role = ROLE_DAMAGER
	end
end

local function IsPvPInstanceType(instanceType)
	return instanceType == "pvp" or instanceType == "arena"
end

local function ContextIsPvP(context)
	return context and context.pvpInstance == true
end

local function FilterPriorityForContext(priority, context)
	if not ContextIsPvP(context) then
		return priority
	end

	local filtered = {}
	local lowPriority = {}
	for _, buff in ipairs(priority or {}) do
		if not PVP_REMOVED_BLESSINGS[buff] then
			if PVP_LOW_PRIORITY_BLESSINGS[buff] then
				AddUnique(lowPriority, buff)
			else
				AddUnique(filtered, buff)
			end
		end
	end
	for _, buff in ipairs(lowPriority) do
		AddUnique(filtered, buff)
	end
	return filtered
end

local function SelectedHasNonSanctuaryBlessing(selected)
	for _, assignment in ipairs(selected or {}) do
		if assignment.buff and assignment.buff ~= BUFF_SANCTUARY then
			return true
		end
	end
	return false
end

function PPA:UnitHasImprovedWisdom(unit, context)
	if PaladinHasImprovedWisdom(unit) then
		return true
	end
	local contextPaladin = FindContextPaladin(context, unit and (unit.name or unit.fullName))
	if PaladinHasImprovedWisdom(contextPaladin) then
		return true
	end
	local specData = unit and unit.name and self:GetUnitSpecData(unit.name)
	return type(specData) == "table" and SafeNumber(specData.impWisdom, 0) > 0
end

local function UnitIsKnownPet(unit)
	if type(unit) ~= "table" then
		return false
	end
	if unit.isPet == true then
		return true
	end
	local token = unit.unit or unit.unitid
	return type(token) == "string" and string.find(token, "pet") ~= nil
end

local function SpecDataHasProtectionTalents(specData)
	return type(specData) == "table"
		and (SafeNumber(specData.holyShield, 0) > 0 or SafeNumber(specData.impSanc, 0) > 0)
end

function PPA:GetBasePriorityForUnit(unit, context)
	local role = NormalizeRole(unit.role)
	local includeLight = context and context.healingPaladinPresent
	local improvedWisdom = ContextHasImprovedWisdom(context)
	local preferWisdomOnHealers = improvedWisdom or ContextAlwaysPreferWisdomOnHealers(context)
	local preferWisdomOnPaladinTanks = ContextAlwaysPreferWisdomOnPaladinTanks(context)
	local class = unit.class
	local spec = unit.spec

	if UnitIsKnownPet(unit) then
		return BuildPriority(includeLight, BUFF_MIGHT, BUFF_KINGS, BUFF_SALVATION, BUFF_LIGHT, BUFF_SANCTUARY)
	end

	if class == "WARRIOR" then
		if role == ROLE_TANK then
			return BuildPriority(includeLight, BUFF_KINGS, BUFF_SANCTUARY, BUFF_LIGHT, BUFF_MIGHT)
		end
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_MIGHT, BUFF_LIGHT, BUFF_SANCTUARY)
	elseif class == "ROGUE" then
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_MIGHT, BUFF_KINGS, BUFF_LIGHT, BUFF_SANCTUARY)
	elseif class == "PRIEST" then
		if role == ROLE_HEALER then
			if not preferWisdomOnHealers then
				return BuildPriority(includeLight, BUFF_KINGS, BUFF_WISDOM, BUFF_SALVATION, BUFF_LIGHT, BUFF_SANCTUARY)
			end
			return BuildPriority(includeLight, BUFF_WISDOM, BUFF_KINGS, BUFF_SALVATION, BUFF_LIGHT, BUFF_SANCTUARY)
		end
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_WISDOM, BUFF_LIGHT, BUFF_SANCTUARY)
	elseif class == "DRUID" then
		if role == ROLE_TANK then
			return BuildPriority(includeLight, BUFF_KINGS, BUFF_SANCTUARY, BUFF_LIGHT, BUFF_MIGHT, BUFF_WISDOM)
		elseif role == ROLE_HEALER then
			if not preferWisdomOnHealers then
				return BuildPriority(includeLight, BUFF_KINGS, BUFF_WISDOM, BUFF_SALVATION, BUFF_LIGHT, BUFF_SANCTUARY)
			end
			return BuildPriority(includeLight, BUFF_WISDOM, BUFF_KINGS, BUFF_SALVATION, BUFF_LIGHT, BUFF_SANCTUARY)
		elseif spec == "BALANCE" then
			return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_WISDOM, BUFF_LIGHT, BUFF_SANCTUARY)
		end
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_MIGHT, BUFF_LIGHT, BUFF_SANCTUARY)
	elseif class == "PALADIN" then
		local targetHasImprovedWisdom = self:UnitHasImprovedWisdom(unit, context)
		local specData = self:GetUnitSpecData(unit.name)
		if role == ROLE_TANK and preferWisdomOnPaladinTanks then
			if specData and (specData.sanctityAura or 0) > 0 then
				return BuildPriority(includeLight, BUFF_SANCTUARY, BUFF_WISDOM, BUFF_KINGS, BUFF_LIGHT, BUFF_MIGHT)
			end
			if specData then
				return BuildPriority(includeLight, BUFF_WISDOM, BUFF_KINGS, BUFF_SANCTUARY, BUFF_LIGHT, BUFF_MIGHT)
			end
			if (context and context.pallyCount or 0) > 2 then
				return BuildPriority(includeLight, BUFF_SANCTUARY, BUFF_WISDOM, BUFF_KINGS, BUFF_LIGHT, BUFF_MIGHT)
			end
			return BuildPriority(includeLight, BUFF_WISDOM, BUFF_KINGS, BUFF_SANCTUARY, BUFF_LIGHT, BUFF_MIGHT)
		end
		if role == ROLE_TANK
			and targetHasImprovedWisdom
			and specData
			and not SpecDataHasProtectionTalents(specData)
		then
			return BuildPriority(includeLight, BUFF_WISDOM, BUFF_KINGS, BUFF_SALVATION, BUFF_LIGHT, BUFF_SANCTUARY, BUFF_MIGHT)
		end
		if role == ROLE_TANK then
			if specData then
				if (specData.sanctityAura or 0) > 0 then
					if improvedWisdom or targetHasImprovedWisdom then
						return BuildPriority(includeLight, BUFF_SANCTUARY, BUFF_WISDOM, BUFF_LIGHT, BUFF_KINGS, BUFF_MIGHT)
					end
					return BuildPriority(includeLight, BUFF_SANCTUARY, BUFF_KINGS, BUFF_LIGHT, BUFF_WISDOM, BUFF_MIGHT)
				end
				return BuildPriority(includeLight, BUFF_KINGS, BUFF_SANCTUARY, BUFF_WISDOM, BUFF_LIGHT, BUFF_MIGHT)
			end
			if (context and context.pallyCount or 0) <= 2 then
				return BuildPriority(includeLight, BUFF_KINGS, BUFF_SANCTUARY, BUFF_WISDOM, BUFF_LIGHT, BUFF_MIGHT)
			end
			if improvedWisdom or targetHasImprovedWisdom then
				return BuildPriority(includeLight, BUFF_SANCTUARY, BUFF_WISDOM, BUFF_LIGHT, BUFF_KINGS, BUFF_MIGHT)
			end
			return BuildPriority(includeLight, BUFF_SANCTUARY, BUFF_KINGS, BUFF_LIGHT, BUFF_WISDOM, BUFF_MIGHT)
		elseif role == ROLE_HEALER or targetHasImprovedWisdom then
			if not (preferWisdomOnHealers or targetHasImprovedWisdom) then
				return BuildPriority(includeLight, BUFF_KINGS, BUFF_WISDOM, BUFF_SALVATION, BUFF_LIGHT, BUFF_SANCTUARY)
			end
			return BuildPriority(includeLight, BUFF_WISDOM, BUFF_KINGS, BUFF_SALVATION, BUFF_LIGHT, BUFF_SANCTUARY)
		end
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_MIGHT, BUFF_LIGHT, BUFF_SANCTUARY)
	elseif class == "HUNTER" then
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_MIGHT, BUFF_WISDOM, BUFF_LIGHT, BUFF_SANCTUARY)
	elseif class == "MAGE" or class == "WARLOCK" then
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_WISDOM, BUFF_LIGHT, BUFF_SANCTUARY)
	elseif class == "SHAMAN" then
		if role == ROLE_HEALER then
			if not preferWisdomOnHealers then
				return BuildPriority(includeLight, BUFF_KINGS, BUFF_WISDOM, BUFF_SALVATION, BUFF_LIGHT, BUFF_SANCTUARY)
			end
			return BuildPriority(includeLight, BUFF_WISDOM, BUFF_KINGS, BUFF_SALVATION, BUFF_LIGHT, BUFF_SANCTUARY)
		elseif spec == "ELEMENTAL" then
			return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_WISDOM, BUFF_LIGHT, BUFF_SANCTUARY)
		end
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_MIGHT, BUFF_LIGHT, BUFF_SANCTUARY)
	end

	return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_MIGHT, BUFF_LIGHT, BUFF_SANCTUARY)
end

function PPA:GetPriorityForUnit(unit, context)
	return FilterPriorityForContext(self:GetBasePriorityForUnit(unit, context), context)
end

local function PriorityIndex(priority, buff)
	for index, value in ipairs(priority or {}) do
		if value == buff then
			return index
		end
	end
	return nil
end

local function SkillForBuff(paladin, buff)
	if type(paladin.skills) ~= "table" then
		return nil
	end
	return paladin.skills[buff]
end

local function SkillRank(skill)
	if type(skill) == "table" then
		return SafeNumber(skill.rank, 0)
	end
	return skill == true and 1 or 0
end

local function SkillTalent(skill)
	if type(skill) == "table" then
		return SafeNumber(skill.talent, 0)
	end
	return 0
end

function PPA:GetPallyPowerBuffCapability(paladinName, buff)
	local pallyPower = _G.PallyPower
	if type(pallyPower) ~= "table" or type(pallyPower.CanBuff) ~= "function" then
		return nil
	end
	if type(_G.AllPallys) ~= "table" or type(_G.AllPallys[paladinName]) ~= "table" then
		return nil
	end
	local ok, canBuff = pcall(pallyPower.CanBuff, pallyPower, paladinName, buff)
	if ok then
		return canBuff == true
	end
	return nil
end

function PPA:InferPaladinRoleFromSkills(skills)
	if type(skills) ~= "table" then
		return nil
	end

	if SkillTalent(skills[BUFF_SANCTUARY]) > 0 then
		return ROLE_TANK
	end
	if SkillTalent(skills[BUFF_WISDOM]) > 0 then
		return ROLE_HEALER
	end
	return nil
end

function PPA:CanPaladinBuff(paladin, buff)
	if not paladin or buff == nil or buff <= 0 or buff > BUFF_SANCTUARY then
		return false
	end

	if paladin.hasAddon then
		local skill = SkillForBuff(paladin, buff)
		local pallyPowerCanBuff = self:GetPallyPowerBuffCapability(paladin.name, buff)
		if pallyPowerCanBuff ~= nil then
			if not pallyPowerCanBuff then
				return false
			end
			if buff == BUFF_SANCTUARY then
				return SkillRank(skill) > 0 and SkillTalent(skill) > 0
			end
			return SkillRank(skill) > 0
		end
		if buff == BUFF_SANCTUARY then
			return SkillRank(skill) > 0 and SkillTalent(skill) > 0
		end
		return SkillRank(skill) > 0
	end

	local role = NormalizeRole(paladin.role)
	if buff == BUFF_KINGS then
		return true
	elseif buff == BUFF_SANCTUARY then
		return role == ROLE_TANK
	elseif buff == BUFF_WISDOM or buff == BUFF_MIGHT or buff == BUFF_SALVATION or buff == BUFF_LIGHT then
		return true
	end
	return false
end

function PPA:ScorePaladinForBuff(paladin, buff)
	local score = 0
	local role = NormalizeRole(paladin.role)

	if paladin.hasAddon then
		local skill = SkillForBuff(paladin, buff)
		local rank = 1
		local talent = 0
		if type(skill) == "table" then
			rank = SafeNumber(skill.rank, 1)
			talent = SafeNumber(skill.talent, 0)
		end
		score = score + 25 + rank * 12 + talent * 8
	else
		score = score + 8
		if buff == BUFF_KINGS then
			score = score + ((role == ROLE_TANK or role == ROLE_HEALER) and 12 or 0)
		elseif buff == BUFF_SANCTUARY then
			score = score + (role == ROLE_TANK and 14 or -20)
		elseif buff == BUFF_SALVATION then
			score = score + (role == ROLE_DAMAGER and 12 or 0)
		elseif buff == BUFF_LIGHT then
			score = score + (role == ROLE_HEALER and 10 or 4)
		elseif buff == BUFF_WISDOM then
			score = score + (role == ROLE_HEALER and 8 or 0)
		elseif buff == BUFF_MIGHT then
			score = score + (role == ROLE_DAMAGER and 8 or 3)
		end
	end

	if buff == BUFF_WISDOM then
		score = score + (role == ROLE_HEALER and 18 or 0)
		score = score + (PaladinHasImprovedWisdom(paladin) and 12 or 0)
	elseif buff == BUFF_LIGHT then
		score = score + (role == ROLE_HEALER and 16 or 0)
	elseif buff == BUFF_SANCTUARY then
		score = score + (role == ROLE_TANK and 20 or 0)
	elseif buff == BUFF_MIGHT then
		score = score + (role == ROLE_DAMAGER and 10 or 0)
		score = score + (PaladinHasImprovedMight(paladin) and 12 or 0)
	elseif buff == BUFF_SALVATION then
		if not paladin.hasAddon then
			score = score + (role == ROLE_DAMAGER and 8 or 0)
		end
	elseif buff == BUFF_KINGS then
		score = score + ((role == ROLE_TANK or role == ROLE_HEALER) and 6 or 0)
	end

	return score
end

function PPA:ScorePaladinForClassBuff(context, paladin, buff, classID, members)
	local score = self:ScorePaladinForBuff(paladin, buff)
	if paladin.name == context.playerName and buff == BUFF_SANCTUARY and paladin.role == ROLE_TANK then
		score = score + 15
	end
	if classID == CLASS_ID.PALADIN and buff == BUFF_SANCTUARY then
		for _, unit in ipairs(members or {}) do
			if unit.name == paladin.name and NormalizeRole(unit.role) == ROLE_TANK then
				score = score + 25
			end
		end
	end
	return score
end

function PPA:SelectPaladinForBuff(context, buff, usedPaladins, classID, members)
	local bestPaladin
	local bestScore = -100000
	for _, paladin in ipairs(context.paladins or {}) do
		if not usedPaladins[paladin.name] and self:CanPaladinBuff(paladin, buff) then
			local score = self:ScorePaladinForClassBuff(context, paladin, buff, classID, members)
			if score > bestScore or (score == bestScore and paladin.name < (bestPaladin and bestPaladin.name or "\255")) then
				bestScore = score
				bestPaladin = paladin
			end
		end
	end
	return bestPaladin, bestScore
end

local function EnsureClassAssignment(assignments, paladinName)
	if not assignments[paladinName] then
		assignments[paladinName] = {}
	end
	return assignments[paladinName]
end

local function EnsureManualAssignment(plan, paladin)
	if not plan.manualAssignments[paladin.name] then
		plan.manualAssignments[paladin.name] = {greater = {}, normal = {}, role = paladin.role}
	end
	return plan.manualAssignments[paladin.name]
end

local function SetPlanAssignment(plan, paladin, classID, buff)
	if paladin.hasAddon then
		EnsureClassAssignment(plan.assignments, paladin.name)[classID] = buff
	else
		EnsureManualAssignment(plan, paladin).greater[classID] = buff
	end
end

local function SetPlanNormal(plan, paladin, classID, targetName, buff, replaced)
	if paladin.hasAddon then
		if not plan.normalAssignments[paladin.name] then
			plan.normalAssignments[paladin.name] = {}
		end
		if not plan.normalAssignments[paladin.name][classID] then
			plan.normalAssignments[paladin.name][classID] = {}
		end
		plan.normalAssignments[paladin.name][classID][targetName] = buff
	else
		local manual = EnsureManualAssignment(plan, paladin).normal
		manual[#manual + 1] = {
			classID = classID,
			targetName = targetName,
			buff = buff,
			replaced = replaced,
		}
	end
end

local function GroupPlayersByClass(players)
	local groups = {}
	for _, unit in ipairs(players or {}) do
		if unit.classID and unit.classID >= 1 and unit.classID <= 9 then
			if not groups[unit.classID] then
				groups[unit.classID] = {}
			end
			groups[unit.classID][#groups[unit.classID] + 1] = unit
		end
	end
	return groups
end

local CLASS_DISALLOWED_BUFFS = {
	[CLASS_ID.WARRIOR] = {
		[BUFF_WISDOM] = true,
	},
	[CLASS_ID.ROGUE] = {
		[BUFF_WISDOM] = true,
	},
	[CLASS_ID.PRIEST] = {
		[BUFF_MIGHT] = true,
	},
	[CLASS_ID.MAGE] = {
		[BUFF_MIGHT] = true,
	},
	[CLASS_ID.WARLOCK] = {
		[BUFF_MIGHT] = true,
	},
}

local function IsBuffAllowedForClass(classID, buff)
	local disallowed = CLASS_DISALLOWED_BUFFS[classID]
	return not (disallowed and disallowed[buff])
end

local function IsBuffAllowedForUnit(unit, buff)
	if UnitIsKnownPet(unit) and buff == BUFF_MIGHT then
		return true
	end
	return IsBuffAllowedForClass(unit and unit.classID, buff)
end

function PPA:CreateAssumedClassMember(classID)
	local classFile = CLASS_FILES_BY_ID[classID]
	if not classFile then
		return nil
	end

	local defaults = ASSUMED_MISSING_CLASS_UNITS[classID] or {role = ROLE_DAMAGER}
	return {
		name = "Assumed" .. ClassText(classID),
		class = classFile,
		classID = classID,
		role = defaults.role,
		spec = defaults.spec,
		assumed = true,
	}
end

function PPA:ScoreClassBuffs(members, context)
	local scores = {}
	for _, unit in ipairs(members) do
		local priority = self:GetPriorityForUnit(unit, context)
		unit.priority = priority
		for index, buff in ipairs(priority) do
			if IsBuffAllowedForUnit(unit, buff) then
				local points = (#priority - index + 1) * 10
				if index == 1 then
					points = points + 8
				end
				scores[buff] = (scores[buff] or 0) + points
			end
		end
	end
	return scores
end

local function SortedScoredBuffs(scores)
	local sorted = {}
	for buff, score in pairs(scores) do
		sorted[#sorted + 1] = {buff = buff, score = score}
	end
	table.sort(sorted, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		return (GENERAL_TIE_ORDER[a.buff] or 99) < (GENERAL_TIE_ORDER[b.buff] or 99)
	end)
	return sorted
end

local function ClassAssignmentSignature(selected)
	local pieces = {}
	for _, assignment in ipairs(selected or {}) do
		pieces[#pieces + 1] = tostring(assignment.buff) .. ":" .. tostring(assignment.paladin and assignment.paladin.name or "")
	end
	table.sort(pieces)
	return table.concat(pieces, "|")
end

function PPA:OptimizeClassAssignments(context, classID, members, scoredBuffs, maxAssignments)
	local bestCount = -1
	local bestClassScore = -1
	local bestPaladinScore = -1
	local bestSelected = {}
	local bestSignature = nil
	local paladins = context.paladins or {}

	local function classValue(scored)
		return scored.score * 100 + (100 - (GENERAL_TIE_ORDER[scored.buff] or 99))
	end

	local function consider(selected, totalClassScore, totalPaladinScore)
		local signature = ClassAssignmentSignature(selected)
		if #selected > bestCount
			or (#selected == bestCount and totalClassScore > bestClassScore)
			or (#selected == bestCount and totalClassScore == bestClassScore and totalPaladinScore > bestPaladinScore)
			or (
				#selected == bestCount
				and totalClassScore == bestClassScore
				and totalPaladinScore == bestPaladinScore
				and (not bestSignature or signature < bestSignature)
			)
		then
			bestCount = #selected
			bestClassScore = totalClassScore
			bestPaladinScore = totalPaladinScore
			bestSignature = signature
			bestSelected = {}
			for index, assignment in ipairs(selected) do
				bestSelected[index] = {
					buff = assignment.buff,
					score = assignment.score,
					paladin = assignment.paladin,
					paladinScore = assignment.paladinScore,
				}
			end
		end
	end

	local function search(index, usedPaladins, selected, totalClassScore, totalPaladinScore)
		if index > #scoredBuffs or #selected >= maxAssignments then
			consider(selected, totalClassScore, totalPaladinScore)
			return
		end

		local scored = scoredBuffs[index]
		if scored.score <= 0 then
			search(index + 1, usedPaladins, selected, totalClassScore, totalPaladinScore)
			return
		end

		search(index + 1, usedPaladins, selected, totalClassScore, totalPaladinScore)

		for _, paladin in ipairs(paladins) do
			if not usedPaladins[paladin.name] and self:CanPaladinBuff(paladin, scored.buff) then
				local paladinScore = self:ScorePaladinForClassBuff(context, paladin, scored.buff, classID, members)
				usedPaladins[paladin.name] = true
				selected[#selected + 1] = {
					buff = scored.buff,
					score = scored.score,
					paladin = paladin,
					paladinScore = paladinScore,
				}
				search(index + 1, usedPaladins, selected, totalClassScore + classValue(scored), totalPaladinScore + paladinScore)
				selected[#selected] = nil
				usedPaladins[paladin.name] = nil
			end
		end
	end

	search(1, {}, {}, 0, 0)
	return bestSelected
end

function PPA:SelectClassAssignments(context, classID, members, plan)
	local scores = self:ScoreClassBuffs(members, context)
	if classID == CLASS_ID.PALADIN and (context and context.pallyCount or 0) <= 2 then
		local hasTank, hasHealer = false, false
		for _, unit in ipairs(members or {}) do
			local role = NormalizeRole(unit.role)
			if role == ROLE_TANK then
				hasTank = true
			elseif role == ROLE_HEALER then
				hasHealer = true
			end
		end
		if hasTank and hasHealer then
			scores[BUFF_WISDOM] = (scores[BUFF_WISDOM] or 0) + 25
		end
	end
	local scoredBuffs = SortedScoredBuffs(scores)
	local maxAssignments = math.min(#(context.paladins or {}), BUFF_SANCTUARY)
	local selected = self:OptimizeClassAssignments(context, classID, members, scoredBuffs, maxAssignments)

	table.sort(selected, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		return (GENERAL_TIE_ORDER[a.buff] or 99) < (GENERAL_TIE_ORDER[b.buff] or 99)
	end)
	for _, assignment in ipairs(selected) do
		SetPlanAssignment(plan, assignment.paladin, classID, assignment.buff)
	end

	return selected, scoredBuffs
end

local function BuildPaladinLookup(context)
	local lookup = {}
	for _, paladin in ipairs(context and context.paladins or {}) do
		lookup[paladin.name] = paladin
	end
	return lookup
end

local function CountAssignmentBuffs(classMap)
	local counts = {}
	local total = 0
	local distinct = 0
	for _, buff in pairs(classMap or {}) do
		if buff and buff > 0 then
			total = total + 1
			if not counts[buff] then
				distinct = distinct + 1
				counts[buff] = 0
			end
			counts[buff] = counts[buff] + 1
		end
	end
	return counts, total, distinct
end

local function SortedAssignmentBuffCounts(counts)
	local sorted = {}
	for buff, count in pairs(counts or {}) do
		sorted[#sorted + 1] = {buff = buff, count = count}
	end
	table.sort(sorted, function(a, b)
		if a.count ~= b.count then
			return a.count > b.count
		end
		return (GENERAL_TIE_ORDER[a.buff] or 99) < (GENERAL_TIE_ORDER[b.buff] or 99)
	end)
	return sorted
end

local function AssignmentSimplicityScore(assignments, context)
	local score = {
		singleBuffPaladins = 0,
		totalDistinctBuffs = 0,
		maxDistinctBuffs = 0,
	}

	for _, paladin in ipairs(context and context.paladins or {}) do
		local _, total, distinct = CountAssignmentBuffs(assignments and assignments[paladin.name])
		if total > 0 then
			if distinct == 1 then
				score.singleBuffPaladins = score.singleBuffPaladins + 1
			end
			score.totalDistinctBuffs = score.totalDistinctBuffs + distinct
			if distinct > score.maxDistinctBuffs then
				score.maxDistinctBuffs = distinct
			end
		end
	end

	return score
end

local function SimplicityScoreIsBetter(candidate, current)
	if candidate.singleBuffPaladins ~= current.singleBuffPaladins then
		return candidate.singleBuffPaladins > current.singleBuffPaladins
	end
	if candidate.totalDistinctBuffs ~= current.totalDistinctBuffs then
		return candidate.totalDistinctBuffs < current.totalDistinctBuffs
	end
	if candidate.maxDistinctBuffs ~= current.maxDistinctBuffs then
		return candidate.maxDistinctBuffs < current.maxDistinctBuffs
	end
	return false
end

local function PaladinBuffQuality(paladin, buff)
	local skill = SkillForBuff(paladin, buff)
	return SkillTalent(skill), SkillRank(skill)
end

local function CanTakeBuffWithoutDowngrade(candidate, source, buff)
	if not candidate or not source or not candidate.hasAddon or not source.hasAddon then
		return false
	end

	local candidateTalent, candidateRank = PaladinBuffQuality(candidate, buff)
	local sourceTalent, sourceRank = PaladinBuffQuality(source, buff)
	return candidateTalent >= sourceTalent and candidateRank >= sourceRank
end

local function FindAssignedPaladinForClassBuff(context, assignments, classID, buff, excludedName)
	for _, paladin in ipairs(context and context.paladins or {}) do
		local name = paladin.name
		local classMap = assignments and assignments[name]
		if name ~= excludedName and classMap and classMap[classID] == buff then
			return name
		end
	end
	return nil
end

local function CopyAssignmentsWithSwaps(assignments, swaps)
	local copy = DeepCopy(assignments) or {}
	for _, swap in ipairs(swaps or {}) do
		if copy[swap.paladinName] and copy[swap.otherName] then
			copy[swap.paladinName][swap.classID] = swap.targetBuff
			copy[swap.otherName][swap.classID] = swap.currentBuff
		end
	end
	return copy
end

local function SimplificationCandidateIsBetter(candidate, best)
	if not best then
		return true
	end
	if candidate.score.singleBuffPaladins ~= best.score.singleBuffPaladins then
		return candidate.score.singleBuffPaladins > best.score.singleBuffPaladins
	end
	if candidate.targetCount ~= best.targetCount then
		return candidate.targetCount > best.targetCount
	end
	if SimplicityScoreIsBetter(candidate.score, best.score) then
		return true
	end
	if SimplicityScoreIsBetter(best.score, candidate.score) then
		return false
	end
	if candidate.currentCount ~= best.currentCount then
		return candidate.currentCount < best.currentCount
	end
	if #candidate.swaps ~= #best.swaps then
		return #candidate.swaps > #best.swaps
	end
	return false
end

function PPA:BuildGreaterAssignmentSimplificationSwaps(context, plan, paladinLookup, paladinName, targetBuff, currentBuff)
	local swaps = {}
	local classMap = plan.assignments and plan.assignments[paladinName]
	local paladin = paladinLookup and paladinLookup[paladinName]
	if not classMap or not paladin then
		return nil
	end

	for classID, assignedBuff in pairs(classMap) do
		if assignedBuff == currentBuff then
			local otherName = FindAssignedPaladinForClassBuff(context, plan.assignments, classID, targetBuff, paladinName)
			local otherPaladin = paladinLookup and paladinLookup[otherName]
			if not otherName or not otherPaladin then
				return nil
			end
			if not self:CanPaladinBuff(paladin, targetBuff) or not self:CanPaladinBuff(otherPaladin, currentBuff) then
				return nil
			end
			if not CanTakeBuffWithoutDowngrade(paladin, otherPaladin, targetBuff) then
				return nil
			end
			if not CanTakeBuffWithoutDowngrade(otherPaladin, paladin, currentBuff) then
				return nil
			end
			swaps[#swaps + 1] = {
				classID = classID,
				paladinName = paladinName,
				otherName = otherName,
				targetBuff = targetBuff,
				currentBuff = currentBuff,
			}
		end
	end

	return #swaps > 0 and swaps or nil
end

function PPA:UpdateSelectedAssignmentOwner(context, plan, classID, buff, paladin)
	for _, classPlan in ipairs(plan.classPlans or {}) do
		if classPlan.classID == classID then
			for _, assignment in ipairs(classPlan.selected or {}) do
				if assignment.buff == buff then
					assignment.paladin = paladin
					assignment.paladinScore = self:ScorePaladinForClassBuff(context, paladin, buff, classID, classPlan.members)
					return
				end
			end
		end
	end
end

function PPA:ApplyGreaterAssignmentSwaps(context, plan, swaps, paladinLookup)
	for _, swap in ipairs(swaps or {}) do
		local paladin = paladinLookup[swap.paladinName]
		local otherPaladin = paladinLookup[swap.otherName]
		plan.assignments[swap.paladinName][swap.classID] = swap.targetBuff
		plan.assignments[swap.otherName][swap.classID] = swap.currentBuff
		self:UpdateSelectedAssignmentOwner(context, plan, swap.classID, swap.targetBuff, paladin)
		self:UpdateSelectedAssignmentOwner(context, plan, swap.classID, swap.currentBuff, otherPaladin)
	end
end

function PPA:SimplifyGreaterAssignmentWorkloads(context, plan)
	if not context or not plan or not plan.assignments then
		return
	end

	local paladinLookup = BuildPaladinLookup(context)
	local changed = true
	local guard = 0
	while changed and guard < 50 do
		changed = false
		guard = guard + 1

		local currentScore = AssignmentSimplicityScore(plan.assignments, context)
		local bestCandidate

		for _, paladin in ipairs(context.paladins or {}) do
			local counts, total, distinct = CountAssignmentBuffs(plan.assignments[paladin.name])
			if total > 0 and distinct > 1 then
				local sortedCounts = SortedAssignmentBuffCounts(counts)
				for _, target in ipairs(sortedCounts) do
					for _, current in ipairs(sortedCounts) do
						if current.buff ~= target.buff then
							local swaps = self:BuildGreaterAssignmentSimplificationSwaps(
								context,
								plan,
								paladinLookup,
								paladin.name,
								target.buff,
								current.buff
							)
							if swaps then
								local candidateAssignments = CopyAssignmentsWithSwaps(plan.assignments, swaps)
								local candidateScore = AssignmentSimplicityScore(candidateAssignments, context)
								local candidate = {
									swaps = swaps,
									score = candidateScore,
									paladinName = paladin.name,
									targetBuff = target.buff,
									targetCount = target.count,
									currentBuff = current.buff,
									currentCount = current.count,
								}
								if SimplicityScoreIsBetter(candidateScore, currentScore)
									and SimplificationCandidateIsBetter(candidate, bestCandidate)
								then
									bestCandidate = candidate
								end
							end
						end
					end
				end
			end
		end

		if bestCandidate then
			self:ApplyGreaterAssignmentSwaps(context, plan, bestCandidate.swaps, paladinLookup)
			local _, _, distinct = CountAssignmentBuffs(plan.assignments[bestCandidate.paladinName])
			if distinct == 1 then
				plan.debugLines[#plan.debugLines + 1] = string.format(
					"Simplified %s to only %s without downgrading blessing rank or talents.",
					bestCandidate.paladinName,
					BuffText(bestCandidate.targetBuff)
				)
			else
				plan.debugLines[#plan.debugLines + 1] = string.format(
					"Simplified %s toward %s by moving %s on %d class(es) without downgrading blessing rank or talents.",
					bestCandidate.paladinName,
					BuffText(bestCandidate.targetBuff),
					BuffText(bestCandidate.currentBuff),
					#bestCandidate.swaps
				)
			end
			changed = true
		end
	end
end

local function PlanHasNormalBuff(plan, classID, targetName, buff)
	for _, classMap in pairs(plan.normalAssignments or {}) do
		local targets = classMap and classMap[classID]
		if targets and targets[targetName] == buff then
			return true
		end
	end
	return false
end

local function PlanTargetHasBuff(plan, classID, targetName, buff)
	for paladinName, classMap in pairs(plan.assignments or {}) do
		local normal = plan.normalAssignments
			and plan.normalAssignments[paladinName]
			and plan.normalAssignments[paladinName][classID]
			and plan.normalAssignments[paladinName][classID][targetName]
		if normal then
			if normal == buff then
				return true
			end
		elseif classMap and classMap[classID] == buff then
			return true
		end
	end

	for _, manual in pairs(plan.manualAssignments or {}) do
		local normalBuff
		for _, normal in ipairs(manual.normal or {}) do
			if normal.classID == classID and normal.targetName == targetName then
				normalBuff = normal.buff
			end
		end
		if normalBuff then
			if normalBuff == buff then
				return true
			end
		elseif manual.greater and manual.greater[classID] == buff then
			return true
		end
	end
	return false
end

function PPA:FindBestPaladinForUnassignedNormal(context, buff)
	local bestPaladin
	local bestScore = -100000
	for _, paladin in ipairs(context.paladins or {}) do
		if self:CanPaladinBuff(paladin, buff) then
			local score = self:ScorePaladinForBuff(paladin, buff)
			if score > bestScore or (score == bestScore and paladin.name < (bestPaladin and bestPaladin.name or "\255")) then
				bestScore = score
				bestPaladin = paladin
			end
		end
	end
	return bestPaladin
end

function PPA:FindBestPaladinForTankLightOverride(context, plan, classID, targetName, priority)
	local lightIndex = PriorityIndex(priority, BUFF_LIGHT)
	if not lightIndex then
		return nil
	end

	local bestCandidate
	for _, paladin in ipairs(context.paladins or {}) do
		if self:CanPaladinBuff(paladin, BUFF_LIGHT) then
			local currentBuff = 0
			if paladin.hasAddon then
				currentBuff = plan.assignments
					and plan.assignments[paladin.name]
					and plan.assignments[paladin.name][classID]
					or 0
				local normal = plan.normalAssignments
					and plan.normalAssignments[paladin.name]
					and plan.normalAssignments[paladin.name][classID]
					and plan.normalAssignments[paladin.name][classID][targetName]
				if normal then
					currentBuff = normal
				end
			else
				local manual = plan.manualAssignments and plan.manualAssignments[paladin.name]
				currentBuff = manual and manual.greater and manual.greater[classID] or 0
				for _, normal in ipairs((manual and manual.normal) or {}) do
					if normal.classID == classID and normal.targetName == targetName then
						currentBuff = normal.buff
					end
				end
			end

			local currentIndex = PriorityIndex(priority, currentBuff) or 999
			if currentIndex > lightIndex then
				local candidate = {
					paladin = paladin,
					currentBuff = currentBuff,
					currentIndex = currentIndex,
					score = self:ScorePaladinForBuff(paladin, BUFF_LIGHT),
				}
				if not bestCandidate
					or candidate.currentIndex > bestCandidate.currentIndex
					or (candidate.currentIndex == bestCandidate.currentIndex and candidate.score > bestCandidate.score)
					or (
						candidate.currentIndex == bestCandidate.currentIndex
						and candidate.score == bestCandidate.score
						and candidate.paladin.name < bestCandidate.paladin.name
					)
				then
					bestCandidate = candidate
				end
			end
		end
	end
	return bestCandidate
end

function PPA:ApplyTankSanctuaryFallbacks(context, classID, members, selected, plan)
	local provided = {}
	for _, assignment in ipairs(selected or {}) do
		provided[assignment.buff] = assignment.paladin.name
	end
	if provided[BUFF_SANCTUARY] then
		return
	end
	if ContextIsPvP(context) and SelectedHasNonSanctuaryBlessing(selected) then
		return
	end

	for _, unit in ipairs(members or {}) do
		if NormalizeRole(unit.role) == ROLE_TANK and not PlanHasNormalBuff(plan, classID, unit.name, BUFF_SANCTUARY) then
			local skipSanctuary = false
			if unit.class == "PALADIN" then
				local specData = self:GetUnitSpecData(unit.name)
				if specData and (specData.sanctityAura or 0) == 0 then
					skipSanctuary = true
				end
			end
			if not skipSanctuary then
				local priority = unit.priority or self:GetPriorityForUnit(unit, context)
				if PriorityIndex(priority, BUFF_SANCTUARY) then
					local paladin = self:FindBestPaladinForUnassignedNormal(context, BUFF_SANCTUARY)
					if paladin then
						SetPlanNormal(plan, paladin, classID, unit.name, BUFF_SANCTUARY, 0)
						plan.debugLines[#plan.debugLines + 1] = string.format(
							"%s: %s adds single-target %s for tank coverage.",
							unit.name,
							paladin.name,
							BuffText(BUFF_SANCTUARY)
						)
					end
				end
			end
		end
	end
end

function PPA:ApplyTankLightFallbacks(context, classID, members, plan)
	if not (context and context.healingPaladinPresent) then
		return
	end

	for _, unit in ipairs(members or {}) do
		if NormalizeRole(unit.role) == ROLE_TANK and not PlanTargetHasBuff(plan, classID, unit.name, BUFF_LIGHT) then
			local priority = unit.priority or self:GetPriorityForUnit(unit, context)
			if PriorityIndex(priority, BUFF_LIGHT) then
				local candidate = self:FindBestPaladinForTankLightOverride(context, plan, classID, unit.name, priority)
				if candidate then
					SetPlanNormal(plan, candidate.paladin, classID, unit.name, BUFF_LIGHT, candidate.currentBuff)
					plan.debugLines[#plan.debugLines + 1] = string.format(
						"%s: %s adds single-target %s for tank healing because %s priority is %s.",
						unit.name,
						candidate.paladin.name,
						BuffText(BUFF_LIGHT),
						RoleText(unit.role),
						JoinBuffs(priority)
					)
				end
			end
		end
	end
end

function PPA:FindBestReplacementAssignment(priority, buff, buffIndex, selected, usedAssignments)
	local bestCandidate
	for _, assignment in ipairs(selected or {}) do
		if not usedAssignments[assignment] then
			local priorityIndex = PriorityIndex(priority, assignment.buff)
			local currentIndex = priorityIndex or 999
			if buffIndex < currentIndex and self:CanPaladinBuff(assignment.paladin, buff) then
				local candidate = {
					assignment = assignment,
					currentKnown = priorityIndex ~= nil,
					currentIndex = currentIndex,
					score = self:ScorePaladinForBuff(assignment.paladin, buff),
				}
				if not bestCandidate
					or (candidate.currentKnown ~= bestCandidate.currentKnown and candidate.currentKnown)
					or (
						candidate.currentKnown == bestCandidate.currentKnown
						and candidate.currentIndex > bestCandidate.currentIndex
					)
					or (
						candidate.currentKnown == bestCandidate.currentKnown
						and candidate.currentIndex == bestCandidate.currentIndex
						and candidate.score > bestCandidate.score
					)
					or (
						candidate.currentKnown == bestCandidate.currentKnown
						and candidate.currentIndex == bestCandidate.currentIndex
						and candidate.score == bestCandidate.score
						and candidate.assignment.paladin.name < bestCandidate.assignment.paladin.name
					)
				then
					bestCandidate = candidate
				end
			end
		end
	end
	return bestCandidate and bestCandidate.assignment or nil
end

function PPA:ApplyPlayerOverrides(context, classID, members, selected, plan)
	for _, unit in ipairs(members) do
		local priority = unit.priority or self:GetPriorityForUnit(unit, context)
		local provided = {}
		for _, assignment in ipairs(selected) do
			provided[assignment.buff] = assignment
		end
		local usedAssignments = {}

		for buffIndex, replacement in ipairs(priority) do
			if not provided[replacement] then
				local assignment = self:FindBestReplacementAssignment(priority, replacement, buffIndex, selected, usedAssignments)
				if assignment then
					SetPlanNormal(plan, assignment.paladin, classID, unit.name, replacement, assignment.buff)
					usedAssignments[assignment] = true
					provided[assignment.buff] = nil
					provided[replacement] = assignment
					plan.debugLines[#plan.debugLines + 1] = string.format(
						"%s: %s replaces %s with %s because %s priority is %s.",
						unit.name,
						assignment.paladin.name,
						BuffText(assignment.buff),
						BuffText(replacement),
						RoleText(unit.role),
						JoinBuffs(priority)
					)
				end
			end
		end
	end
end

local function AuraSkillForPaladin(paladin, aura)
	if type(paladin.auras) ~= "table" then
		return nil
	end
	return paladin.auras[aura]
end

local function IsTrackedAura(aura)
	return TRACKED_AURA_SET[aura] == true
end

function PPA:PaladinHasImprovedSanctityAura(paladin)
	if not paladin then
		return false
	end
	local specData = paladin.specData or self:GetUnitSpecData(paladin.name)
	if type(specData) == "table" and specData.impSanctityAura ~= nil then
		return SafeNumber(specData.impSanctityAura, 0) > 0
	end
	return SkillTalent(AuraSkillForPaladin(paladin, AURA_SANCTITY)) > 0
end

function PPA:CanPaladinUseAura(paladin, aura)
	if not paladin or not IsTrackedAura(aura) then
		return false
	end
	if aura == AURA_SANCTITY then
		return SkillRank(AuraSkillForPaladin(paladin, aura)) > 0 and self:PaladinHasImprovedSanctityAura(paladin)
	end
	if paladin.hasAddon then
		return SkillRank(AuraSkillForPaladin(paladin, aura)) > 0
	end
	return true
end

function PPA:ScorePaladinForAura(paladin, aura)
	if paladin.hasAddon then
		local skill = AuraSkillForPaladin(paladin, aura)
		local rank = SkillRank(skill)
		local talent = SkillTalent(skill)
		return talent * 100 + rank * 10
	end

	local role = NormalizeRole(paladin.role)
	if aura == AURA_DEVOTION then
		return 10 + (role == ROLE_TANK and 4 or 0)
	elseif aura == AURA_RETRIBUTION then
		return 8 + (role == ROLE_DAMAGER and 4 or 0)
	elseif aura == AURA_CONCENTRATION then
		return 6 + (role == ROLE_HEALER and 4 or 0)
	elseif aura == AURA_SANCTITY then
		return self:PaladinHasImprovedSanctityAura(paladin) and 20 or 0
	end
	return 0
end

function PPA:SelectPaladinForAura(paladins, aura, usedPaladins)
	local bestPaladin
	local bestScore = -100000
	for _, paladin in ipairs(paladins or {}) do
		if not usedPaladins[paladin.name] and self:CanPaladinUseAura(paladin, aura) then
			local score = self:ScorePaladinForAura(paladin, aura)
			if score > bestScore or (score == bestScore and paladin.name < (bestPaladin and bestPaladin.name or "\255")) then
				bestScore = score
				bestPaladin = paladin
			end
		end
	end
	return bestPaladin, bestScore
end

local TANK_AURA_PRIORITY = {
	AURA_DEVOTION,
	AURA_RETRIBUTION,
	AURA_CONCENTRATION,
}

local NON_TANK_AURA_PRIORITY = {
	AURA_CONCENTRATION,
	AURA_DEVOTION,
	AURA_RETRIBUTION,
}

local function UnitIsTank(unit)
	if not unit then
		return false
	end
	return NormalizeRole(unit.role) == ROLE_TANK or unit.mainTank == true or NormalizeRole(unit.raidRole) == ROLE_TANK
end

local function GetUnitSubgroup(unit)
	return SafeNumber(unit and unit.subgroup, 1)
end

function PPA:GetAuraPriorityForSubgroup(group)
	local priority = {}
	if group then
		local sanctityPaladin = self:SelectPaladinForAura(group.paladins, AURA_SANCTITY, {})
		local soloTankPaladin = group.hasTank and #(group.paladins or {}) == 1 and UnitIsTank(sanctityPaladin)
		if sanctityPaladin and not soloTankPaladin then
			priority[#priority + 1] = AURA_SANCTITY
		end
	end

	local fallback = group and group.hasTank and TANK_AURA_PRIORITY or NON_TANK_AURA_PRIORITY
	for _, aura in ipairs(fallback) do
		priority[#priority + 1] = aura
	end
	return priority
end

function PPA:BuildAuraAssignments(context, plan)
	local subgroups = {}
	for _, unit in ipairs(context.players or {}) do
		local subgroup = GetUnitSubgroup(unit)
		if not subgroups[subgroup] then
			subgroups[subgroup] = {paladins = {}, hasTank = false}
		end
		if UnitIsTank(unit) then
			subgroups[subgroup].hasTank = true
		end
	end

	for _, paladin in ipairs(context.paladins or {}) do
		local subgroup = GetUnitSubgroup(paladin)
		if not subgroups[subgroup] then
			subgroups[subgroup] = {paladins = {}, hasTank = false}
		end
		subgroups[subgroup].paladins[#subgroups[subgroup].paladins + 1] = paladin
		if UnitIsTank(paladin) then
			subgroups[subgroup].hasTank = true
		end
		if paladin.hasAddon then
			plan.auraAssignments[paladin.name] = 0
		end
	end

	for subgroup, group in pairs(subgroups) do
		local usedPaladins = {}
		for _, aura in ipairs(self:GetAuraPriorityForSubgroup(group)) do
			local paladin = self:SelectPaladinForAura(group.paladins, aura, usedPaladins)
			if paladin then
				usedPaladins[paladin.name] = true
				if paladin.hasAddon then
					plan.auraAssignments[paladin.name] = aura
				else
					EnsureManualAssignment(plan, paladin).aura = aura
				end
				plan.debugLines[#plan.debugLines + 1] = string.format(
					"Group %s aura: %s -> %s.",
					tostring(subgroup),
					AuraText(aura),
					paladin.name
				)
			end
		end
	end
end

function PPA:BuildSmartPlan(context)
	local plan = {
		assignments = {},
		normalAssignments = {},
		auraAssignments = {},
		manualAssignments = {},
		classPlans = {},
		debugLines = {},
		warnings = {},
	}

	if not context or not context.players or not context.paladins or #context.paladins == 0 then
		plan.warnings[#plan.warnings + 1] = "No paladins were found in the current group."
		return plan
	end

	local pallyLabels = {}
	for _, paladin in ipairs(context.paladins) do
		local source = paladin.hasAddon and "PallyPower" or "manual"
		pallyLabels[#pallyLabels + 1] = paladin.name .. "(" .. RoleText(paladin.role) .. ", " .. source .. ")"
	end
	plan.debugLines[#plan.debugLines + 1] = "Paladins considered: " .. table.concat(pallyLabels, ", ")
	if ContextIsPvP(context) then
		plan.debugLines[#plan.debugLines + 1] = "PvP instance detected; skipping Salvation and treating Sanctuary as lowest priority."
	end

	local groups = GroupPlayersByClass(context.players)
	for _, classID in ipairs(DEFAULT_CLASS_ORDER) do
		local members = groups[classID]
		local assumed = false
		if not members or #members == 0 then
			local assumedMember = self:CreateAssumedClassMember(classID)
			if assumedMember then
				members = {assumedMember}
				assumed = true
			end
		end
		if members and #members > 0 then
			local selected, scored = self:SelectClassAssignments(context, classID, members, plan)
			local classPlan = {
				classID = classID,
				members = members,
				selected = selected,
				scored = scored,
				assumed = assumed,
			}
			plan.classPlans[#plan.classPlans + 1] = classPlan
		end
	end

	self:SimplifyGreaterAssignmentWorkloads(context, plan)
	for _, classPlan in ipairs(plan.classPlans) do
		local classID = classPlan.classID
		local members = classPlan.members
		local selected = classPlan.selected
		local assumed = classPlan.assumed
		local pieces = {}
		for _, assignment in ipairs(selected) do
			pieces[#pieces + 1] = string.format(
				"%s -> %s",
				BuffText(assignment.buff),
				assignment.paladin.name
			)
		end
		if #pieces > 0 then
			local prefix = ClassText(classID) .. ": "
			if assumed then
				prefix = prefix .. "no players found; assumed " .. RoleText(members[1].role) .. " priorities. "
			end
			plan.debugLines[#plan.debugLines + 1] = prefix .. table.concat(pieces, ", ")
		else
			plan.debugLines[#plan.debugLines + 1] = ClassText(classID) .. ": no castable blessing assignment found."
		end

		if not assumed then
			self:ApplyPlayerOverrides(context, classID, members, selected, plan)
			self:ApplyTankSanctuaryFallbacks(context, classID, members, selected, plan)
			self:ApplyTankLightFallbacks(context, classID, members, plan)
		end
	end

	self:BuildAuraAssignments(context, plan)

	return plan
end

function PPA:GetUncertainPlayers(context)
	local uncertain = {}
	for _, unit in ipairs(context and context.players or {}) do
		local choices = self:GetChoiceList(unit)
		local role = NormalizeRole(unit.role)
		if choices then
			if role == ROLE_NONE then
				uncertain[#uncertain + 1] = unit
			elseif unit.class == "DRUID" and role == ROLE_DAMAGER and unit.spec ~= "BALANCE" and unit.spec ~= "FERAL" then
				uncertain[#uncertain + 1] = unit
			elseif unit.class == "SHAMAN" and role == ROLE_DAMAGER and unit.spec ~= "ELEMENTAL" and unit.spec ~= "ENHANCEMENT" then
				uncertain[#uncertain + 1] = unit
			end
		end
	end
	return uncertain
end

local function GetUnitNameSafe(unit)
	if _G.GetUnitName then
		local name = _G.GetUnitName(unit, true)
		if name then
			return name
		end
	end
	if _G.UnitName then
		return _G.UnitName(unit)
	end
	return nil
end

local function RemoveRealmName(name)
	if _G.PallyPower and _G.PallyPower.RemoveRealmName then
		return _G.PallyPower:RemoveRealmName(name)
	end
	if _G.Ambiguate then
		return _G.Ambiguate(name, "none")
	end
	local shortName = name and string.match(name, "^([^-]+)")
	return shortName or name
end

function PPA:GetLocalPaladinName()
	local name = _G.PallyPower and _G.PallyPower.player
	if not name and _G.UnitName then
		name = _G.UnitName("player")
	end
	return RemoveRealmName(name)
end

function PPA:GetMaxClasses()
	return SafeNumber(_G.PALLYPOWER_MAXCLASSES, #DEFAULT_CLASS_ORDER)
end

function PPA:IsAssignmentAlertMessage(message)
	return type(message) == "string" and (
		string.find(message, "^ASSIGN")
		or string.find(message, "^PASSIGN")
		or string.find(message, "^MASSIGN")
		or string.find(message, "^NASSIGN")
		or string.find(message, "^AASSIGN")
		or string.find(message, "^CLEAR")
	)
end

function PPA:SnapshotPaladinAssignments(playerName)
	if not playerName then
		return nil
	end
	playerName = RemoveRealmName(playerName)

	local snapshot = {
		greater = {},
		normal = {},
		aura = 0,
	}

	local assignments = _G.PallyPower_Assignments and _G.PallyPower_Assignments[playerName]
	for classID = 1, self:GetMaxClasses() do
		snapshot.greater[classID] = SafeNumber(assignments and assignments[classID], 0)
	end

	local normalAssignments = _G.PallyPower_NormalAssignments and _G.PallyPower_NormalAssignments[playerName]
	if type(normalAssignments) == "table" then
		for classID, targets in pairs(normalAssignments) do
			local numericClassID = SafeNumber(classID, classID)
			if type(targets) == "table" then
				snapshot.normal[numericClassID] = {}
				for targetName, buff in pairs(targets) do
					snapshot.normal[numericClassID][targetName] = SafeNumber(buff, 0)
				end
			end
		end
	end

	local auraAssignments = _G.PallyPower_AuraAssignments
	snapshot.aura = SafeNumber(auraAssignments and auraAssignments[playerName], 0)

	return snapshot
end

function PPA:SnapshotOwnAssignments()
	return self:SnapshotPaladinAssignments(self:GetLocalPaladinName())
end

local function AddAssignmentSnapshotName(names, name)
	local normalized = RemoveRealmName(name)
	if normalized and normalized ~= "" then
		names[normalized] = true
	end
end

function PPA:SnapshotAllAssignments()
	local names = {}
	for name in pairs(_G.PallyPower_Assignments or {}) do
		AddAssignmentSnapshotName(names, name)
	end
	for name in pairs(_G.PallyPower_NormalAssignments or {}) do
		AddAssignmentSnapshotName(names, name)
	end
	for name in pairs(_G.PallyPower_AuraAssignments or {}) do
		AddAssignmentSnapshotName(names, name)
	end
	for name in pairs(_G.AllPallys or {}) do
		AddAssignmentSnapshotName(names, name)
	end
	if _G.PallyPower and _G.PallyPower.player then
		AddAssignmentSnapshotName(names, _G.PallyPower.player)
	end

	local snapshot = {
		paladins = {},
	}
	for name in pairs(names) do
		snapshot.paladins[name] = self:SnapshotPaladinAssignments(name)
	end
	return snapshot
end

local function AddNormalTargetKeys(keys, assignments)
	for classID, targets in pairs(assignments or {}) do
		if type(targets) == "table" then
			if not keys[classID] then
				keys[classID] = {}
			end
			for targetName in pairs(targets) do
				keys[classID][targetName] = true
			end
		end
	end
end

function PPA:DescribeAssignmentChange(sender, change)
	local source = RemoveRealmName(sender) or "Someone"
	if change.kind == "greater" then
		if change.buff and change.buff > 0 then
			return string.format(
				"%s has assigned you to %s all %s.",
				source,
				LongBuffText(change.buff),
				ClassPluralText(change.classID)
			)
		end
		return string.format(
			"%s has cleared your assignment for all %s.",
			source,
			ClassPluralText(change.classID)
		)
	end

	if change.kind == "normal" then
		if change.buff and change.buff > 0 then
			return string.format(
				"%s has assigned you to single buff %s to %s.",
				source,
				LongBuffText(change.buff),
				change.targetName
			)
		end
		return string.format(
			"%s has cleared your single buff assignment to %s.",
			source,
			change.targetName
		)
	end

	return nil
end

function PPA:CollectAssignmentChanges(before, after, includeMissing)
	local changes = {}
	if not before or not after then
		if not includeMissing then
			return changes
		end
		before = before or {greater = {}, normal = {}}
		after = after or {greater = {}, normal = {}}
	end
	before.greater = before.greater or {}
	before.normal = before.normal or {}
	after.greater = after.greater or {}
	after.normal = after.normal or {}

	for classID = 1, self:GetMaxClasses() do
		local oldBuff = SafeNumber(before.greater and before.greater[classID], 0)
		local newBuff = SafeNumber(after.greater and after.greater[classID], 0)
		if oldBuff ~= newBuff then
			changes[#changes + 1] = {
				kind = "greater",
				classID = classID,
				buff = newBuff,
			}
		end
	end

	local targetKeys = {}
	AddNormalTargetKeys(targetKeys, before.normal)
	AddNormalTargetKeys(targetKeys, after.normal)
	for classID, targets in pairs(targetKeys) do
		for targetName in pairs(targets) do
			local oldBuff = SafeNumber(before.normal[classID] and before.normal[classID][targetName], 0)
			local newBuff = SafeNumber(after.normal[classID] and after.normal[classID][targetName], 0)
			if oldBuff ~= newBuff then
				changes[#changes + 1] = {
					kind = "normal",
					classID = classID,
					targetName = targetName,
					buff = newBuff,
				}
			end
		end
	end

	return changes
end

local function AddPaladinSnapshotKeys(keys, snapshot)
	for name in pairs(snapshot and snapshot.paladins or {}) do
		keys[name] = true
	end
end

function PPA:CollectAllAssignmentChanges(before, after)
	local changes = {}
	local paladinNames = {}
	AddPaladinSnapshotKeys(paladinNames, before)
	AddPaladinSnapshotKeys(paladinNames, after)

	for paladinName in pairs(paladinNames) do
		local beforePaladin = before and before.paladins and before.paladins[paladinName]
		local afterPaladin = after and after.paladins and after.paladins[paladinName]
		for _, change in ipairs(self:CollectAssignmentChanges(beforePaladin, afterPaladin, true)) do
			change.paladinName = paladinName
			changes[#changes + 1] = change
		end

		local oldAura = SafeNumber(beforePaladin and beforePaladin.aura, 0)
		local newAura = SafeNumber(afterPaladin and afterPaladin.aura, 0)
		if oldAura ~= newAura then
			changes[#changes + 1] = {
				kind = "aura",
				paladinName = paladinName,
				aura = newAura,
			}
		end
	end

	table.sort(changes, function(a, b)
		if (a.paladinName or "") ~= (b.paladinName or "") then
			return (a.paladinName or "") < (b.paladinName or "")
		end
		if (a.kind or "") ~= (b.kind or "") then
			return (a.kind or "") < (b.kind or "")
		end
		if SafeNumber(a.classID, 0) ~= SafeNumber(b.classID, 0) then
			return SafeNumber(a.classID, 0) < SafeNumber(b.classID, 0)
		end
		return tostring(a.targetName or "") < tostring(b.targetName or "")
	end)

	return changes
end

function PPA:ReportAssignmentChanges(sender, before, after)
	local source = RemoveRealmName(sender)
	local playerName = self:GetLocalPaladinName()
	if not source or source == playerName then
		return
	end

	local changes = self:CollectAssignmentChanges(before, after)
	for _, change in ipairs(changes) do
		local message = self:DescribeAssignmentChange(source, change)
		if message then
			Print(message)
		end
	end
end

function PPA:DescribeRaidAssignmentChange(sender, change)
	local source = RemoveRealmName(sender) or "Someone"
	local assignee = change.paladinName or "Unknown"
	if change.kind == "greater" then
		if change.buff and change.buff > 0 then
			return string.format(
				"Trace: %s set %s to %s on all %s.",
				source,
				assignee,
				LongBuffText(change.buff),
				ClassPluralText(change.classID)
			)
		end
		return string.format(
			"Trace: %s cleared %s's assignment for all %s.",
			source,
			assignee,
			ClassPluralText(change.classID)
		)
	end

	if change.kind == "normal" then
		if change.buff and change.buff > 0 then
			return string.format(
				"Trace: %s set %s to single-buff %s on %s.",
				source,
				assignee,
				LongBuffText(change.buff),
				change.targetName
			)
		end
		return string.format(
			"Trace: %s cleared %s's single-buff assignment on %s.",
			source,
			assignee,
			change.targetName
		)
	end

	if change.kind == "aura" then
		if change.aura and change.aura > 0 then
			return string.format("Trace: %s set %s to %s.", source, assignee, AuraText(change.aura))
		end
		return string.format("Trace: %s cleared %s's aura assignment.", source, assignee)
	end

	return nil
end

function PPA:DescribeRaidAssignmentChangeDetail(change)
	local assignee = change.paladinName or "Unknown"
	if change.kind == "greater" then
		if change.buff and change.buff > 0 then
			return string.format(
				"%s -> %s on all %s",
				assignee,
				LongBuffText(change.buff),
				ClassPluralText(change.classID)
			)
		end
		return string.format("%s -> cleared all %s", assignee, ClassPluralText(change.classID))
	end

	if change.kind == "normal" then
		if change.buff and change.buff > 0 then
			return string.format("%s -> single-buff %s on %s", assignee, LongBuffText(change.buff), change.targetName)
		end
		return string.format("%s -> cleared single-buff on %s", assignee, change.targetName)
	end

	if change.kind == "aura" then
		if change.aura and change.aura > 0 then
			return string.format("%s -> %s", assignee, AuraText(change.aura))
		end
		return string.format("%s -> cleared aura", assignee)
	end

	return "unknown assignment change"
end

function PPA:NoteLocalAssignmentAction(source)
	self.assignmentConflictWatch = {
		source = source or "assignment",
		startedAt = Now(),
		externalBursts = 0,
		warned = false,
	}
end

function PPA:IsAssignmentConflictWatchActive(now)
	local watch = self.assignmentConflictWatch
	if not watch or not watch.startedAt then
		return false
	end
	now = now or Now()
	if now - watch.startedAt > ASSIGNMENT_CONFLICT_WINDOW_SECONDS then
		self.assignmentConflictWatch = nil
		return false
	end
	return true
end

function PPA:ReportAssignmentConflict(source, watch, changes, now)
	local elapsed = math.max(0, now - (watch.startedAt or now))
	local detail = changes[1] and self:DescribeRaidAssignmentChangeDetail(changes[1]) or "no changed assignment detail"
	Print(string.format(
		"Assignment conflict: %s overwrote assignments again %.1fs after your %s.",
		source,
		elapsed,
		watch.source or "assignment"
	))
	Print("Reason: your client accepted a second external PallyPower assignment burst inside 5s; Free Assignment or raid lead/assist can allow that override.")
	Print("Last change: " .. detail .. ".")
end

function PPA:HandleAssignmentConflict(sender, before, after)
	local source = RemoveRealmName(sender)
	local playerName = self:GetLocalPaladinName()
	if not source or source == playerName then
		return
	end

	local now = Now()
	if not self:IsAssignmentConflictWatchActive(now) then
		return
	end

	local changes = self:CollectAllAssignmentChanges(before, after)
	if #changes == 0 then
		return
	end

	local watch = self.assignmentConflictWatch
	local sameBurst = watch.lastExternalAt
		and watch.lastSender == source
		and (now - watch.lastExternalAt) <= ASSIGNMENT_CONFLICT_BURST_SECONDS
	watch.lastExternalAt = now
	watch.lastSender = source
	watch.lastChanges = changes
	if not sameBurst then
		watch.externalBursts = (watch.externalBursts or 0) + 1
	end

	if not watch.warned and (watch.externalBursts or 0) >= 2 then
		self:ReportAssignmentConflict(source, watch, changes, now)
		watch.warned = true
	end
end

function PPA:ReportAssignmentTrace(sender, before, after)
	if not self:IsAssignmentTraceEnabled() then
		return
	end

	local source = RemoveRealmName(sender)
	local playerName = self:GetLocalPaladinName()
	if not source or source == playerName then
		return
	end

	local changes = self:CollectAllAssignmentChanges(before, after)
	if #changes == 0 then
		return
	end

	if #changes == 1 then
		local message = self:DescribeRaidAssignmentChange(source, changes[1])
		if message then
			Print(message)
		end
		return
	end

	Print(string.format("Trace: %s changed %d PallyPower assignments.", source, #changes))
	local detailLimit = 8
	for index = 1, math.min(#changes, detailLimit) do
		local message = self:DescribeRaidAssignmentChange(source, changes[index])
		if message then
			Print(message)
		end
	end
	if #changes > detailLimit then
		Print(string.format("Trace: %d more assignment changes hidden.", #changes - detailLimit))
	end
end

function PPA:HookAssignmentAlerts()
	if self.assignmentAlertsHooked or not _G.PallyPower or type(_G.PallyPower.ParseMessage) ~= "function" then
		return
	end

	local originalParseMessage = _G.PallyPower.ParseMessage
	_G.PallyPower.ParseMessage = function(pallyPower, sender, message, ...)
		local before
		local allBefore
		if PPA:IsAssignmentAlertMessage(message) then
			before = PPA:SnapshotOwnAssignments()
			if PPA:IsAssignmentTraceEnabled() or PPA:IsAssignmentConflictWatchActive() then
				allBefore = PPA:SnapshotAllAssignments()
			end
		end

		local result = originalParseMessage(pallyPower, sender, message, ...)

		if before then
			PPA:ReportAssignmentChanges(sender, before, PPA:SnapshotOwnAssignments())
			if allBefore then
				local allAfter = PPA:SnapshotAllAssignments()
				PPA:ReportAssignmentTrace(sender, allBefore, allAfter)
				PPA:HandleAssignmentConflict(sender, allBefore, allAfter)
			end
		end

		return result
	end

	self.assignmentAlertsHooked = true
end

function PPA:GetAssignedBuffForUnit(unit)
	local playerName = self:GetLocalPaladinName()
	if not playerName or not unit or not unit.classID then
		return nil
	end

	local normalAssignments = _G.PallyPower_NormalAssignments and _G.PallyPower_NormalAssignments[playerName]
	local normal = normalAssignments
		and normalAssignments[unit.classID]
		and normalAssignments[unit.classID][unit.name]
	normal = SafeNumber(normal, 0)
	if normal > 0 then
		return normal, "normal"
	end

	local assignments = _G.PallyPower_Assignments and _G.PallyPower_Assignments[playerName]
	local greater = SafeNumber(assignments and assignments[unit.classID], 0)
	if greater > 0 then
		return greater, "greater"
	end

	return nil
end

function PPA:GetUnitBlessingExpiration(unit, buffID)
	if not unit or not unit.unit or not buffID or not _G.PallyPower then
		return nil
	end

	local spell = _G.PallyPower.Spells and _G.PallyPower.Spells[buffID]
	local greaterSpell = _G.PallyPower.GSpells and _G.PallyPower.GSpells[buffID]
	if not spell and not greaterSpell then
		return nil
	end

	if type(_G.PallyPower.IsBuffActive) == "function" then
		local ok, remaining, duration, buffName = pcall(_G.PallyPower.IsBuffActive, _G.PallyPower, spell, greaterSpell, unit.unit)
		if ok then
			return tonumber(remaining), tonumber(duration), buffName
		end
	end

	return nil
end

function PPA:FindExpiringAssignedBuffs(threshold)
	local warnings = {}
	threshold = threshold or BUFF_WARNING_SECONDS

	if not _G.PallyPower or not _G.PallyPower.Spells then
		return warnings
	end

	for _, unit in ipairs(self:CollectRoster()) do
		local buffID, assignmentType = self:GetAssignedBuffForUnit(unit)
		if buffID then
			local remaining, duration, buffName = self:GetUnitBlessingExpiration(unit, buffID)
			if remaining and duration and duration > 0 and remaining > 0 and remaining <= threshold then
				warnings[#warnings + 1] = {
					unitName = unit.name,
					unit = unit.unit,
					classID = unit.classID,
					buffID = buffID,
					assignmentType = assignmentType,
					remaining = remaining,
					duration = duration,
					buffName = buffName or LongBuffText(buffID),
				}
			end
		end
	end

	return warnings
end

function PPA:GetBuffWarningKey(warning)
	return table.concat({
		tostring(warning.unitName or ""),
		tostring(warning.classID or ""),
		tostring(warning.buffID or ""),
		tostring(warning.assignmentType or ""),
	}, "|")
end

function PPA:GetCVarBool(name)
	if type(_G.GetCVarBool) == "function" then
		return _G.GetCVarBool(name) == true
	end
	if type(_G.GetCVar) == "function" then
		local value = _G.GetCVar(name)
		return value == true or value == 1 or value == "1"
	end
	return true
end

function PPA:IsGameSoundMuted()
	local allSound = self:GetCVarBool("Sound_EnableAllSound")
	local sfx = self:GetCVarBool("Sound_EnableSFX")
	local masterVolume = 1
	if type(_G.GetCVar) == "function" then
		masterVolume = tonumber(_G.GetCVar("Sound_MasterVolume")) or 1
	end
	return not allSound or not sfx or masterVolume <= 0
end

function PPA:RestoreSoundCVars(previous)
	if type(previous) ~= "table" or type(_G.SetCVar) ~= "function" then
		return
	end
	for name, value in pairs(previous) do
		_G.SetCVar(name, value)
	end
end

function PPA:PlayBuffWarningSound()
	local soundKit = _G.SOUNDKIT and (_G.SOUNDKIT[BUFF_WARNING_SOUNDKIT] or _G.SOUNDKIT[BUFF_WARNING_SOUNDKIT_FALLBACK])
	if not soundKit or type(_G.PlaySound) ~= "function" then
		return false
	end

	local previous
	if self:IsGameSoundMuted() and type(_G.GetCVar) == "function" and type(_G.SetCVar) == "function" then
		previous = {
			Sound_EnableAllSound = _G.GetCVar("Sound_EnableAllSound"),
			Sound_EnableSFX = _G.GetCVar("Sound_EnableSFX"),
			Sound_MasterVolume = _G.GetCVar("Sound_MasterVolume"),
		}
		if previous.Sound_EnableAllSound == "0" then
			_G.SetCVar("Sound_EnableAllSound", 1)
		end
		if previous.Sound_EnableSFX == "0" then
			_G.SetCVar("Sound_EnableSFX", 1)
		end
		if (tonumber(previous.Sound_MasterVolume) or 1) <= 0 then
			_G.SetCVar("Sound_MasterVolume", 0.5)
		end
	end

	local ok = pcall(_G.PlaySound, soundKit, BUFF_WARNING_SOUND_CHANNEL)

	if previous then
		if _G.C_Timer and type(_G.C_Timer.After) == "function" then
			_G.C_Timer.After(BUFF_WARNING_RESTORE_DELAY, function()
				PPA:RestoreSoundCVars(previous)
			end)
		else
			self:RestoreSoundCVars(previous)
		end
	end

	return ok
end

function PPA:CheckBuffWarnings(now)
	local db = self:EnsureDB()
	if db.buffWarningSound ~= true then
		return
	end

	now = now or ((_G.GetTime and _G.GetTime()) or (_G.time and _G.time()) or 0)
	self.buffWarningState = self.buffWarningState or {}
	local activeKeys = {}
	local hasNewWarning = false

	for _, warning in ipairs(self:FindExpiringAssignedBuffs(BUFF_WARNING_SECONDS)) do
		local key = self:GetBuffWarningKey(warning)
		activeKeys[key] = true
		if not self.buffWarningState[key] then
			hasNewWarning = true
		end
	end

	for key in pairs(self.buffWarningState) do
		if not activeKeys[key] then
			self.buffWarningState[key] = nil
		end
	end

	if hasNewWarning and (not self.lastBuffWarningSound or now - self.lastBuffWarningSound >= BUFF_WARNING_SOUND_COOLDOWN) then
		if self:PlayBuffWarningSound() then
			self.lastBuffWarningSound = now
			for key in pairs(activeKeys) do
				self.buffWarningState[key] = true
			end
		end
	elseif not hasNewWarning then
		for key in pairs(activeKeys) do
			self.buffWarningState[key] = true
		end
	end
end

function PPA:OnUpdate(elapsed)
	self.buffWarningElapsed = (self.buffWarningElapsed or 0) + (elapsed or 0)
	if self.buffWarningElapsed < BUFF_WARNING_SCAN_INTERVAL then
		return
	end
	self.buffWarningElapsed = 0
	self:CheckBuffWarnings()
end

function PPA:BuildPaladinSkills(name)
	local skills = {}
	local allPallys = _G.AllPallys
	local info = allPallys and allPallys[name]
	if type(info) == "table" then
		for buff = BUFF_WISDOM, BUFF_SANCTUARY do
			if type(info[buff]) == "table" then
				skills[buff] = {
					rank   = SafeNumber(info[buff].rank, 0),
					talent = SafeNumber(info[buff].talent, 0),
				}
			end
		end
	end

	local specData
	local UnitName = _G.UnitName
	if type(UnitName) == "function" and name == UnitName("player") then
		specData = self:ReadLocalTalents()
	else
		specData = self.peerSpecs[name]
	end

	if specData then
		local overrides = {
			[BUFF_MIGHT]     = specData.impMight,
			[BUFF_WISDOM]    = specData.impWisdom,
			[BUFF_SANCTUARY] = specData.impSanc,
			[BUFF_KINGS]     = specData.kings,
		}
		for buff, talentRank in pairs(overrides) do
			if skills[buff] then
				if buff == BUFF_KINGS and SafeNumber(talentRank, 0) <= 0 then
					skills[buff] = nil
				else
					skills[buff].talent = talentRank
				end
			elseif buff == BUFF_KINGS and SafeNumber(talentRank, 0) > 0 then
				skills[buff] = {rank = 1, talent = talentRank}
			end
		end
	end
	if skills[BUFF_SANCTUARY] and SkillTalent(skills[BUFF_SANCTUARY]) <= 0 then
		skills[BUFF_SANCTUARY] = nil
	end

	return skills
end

function PPA:BuildPaladinAuras(name)
	local auras = {}
	local allPallys = _G.AllPallys
	local info = allPallys and allPallys[name]
	local auraInfo = type(info) == "table" and info.AuraInfo

	if type(auraInfo) == "table" then
		for _, aura in ipairs(TRACKED_AURAS) do
			if type(auraInfo[aura]) == "table" then
				auras[aura] = {
					rank = SafeNumber(auraInfo[aura].rank, 0),
					talent = SafeNumber(auraInfo[aura].talent, 0),
				}
			end
		end
	end

	local specData = self:GetUnitSpecData(name)
	if type(specData) == "table" then
		local hasSanctity = SafeNumber(specData.sanctityAura, 0) > 0
		if specData.impSanctityAura ~= nil then
			local improvedSanctity = SafeNumber(specData.impSanctityAura, 0)
			if auras[AURA_SANCTITY] then
				auras[AURA_SANCTITY].talent = improvedSanctity
			elseif hasSanctity or improvedSanctity > 0 then
				auras[AURA_SANCTITY] = {rank = 1, talent = improvedSanctity}
			end
		elseif hasSanctity and not auras[AURA_SANCTITY] then
			auras[AURA_SANCTITY] = {rank = 1, talent = 0}
		end
	end
	return auras
end

local SPEC_TALENT_NAMES = {
	["Improved Blessing of Might"]     = "impMight",
	["Improved Blessing of Wisdom"]    = "impWisdom",
	["Improved Blessing of Sanctuary"] = "impSanc",
	["Blessing of Sanctuary"]          = "impSanc",
	["Blessing of Kings"]              = "kings",
	["Sanctity Aura"]                  = "sanctityAura",
	["Improved Sanctity Aura"]         = "impSanctityAura",
	["Holy Shield"]                    = "holyShield",
}

function PPA:ReadLocalTalents()
	local GetActiveTalentGroup = _G.GetActiveTalentGroup
	local GetNumTalentTabs     = _G.GetNumTalentTabs
	local GetNumTalents        = _G.GetNumTalents
	local GetTalentTabInfo     = _G.GetTalentTabInfo
	local GetTalentInfo        = _G.GetTalentInfo
	if not GetActiveTalentGroup or not GetTalentInfo then
		return nil
	end

	local activeGroup = GetActiveTalentGroup() or 1
	local numTabs = (GetNumTalentTabs and GetNumTalentTabs()) or 3

	local result = {activeTab = 1, impMight = 0, impWisdom = 0, impSanc = 0, kings = 0, sanctityAura = 0, impSanctityAura = 0, holyShield = 0}

	local bestPoints = -1
	for tab = 1, numTabs do
		local _, _, _, _, pointsSpent = GetTalentTabInfo(tab, false, false, activeGroup)
		if (pointsSpent or 0) > bestPoints then
			bestPoints = pointsSpent or 0
			result.activeTab = tab
		end
	end

	for tab = 1, numTabs do
		local numTalents = (GetNumTalents and GetNumTalents(tab)) or 0
		for i = 1, numTalents do
			local name, _, _, _, rank = GetTalentInfo(tab, i, false, false, activeGroup)
			local field = name and SPEC_TALENT_NAMES[name]
			if field then
				result[field] = rank or 0
			end
		end
	end

	return result
end

function PPA:BroadcastSpec()
	local C_ChatInfo = _G.C_ChatInfo
	if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
		return
	end
	local t = self:ReadLocalTalents()
	if not t then
		return
	end
	local msg = string.format("SPEC:%d|M:%d|W:%d|S:%d|K:%d|SA:%d|ISA:%d|HS:%d|v:%d",
		t.activeTab, t.impMight, t.impWisdom, t.impSanc, t.kings, t.sanctityAura, t.impSanctityAura, t.holyShield, PPA_SPEC_VERSION)
	local IsInRaid  = _G.IsInRaid
	local IsInGroup = _G.IsInGroup
	local channel
	if IsInRaid and IsInRaid() then
		channel = "RAID"
	elseif IsInGroup and IsInGroup() then
		channel = "PARTY"
	else
		return
	end
	C_ChatInfo.SendAddonMessage(PPA_SPEC_PREFIX, msg, channel)
end

function PPA:GetUnitSpecData(unitName)
	local UnitName = _G.UnitName
	if type(UnitName) == "function" and unitName == UnitName("player") then
		return self:ReadLocalTalents()
	end
	return self.peerSpecs[unitName]
end

function PPA:HandleAddonMessage(prefix, text, _, sender)
	if prefix ~= PPA_SPEC_PREFIX or not text or not sender then
		return
	end
	local activeTab = tonumber(text:match("^SPEC:(%d+)"))
	if not activeTab then
		return
	end
	local name = sender:match("^([^%-]+)") or sender
	self.peerSpecs[name] = {
		activeTab    = activeTab,
		impMight     = tonumber(text:match("|M:(%d+)")) or 0,
		impWisdom    = tonumber(text:match("|W:(%d+)")) or 0,
		impSanc      = tonumber(text:match("|S:(%d+)")) or 0,
		kings        = tonumber(text:match("|K:(%d+)")) or 0,
		sanctityAura    = tonumber(text:match("|SA:(%d+)")) or 0,
		impSanctityAura = tonumber(text:match("|ISA:(%d+)")),
		holyShield      = tonumber(text:match("|HS:(%d+)")) or 0,
	}
end

function PPA:GetClassID(classFile)
	if _G.PallyPower and _G.PallyPower.ClassToID and _G.PallyPower.ClassToID[classFile] then
		return _G.PallyPower.ClassToID[classFile]
	end
	return CLASS_ID[classFile]
end

function PPA:RepairPallyPowerCooldownInfo(name)
	local allPallys = _G.AllPallys
	local info = allPallys and name and allPallys[name]
	if type(info) ~= "table" or type(info.CooldownInfo) ~= "table" then
		return
	end

	for id = 1, 2 do
		local cooldown = info.CooldownInfo[id]
		if type(cooldown) == "table" then
			if cooldown.start == nil then
				cooldown.start = 0
			end
			if cooldown.duration == nil then
				cooldown.duration = 0
			end
		end
	end
end

function PPA:RefreshPallyPowerState()
	if not _G.PallyPower then
		return
	end

	if _G.PallyPower.ScanSpells then
		pcall(_G.PallyPower.ScanSpells, _G.PallyPower)
	end
	if _G.PallyPower.ScanCooldowns then
		pcall(_G.PallyPower.ScanCooldowns, _G.PallyPower)
	end
	if _G.PallyPower.ScanInventory then
		pcall(_G.PallyPower.ScanInventory, _G.PallyPower)
	end
	self:RepairPallyPowerCooldownInfo(_G.PallyPower.player)

	if _G.PallyPower.UpdateRoster then
		pcall(_G.PallyPower.UpdateRoster, _G.PallyPower)
	end
end

function PPA:RefreshPallyPowerTalentState()
	local pallyPower = _G.PallyPower
	if not pallyPower then
		return
	end

	if type(_G.PallyPower_Talents) == "table" then
		for key in pairs(_G.PallyPower_Talents) do
			_G.PallyPower_Talents[key] = nil
		end
	end
	if pallyPower.ScanTalents then
		pcall(pallyPower.ScanTalents, pallyPower)
	end
	self:RefreshPallyPowerState()
	if pallyPower.SendSelf then
		pcall(pallyPower.SendSelf, pallyPower)
	end
	if pallyPower.UpdateLayout then
		pcall(pallyPower.UpdateLayout, pallyPower)
	end
end

function PPA:HandleLocalTalentChanged()
	self:RefreshPallyPowerTalentState()
	self:BroadcastSpec()
	if _G.C_Timer and type(_G.C_Timer.After) == "function" then
		_G.C_Timer.After(1.0, function()
			PPA:RefreshPallyPowerTalentState()
			PPA:BroadcastSpec()
		end)
	end
end

local SIMULATION_TANK_CLASSES = {"WARRIOR", "DRUID", "PALADIN"}
local SIMULATION_HEALER_CLASSES = {"PRIEST", "DRUID", "PALADIN", "SHAMAN"}
local SIMULATION_DPS_CLASSES = {
	"WARRIOR",
	"ROGUE",
	"DRUID",
	"PALADIN",
	"HUNTER",
	"MAGE",
	"WARLOCK",
	"SHAMAN",
	"PRIEST",
}

local SIMULATION_BASE_NAMES = {
	WARRIOR = "War",
	ROGUE = "Rogue",
	PRIEST = "Priest",
	DRUID = "Druid",
	HUNTER = "Hunter",
	MAGE = "Mage",
	WARLOCK = "Lock",
	SHAMAN = "Shaman",
}

local SIMULATION_PALADIN_NAMES = {
	TANK = "Prot",
	HEALER = "Holy",
	DAMAGER = "Ret",
	NONE = "Ret",
}

local function SimulationNameBase(classFile, role, spec)
	role = NormalizeRole(role)
	if classFile == "PALADIN" then
		return SIMULATION_PALADIN_NAMES[role] or SIMULATION_PALADIN_NAMES.DAMAGER
	elseif classFile == "WARRIOR" then
		if role == ROLE_TANK then
			return "TankWar"
		elseif role == ROLE_DAMAGER then
			return "DpsWar"
		end
	elseif classFile == "PRIEST" then
		if role == ROLE_HEALER then
			return "HolyPriest"
		elseif spec == "SHADOW" or role == ROLE_DAMAGER then
			return "ShadowPriest"
		end
	elseif classFile == "DRUID" then
		if role == ROLE_TANK then
			return "TankDruid"
		elseif role == ROLE_HEALER then
			return "RestoDruid"
		elseif spec == "BALANCE" then
			return "BalanceDruid"
		elseif spec == "FERAL" then
			return "FeralDruid"
		end
	elseif classFile == "SHAMAN" then
		if role == ROLE_HEALER then
			return "RestoShaman"
		elseif spec == "ELEMENTAL" then
			return "EleShaman"
		elseif spec == "ENHANCEMENT" then
			return "EnhShaman"
		end
	end
	return SIMULATION_BASE_NAMES[classFile] or classFile
end

local function CreateSimulationRng(seed)
	local state = SafeNumber(seed, 1)
	if state <= 0 then
		state = 1
	end
	state = state % 2147483647
	if state == 0 then
		state = 1
	end
	return function(max)
		state = (state * 48271) % 2147483647
		if not max or max <= 0 then
			return state
		end
		return (state % max) + 1
	end
end

local function SimulationChoice(rng, list)
	return list[rng(#list)]
end

local function SimulationDpsSpec(classFile, rng)
	if classFile == "DRUID" then
		return rng(2) == 1 and "FERAL" or "BALANCE"
	elseif classFile == "SHAMAN" then
		return rng(2) == 1 and "ENHANCEMENT" or "ELEMENTAL"
	elseif classFile == "PRIEST" then
		return "SHADOW"
	end
	return nil
end

local function SimulationTankSpec(classFile)
	if classFile == "DRUID" then
		return "FERAL_TANK"
	end
	return nil
end

local function SimulationHealerSpec(classFile)
	if classFile == "DRUID" or classFile == "SHAMAN" then
		return "RESTORATION"
	end
	return nil
end

local function SimulationRaidRole(role)
	if NormalizeRole(role) == ROLE_TANK then
		return "MAINTANK"
	end
	return NormalizeRole(role)
end

function PPA:BuildSimulationPaladinSkills(role, hasKings)
	role = NormalizeRole(role)
	local skills = {
		[BUFF_WISDOM] = {rank = 7, talent = role == ROLE_HEALER and 2 or 0},
		[BUFF_MIGHT] = {rank = 7, talent = role == ROLE_DAMAGER and 2 or 0},
		[BUFF_SALVATION] = {rank = 1, talent = 0},
		[BUFF_LIGHT] = {rank = 4, talent = 0},
	}
	if hasKings == nil then
		hasKings = true
	end
	if hasKings then
		skills[BUFF_KINGS] = {rank = 1, talent = 0}
	end
	if role == ROLE_TANK then
		skills[BUFF_SANCTUARY] = {rank = 5, talent = 2}
	end
	return skills
end

function PPA:BuildSimulationPaladinAuras(role)
	role = NormalizeRole(role)
	return {
		[AURA_DEVOTION] = {rank = 7, talent = role == ROLE_TANK and 2 or 0},
		[AURA_RETRIBUTION] = {rank = 5, talent = role == ROLE_DAMAGER and 1 or 0},
		[AURA_CONCENTRATION] = {rank = 1, talent = role == ROLE_HEALER and 1 or 0},
		[AURA_SANCTITY] = {rank = role == ROLE_DAMAGER and 1 or 0, talent = role == ROLE_DAMAGER and 2 or 0},
	}
end

function PPA:GetNextSimulationSeed()
	local db = self:EnsureDB()
	db.simulationSeed = SafeNumber(db.simulationSeed, 0) + 1
	return db.simulationSeed
end

function PPA:BuildSimulationContext(seed)
	seed = SafeNumber(seed, 1)
	local rng = CreateSimulationRng(seed)
	local targetTanks = 2 + rng(2) - 1
	local targetHealers = 4 + rng(6) - 1
	local targetPaladins = 3 + rng(3) - 1
	local players = {}
	local classCounts = {}
	local roleCounts = {
		[ROLE_TANK] = 0,
		[ROLE_HEALER] = 0,
		[ROLE_DAMAGER] = 0,
	}
	local nameCounts = {}
	local paladinRoleBuildCounts = {}

	local function nextName(classFile, role, spec)
		local base = SimulationNameBase(classFile, role, spec)
		local key = classFile .. "_" .. base
		nameCounts[key] = (nameCounts[key] or 0) + 1
		return "PpaSim" .. base .. tostring(nameCounts[key])
	end

	local function addPlayer(classFile, role, spec, name)
		local classID = CLASS_ID[classFile]
		if not classID then
			return nil
		end
		if name and classFile == "PALADIN" then
			local paladinRole = NormalizeRole(role)
			local key = classFile .. "_" .. SimulationNameBase(classFile, paladinRole, spec)
			nameCounts[key] = math.max(nameCounts[key] or 0, 1)
		end
		name = name or nextName(classFile, role, spec)
		local unit = {
			name = name,
			fullName = name,
			key = name,
			class = classFile,
			classID = classID,
			role = NormalizeRole(role),
			spec = spec,
			simulation = true,
		}
		if classFile == "PALADIN" then
			local roleKey = unit.role or ROLE_NONE
			paladinRoleBuildCounts[roleKey] = (paladinRoleBuildCounts[roleKey] or 0) + 1
			unit.hasKings = paladinRoleBuildCounts[roleKey] ~= 2
		end
		players[#players + 1] = unit
		classCounts[classFile] = (classCounts[classFile] or 0) + 1
		roleCounts[unit.role] = (roleCounts[unit.role] or 0) + 1
		return unit
	end

	local function chooseClass(list)
		for _ = 1, #list do
			local classFile = SimulationChoice(rng, list)
			if classFile ~= "PALADIN" or (classCounts.PALADIN or 0) < targetPaladins then
				return classFile
			end
		end
		for _, classFile in ipairs(list) do
			if classFile ~= "PALADIN" then
				return classFile
			end
		end
		return list[1]
	end

	addPlayer("PALADIN", ROLE_HEALER, nil, SIMULATION_LOCAL_PALADIN)
	addPlayer("WARRIOR", ROLE_TANK)
	addPlayer("PALADIN", ROLE_TANK)
	addPlayer("PALADIN", ROLE_DAMAGER)
	addPlayer("PRIEST", ROLE_HEALER)
	addPlayer("DRUID", ROLE_DAMAGER, SimulationDpsSpec("DRUID", rng))
	addPlayer("ROGUE", ROLE_DAMAGER)
	addPlayer("HUNTER", ROLE_DAMAGER)
	addPlayer("MAGE", ROLE_DAMAGER)
	addPlayer("WARLOCK", ROLE_DAMAGER)
	addPlayer("SHAMAN", ROLE_DAMAGER, SimulationDpsSpec("SHAMAN", rng))

	while roleCounts[ROLE_TANK] < targetTanks do
		local classFile = chooseClass(SIMULATION_TANK_CLASSES)
		addPlayer(classFile, ROLE_TANK, SimulationTankSpec(classFile))
	end

	while roleCounts[ROLE_HEALER] < targetHealers do
		local classFile = chooseClass(SIMULATION_HEALER_CLASSES)
		addPlayer(classFile, ROLE_HEALER, SimulationHealerSpec(classFile))
	end

	while (classCounts.PALADIN or 0) < targetPaladins do
		local role = ROLE_DAMAGER
		if roleCounts[ROLE_TANK] < targetTanks then
			role = ROLE_TANK
		elseif roleCounts[ROLE_HEALER] < targetHealers then
			role = ROLE_HEALER
		end
		addPlayer("PALADIN", role)
	end

	while #players < SIMULATION_ROSTER_SIZE do
		local classFile = chooseClass(SIMULATION_DPS_CLASSES)
		addPlayer(classFile, ROLE_DAMAGER, SimulationDpsSpec(classFile, rng))
	end

	for index = #players, 2, -1 do
		local swap = 2 + rng(index - 1) - 1
		players[index], players[swap] = players[swap], players[index]
	end

	for index, unit in ipairs(players) do
		unit.unit = "raid" .. tostring(index)
		unit.subgroup = math.floor((index - 1) / 5) + 1
		unit.rank = unit.name == SIMULATION_LOCAL_PALADIN and 2 or (unit.class == "PALADIN" and 1 or 0)
		unit.mainTank = NormalizeRole(unit.role) == ROLE_TANK
		unit.raidRole = SimulationRaidRole(unit.role)
	end

	local paladins = {}
	local context = {
		players = players,
		paladins = paladins,
		pallyCount = 0,
		playerName = SIMULATION_LOCAL_PALADIN,
		healingPaladinPresent = false,
		improvedWisdomPaladinPresent = false,
		simulation = true,
		simulationSeed = seed,
		simulationSummary = {
			tanks = roleCounts[ROLE_TANK] or 0,
			healers = roleCounts[ROLE_HEALER] or 0,
			dps = roleCounts[ROLE_DAMAGER] or 0,
			paladins = classCounts.PALADIN or 0,
		},
	}

	for _, unit in ipairs(players) do
		if unit.class == "PALADIN" then
			local paladin = DeepCopy(unit)
			paladin.hasAddon = true
			paladin.skills = self:BuildSimulationPaladinSkills(unit.role, unit.hasKings)
			paladin.auras = self:BuildSimulationPaladinAuras(unit.role)
			paladins[#paladins + 1] = paladin
			if NormalizeRole(paladin.role) == ROLE_HEALER then
				context.healingPaladinPresent = true
			end
			if PaladinHasImprovedWisdom(paladin) then
				context.improvedWisdomPaladinPresent = true
			end
		end
	end
	context.pallyCount = #paladins

	return context
end

function PPA:IsSimulationActive()
	return type(self.simulation) == "table" and self.simulation.active == true and type(self.simulation.context) == "table"
end

function PPA:GetSimulationUnit(identifier)
	if not self:IsSimulationActive() then
		return nil
	end
	if identifier == nil then
		return nil
	end
	local simulation = self.simulation
	return (simulation.unitsByToken and simulation.unitsByToken[identifier])
		or (simulation.unitsByName and simulation.unitsByName[identifier])
end

function PPA:PrepareSimulationUnitMaps(context)
	local unitsByToken = {}
	local unitsByName = {}
	local rosterByIndex = {}
	for index, unit in ipairs(context.players or {}) do
		rosterByIndex[index] = unit
		unitsByToken["raid" .. tostring(index)] = unit
		unitsByName[unit.name] = unit
		unitsByName[unit.fullName] = unit
		if unit.name == context.playerName then
			unitsByToken.player = unit
		end
	end
	self.simulation.unitsByToken = unitsByToken
	self.simulation.unitsByName = unitsByName
	self.simulation.rosterByIndex = rosterByIndex
	self:PrepareSimulationClassRoster(context)
end

function PPA:BuildSimulationClassRoster(context)
	local roster = {}
	local maxClassMembers = 0
	for classID = 1, self:GetMaxClasses() do
		roster[classID] = {}
	end

	for _, unit in ipairs((context and context.players) or {}) do
		local classID = SafeNumber(unit.classID or self:GetClassID(unit.class), 0)
		if classID > 0 then
			local entry = DeepCopy(unit)
			entry.classID = classID
			entry.class = entry.class or CLASS_FILES_BY_ID[classID]
			entry.unitid = entry.unitid or entry.unit
			entry.visible = false
			entry.hasbuff = false
			entry.specialbuff = false
			entry.dead = false
			roster[classID][#roster[classID] + 1] = entry
			if #roster[classID] > maxClassMembers then
				maxClassMembers = #roster[classID]
			end
		end
	end

	return roster, maxClassMembers
end

function PPA:PrepareSimulationClassRoster(context)
	if type(self.simulation) ~= "table" then
		return
	end
	local roster, maxClassMembers = self:BuildSimulationClassRoster(context or self.simulation.context)
	self.simulation.classRoster = roster
	self.simulation.maxClassMembers = maxClassMembers
end

function PPA:GetSimulationClassUnit(classID, playerID)
	if not self:IsSimulationActive() then
		return nil
	end
	classID = tonumber(classID)
	playerID = tonumber(playerID)
	if not classID or not playerID then
		return nil
	end
	if type(self.simulation.classRoster) ~= "table" then
		self:PrepareSimulationClassRoster(self.simulation.context)
	end
	local classRoster = self.simulation.classRoster and self.simulation.classRoster[classID]
	return classRoster and classRoster[playerID] or nil
end

function PPA:CloneSimulationContext(guess)
	local context = DeepCopy(self.simulation and self.simulation.context)
	if type(context) ~= "table" then
		return nil
	end

	context.alwaysPreferWisdomOnHealers = ContextAlwaysPreferWisdomOnHealers(context)
	context.alwaysPreferWisdomOnPaladinTanks = ContextAlwaysPreferWisdomOnPaladinTanks(context)
	context.healingPaladinPresent = false
	context.improvedWisdomPaladinPresent = false
	for _, unit in ipairs(context.players or {}) do
		self:ApplyManualChoice(unit)
		if guess then
			self:ApplyGuess(unit)
		end
	end
	for _, paladin in ipairs(context.paladins or {}) do
		self:ApplyManualChoice(paladin)
		if guess then
			self:ApplyGuess(paladin)
		end
		if NormalizeRole(paladin.role) == ROLE_HEALER then
			context.healingPaladinPresent = true
		end
		if PaladinHasImprovedWisdom(paladin) then
			context.improvedWisdomPaladinPresent = true
		end
	end
	return context
end

function PPA:WithSimulationUnitAPIs(callback)
	if not self:IsSimulationActive() then
		return callback()
	end
	if IsLiveClient() then
		error("Simulation unit API overrides are disabled in-game to avoid UI taint.")
	end

	local previous = {}
	local names = {
		"IsInRaid",
		"IsInGroup",
		"IsInInstance",
		"GetNumGroupMembers",
		"GetRaidRosterInfo",
		"GetInstanceInfo",
		"UnitExists",
		"GetUnitName",
		"UnitName",
		"UnitClassBase",
		"UnitClass",
		"UnitGroupRolesAssigned",
		"UnitIsGroupLeader",
		"UnitIsGroupAssistant",
		"UnitIsVisible",
		"UnitIsConnected",
		"UnitIsDeadOrGhost",
		"UnitBuff",
		"UnitGUID",
		"IsSpellInRange",
	}
	for _, name in ipairs(names) do
		previous[name] = _G[name]
	end

	local function unitFor(identifier)
		return PPA:GetSimulationUnit(identifier)
	end

	_G.IsInRaid = function()
		return true
	end
	_G.IsInGroup = function()
		return true
	end
	_G.IsInInstance = function()
		return false
	end
	_G.GetNumGroupMembers = function()
		return SIMULATION_ROSTER_SIZE
	end
	_G.GetRaidRosterInfo = function(index)
		local rosterIndex = SafeNumber(index, index)
		local unit = PPA.simulation and PPA.simulation.rosterByIndex and PPA.simulation.rosterByIndex[rosterIndex]
		if not unit then
			return nil
		end
		return unit.fullName, unit.rank or 0, unit.subgroup or 1, 70, ClassText(unit.classID), unit.class, "PPA Simulation", true, false, unit.raidRole
	end
	_G.GetInstanceInfo = function()
		return "PPA Simulation", "raid", 0, "Normal", SIMULATION_ROSTER_SIZE
	end
	_G.UnitExists = function(identifier)
		return unitFor(identifier) ~= nil
	end
	_G.GetUnitName = function(identifier)
		local unit = unitFor(identifier)
		return unit and unit.fullName or nil
	end
	_G.UnitName = function(identifier)
		local unit = unitFor(identifier)
		return unit and unit.name or nil
	end
	_G.UnitClassBase = function(identifier)
		local unit = unitFor(identifier)
		return unit and unit.class or nil
	end
	_G.UnitClass = function(identifier)
		local unit = unitFor(identifier)
		if unit then
			return ClassText(unit.classID), unit.class
		end
		return nil
	end
	_G.UnitGroupRolesAssigned = function(identifier)
		local unit = unitFor(identifier)
		return unit and NormalizeRole(unit.role) or ROLE_NONE
	end
	_G.UnitIsGroupLeader = function(identifier)
		local unit = unitFor(identifier)
		return unit and unit.rank == 2 or false
	end
	_G.UnitIsGroupAssistant = function(identifier)
		local unit = unitFor(identifier)
		return unit and unit.rank == 1 or false
	end
	_G.UnitIsVisible = function(identifier)
		return unitFor(identifier) ~= nil
	end
	_G.UnitIsConnected = function(identifier)
		return unitFor(identifier) ~= nil
	end
	_G.UnitIsDeadOrGhost = function()
		return false
	end
	_G.UnitBuff = function()
		return nil
	end
	_G.UnitGUID = function(identifier)
		local unit = unitFor(identifier)
		return unit and ("Player-PpaSim-" .. tostring(unit.unit or unit.name)) or nil
	end
	_G.IsSpellInRange = function(_, identifier)
		return unitFor(identifier) and 1 or 0
	end

	local results = {pcall(callback)}
	for _, name in ipairs(names) do
		_G[name] = previous[name]
	end
	if not results[1] then
		error(results[2])
	end
	table.remove(results, 1)
	return Unpack(results)
end

function PPA:CollectRoster()
	local players = {}
	local units = {}
	local showPets = not (_G.PallyPower and _G.PallyPower.opt and _G.PallyPower.opt.ShowPets == false)

	if _G.IsInRaid and _G.IsInRaid() then
		local maxRaid = _G.MAX_RAID_MEMBERS or 40
		for index = 1, maxRaid do
			units[#units + 1] = {"raid" .. index, index, false}
			if showPets then
				units[#units + 1] = {"raidpet" .. index, index, true}
			end
		end
	else
		units[#units + 1] = {"player", nil, false}
		if showPets then
			units[#units + 1] = {"pet", nil, true}
		end
		local maxParty = _G.MAX_PARTY_MEMBERS or 4
		for index = 1, maxParty do
			units[#units + 1] = {"party" .. index, nil, false}
			if showPets then
				units[#units + 1] = {"partypet" .. index, nil, true}
			end
		end
	end

	for _, unitInfo in ipairs(units) do
		local unit = unitInfo[1]
		local raidIndex = unitInfo[2]
		local isPet = unitInfo[3]
		if (not _G.UnitExists) or _G.UnitExists(unit) then
			local fullName = GetUnitNameSafe(unit)
			local classFile
			if _G.UnitClassBase then
				classFile = _G.UnitClassBase(unit)
			elseif _G.UnitClass then
				classFile = select(2, _G.UnitClass(unit))
			end

			if fullName and classFile and self:GetClassID(classFile) then
				local raidRole
				local subgroup = 1
				local rank = 0
				if raidIndex and _G.GetRaidRosterInfo then
					local rosterName, rosterRank, rosterSubgroup, _, _, rosterClass, _, _, _, rosterRole = _G.GetRaidRosterInfo(raidIndex)
					if rosterName and not isPet then
						fullName = rosterName
					end
					rank = rosterRank or rank
					subgroup = rosterSubgroup or subgroup
					if not isPet then
						classFile = rosterClass or classFile
						raidRole = rosterRole
					end
				elseif _G.UnitIsGroupLeader and _G.UnitIsGroupLeader(unit) then
					rank = 2
				end

				local role = NormalizeRole(raidRole)
				local mainTank = role == ROLE_TANK
				if role == ROLE_NONE and _G.UnitGroupRolesAssigned then
					role = NormalizeRole(_G.UnitGroupRolesAssigned(unit))
				end

				local name = RemoveRealmName(fullName)
				local player = {
					unit = unit,
					key = fullName,
					name = name,
					fullName = fullName,
					class = classFile,
					classID = self:GetClassID(classFile),
					role = role,
					subgroup = subgroup,
					rank = rank,
					mainTank = mainTank,
					isPet = isPet == true,
				}

				self:ApplyManualChoice(player)
				players[#players + 1] = player
			end
		end
	end

	return players
end

function PPA:GetCurrentPvPInstanceType()
	if _G.IsInInstance then
		local ok, inInstance, instanceType = pcall(_G.IsInInstance)
		if ok and inInstance and IsPvPInstanceType(instanceType) then
			return instanceType
		end
	end
	if _G.GetInstanceInfo then
		local ok, _, instanceType = pcall(_G.GetInstanceInfo)
		if ok and IsPvPInstanceType(instanceType) then
			return instanceType
		end
	end
	return nil
end

function PPA:BuildRuntimeContext(guess)
	self:EnsureDB()
	if self:IsSimulationActive() then
		return self:CloneSimulationContext(guess)
	end
	self:RefreshPallyPowerState()

	local players = self:CollectRoster()
	local paladins = {}
	local pvpInstanceType = self:GetCurrentPvPInstanceType()
	for _, unit in ipairs(players) do
		if unit.class == "PALADIN" then
			local hasAddon = type(_G.AllPallys) == "table" and type(_G.AllPallys[unit.name]) == "table"
			local specData = self:GetUnitSpecData(unit.name)
			local skills = hasAddon and self:BuildPaladinSkills(unit.name) or {}
			local role = unit.role
			if NormalizeRole(role) == ROLE_NONE then
				role = self:InferPaladinRoleFromSkills(skills) or role
				unit.role = role
			end
			paladins[#paladins + 1] = {
				name = unit.name,
				fullName = unit.fullName,
				key = unit.key,
				class = "PALADIN",
				classID = CLASS_ID.PALADIN,
				role = role,
				spec = unit.spec,
				subgroup = unit.subgroup,
				hasAddon = hasAddon,
				skills = skills,
				auras = hasAddon and self:BuildPaladinAuras(unit.name) or {},
				specData = specData,
			}
		end
	end

	local context = {
		players = players,
		paladins = paladins,
		pallyCount = #paladins,
		playerName = _G.PallyPower and _G.PallyPower.player or (_G.UnitName and _G.UnitName("player")) or "",
		healingPaladinPresent = false,
		improvedWisdomPaladinPresent = false,
		alwaysPreferWisdomOnHealers = ContextAlwaysPreferWisdomOnHealers(),
		alwaysPreferWisdomOnPaladinTanks = ContextAlwaysPreferWisdomOnPaladinTanks(),
		pvpInstance = pvpInstanceType ~= nil,
		pvpInstanceType = pvpInstanceType,
	}

	for _, unit in ipairs(players) do
		if guess then
			self:ApplyGuess(unit)
		end
	end
	for _, paladin in ipairs(paladins) do
		if guess then
			self:ApplyGuess(paladin)
		end
		if NormalizeRole(paladin.role) == ROLE_HEALER then
			context.healingPaladinPresent = true
		end
		if PaladinHasImprovedWisdom(paladin) then
			context.improvedWisdomPaladinPresent = true
		end
	end

	for _, unit in ipairs(players) do
		if NormalizeRole(unit.role) == ROLE_HEALER and unit.class == "PALADIN" then
			context.healingPaladinPresent = true
		end
	end

	return context
end

local function EnsurePallyPowerAssignmentTable(name)
	if type(_G.PallyPower_Assignments) ~= "table" then
		_G.PallyPower_Assignments = {}
	end
	if type(_G.PallyPower_Assignments[name]) ~= "table" then
		_G.PallyPower_Assignments[name] = {}
	end
	return _G.PallyPower_Assignments[name]
end

local function EnsurePallyPowerNormalTable(name, classID)
	if type(_G.PallyPower_NormalAssignments) ~= "table" then
		_G.PallyPower_NormalAssignments = {}
	end
	if type(_G.PallyPower_NormalAssignments[name]) ~= "table" then
		_G.PallyPower_NormalAssignments[name] = {}
	end
	if type(_G.PallyPower_NormalAssignments[name][classID]) ~= "table" then
		_G.PallyPower_NormalAssignments[name][classID] = {}
	end
	return _G.PallyPower_NormalAssignments[name][classID]
end

local function EnsurePallyPowerAuraAssignments()
	if type(_G.PallyPower_AuraAssignments) ~= "table" then
		_G.PallyPower_AuraAssignments = {}
	end
	return _G.PallyPower_AuraAssignments
end

function PPA:CapturePallyPowerState()
	local pallyPower = _G.PallyPower
	return {
		AllPallys = DeepCopy(_G.AllPallys),
		SyncList = DeepCopy(_G.SyncList),
		PallyPower_Assignments = DeepCopy(_G.PallyPower_Assignments),
		PallyPower_NormalAssignments = DeepCopy(_G.PallyPower_NormalAssignments),
		PallyPower_AuraAssignments = DeepCopy(_G.PallyPower_AuraAssignments),
		PP_Leader = _G.PP_Leader,
		player = pallyPower and pallyPower.player,
		freeassign = pallyPower and pallyPower.opt and pallyPower.opt.freeassign,
	}
end

function PPA:SaveSimulationRestorePoint(state)
	local db = self:EnsureDB()
	db.simulationRestore = {
		PallyPower_Assignments = DeepCopy(state and state.PallyPower_Assignments),
		PallyPower_NormalAssignments = DeepCopy(state and state.PallyPower_NormalAssignments),
		PallyPower_AuraAssignments = DeepCopy(state and state.PallyPower_AuraAssignments),
		player = state and state.player,
		freeassign = state and state.freeassign,
		PP_Leader = state and state.PP_Leader,
	}
	db.simulationActive = true
end

function PPA:RestorePallyPowerState(state)
	local db = self:EnsureDB()
	state = state or db.simulationRestore
	if type(state) ~= "table" then
		return false
	end

	if state.AllPallys ~= nil then
		_G.AllPallys = DeepCopy(state.AllPallys)
	end
	if state.SyncList ~= nil then
		_G.SyncList = DeepCopy(state.SyncList)
	end
	_G.PallyPower_Assignments = DeepCopy(state.PallyPower_Assignments) or {}
	_G.PallyPower_NormalAssignments = DeepCopy(state.PallyPower_NormalAssignments) or {}
	_G.PallyPower_AuraAssignments = DeepCopy(state.PallyPower_AuraAssignments) or {}
	if _G.PallyPower then
		if state.player then
			_G.PallyPower.player = state.player
		end
		if _G.PallyPower.opt and state.freeassign ~= nil then
			_G.PallyPower.opt.freeassign = state.freeassign
		end
	end
	if state.PP_Leader ~= nil then
		_G.PP_Leader = state.PP_Leader
	end

	db.simulationRestore = nil
	db.simulationActive = nil
	return true
end

function PPA:RestoreStaleSimulationState()
	local db = self:EnsureDB()
	if self:IsSimulationActive() or type(db.simulationRestore) ~= "table" then
		return
	end
	if self:RestorePallyPowerState(db.simulationRestore) then
		Print("Restored PallyPower assignments from the previous PPA simulation session.")
	end
end

function PPA:SeedPallyPowerSimulation(context)
	_G.AllPallys = {}
	_G.SyncList = {}
	_G.PallyPower_Assignments = {}
	_G.PallyPower_NormalAssignments = {}
	_G.PallyPower_AuraAssignments = {}

	for _, paladin in ipairs(context.paladins or {}) do
		local info = DeepCopy(paladin.skills) or {}
		info.AuraInfo = DeepCopy(paladin.auras) or {}
		info.CooldownInfo = {
			[1] = {start = 0, duration = 0},
			[2] = {start = 0, duration = 0},
		}
		info.symbols = 200
		info.freeassign = true
		info.subgroup = paladin.subgroup or 1
		_G.AllPallys[paladin.name] = info

		_G.PallyPower_Assignments[paladin.name] = {}
		for classID = 1, self:GetMaxClasses() do
			_G.PallyPower_Assignments[paladin.name][classID] = 0
		end
		_G.PallyPower_NormalAssignments[paladin.name] = {}
		_G.PallyPower_AuraAssignments[paladin.name] = 0
		_G.SyncList[#_G.SyncList + 1] = paladin.name
	end
	table.sort(_G.SyncList)

	if _G.PallyPower then
		_G.PallyPower.player = context.playerName
		if type(_G.PallyPower.opt) ~= "table" then
			_G.PallyPower.opt = {}
		end
		_G.PallyPower.opt.freeassign = true
	end
	_G.PP_Leader = true
end

function PPA:RenderSimulationBlessingsGrid()
	if not self:IsSimulationActive() or not _G.PallyPower then
		return false
	end

	local frame = _G.PallyPowerBlessingsFrame
	if frame and frame.IsVisible and not frame:IsVisible() then
		return false
	end

	local pallyPower = _G.PallyPower
	local maxClasses = self:GetMaxClasses()
	local maxPerClass = SafeNumber(_G.PALLYPOWER_MAXPERCLASS, 15)
	local maxClassMembers = 0
	if type(self.simulation.classRoster) ~= "table" then
		self:PrepareSimulationClassRoster(self.simulation.context)
	end

	for classID = 1, maxClasses do
		local groupName = "PallyPowerBlessingsFrameClassGroup" .. tostring(classID)
		local classIcon = _G[groupName .. "ClassButtonIcon"]
		if classIcon and classIcon.SetTexture then
			classIcon:SetTexture(pallyPower.ClassIcons and pallyPower.ClassIcons[classID] or nil)
		end

		local classRoster = (self.simulation.classRoster and self.simulation.classRoster[classID]) or {}
		if #classRoster > maxClassMembers then
			maxClassMembers = #classRoster
		end
		for playerID = 1, maxPerClass do
			local buttonName = groupName .. "PlayerButton" .. tostring(playerID)
			local button = _G[buttonName]
			local unit = classRoster[playerID]
			if button and unit then
				self:InstallSimulationPlayerButtonWrapper(button)
				local text = _G[buttonName .. "Text"]
				if text and text.SetText then
					local shortName = unit.name
					if _G.Ambiguate then
						shortName = _G.Ambiguate(unit.fullName or unit.name, "short")
					end
					text:SetText(shortName)
				end
				local icon = _G[buttonName .. "Icon"]
				if icon and icon.SetTexture then
					local normal, greater = 0, 0
					if pallyPower.GetSpellID then
						normal, greater = pallyPower:GetSpellID(classID, unit.name)
					end
					if normal and greater and normal ~= greater then
						icon:SetTexture(pallyPower.NormalBlessingIcons and pallyPower.NormalBlessingIcons[normal] or nil)
					else
						icon:SetTexture("")
					end
				end
				if button.Show then
					button:Show()
				end
			elseif button and button.Hide then
				button:Hide()
			end
		end
	end

	local numPallys = 0
	if type(_G.SyncList) == "table" then
		for _ in pairs(_G.SyncList) do
			numPallys = numPallys + 1
		end
	end
	if frame then
		if frame.SetScale then
			frame:SetScale(pallyPower.opt and pallyPower.opt.configscale or 1)
		end
		if frame.SetHeight then
			frame:SetHeight(14 + 24 + 56 + (numPallys * 100) + 22 + 13 * maxClassMembers)
		end
	end

	local firstPlayer = _G.PallyPowerBlessingsFramePlayer1
	if firstPlayer and firstPlayer.SetPoint then
		firstPlayer:SetPoint("TOPLEFT", 8, -80 - 13 * maxClassMembers)
	end
	for classID = 1, maxClasses do
		local line = _G["PallyPowerBlessingsFrameClassGroup" .. tostring(classID) .. "Line"]
		if line and line.SetHeight then
			line:SetHeight(56 + 13 * maxClassMembers)
		end
	end
	local auraLine = _G.PallyPowerBlessingsFrameAuraGroup1Line
	if auraLine and auraLine.SetHeight then
		auraLine:SetHeight(56 + 13 * maxClassMembers)
	end
	local freeAssign = _G.PallyPowerBlessingsFrameFreeAssign
	if freeAssign and freeAssign.SetChecked then
		freeAssign:SetChecked(pallyPower.opt and pallyPower.opt.freeassign or false)
	end

	return true
end

function PPA:GetSimulationPlayerButtonUnit(button)
	if not button or not button.GetName then
		return nil
	end
	local classID, playerID = string.match(button:GetName() or "", "PallyPowerBlessingsFrameClassGroup(%d+)PlayerButton(%d+)")
	return self:GetSimulationClassUnit(classID, playerID), tonumber(classID), tonumber(playerID)
end

function PPA:HandleSimulationPlayerButtonClick(button, mouseButton)
	local unit, classID = self:GetSimulationPlayerButtonUnit(button)
	if not unit then
		return false
	end
	if _G.InCombatLockdown and _G.InCombatLockdown() then
		return true
	end
	if type(_G.PallyPowerGrid_NormalBlessingMenu) == "function" then
		_G.PallyPowerGrid_NormalBlessingMenu(button, mouseButton, unit.name, classID)
	end
	return true
end

function PPA:HandleSimulationPlayerButtonMouseWheel(button, delta)
	local unit, classID = self:GetSimulationPlayerButtonUnit(button)
	if not unit then
		return false
	end
	if _G.InCombatLockdown and _G.InCombatLockdown() then
		return true
	end
	if _G.PallyPower and _G.PallyPower.PerformPlayerCycle then
		_G.PallyPower:PerformPlayerCycle(delta, unit.name, classID)
	end
	return true
end

local function ConfigureSimulationPlayerButton(button)
	if button.Enable then
		button:Enable()
	end
	if button.EnableMouse then
		button:EnableMouse(true)
	end
	if button.RegisterForClicks then
		button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	end
	if button.EnableMouseWheel then
		button:EnableMouseWheel(true)
	end
	if button.SetFrameLevel and button.GetParent then
		local parent = button:GetParent()
		if parent and parent.GetFrameLevel then
			local parentLevel = parent:GetFrameLevel()
			if parentLevel then
				button:SetFrameLevel(parentLevel + 10)
			end
		end
	end
end

function PPA:InstallSimulationPlayerButtonWrapper(button)
	if not button or type(button.SetScript) ~= "function" then
		return
	end
	ConfigureSimulationPlayerButton(button)

	local currentClick = button.GetScript and button:GetScript("OnClick")
	if not button.ppaSimulationButtonClickWrapper then
		button.ppaSimulationButtonOriginalClick = currentClick
		button.ppaSimulationButtonClickWrapper = function(selfButton, mouseButton, ...)
			if PPA:IsSimulationActive() and PPA:HandleSimulationPlayerButtonClick(selfButton, mouseButton) then
				return
			end
			local originalClick = selfButton.ppaSimulationButtonOriginalClick
			if originalClick then
				return originalClick(selfButton, mouseButton, ...)
			end
		end
	elseif currentClick and currentClick ~= button.ppaSimulationButtonClickWrapper then
		button.ppaSimulationButtonOriginalClick = currentClick
	end
	if currentClick ~= button.ppaSimulationButtonClickWrapper then
		button:SetScript("OnClick", button.ppaSimulationButtonClickWrapper)
	end

	local currentWheel = button.GetScript and button:GetScript("OnMouseWheel")
	if not button.ppaSimulationButtonWheelWrapper then
		button.ppaSimulationButtonOriginalWheel = currentWheel
		button.ppaSimulationButtonWheelWrapper = function(selfButton, delta, ...)
			if PPA:IsSimulationActive() and PPA:HandleSimulationPlayerButtonMouseWheel(selfButton, delta) then
				return
			end
			local originalWheel = selfButton.ppaSimulationButtonOriginalWheel
			if originalWheel then
				return originalWheel(selfButton, delta, ...)
			end
		end
	elseif currentWheel and currentWheel ~= button.ppaSimulationButtonWheelWrapper then
		button.ppaSimulationButtonOriginalWheel = currentWheel
	end
	if currentWheel ~= button.ppaSimulationButtonWheelWrapper then
		button:SetScript("OnMouseWheel", button.ppaSimulationButtonWheelWrapper)
	end
	button.ppaSimulationButtonHooked = true
end

function PPA:InstallSimulationFrameHooks()
	if not self.simulationGridUpdateHookInstalled and type(_G.PallyPowerBlessingsGrid_Update) == "function" then
		local originalGridUpdate = _G.PallyPowerBlessingsGrid_Update
		_G.PallyPowerBlessingsGrid_Update = function(...)
			originalGridUpdate(...)
			if PPA:IsSimulationActive() then
				PPA:RenderSimulationBlessingsGrid()
			end
		end
		self.simulationGridUpdateHookInstalled = true
	end

	if not self.simulationPlayerButtonClickHookInstalled and type(_G.PallyPowerPlayerButton_OnClick) == "function" then
		local originalClick = _G.PallyPowerPlayerButton_OnClick
		_G.PallyPowerPlayerButton_OnClick = function(button, mouseButton, ...)
			if PPA:IsSimulationActive() and PPA:HandleSimulationPlayerButtonClick(button, mouseButton) then
				return
			end
			return originalClick(button, mouseButton, ...)
		end
		self.simulationPlayerButtonClickHookInstalled = true
	end

	if not self.simulationPlayerButtonWheelHookInstalled and type(_G.PallyPowerPlayerButton_OnMouseWheel) == "function" then
		local originalWheel = _G.PallyPowerPlayerButton_OnMouseWheel
		_G.PallyPowerPlayerButton_OnMouseWheel = function(button, delta, ...)
			if PPA:IsSimulationActive() and PPA:HandleSimulationPlayerButtonMouseWheel(button, delta) then
				return
			end
			return originalWheel(button, delta, ...)
		end
		self.simulationPlayerButtonWheelHookInstalled = true
	end
end

function PPA:InstallSimulationHooks()
	local pallyPower = _G.PallyPower
	self:InstallSimulationFrameHooks()
	if not pallyPower or self.simulationHooksInstalledFor == pallyPower then
		return
	end
	self.simulationHooksInstalledFor = pallyPower

	local function wrapNoopDuringSimulation(methodName)
		local original = pallyPower[methodName]
		if type(original) ~= "function" then
			return
		end
		pallyPower[methodName] = function(target, ...)
			if PPA:IsSimulationActive() then
				if methodName == "UpdateRoster" then
					PPA:PrepareSimulationClassRoster()
					PPA:RenderSimulationBlessingsGrid()
				end
				return
			end
			return original(target, ...)
		end
	end

	local originalGetUnit = pallyPower.GetUnit
	if type(originalGetUnit) == "function" then
		pallyPower.GetUnit = function(target, classID, playerID)
			if PPA:IsSimulationActive() then
				local unit = PPA:GetSimulationClassUnit(classID, playerID)
				if unit then
					return unit
				end
			end
			return originalGetUnit(target, classID, playerID)
		end
	end

	local originalGetUnitIdByName = pallyPower.GetUnitIdByName
	if type(originalGetUnitIdByName) == "function" then
		pallyPower.GetUnitIdByName = function(target, name)
			if PPA:IsSimulationActive() then
				local unit = PPA:GetSimulationUnit(name)
				if unit then
					return unit.unit
				end
			end
			return originalGetUnitIdByName(target, name)
		end
	end

	local originalCanBuffBlessing = pallyPower.CanBuffBlessing
	if type(originalCanBuffBlessing) == "function" then
		pallyPower.CanBuffBlessing = function(target, spellID, greaterSpellID, unitID, config)
			local unit = PPA:IsSimulationActive() and PPA:GetSimulationUnit(unitID)
			if unit then
				local normalSpell
				local greaterSpell
				spellID = SafeNumber(spellID, 0)
				greaterSpellID = SafeNumber(greaterSpellID, 0)
				if spellID > 0 then
					normalSpell = target.Spells and target.Spells[spellID]
				end
				if not target.isWrath and spellID == 7 and unit.name == target.player then
					normalSpell = nil
				end
				if greaterSpellID > 0 then
					greaterSpell = target.GSpells and target.GSpells[greaterSpellID]
				end
				return normalSpell, greaterSpell
			end
			return originalCanBuffBlessing(target, spellID, greaterSpellID, unitID, config)
		end
	end

	local originalCheckLeader = pallyPower.CheckLeader
	if type(originalCheckLeader) == "function" then
		pallyPower.CheckLeader = function(target, name)
			if PPA:IsSimulationActive() then
				local unit = PPA:GetSimulationUnit(name)
				if unit and SafeNumber(unit.rank, 0) > 0 then
					return true
				end
			end
			return originalCheckLeader(target, name)
		end
	end

	wrapNoopDuringSimulation("UpdateRoster")
	wrapNoopDuringSimulation("AutoAssign")
	wrapNoopDuringSimulation("UpdateAllPallys")
	wrapNoopDuringSimulation("ScanSpells")
	wrapNoopDuringSimulation("ScanCooldowns")
	wrapNoopDuringSimulation("ScanInventory")
	wrapNoopDuringSimulation("SendSelf")
	wrapNoopDuringSimulation("SendMessage")
end

function PPA:InstallAssignmentActionHooks()
	local pallyPower = _G.PallyPower
	if not pallyPower or self.assignmentActionHooksInstalledFor == pallyPower then
		return
	end
	self.assignmentActionHooksInstalledFor = pallyPower

	local originalAutoAssign = pallyPower.AutoAssign
	if type(originalAutoAssign) == "function" then
		pallyPower.AutoAssign = function(target, ...)
			local result = originalAutoAssign(target, ...)
			if not PPA:IsSimulationActive() then
				PPA:NoteLocalAssignmentAction("Auto-Assign")
			end
			return result
		end
	end
end

function PPA:OpenAssignmentFrame()
	if not _G.PallyPower then
		Print("PallyPower is required.")
		return false
	end
	self:HookPallyPower()
	local frame = _G.PallyPowerBlessingsFrame
	if not frame then
		Print("PallyPower's assignment frame is not available yet.")
		return false
	end

	if _G.PallyPowerConfigFrame and _G.PallyPowerConfigFrame.IsShown and _G.PallyPowerConfigFrame:IsShown() then
		_G.PallyPowerConfigFrame:Hide()
	end
	if frame.ClearAllPoints then
		frame:ClearAllPoints()
	end
	if frame.SetPoint then
		frame:SetPoint("CENTER", _G.UIParent or "UIParent", "CENTER", 0, 0)
	end
	if frame.Show then
		frame:Show()
	end
	if type(_G.UISpecialFrames) == "table" then
		local found = false
		for _, name in ipairs(_G.UISpecialFrames) do
			if name == "PallyPowerBlessingsFrame" then
				found = true
				break
			end
		end
		if not found then
			table.insert(_G.UISpecialFrames, "PallyPowerBlessingsFrame")
		end
	end
	if self:IsSimulationActive() and _G.PallyPower.UpdateLayout then
		_G.PallyPower:UpdateLayout()
	elseif _G.PallyPower.UpdateRoster then
		_G.PallyPower:UpdateRoster()
	elseif _G.PallyPower.UpdateLayout then
		_G.PallyPower:UpdateLayout()
	end
	self:CreateSmartButton()
	self:ReflowButtons()
	if self:IsSimulationActive() then
		self:RenderSimulationBlessingsGrid()
	end
	return true
end

function PPA:ActivateSimulation(seed)
	if _G.InCombatLockdown and _G.InCombatLockdown() then
		Print("Simulation cannot start in combat.")
		return false
	end
	if not _G.PallyPower then
		Print("PallyPower is required.")
		return false
	end

	self:InstallSimulationHooks()
	local previous = self:IsSimulationActive() and self.simulation.previous or self:CapturePallyPowerState()
	if not self:IsSimulationActive() then
		self:SaveSimulationRestorePoint(previous)
	end

	local context = self:BuildSimulationContext(seed or self:GetNextSimulationSeed())
	self.simulation = {
		active = true,
		context = context,
		previous = previous,
	}
	self:PrepareSimulationUnitMaps(context)
	self:SeedPallyPowerSimulation(context)
	self:OpenAssignmentFrame()

	local summary = context.simulationSummary or {}
	Print(string.format(
		"Simulation raid active: %d players, %d tanks, %d healers, %d DPS, %d paladins.",
		#(context.players or {}),
		SafeNumber(summary.tanks, 0),
		SafeNumber(summary.healers, 0),
		SafeNumber(summary.dps, 0),
		SafeNumber(summary.paladins, 0)
	))
	Print("Run /ppa smart or click Smart-Assign. /ppa simulate off restores your previous PallyPower state.")
	return true
end

function PPA:DeactivateSimulation()
	if not self:IsSimulationActive() then
		local restored = self:RestorePallyPowerState()
		Print(restored and "Simulation state restored." or "No PPA simulation is active.")
		return restored
	end

	local previous = self.simulation.previous
	self.simulation = nil
	local restored = self:RestorePallyPowerState(previous)
	if _G.PallyPower then
		if _G.PallyPower.ScanSpells then
			pcall(_G.PallyPower.ScanSpells, _G.PallyPower)
		end
		if _G.PallyPower.ScanCooldowns then
			pcall(_G.PallyPower.ScanCooldowns, _G.PallyPower)
		end
		if _G.PallyPower.ScanInventory then
			pcall(_G.PallyPower.ScanInventory, _G.PallyPower)
		end
		if _G.PallyPower.UpdateRoster then
			pcall(_G.PallyPower.UpdateRoster, _G.PallyPower)
		elseif _G.PallyPower.UpdateLayout then
			pcall(_G.PallyPower.UpdateLayout, _G.PallyPower)
		end
	end
	Print(restored and "PPA simulation disabled and previous PallyPower state restored." or "PPA simulation disabled.")
	return true
end

function PPA:AssignmentString(assignments)
	local maxClasses = _G.PALLYPOWER_MAXCLASSES or 9
	local parts = {}
	for classID = 1, maxClasses do
		local value = assignments and assignments[classID] or 0
		if not value or value == 0 then
			parts[#parts + 1] = "n"
		else
			parts[#parts + 1] = tostring(value)
		end
	end
	return table.concat(parts, "")
end

function PPA:ShouldSendPlanForPaladin(paladinName, context)
	if not self:ShouldWarnSmartAssignRaidAuthority() then
		return true
	end
	local playerName = RemoveRealmName(context and context.playerName or (_G.PallyPower and _G.PallyPower.player))
	return playerName and RemoveRealmName(paladinName) == playerName
end

function PPA:SendPlanMessages(plan, context)
	if not _G.PallyPower or not _G.PallyPower.SendMessage then
		return
	end

	for paladinName, assignments in pairs(plan.assignments or {}) do
		if self:ShouldSendPlanForPaladin(paladinName, context) then
			_G.PallyPower:SendMessage("PASSIGN " .. paladinName .. "@" .. self:AssignmentString(assignments))
		end
	end

	local normalList = {}
	for paladinName, classMap in pairs(plan.normalAssignments or {}) do
		if self:ShouldSendPlanForPaladin(paladinName, context) then
			for classID, targets in pairs(classMap) do
				for targetName, buff in pairs(targets) do
					normalList[#normalList + 1] = string.format("%s %s %s %s", paladinName, classID, targetName, buff)
				end
			end
		end
	end
	for offset = 1, #normalList, 5 do
		_G.PallyPower:SendMessage("NASSIGN " .. table.concat(normalList, "@", offset, math.min(offset + 4, #normalList)))
	end

	for paladinName, aura in pairs(plan.auraAssignments or {}) do
		if self:ShouldSendPlanForPaladin(paladinName, context) then
			_G.PallyPower:SendMessage("AASSIGN " .. paladinName .. " " .. SafeNumber(aura, 0))
		end
	end
end

function PPA:ClearManagedNormalAssignments(context, plan)
	local managedTargets = {}
	local function mark(classID, targetName)
		classID = SafeNumber(classID, 0)
		targetName = RemoveRealmName(targetName)
		if classID <= 0 or not targetName or targetName == "" then
			return
		end
		if not managedTargets[classID] then
			managedTargets[classID] = {}
		end
		managedTargets[classID][targetName] = true
	end

	for _, unit in ipairs(context and context.players or {}) do
		mark(unit.classID, unit.name)
		mark(unit.classID, unit.fullName)
	end
	for _, classMap in pairs(plan and plan.normalAssignments or {}) do
		for classID, targets in pairs(classMap or {}) do
			for targetName in pairs(targets or {}) do
				mark(classID, targetName)
			end
		end
	end

	for _, classMap in pairs(_G.PallyPower_NormalAssignments or {}) do
		for classID, targets in pairs(classMap or {}) do
			local managed = managedTargets[SafeNumber(classID, 0)]
			if managed then
				for targetName in pairs(targets or {}) do
					if managed[RemoveRealmName(targetName)] then
						targets[targetName] = nil
					end
				end
			end
		end
	end
end

function PPA:ApplyPlan(plan, context)
	if not _G.PallyPower then
		Print("PallyPower is not loaded.")
		return false
	end

	local simulation = context and context.simulation == true
	if not simulation and _G.PallyPower.ClearAssignments then
		_G.PallyPower:ClearAssignments(_G.PallyPower.player, true)
	end
	if not simulation and _G.PallyPower.SendMessage then
		_G.PallyPower:SendMessage("CLEAR SKIP")
	end

	for _, paladin in ipairs(context.paladins or {}) do
		if paladin.hasAddon then
			local tableForPaladin = EnsurePallyPowerAssignmentTable(paladin.name)
			for classID = 1, (_G.PALLYPOWER_MAXCLASSES or 9) do
				tableForPaladin[classID] = 0
			end
		end
	end

	for paladinName, classMap in pairs(plan.assignments) do
		local tableForPaladin = EnsurePallyPowerAssignmentTable(paladinName)
		for classID, buff in pairs(classMap) do
			tableForPaladin[classID] = buff
		end
	end

	self:ClearManagedNormalAssignments(context, plan)

	for paladinName, classMap in pairs(plan.normalAssignments or {}) do
		for classID, targets in pairs(classMap) do
			local normalTable = EnsurePallyPowerNormalTable(paladinName, classID)
			for targetName, buff in pairs(targets) do
				normalTable[targetName] = buff
			end
		end
	end

	local auraAssignments = EnsurePallyPowerAuraAssignments()
	for _, paladin in ipairs(context.paladins or {}) do
		if paladin.hasAddon then
			auraAssignments[paladin.name] = SafeNumber(plan.auraAssignments and plan.auraAssignments[paladin.name], 0)
		end
	end
	if not simulation then
		self:NoteLocalAssignmentAction("Smart-Assign")
	end

	local function afterAssignments()
		if not simulation then
			self:SendPlanMessages(plan, context)
		end
		if _G.PallyPower.UpdateRoster then
			_G.PallyPower:UpdateRoster()
		end
		if _G.PallyPower.UpdateLayout then
			_G.PallyPower:UpdateLayout()
		end
		if simulation then
			self:RenderSimulationBlessingsGrid()
		end
	end

	if _G.C_Timer and _G.C_Timer.After then
		_G.C_Timer.After(0.25, afterAssignments)
	else
		afterAssignments()
	end

	return true
end

function PPA:PrintManualAssignments(plan)
	for paladinName, manual in pairs(plan.manualAssignments or {}) do
		local classPieces = {}
		for classID, buff in pairs(manual.greater or {}) do
			classPieces[#classPieces + 1] = LongBuffText(buff) .. " on " .. ClassText(classID)
		end
		table.sort(classPieces)
		if #classPieces > 0 then
			Print("Ask " .. paladinName .. " to cast " .. table.concat(classPieces, ", ") .. ".")
		end
		for _, normal in ipairs(manual.normal or {}) do
			Print("Ask " .. paladinName .. " to single-buff " .. normal.targetName .. " with " .. LongBuffText(normal.buff) .. " instead of " .. BuffText(normal.replaced) .. ".")
		end
		if manual.aura then
			Print("Ask " .. paladinName .. " to use " .. AuraText(manual.aura) .. ".")
		end
	end
end

function PPA:GetBlessingsReportPaladinNames()
	local names = {}
	local seen = {}
	local function add(name)
		name = RemoveRealmName(name)
		if name and name ~= "" and not seen[name] then
			seen[name] = true
			names[#names + 1] = name
		end
	end

	for _, name in ipairs(_G.SyncList or {}) do
		add(name)
	end
	for name in pairs(_G.AllPallys or {}) do
		add(name)
	end
	for name in pairs(_G.PallyPower_Assignments or {}) do
		add(name)
	end
	for name in pairs(_G.PallyPower_NormalAssignments or {}) do
		add(name)
	end
	for name in pairs(_G.PallyPower_AuraAssignments or {}) do
		add(name)
	end
	return names
end

function PPA:BuildLocalBlessingsReportLinesForPaladin(paladinName)
	local grouped = {}
	local buffs = {}
	local function groupForBuff(buff)
		buff = SafeNumber(buff, 0)
		if buff <= 0 then
			return nil
		end
		if not grouped[buff] then
			grouped[buff] = {
				classes = {},
				singles = {},
			}
			buffs[#buffs + 1] = buff
		end
		return grouped[buff]
	end

	local greater = _G.PallyPower_Assignments and _G.PallyPower_Assignments[paladinName]
	for classID = 1, self:GetMaxClasses() do
		local buff = SafeNumber(greater and greater[classID], 0)
		local group = groupForBuff(buff)
		if group then
			group.classes[#group.classes + 1] = ClassPluralText(classID)
		end
	end

	local normal = _G.PallyPower_NormalAssignments and _G.PallyPower_NormalAssignments[paladinName]
	if type(normal) == "table" then
		for _, targets in pairs(normal) do
			if type(targets) == "table" then
				for targetName, buff in pairs(targets) do
					buff = SafeNumber(buff, 0)
					local group = groupForBuff(buff)
					if group then
						group.singles[#group.singles + 1] = targetName
					end
				end
			end
		end
	end

	local lines = {}
	table.sort(buffs)
	for _, buff in ipairs(buffs) do
		local entry = grouped[buff]
		table.sort(entry.singles)
		local pieces = {}
		if #entry.classes > 0 then
			pieces[#pieces + 1] = JoinList(entry.classes)
		end
		if #entry.singles > 0 then
			pieces[#pieces + 1] = "single " .. JoinList(entry.singles)
		end
		if #pieces > 0 then
			lines[#lines + 1] = ReportBuffText(buff) .. ": " .. table.concat(pieces, "; ")
		end
	end

	local aura = SafeNumber(_G.PallyPower_AuraAssignments and _G.PallyPower_AuraAssignments[paladinName], 0)
	if aura > 0 then
		lines[#lines + 1] = "Aura: " .. AuraText(aura)
	end
	if #lines == 0 then
		lines[#lines + 1] = "No assignments."
	end

	return lines
end

function PPA:PrintLocalBlessingsReport()
	local names = self:GetBlessingsReportPaladinNames()
	Print("Blessings Report (local):")
	if #names == 0 then
		Print("  No paladin assignments are available.")
		return true
	end

	for _, paladinName in ipairs(names) do
		Print(paladinName .. ":")
		for _, line in ipairs(self:BuildLocalBlessingsReportLinesForPaladin(paladinName)) do
			Print("  " .. line)
		end
	end
	Print("End of local Blessings Report.")
	return true
end

function PPA:AdvertiseBlessingsReportHeader(message)
	if message == "--- Paladin assignments ---" then
		return "--- Paladin assignments (PallyPowerAdvanced) ---"
	end
	return message
end

function PPA:RunPallyPowerReportWithAdvertisedHeader(originalReport, target, ...)
	local originalSendChatMessage = _G.SendChatMessage
	if type(originalSendChatMessage) ~= "function" then
		return originalReport(target, ...)
	end

	local replacedHeader = false
	_G.SendChatMessage = function(message, ...)
		if not replacedHeader then
			local advertised = PPA:AdvertiseBlessingsReportHeader(message)
			if advertised ~= message then
				replacedHeader = true
				message = advertised
			end
		end
		return originalSendChatMessage(message, ...)
	end

	local results = {pcall(originalReport, target, ...)}
	_G.SendChatMessage = originalSendChatMessage
	if not results[1] then
		error(results[2], 0)
	end
	return Unpack(results, 2)
end

function PPA:PrintDebugPlan(plan, context)
	if not self:IsDebugEnabled() then
		return
	end
	for _, unit in ipairs(context.players or {}) do
		if unit.guessed then
			Print("Guessed " .. unit.name .. " as " .. RoleText(unit.role) .. (unit.spec and (" / " .. unit.spec) or "") .. ".")
		end
	end
	for _, line in ipairs(plan.debugLines or {}) do
		Print(line)
	end
end

function PPA:IsInRaidGroup()
	if _G.IsInRaid then
		local ok, inRaid = pcall(_G.IsInRaid)
		return ok and inRaid == true
	end
	return false
end

function PPA:IsLocalRaidLeaderOrAssistant()
	if _G.UnitIsGroupLeader then
		local ok, isLeader = pcall(_G.UnitIsGroupLeader, "player")
		if ok and isLeader then
			return true
		end
	end
	if _G.UnitIsGroupAssistant then
		local ok, isAssistant = pcall(_G.UnitIsGroupAssistant, "player")
		if ok and isAssistant then
			return true
		end
	end
	if _G.PallyPower and _G.PallyPower.CheckLeader and _G.PallyPower.player then
		local ok, isLeader = pcall(_G.PallyPower.CheckLeader, _G.PallyPower, _G.PallyPower.player)
		if ok and isLeader then
			return true
		end
	end
	return false
end

function PPA:ShouldWarnSmartAssignRaidAuthority()
	return not self:IsSimulationActive()
		and self:IsInRaidGroup()
		and not self:IsLocalRaidLeaderOrAssistant()
end

function PPA:WarnSmartAssignRaidAuthority()
	if not self:ShouldWarnSmartAssignRaidAuthority() then
		return false
	end
	Print("Smart-Assign warning: without raid leader or assistant, other clients may only accept changes to your own paladin row.")
	Print("Ask for assist or lead before broadcasting a full raid plan.")
	return true
end

function PPA:ShouldUseLocalBlessingsReport()
	return self:IsSimulationActive()
		or (self:IsInRaidGroup() and not self:IsLocalRaidLeaderOrAssistant())
end

function PPA:InstallLocalReportHook()
	local pallyPower = _G.PallyPower
	if not pallyPower or self.localReportHookInstalledFor == pallyPower or type(pallyPower.Report) ~= "function" then
		return
	end
	self.localReportHookInstalledFor = pallyPower

	local originalReport = pallyPower.Report
	pallyPower.Report = function(target, ...)
		if PPA:ShouldUseLocalBlessingsReport() then
			return PPA:PrintLocalBlessingsReport()
		end
		return PPA:RunPallyPowerReportWithAdvertisedHeader(originalReport, target, ...)
	end
end

function PPA:CanRunSmartAssign()
	if _G.InCombatLockdown and _G.InCombatLockdown() then
		Print("Smart-Assign cannot run in combat.")
		return false
	end
	if not _G.PallyPower then
		Print("PallyPower is required.")
		return false
	end
	if _G.PallyPower.isWrath then
		Print("This addon is staged for TBC Anniversary, not Wrath.")
		return false
	end
	if _G.PallyPower.CheckLeader and (_G.PallyPower:CheckLeader(_G.PallyPower.player) or _G.PP_Leader == false) then
		return true
	end
	if _G.PallyPower.opt and _G.PallyPower.opt.freeassign then
		return true
	end
	if self:IsInRaidGroup() then
		return true
	end
	Print("Only a group leader, raid assistant, or free-assignment paladin can broadcast assignments.")
	return false
end

function PPA:ExecuteSmartAssign(options)
	options = options or {}
	if not self:CanRunSmartAssign() then
		return
	end
	self:WarnSmartAssignRaidAuthority()

	local context = self:BuildRuntimeContext(options.guess == true)
	local uncertain = self:GetUncertainPlayers(context)
	if #uncertain > 0 and not options.guess and not options.noPrompt then
		self:ShowGuessPrompt(uncertain)
		return
	end

	local plan = self:BuildSmartPlan(context)
	for _, warning in ipairs(plan.warnings or {}) do
		Print(warning)
	end
	if #context.paladins == 0 then
		return
	end

	self:ApplyPlan(plan, context)
	self:PrintManualAssignments(plan)
	self:PrintDebugPlan(plan, context)
	Print("Smart-Assign complete.")
end

function PPA:ShowGuessPrompt(uncertain)
	if type(_G.StaticPopupDialogs) == "table" and type(_G.StaticPopup_Show) == "function" then
		_G.StaticPopupDialogs.PALLYPOWERADVANCED_GUESS_SPECS = {
			text = "PallyPowerAdvanced is unsure about %s role/spec assignment(s).",
			button1 = "Guess specs (Unreliable)",
			button2 = "Assign specs",
			OnAccept = function()
				PPA:ExecuteSmartAssign({guess = true})
			end,
			OnCancel = function(_, data)
				PPA:ShowSpecFrame(data or uncertain)
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			noCancelOnEscape = true,
			preferredIndex = 3,
		}
		_G.StaticPopup_Show("PALLYPOWERADVANCED_GUESS_SPECS", tostring(#uncertain), nil, uncertain)
	else
		self:ShowSpecFrame(uncertain)
	end
end

local function SetButtonSelected(button, selected)
	if not button then
		return
	end
	if selected then
		button:Disable()
		if button.GetFontString and button:GetFontString() then
			button:GetFontString():SetTextColor(0.2, 1.0, 0.2)
		end
	else
		button:Enable()
		if button.GetFontString and button:GetFontString() then
			button:GetFontString():SetTextColor(1.0, 1.0, 1.0)
		end
	end
end

function PPA:EnsureSpecFrame()
	if self.specFrame or type(_G.CreateFrame) ~= "function" then
		return self.specFrame
	end

	local frame = _G.CreateFrame("Frame", "PallyPowerAdvancedSpecFrame", _G.UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(620, 420)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:Hide()

	frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	frame.Title:SetPoint("TOP", 0, -8)
	frame.Title:SetText("PallyPowerAdvanced Smart-Assign")

	frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.Text:SetPoint("TOPLEFT", 18, -36)
	frame.Text:SetPoint("TOPRIGHT", -18, -36)
	frame.Text:SetJustifyH("LEFT")
	frame.Text:SetText("Select role/spec for uncertain players, then apply Smart-Assign.")

	frame.Scroll = _G.CreateFrame("ScrollFrame", "PallyPowerAdvancedSpecScrollFrame", frame, "UIPanelScrollFrameTemplate")
	frame.Scroll:SetPoint("TOPLEFT", 18, -62)
	frame.Scroll:SetPoint("BOTTOMRIGHT", -38, 52)

	frame.ScrollChild = _G.CreateFrame("Frame", "PallyPowerAdvancedSpecScrollChild", frame.Scroll)
	frame.ScrollChild:SetSize(540, 1)
	frame.Scroll:SetScrollChild(frame.ScrollChild)
	frame.Rows = {}

	frame.ApplyButton = _G.CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.ApplyButton:SetSize(110, 22)
	frame.ApplyButton:SetPoint("BOTTOMRIGHT", -18, 18)
	frame.ApplyButton:SetText("Apply")
	frame.ApplyButton:SetScript("OnClick", function()
		PPA:ApplySpecFrameSelections()
	end)

	frame.GuessButton = _G.CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.GuessButton:SetSize(110, 22)
	frame.GuessButton:SetPoint("RIGHT", frame.ApplyButton, "LEFT", -8, 0)
	frame.GuessButton:SetText("Guess")
	frame.GuessButton:SetScript("OnClick", function()
		frame:Hide()
		PPA:ExecuteSmartAssign({guess = true})
	end)

	frame.CancelButton = _G.CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.CancelButton:SetSize(110, 22)
	frame.CancelButton:SetPoint("RIGHT", frame.GuessButton, "LEFT", -8, 0)
	frame.CancelButton:SetText("Cancel")
	frame.CancelButton:SetScript("OnClick", function()
		frame:Hide()
	end)

	if type(_G.UISpecialFrames) == "table" then
		table.insert(_G.UISpecialFrames, "PallyPowerAdvancedSpecFrame")
	end
	self.specFrame = frame
	return frame
end

function PPA:UpdateSpecRow(row, selected)
	for _, button in ipairs(row.Buttons or {}) do
		SetButtonSelected(button, button.choice == selected)
	end
end

function PPA:ShowSpecFrame(uncertain)
	if not uncertain or #uncertain == 0 then
		Print("No uncertain role/spec assignments were found.")
		return
	end

	local frame = self:EnsureSpecFrame()
	if not frame then
		Print("The manual spec frame could not be created.")
		return
	end

	self.pendingSpecUnits = uncertain
	self.specSelections = {}

	local rowHeight = 34
	for index, unit in ipairs(uncertain) do
		local row = frame.Rows[index]
		if not row then
			row = _G.CreateFrame("Frame", nil, frame.ScrollChild)
			row:SetSize(540, rowHeight)
			row.Name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			row.Name:SetPoint("LEFT", 0, 0)
			row.Name:SetSize(150, 18)
			row.Name:SetJustifyH("LEFT")
			row.Buttons = {}
			frame.Rows[index] = row
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, -((index - 1) * rowHeight))
		row.unit = unit
		row:Show()
		row.Name:SetText(unit.name .. " (" .. ClassText(unit.classID) .. ")")

		local choices = self:GetChoiceList(unit) or {}
		local selected = choices[1]
		self.specSelections[unit.key or unit.name] = selected

		for buttonIndex, choice in ipairs(choices) do
			local button = row.Buttons[buttonIndex]
			if not button then
				button = _G.CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
				button:SetSize(88, 22)
				row.Buttons[buttonIndex] = button
			end
			button:ClearAllPoints()
			button:SetPoint("LEFT", 160 + ((buttonIndex - 1) * 94), 0)
			button:SetText(choice.label)
			button.choice = choice
			local unitRef = unit
			local rowRef = row
			button:SetScript("OnClick", function(selfButton)
				PPA.specSelections[unitRef.key or unitRef.name] = selfButton.choice
				PPA:UpdateSpecRow(rowRef, selfButton.choice)
			end)
			button:Show()
			SetButtonSelected(button, choice == selected)
		end
		for buttonIndex = #choices + 1, #row.Buttons do
			row.Buttons[buttonIndex]:Hide()
		end
	end

	for index = #uncertain + 1, #frame.Rows do
		frame.Rows[index]:Hide()
	end

	frame.ScrollChild:SetHeight(math.max(1, #uncertain * rowHeight))
	frame:SetHeight(math.min(520, math.max(210, 122 + (#uncertain * rowHeight))))
	frame:Show()
end

function PPA:ApplySpecFrameSelections()
	local frame = self.specFrame
	if not frame then
		return
	end
	for _, unit in ipairs(self.pendingSpecUnits or {}) do
		local choice = self.specSelections and self.specSelections[unit.key or unit.name]
		if choice then
			self:SaveManualChoice(unit, choice)
		end
	end
	frame:Hide()
	self:ExecuteSmartAssign({noPrompt = true})
end

function PPA:CreateSmartButton()
	if self.smartButton or type(_G.CreateFrame) ~= "function" then
		return
	end
	local parent = _G.PallyPowerBlessingsFrame
	local autoAssign = _G.PallyPowerBlessingsFrameAutoAssign or _G.PallyPowerBlessingsAutoAssign
	if not parent or not autoAssign then
		return
	end

	local button = _G.CreateFrame("Button", "PallyPowerBlessingsFrameSmartAssign", parent, "GameMenuButtonTemplate")
	button:SetSize(110, 20)
	button:SetText("Smart-Assign")
	button:SetScript("OnClick", function()
		PPA:ExecuteSmartAssign()
	end)
	button:SetScript("OnEnter", function(self)
		if _G.GameTooltip then
			_G.GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			_G.GameTooltip:SetText("Smart-Assign")
			_G.GameTooltip:AddLine("Build role/spec-aware PallyPower blessing assignments.", 1, 1, 1, true)
			_G.GameTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", function()
		if _G.GameTooltip then
			_G.GameTooltip:Hide()
		end
	end)

	self.smartButton = button
	self:ReflowButtons()
end

function PPA:ReflowButtons()
	local smart = self.smartButton
	local autoAssign = _G.PallyPowerBlessingsFrameAutoAssign or _G.PallyPowerBlessingsAutoAssign
	local options = _G.PallyPowerBlessingsFrameOptions
	local preset = _G.PallyPowerBlessingsFramePreset
	local report = _G.PallyPowerBlessingsFrameReport
	if not smart or not autoAssign then
		return
	end

	smart:ClearAllPoints()
	smart:SetPoint("BOTTOMRIGHT", autoAssign, "BOTTOMLEFT", -7, 0)
	smart:Show()

	if options then
		options:ClearAllPoints()
		options:SetPoint("BOTTOMRIGHT", smart, "BOTTOMLEFT", -7, 0)
	end
	if preset and preset:IsShown() then
		preset:ClearAllPoints()
		preset:SetPoint("BOTTOMRIGHT", options or smart, "BOTTOMLEFT", -7, 0)
		if report then
			report:ClearAllPoints()
			report:SetPoint("BOTTOMRIGHT", preset, "BOTTOMLEFT", -7, 0)
		end
	elseif report then
		report:ClearAllPoints()
		report:SetPoint("BOTTOMRIGHT", options or smart, "BOTTOMLEFT", -7, 0)
	end
end

function PPA:BuildOptionsTable()
	return {
		name = "PallyPowerAdvanced",
		type = "group",
		childGroups = "tab",
		args = {
			settings = {
				order = 1,
				name = "Settings",
				type = "group",
				args = {
					advanced_settings = {
						order = 1,
						name = "PallyPowerAdvanced Settings",
						type = "group",
						inline = true,
						args = {
							always_prefer_wisdom_on_healers = {
								order = 1,
								type = "toggle",
								name = "Always Prefer Wisdom on Healers",
								desc = "Prefer Blessing of Wisdom over Blessing of Kings for healer assignments even when Wisdom is not improved.",
								width = "full",
								get = function()
									return PPA:EnsureDB().alwaysPreferWisdomOnHealers == true
								end,
								set = function(_, value)
									PPA:EnsureDB().alwaysPreferWisdomOnHealers = value == true
								end,
							},
							always_prefer_wisdom_on_paladin_tanks = {
								order = 2,
								type = "toggle",
								name = "Always Prefer Wisdom for Paladin Tanks",
								desc = "Prefer Blessing of Wisdom over Blessing of Kings for paladin tank assignments regardless of active spec data.",
								width = "full",
								get = function()
									return PPA:EnsureDB().alwaysPreferWisdomOnPaladinTanks == true
								end,
								set = function(_, value)
									PPA:EnsureDB().alwaysPreferWisdomOnPaladinTanks = value == true
								end,
							},
						},
					},
				},
			},
		},
	}
end

function PPA:RegisterPallyPowerAdvancedOptions()
	self:EnsureDB()
	if self.optionsRegistered then
		return true
	end
	if type(_G.LibStub) ~= "function" then
		return false
	end

	local okConfig, config = pcall(_G.LibStub, "AceConfig-3.0", true)
	local okDialog, dialog = pcall(_G.LibStub, "AceConfigDialog-3.0", true)
	if not okConfig or not config or type(config.RegisterOptionsTable) ~= "function" then
		return false
	end
	if not okDialog or not dialog or type(dialog.AddToBlizOptions) ~= "function" then
		return false
	end

	self.options = self.options or self:BuildOptionsTable()
	local okRegister = pcall(config.RegisterOptionsTable, config, "PallyPowerAdvanced", self.options, {"ppa", "pallypoweradvanced"})
	if not okRegister then
		return false
	end
	local okAdd, optionsFrame = pcall(dialog.AddToBlizOptions, dialog, "PallyPowerAdvanced", "PallyPowerAdvanced")
	if not okAdd then
		return false
	end
	self.optionsFrame = optionsFrame
	self.optionsRegistered = true
	return true
end

function PPA:HookPallyPower()
	if not _G.PallyPower then
		return
	end
	self:EnsureDB()
	self:HookAssignmentAlerts()
	self:InstallSimulationHooks()
	self:InstallAssignmentActionHooks()
	self:InstallLocalReportHook()
	if self.hookedPallyPower then
		return
	end
	self.hookedPallyPower = true
	if type(_G.hooksecurefunc) == "function" and _G.PallyPower.UpdateLayout then
		_G.hooksecurefunc(_G.PallyPower, "UpdateLayout", function()
			PPA:CreateSmartButton()
			PPA:ReflowButtons()
		end)
	end
	self:CreateSmartButton()
end

function PPA:ShowHelp()
	Print("/ppa smart - run Smart-Assign")
	Print("/ppa simulate - open a local 25-player simulation raid")
	Print("/ppa simulate off - restore the previous PallyPower state")
	Print("/ppa debug - toggle debug reasoning")
	Print("/ppa debug on - enable debug reasoning")
	Print("/ppa debug off - disable debug reasoning")
	Print("/ppa trace - toggle PallyPower assignment trace")
	Print("/ppa trace on - show who changes raid assignments")
	Print("/ppa trace off - disable assignment trace")
	Print("/ppa sound - toggle one-minute buff warning sound")
	Print("/ppa specs - choose uncertain roles/specs manually")
end

function PPA:HandleSlash(input)
	input = string.lower(input or "")
	if input == "" or input == "smart" then
		self:ExecuteSmartAssign()
	elseif input == "debug" then
		local db = self:EnsureDB()
		db.debug = not db.debug
		Print("Debug " .. (db.debug and "enabled." or "disabled."))
	elseif input == "debug on" then
		self:EnsureDB().debug = true
		Print("Debug enabled.")
	elseif input == "debug off" then
		self:EnsureDB().debug = false
		Print("Debug disabled.")
	elseif input == "trace" then
		local db = self:EnsureDB()
		db.assignmentTrace = not db.assignmentTrace
		Print("Assignment trace " .. (db.assignmentTrace and "enabled." or "disabled."))
	elseif input == "trace on" then
		self:EnsureDB().assignmentTrace = true
		Print("Assignment trace enabled.")
	elseif input == "trace off" then
		self:EnsureDB().assignmentTrace = false
		Print("Assignment trace disabled.")
	elseif input == "sound" then
		local db = self:EnsureDB()
		db.buffWarningSound = not db.buffWarningSound
		Print("Buff warning sound " .. (db.buffWarningSound and "enabled." or "disabled."))
	elseif input == "sound on" then
		self:EnsureDB().buffWarningSound = true
		Print("Buff warning sound enabled.")
	elseif input == "sound off" then
		self:EnsureDB().buffWarningSound = false
		Print("Buff warning sound disabled.")
	elseif input == "simulate" or input == "simulate on" or input == "simulate reroll" or input == "simulate new" then
		self:ActivateSimulation()
	elseif input == "simulate off" or input == "simulate clear" or input == "simulate stop" then
		self:DeactivateSimulation()
	elseif input == "simulate smart" then
		if self:ActivateSimulation() then
			self:ExecuteSmartAssign({guess = true, noPrompt = true})
		end
	elseif input == "specs" or input == "assign specs" then
		local context = self:BuildRuntimeContext(false)
		self:ShowSpecFrame(self:GetUncertainPlayers(context))
	else
		self:ShowHelp()
	end
end

function PPA:RegisterSlash()
	if type(_G.SlashCmdList) ~= "table" then
		return
	end
	_G.SLASH_PALLYPOWERADVANCED1 = "/ppa"
	_G.SLASH_PALLYPOWERADVANCED2 = "/pallypoweradvanced"
	_G.SlashCmdList.PALLYPOWERADVANCED = function(input)
		PPA:HandleSlash(input)
	end
end

function PPA:OnEvent(event, arg1, arg2, arg3, arg4)
	if event == "ADDON_LOADED" then
		if arg1 == addonName then
			self:EnsureDB()
			self:RestoreStaleSimulationState()
			self:RegisterSlash()
			self:RegisterPallyPowerAdvancedOptions()
		elseif arg1 == "PallyPower" then
			self:RestoreStaleSimulationState()
			self:HookPallyPower()
		end
	elseif event == "PLAYER_LOGIN" then
		self:EnsureDB()
		self:RestoreStaleSimulationState()
		self:RegisterSlash()
		self:RegisterPallyPowerAdvancedOptions()
		self:HookPallyPower()
		self:BroadcastSpec()
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:BroadcastSpec()
	elseif event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_TALENT_UPDATE" or event == "SPELLS_CHANGED" then
		self:HandleLocalTalentChanged()
	elseif event == "CHAT_MSG_ADDON" then
		self:HandleAddonMessage(arg1, arg2, arg3, arg4)
	end
end

function PPA:Initialize()
	self:EnsureDB()
	self:RestoreStaleSimulationState()
	self:RegisterSlash()
	self:RegisterPallyPowerAdvancedOptions()
	self:HookPallyPower()
	if type(_G.CreateFrame) == "function" and not self.eventFrame then
		local eventFrame = _G.CreateFrame("Frame")
		eventFrame:RegisterEvent("ADDON_LOADED")
		eventFrame:RegisterEvent("PLAYER_LOGIN")
		eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
		eventFrame:RegisterEvent("SPELLS_CHANGED")
		eventFrame:RegisterEvent("CHAT_MSG_ADDON")
		eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2, arg3, arg4)
			PPA:OnEvent(event, arg1, arg2, arg3, arg4)
		end)
		eventFrame:SetScript("OnUpdate", function(_, elapsed)
			PPA:OnUpdate(elapsed)
		end)
		self.eventFrame = eventFrame
	end
	if _G.C_ChatInfo and _G.C_ChatInfo.RegisterAddonMessagePrefix then
		_G.C_ChatInfo.RegisterAddonMessagePrefix(PPA_SPEC_PREFIX)
	end
end

PPA._test = {
	BUFF_WISDOM = BUFF_WISDOM,
	BUFF_MIGHT = BUFF_MIGHT,
	BUFF_KINGS = BUFF_KINGS,
	BUFF_SALVATION = BUFF_SALVATION,
	BUFF_LIGHT = BUFF_LIGHT,
	BUFF_SANCTUARY = BUFF_SANCTUARY,
	AURA_DEVOTION = AURA_DEVOTION,
	AURA_RETRIBUTION = AURA_RETRIBUTION,
	AURA_CONCENTRATION = AURA_CONCENTRATION,
	AURA_SANCTITY = AURA_SANCTITY,
	BuildSmartPlan = function(context)
		return PPA:BuildSmartPlan(context)
	end,
	CheckBuffWarnings = function(now)
		return PPA:CheckBuffWarnings(now)
	end,
	GetPriorityForUnit = function(unit, context)
		return PPA:GetPriorityForUnit(unit, context)
	end,
	GetCurrentPvPInstanceType = function()
		return PPA:GetCurrentPvPInstanceType()
	end,
	InferPaladinRoleFromSkills = function(skills)
		return PPA:InferPaladinRoleFromSkills(skills)
	end,
	FindExpiringAssignedBuffs = function(threshold)
		return PPA:FindExpiringAssignedBuffs(threshold)
	end,
	GetUncertainPlayers = function(context)
		return PPA:GetUncertainPlayers(context)
	end,
	ApplyGuess = function(unit)
		return PPA:ApplyGuess(unit)
	end,
	BuildRuntimeContext = function(guess)
		return PPA:BuildRuntimeContext(guess)
	end,
	BuildSimulationContext = function(seed)
		return PPA:BuildSimulationContext(seed)
	end,
	PrepareSimulationUnitMaps = function(context)
		return PPA:PrepareSimulationUnitMaps(context)
	end,
	GetSimulationClassUnit = function(classID, playerID)
		return PPA:GetSimulationClassUnit(classID, playerID)
	end,
	RenderSimulationBlessingsGrid = function()
		return PPA:RenderSimulationBlessingsGrid()
	end,
	InstallSimulationHooks = function()
		return PPA:InstallSimulationHooks()
	end,
	WithSimulationUnitAPIs = function(callback)
		return PPA:WithSimulationUnitAPIs(callback)
	end,
	ActivateSimulation = function(seed)
		return PPA:ActivateSimulation(seed)
	end,
	DeactivateSimulation = function()
		return PPA:DeactivateSimulation()
	end,
	IsSimulationActive = function()
		return PPA:IsSimulationActive()
	end,
	ApplyPlan = function(plan, context)
		return PPA:ApplyPlan(plan, context)
	end,
	CanRunSmartAssign = function()
		return PPA:CanRunSmartAssign()
	end,
	ShouldWarnSmartAssignRaidAuthority = function()
		return PPA:ShouldWarnSmartAssignRaidAuthority()
	end,
	ShouldUseLocalBlessingsReport = function()
		return PPA:ShouldUseLocalBlessingsReport()
	end,
	PrintLocalBlessingsReport = function()
		return PPA:PrintLocalBlessingsReport()
	end,
	AdvertiseBlessingsReportHeader = function(message)
		return PPA:AdvertiseBlessingsReportHeader(message)
	end,
	InstallLocalReportHook = function()
		return PPA:InstallLocalReportHook()
	end,
	BuildOptionsTable = function()
		return PPA:BuildOptionsTable()
	end,
	RegisterPallyPowerAdvancedOptions = function()
		return PPA:RegisterPallyPowerAdvancedOptions()
	end,
	CanPaladinBuff = function(paladin, buff)
		return PPA:CanPaladinBuff(paladin, buff)
	end,
	CollectAssignmentChanges = function(before, after)
		return PPA:CollectAssignmentChanges(before, after)
	end,
	DescribeAssignmentChange = function(sender, change)
		return PPA:DescribeAssignmentChange(sender, change)
	end,
	IsGameSoundMuted = function()
		return PPA:IsGameSoundMuted()
	end,
	PlayBuffWarningSound = function()
		return PPA:PlayBuffWarningSound()
	end,
	ReportAssignmentChanges = function(sender, before, after)
		return PPA:ReportAssignmentChanges(sender, before, after)
	end,
	RepairPallyPowerCooldownInfo = function(name)
		return PPA:RepairPallyPowerCooldownInfo(name)
	end,
	SnapshotOwnAssignments = function()
		return PPA:SnapshotOwnAssignments()
	end,
}

PPA:Initialize()
