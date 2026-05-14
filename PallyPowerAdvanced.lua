local addonName = ...

local PPA = _G.PallyPowerAdvanced or {}
_G.PallyPowerAdvanced = PPA

local BUFF_WISDOM = 1
local BUFF_MIGHT = 2
local BUFF_KINGS = 3
local BUFF_SALVATION = 4
local BUFF_LIGHT = 5
local BUFF_SANCTUARY = 6

local BUFF_WARNING_SECONDS = 60
local BUFF_WARNING_SCAN_INTERVAL = 10
local BUFF_WARNING_SOUND_COOLDOWN = 30
local BUFF_WARNING_RESTORE_DELAY = 2
local BUFF_WARNING_SOUND_CHANNEL = "Master"

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

local GENERAL_TIE_ORDER = {
	[BUFF_KINGS] = 1,
	[BUFF_SALVATION] = 2,
	[BUFF_WISDOM] = 3,
	[BUFF_MIGHT] = 4,
	[BUFF_SANCTUARY] = 5,
	[BUFF_LIGHT] = 6,
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
	[CLASS_ID.PRIEST] = {role = ROLE_HEALER},
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

local function ClassText(classID)
	return CLASS_NAMES[classID] or ("Class " .. tostring(classID))
end

local function ClassPluralText(classID)
	return CLASS_PLURAL_NAMES[classID] or (ClassText(classID) .. "s")
end

local function Print(message)
	if _G.DEFAULT_CHAT_FRAME and _G.DEFAULT_CHAT_FRAME.AddMessage then
		_G.DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99PPA|r: " .. tostring(message))
	elseif _G.print then
		_G.print("PPA: " .. tostring(message))
	end
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
	if db.buffWarningSound == nil then
		db.buffWarningSound = true
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
			unit.role = ROLE_HEALER
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

function PPA:GetPriorityForUnit(unit, context)
	local role = NormalizeRole(unit.role)
	local includeLight = context and context.healingPaladinPresent
	local class = unit.class
	local spec = unit.spec

	if class == "WARRIOR" then
		if role == ROLE_TANK then
			return BuildPriority(includeLight, BUFF_KINGS, BUFF_SANCTUARY, BUFF_LIGHT, BUFF_MIGHT, BUFF_WISDOM)
		end
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_MIGHT, BUFF_LIGHT, BUFF_SANCTUARY)
	elseif class == "ROGUE" then
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_MIGHT, BUFF_KINGS, BUFF_LIGHT, BUFF_SANCTUARY)
	elseif class == "PRIEST" then
		if role == ROLE_HEALER then
			return BuildPriority(includeLight, BUFF_WISDOM, BUFF_KINGS, BUFF_SALVATION, BUFF_LIGHT, BUFF_SANCTUARY)
		end
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_WISDOM, BUFF_LIGHT, BUFF_SANCTUARY)
	elseif class == "DRUID" then
		if role == ROLE_TANK then
			return BuildPriority(includeLight, BUFF_KINGS, BUFF_SANCTUARY, BUFF_LIGHT, BUFF_MIGHT, BUFF_WISDOM)
		elseif role == ROLE_HEALER then
			return BuildPriority(includeLight, BUFF_WISDOM, BUFF_KINGS, BUFF_SALVATION, BUFF_LIGHT, BUFF_SANCTUARY)
		elseif spec == "BALANCE" then
			return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_WISDOM, BUFF_LIGHT, BUFF_SANCTUARY)
		end
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_MIGHT, BUFF_LIGHT, BUFF_SANCTUARY)
	elseif class == "PALADIN" then
		if role == ROLE_HEALER then
			return BuildPriority(includeLight, BUFF_WISDOM, BUFF_KINGS, BUFF_SALVATION, BUFF_LIGHT, BUFF_SANCTUARY)
		elseif role == ROLE_TANK then
			if (context and context.pallyCount or 0) <= 2 then
				return BuildPriority(includeLight, BUFF_KINGS, BUFF_SANCTUARY, BUFF_WISDOM, BUFF_LIGHT, BUFF_MIGHT)
			end
			return BuildPriority(includeLight, BUFF_SANCTUARY, BUFF_KINGS, BUFF_LIGHT, BUFF_WISDOM, BUFF_MIGHT)
		end
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_MIGHT, BUFF_LIGHT, BUFF_SANCTUARY)
	elseif class == "HUNTER" then
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_MIGHT, BUFF_LIGHT, BUFF_SANCTUARY)
	elseif class == "MAGE" or class == "WARLOCK" then
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_WISDOM, BUFF_LIGHT, BUFF_SANCTUARY)
	elseif class == "SHAMAN" then
		if role == ROLE_HEALER then
			return BuildPriority(includeLight, BUFF_WISDOM, BUFF_KINGS, BUFF_SALVATION, BUFF_LIGHT, BUFF_SANCTUARY)
		elseif spec == "ELEMENTAL" then
			return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_WISDOM, BUFF_LIGHT, BUFF_SANCTUARY)
		end
		return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_MIGHT, BUFF_LIGHT, BUFF_SANCTUARY)
	end

	return BuildPriority(includeLight, BUFF_SALVATION, BUFF_KINGS, BUFF_MIGHT, BUFF_LIGHT, BUFF_SANCTUARY)
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

function PPA:CanPaladinBuff(paladin, buff)
	if not paladin or buff == nil or buff <= 0 or buff > BUFF_SANCTUARY then
		return false
	end

	if paladin.hasAddon then
		local skill = SkillForBuff(paladin, buff)
		if type(skill) == "table" then
			return SafeNumber(skill.rank, 0) > 0
		end
		return skill == true
	end

	local role = NormalizeRole(paladin.role)
	if buff == BUFF_KINGS then
		return role == ROLE_TANK or role == ROLE_HEALER
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
	elseif buff == BUFF_LIGHT then
		score = score + (role == ROLE_HEALER and 16 or 0)
	elseif buff == BUFF_SANCTUARY then
		score = score + (role == ROLE_TANK and 20 or 0)
	elseif buff == BUFF_MIGHT then
		score = score + (role == ROLE_DAMAGER and 10 or 0)
	elseif buff == BUFF_SALVATION then
		score = score + (role == ROLE_DAMAGER and 8 or 0)
	elseif buff == BUFF_KINGS then
		score = score + ((role == ROLE_TANK or role == ROLE_HEALER) and 6 or 0)
	end

	return score
end

function PPA:SelectPaladinForBuff(context, buff, usedPaladins, classID, members)
	local bestPaladin
	local bestScore = -100000
	for _, paladin in ipairs(context.paladins or {}) do
		if not usedPaladins[paladin.name] and self:CanPaladinBuff(paladin, buff) then
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

local function SetPlanAssignment(plan, paladin, classID, buff)
	if paladin.hasAddon then
		EnsureClassAssignment(plan.assignments, paladin.name)[classID] = buff
	else
		if not plan.manualAssignments[paladin.name] then
			plan.manualAssignments[paladin.name] = {greater = {}, normal = {}, role = paladin.role}
		end
		plan.manualAssignments[paladin.name].greater[classID] = buff
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
		if not plan.manualAssignments[paladin.name] then
			plan.manualAssignments[paladin.name] = {greater = {}, normal = {}, role = paladin.role}
		end
		local manual = plan.manualAssignments[paladin.name].normal
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
			local points = (#priority - index + 1) * 10
			if index == 1 then
				points = points + 8
			end
			scores[buff] = (scores[buff] or 0) + points
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

function PPA:SelectClassAssignments(context, classID, members, plan)
	local scores = self:ScoreClassBuffs(members, context)
	local scoredBuffs = SortedScoredBuffs(scores)
	local usedPaladins = {}
	local selected = {}
	local maxAssignments = math.min(#(context.paladins or {}), BUFF_SANCTUARY)

	for _, scored in ipairs(scoredBuffs) do
		if #selected >= maxAssignments then
			break
		end
		local paladin, paladinScore = self:SelectPaladinForBuff(context, scored.buff, usedPaladins, classID, members)
		if paladin then
			usedPaladins[paladin.name] = true
			selected[#selected + 1] = {
				buff = scored.buff,
				score = scored.score,
				paladin = paladin,
				paladinScore = paladinScore,
			}
			SetPlanAssignment(plan, paladin, classID, scored.buff)
		end
	end

	return selected, scoredBuffs
end

function PPA:FindReplacementBuff(paladin, priority, provided, currentBuff)
	local currentIndex = PriorityIndex(priority, currentBuff) or 999
	for index, buff in ipairs(priority) do
		if index < currentIndex and not provided[buff] and self:CanPaladinBuff(paladin, buff) then
			return buff, index
		end
	end
	return nil
end

function PPA:ApplyPlayerOverrides(context, classID, members, selected, plan)
	for _, unit in ipairs(members) do
		local priority = unit.priority or self:GetPriorityForUnit(unit, context)
		local provided = {}
		for _, assignment in ipairs(selected) do
			provided[assignment.buff] = assignment.paladin.name
		end

		for _, assignment in ipairs(selected) do
			local replacement = self:FindReplacementBuff(assignment.paladin, priority, provided, assignment.buff)
			if replacement then
				SetPlanNormal(plan, assignment.paladin, classID, unit.name, replacement, assignment.buff)
				provided[assignment.buff] = nil
				provided[replacement] = assignment.paladin.name
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

function PPA:BuildSmartPlan(context)
	local plan = {
		assignments = {},
		normalAssignments = {},
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
			end
		end
	end

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
		or string.find(message, "^CLEAR")
	)
end

function PPA:SnapshotOwnAssignments()
	local playerName = self:GetLocalPaladinName()
	if not playerName then
		return nil
	end

	local snapshot = {
		greater = {},
		normal = {},
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

function PPA:CollectAssignmentChanges(before, after)
	local changes = {}
	if not before or not after then
		return changes
	end

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

function PPA:HookAssignmentAlerts()
	if self.assignmentAlertsHooked or not _G.PallyPower or type(_G.PallyPower.ParseMessage) ~= "function" then
		return
	end

	local originalParseMessage = _G.PallyPower.ParseMessage
	_G.PallyPower.ParseMessage = function(pallyPower, sender, message, ...)
		local before
		if PPA:IsAssignmentAlertMessage(message) then
			before = PPA:SnapshotOwnAssignments()
		end

		local result = originalParseMessage(pallyPower, sender, message, ...)

		if before then
			PPA:ReportAssignmentChanges(sender, before, PPA:SnapshotOwnAssignments())
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
	local soundKit = _G.SOUNDKIT and _G.SOUNDKIT.READY_CHECK
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
	if type(info) ~= "table" then
		return skills
	end
	for buff = BUFF_WISDOM, BUFF_SANCTUARY do
		if type(info[buff]) == "table" then
			skills[buff] = {
				rank = SafeNumber(info[buff].rank, 0),
				talent = SafeNumber(info[buff].talent, 0),
			}
		end
	end
	return skills
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

function PPA:CollectRoster()
	local players = {}
	local units = {}

	if _G.IsInRaid and _G.IsInRaid() then
		local maxRaid = _G.MAX_RAID_MEMBERS or 40
		for index = 1, maxRaid do
			units[#units + 1] = {"raid" .. index, index}
		end
	else
		units[#units + 1] = {"player", nil}
		local maxParty = _G.MAX_PARTY_MEMBERS or 4
		for index = 1, maxParty do
			units[#units + 1] = {"party" .. index, nil}
		end
	end

	for _, unitInfo in ipairs(units) do
		local unit = unitInfo[1]
		local raidIndex = unitInfo[2]
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
					if rosterName then
						fullName = rosterName
					end
					rank = rosterRank or rank
					subgroup = rosterSubgroup or subgroup
					classFile = rosterClass or classFile
					raidRole = rosterRole
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
				}

				self:ApplyManualChoice(player)
				players[#players + 1] = player
			end
		end
	end

	return players
end

function PPA:BuildRuntimeContext(guess)
	self:EnsureDB()
	self:RefreshPallyPowerState()

	local players = self:CollectRoster()
	local paladins = {}
	for _, unit in ipairs(players) do
		if unit.class == "PALADIN" then
			local hasAddon = type(_G.AllPallys) == "table" and type(_G.AllPallys[unit.name]) == "table"
			paladins[#paladins + 1] = {
				name = unit.name,
				fullName = unit.fullName,
				key = unit.key,
				class = "PALADIN",
				classID = CLASS_ID.PALADIN,
				role = unit.role,
				spec = unit.spec,
				hasAddon = hasAddon,
				skills = hasAddon and self:BuildPaladinSkills(unit.name) or {},
			}
		end
	end

	local context = {
		players = players,
		paladins = paladins,
		pallyCount = #paladins,
		playerName = _G.PallyPower and _G.PallyPower.player or (_G.UnitName and _G.UnitName("player")) or "",
		healingPaladinPresent = false,
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

function PPA:SendPlanMessages(plan)
	if not _G.PallyPower or not _G.PallyPower.SendMessage then
		return
	end

	for paladinName, assignments in pairs(plan.assignments) do
		_G.PallyPower:SendMessage("PASSIGN " .. paladinName .. "@" .. self:AssignmentString(assignments))
	end

	local normalList = {}
	for paladinName, classMap in pairs(plan.normalAssignments) do
		for classID, targets in pairs(classMap) do
			for targetName, buff in pairs(targets) do
				normalList[#normalList + 1] = string.format("%s %s %s %s", paladinName, classID, targetName, buff)
			end
		end
	end
	for offset = 1, #normalList, 5 do
		_G.PallyPower:SendMessage("NASSIGN " .. table.concat(normalList, "@", offset, math.min(offset + 4, #normalList)))
	end
end

function PPA:ApplyPlan(plan, context)
	if not _G.PallyPower then
		Print("PallyPower is not loaded.")
		return false
	end

	if _G.PallyPower.ClearAssignments then
		_G.PallyPower:ClearAssignments(_G.PallyPower.player, true)
	end
	if _G.PallyPower.SendMessage then
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

	for paladinName, classMap in pairs(plan.normalAssignments) do
		for classID, targets in pairs(classMap) do
			local normalTable = EnsurePallyPowerNormalTable(paladinName, classID)
			for targetName, buff in pairs(targets) do
				normalTable[targetName] = buff
			end
		end
	end

	local function afterAssignments()
		self:SendPlanMessages(plan)
		if _G.PallyPower.UpdateRoster then
			_G.PallyPower:UpdateRoster()
		end
		if _G.PallyPower.UpdateLayout then
			_G.PallyPower:UpdateLayout()
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
	end
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
	Print("Only a group leader, raid assistant, or free-assignment paladin can broadcast assignments.")
	return false
end

function PPA:ExecuteSmartAssign(options)
	options = options or {}
	if not self:CanRunSmartAssign() then
		return
	end

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

function PPA:HookPallyPower()
	if not _G.PallyPower then
		return
	end
	self:HookAssignmentAlerts()
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
	Print("/ppa debug - toggle debug reasoning")
	Print("/ppa debug on - enable debug reasoning")
	Print("/ppa debug off - disable debug reasoning")
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

function PPA:OnEvent(event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == addonName then
			self:EnsureDB()
			self:RegisterSlash()
		elseif arg1 == "PallyPower" then
			self:HookPallyPower()
		end
	elseif event == "PLAYER_LOGIN" then
		self:EnsureDB()
		self:RegisterSlash()
		self:HookPallyPower()
	end
end

function PPA:Initialize()
	self:EnsureDB()
	self:RegisterSlash()
	self:HookPallyPower()
	if type(_G.CreateFrame) == "function" and not self.eventFrame then
		local eventFrame = _G.CreateFrame("Frame")
		eventFrame:RegisterEvent("ADDON_LOADED")
		eventFrame:RegisterEvent("PLAYER_LOGIN")
		eventFrame:SetScript("OnEvent", function(_, event, arg1)
			PPA:OnEvent(event, arg1)
		end)
		eventFrame:SetScript("OnUpdate", function(_, elapsed)
			PPA:OnUpdate(elapsed)
		end)
		self.eventFrame = eventFrame
	end
end

PPA._test = {
	BUFF_WISDOM = BUFF_WISDOM,
	BUFF_MIGHT = BUFF_MIGHT,
	BUFF_KINGS = BUFF_KINGS,
	BUFF_SALVATION = BUFF_SALVATION,
	BUFF_LIGHT = BUFF_LIGHT,
	BUFF_SANCTUARY = BUFF_SANCTUARY,
	BuildSmartPlan = function(context)
		return PPA:BuildSmartPlan(context)
	end,
	CheckBuffWarnings = function(now)
		return PPA:CheckBuffWarnings(now)
	end,
	GetPriorityForUnit = function(unit, context)
		return PPA:GetPriorityForUnit(unit, context)
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
