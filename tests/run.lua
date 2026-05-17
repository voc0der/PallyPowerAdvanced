_G.PallyPowerAdvancedDB = {debug = false, specs = {}}

dofile("PallyPowerAdvanced.lua")

local PPA = _G.PallyPowerAdvanced
local T = PPA._test

local tests = {}

local function test(name, fn)
	tests[#tests + 1] = {name = name, fn = fn}
end

local function assertEquals(actual, expected, message)
	if actual ~= expected then
		error((message or "assertEquals failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

local function skill(rank, talent)
	return {rank = rank or 1, talent = talent or 0}
end

local function collectClassBuffs(plan, classID)
	local buffs = {}
	for _, classMap in pairs(plan.assignments or {}) do
		if classMap[classID] then
			buffs[classMap[classID]] = true
		end
	end
	return buffs
end

local function countDistinctBuffs(classMap)
	local seen = {}
	local count = 0
	for _, buff in pairs(classMap or {}) do
		if buff and not seen[buff] then
			seen[buff] = true
			count = count + 1
		end
	end
	return count, seen
end

local function planContainsBuff(plan, buff)
	for _, classMap in pairs(plan.assignments or {}) do
		for _, assignedBuff in pairs(classMap or {}) do
			if assignedBuff == buff then
				return true
			end
		end
	end
	for _, classMap in pairs(plan.normalAssignments or {}) do
		for _, targets in pairs(classMap or {}) do
			for _, assignedBuff in pairs(targets or {}) do
				if assignedBuff == buff then
					return true
				end
			end
		end
	end
	for _, manual in pairs(plan.manualAssignments or {}) do
		for _, assignedBuff in pairs(manual.greater or {}) do
			if assignedBuff == buff then
				return true
			end
		end
		for _, normal in ipairs(manual.normal or {}) do
			if normal.buff == buff then
				return true
			end
		end
	end
	return false
end

local function baseContext()
	return {
		playerName = "Holyone",
		pallyCount = 2,
		healingPaladinPresent = true,
		paladins = {
			{
				name = "Holyone",
				role = "HEALER",
				hasAddon = true,
				skills = {
					[T.BUFF_WISDOM] = skill(7, 2),
					[T.BUFF_MIGHT] = skill(7, 0),
					[T.BUFF_KINGS] = skill(1, 0),
					[T.BUFF_SALVATION] = skill(1, 0),
					[T.BUFF_LIGHT] = skill(4, 0),
				},
				auras = {
					[T.AURA_DEVOTION] = skill(7, 2),
					[T.AURA_RETRIBUTION] = skill(5, 0),
					[T.AURA_CONCENTRATION] = skill(1, 0),
				},
			},
			{
				name = "Tankadin",
				role = "TANK",
				hasAddon = true,
				skills = {
					[T.BUFF_WISDOM] = skill(7, 0),
					[T.BUFF_MIGHT] = skill(7, 0),
					[T.BUFF_KINGS] = skill(1, 0),
					[T.BUFF_SALVATION] = skill(1, 0),
					[T.BUFF_LIGHT] = skill(4, 0),
					[T.BUFF_SANCTUARY] = skill(5, 2),
				},
				auras = {
					[T.AURA_DEVOTION] = skill(7, 0),
					[T.AURA_RETRIBUTION] = skill(5, 0),
					[T.AURA_CONCENTRATION] = skill(1, 0),
				},
			},
		},
		players = {},
	}
end

test("warrior tank gets normal sanctuary instead of class salvation", function()
	local context = baseContext()
	context.players = {
		{name = "Shieldwall", class = "WARRIOR", classID = 1, role = "TANK"},
		{name = "Slammer", class = "WARRIOR", classID = 1, role = "DAMAGER"},
		{name = "Cleave", class = "WARRIOR", classID = 1, role = "DAMAGER"},
	}

	local plan = T.BuildSmartPlan(context)
	assertEquals(plan.assignments.Holyone[1], T.BUFF_KINGS, "holy paladin should cover warrior kings")
	assertEquals(plan.assignments.Tankadin[1], T.BUFF_SALVATION, "tank paladin should cover warrior salvation")
	assertEquals(plan.normalAssignments.Tankadin[1].Shieldwall, T.BUFF_SANCTUARY, "warrior tank should receive sanctuary override")
end)

test("pvp priority removes salvation and pushes sanctuary last", function()
	local context = {pvpInstance = true, healingPaladinPresent = true, improvedWisdomPaladinPresent = true, pallyCount = 4}
	local rogue = {name = "Sneaky", class = "ROGUE", classID = 2, role = "DAMAGER"}
	local tank = {name = "Shieldwall", class = "WARRIOR", classID = 1, role = "TANK"}

	local priority = T.GetPriorityForUnit(rogue, context)
	assertEquals(priority[1], T.BUFF_MIGHT, "rogue pvp first priority")
	assertEquals(priority[2], T.BUFF_KINGS, "rogue pvp second priority")
	assertEquals(priority[3], T.BUFF_LIGHT, "rogue pvp third priority")
	assertEquals(priority[4], T.BUFF_SANCTUARY, "rogue pvp sanctuary should be last")
	for _, buff in ipairs(priority) do
		assertEquals(buff == T.BUFF_SALVATION, false, "pvp priority should omit salvation")
	end

	priority = T.GetPriorityForUnit(tank, context)
	assertEquals(priority[1], T.BUFF_KINGS, "tank pvp first priority")
	assertEquals(priority[#priority], T.BUFF_SANCTUARY, "tank pvp sanctuary should be last")
end)

test("pvp plan skips salvation without forcing sanctuary over better blessings", function()
	local context = baseContext()
	context.pvpInstance = true
	context.pvpInstanceType = "pvp"
	context.players = {
		{name = "Shieldwall", class = "WARRIOR", classID = 1, role = "TANK"},
		{name = "Slammer", class = "WARRIOR", classID = 1, role = "DAMAGER"},
		{name = "Cleave", class = "WARRIOR", classID = 1, role = "DAMAGER"},
	}

	local plan = T.BuildSmartPlan(context)
	local warriorBuffs = {
		[plan.assignments.Holyone[1]] = true,
		[plan.assignments.Tankadin[1]] = true,
	}
	assertEquals(warriorBuffs[T.BUFF_KINGS], true, "pvp warriors should get kings")
	assertEquals(warriorBuffs[T.BUFF_MIGHT], true, "pvp warriors should get might")
	assertEquals(plan.normalAssignments.Tankadin and plan.normalAssignments.Tankadin[1], nil, "pvp should not force tank sanctuary fallback")
	assertEquals(planContainsBuff(plan, T.BUFF_SALVATION), false, "pvp plan should never assign salvation")
	assertEquals(planContainsBuff(plan, T.BUFF_SANCTUARY), false, "pvp plan should prefer better blessings before sanctuary")
end)

test("pvp plan can still assign sanctuary when it is the only castable blessing", function()
	local context = {
		playerName = "Tankadin",
		pallyCount = 1,
		healingPaladinPresent = false,
		pvpInstance = true,
		pvpInstanceType = "arena",
		paladins = {
			{
				name = "Tankadin",
				role = "TANK",
				hasAddon = true,
				skills = {
					[T.BUFF_SANCTUARY] = skill(5, 2),
				},
			},
		},
		players = {
			{name = "Shieldwall", class = "WARRIOR", classID = 1, role = "TANK"},
		},
	}

	local plan = T.BuildSmartPlan(context)
	assertEquals(plan.assignments.Tankadin[1], T.BUFF_SANCTUARY, "pvp should keep sanctuary when it is the only castable option")
	assertEquals(planContainsBuff(plan, T.BUFF_SALVATION), false, "pvp plan should still omit salvation")
end)

test("prot paladin priority uses confirmed spec data over pally count heuristic", function()
	local tankadin = {name = "Tankadin", class = "PALADIN", classID = 5, role = "TANK"}

	-- No spec data: falls back to pally count heuristic
	local priority = T.GetPriorityForUnit(tankadin, {pallyCount = 2})
	assertEquals(priority[1], T.BUFF_KINGS, "no spec data, low pally count: kings first")
	priority = T.GetPriorityForUnit(tankadin, {pallyCount = 5})
	assertEquals(priority[1], T.BUFF_SANCTUARY, "no spec data, high pally count: sanctuary first")

	-- Confirmed no Sanctity Aura: kings always first regardless of pally count
	PPA.peerSpecs["Tankadin"] = {activeTab = 2, sanctityAura = 0, holyShield = 1, impSanc = 2, kings = 1, impMight = 0, impWisdom = 0}
	priority = T.GetPriorityForUnit(tankadin, {pallyCount = 5})
	assertEquals(priority[1], T.BUFF_KINGS, "confirmed no sanctity aura, high pally count: kings first")
	assertEquals(priority[2], T.BUFF_SANCTUARY, "confirmed no sanctity aura: sanctuary second")

	-- Confirmed Sanctity Aura: sanctuary always first regardless of pally count
	PPA.peerSpecs["Tankadin"] = {activeTab = 2, sanctityAura = 1, holyShield = 1, impSanc = 2, kings = 1, impMight = 0, impWisdom = 0}
	priority = T.GetPriorityForUnit(tankadin, {pallyCount = 2})
	assertEquals(priority[1], T.BUFF_SANCTUARY, "confirmed sanctity aura, low pally count: sanctuary first")
	assertEquals(priority[2], T.BUFF_KINGS, "confirmed sanctity aura: kings second")
	priority = T.GetPriorityForUnit(tankadin, {pallyCount = 5})
	assertEquals(priority[1], T.BUFF_SANCTUARY, "confirmed sanctity aura, high pally count: sanctuary first")

	PPA.peerSpecs["Tankadin"] = nil
end)

test("elemental shaman damage prefers wisdom where enhancement prefers might", function()
	local elemental = {name = "Stormbolt", class = "SHAMAN", classID = 9, role = "DAMAGER", spec = "ELEMENTAL"}
	local enhancement = {name = "Windfury", class = "SHAMAN", classID = 9, role = "DAMAGER", spec = "ENHANCEMENT"}
	local context = {healingPaladinPresent = true, pallyCount = 2}

	assertEquals(T.GetPriorityForUnit(elemental, context)[3], T.BUFF_WISDOM, "elemental third priority")
	assertEquals(T.GetPriorityForUnit(enhancement, context)[3], T.BUFF_MIGHT, "enhancement third priority")
end)

test("physical and caster classes keep useful late blessings without useless fillers", function()
	local context = {
		playerName = "Holyone",
		pallyCount = 5,
		healingPaladinPresent = true,
		improvedWisdomPaladinPresent = true,
		paladins = {
			{name = "Holyone", role = "HEALER", hasAddon = true, skills = {[T.BUFF_WISDOM] = skill(7, 2), [T.BUFF_KINGS] = skill(1), [T.BUFF_SALVATION] = skill(1), [T.BUFF_LIGHT] = skill(4)}},
			{name = "Tankadin", role = "TANK", hasAddon = true, skills = {[T.BUFF_WISDOM] = skill(7), [T.BUFF_MIGHT] = skill(7), [T.BUFF_KINGS] = skill(1), [T.BUFF_SALVATION] = skill(1), [T.BUFF_LIGHT] = skill(4), [T.BUFF_SANCTUARY] = skill(5, 2)}},
			{name = "Retone", role = "DAMAGER", hasAddon = true, skills = {[T.BUFF_WISDOM] = skill(7), [T.BUFF_MIGHT] = skill(7, 2), [T.BUFF_KINGS] = skill(1), [T.BUFF_SALVATION] = skill(1), [T.BUFF_LIGHT] = skill(4)}},
			{name = "Rettwo", role = "DAMAGER", hasAddon = true, skills = {[T.BUFF_WISDOM] = skill(7), [T.BUFF_MIGHT] = skill(7), [T.BUFF_KINGS] = skill(1), [T.BUFF_SALVATION] = skill(1), [T.BUFF_LIGHT] = skill(4)}},
			{name = "Holytwo", role = "HEALER", hasAddon = true, skills = {[T.BUFF_WISDOM] = skill(7), [T.BUFF_MIGHT] = skill(7), [T.BUFF_KINGS] = skill(1), [T.BUFF_SALVATION] = skill(1), [T.BUFF_LIGHT] = skill(4)}},
		},
		players = {
			{name = "Slammer", class = "WARRIOR", classID = 1, role = "DAMAGER"},
			{name = "Sneaky", class = "ROGUE", classID = 2, role = "DAMAGER"},
			{name = "Prayer", class = "PRIEST", classID = 3, role = "HEALER"},
			{name = "Frostbolt", class = "MAGE", classID = 7, role = "DAMAGER"},
			{name = "Dotdot", class = "WARLOCK", classID = 8, role = "DAMAGER"},
		},
	}

	local plan = T.BuildSmartPlan(context)
	for _, classMap in pairs(plan.assignments) do
		assertEquals(classMap[1] == T.BUFF_WISDOM, false, "warriors should not receive wisdom filler")
		assertEquals(classMap[2] == T.BUFF_WISDOM, false, "rogues should not receive wisdom filler")
		assertEquals(classMap[3] == T.BUFF_MIGHT, false, "priests should not receive might filler")
		assertEquals(classMap[7] == T.BUFF_MIGHT, false, "mages should not receive might filler")
		assertEquals(classMap[8] == T.BUFF_MIGHT, false, "warlocks should not receive might filler")
	end
	local warriorBuffs = collectClassBuffs(plan, 1)
	local rogueBuffs = collectClassBuffs(plan, 2)
	assertEquals(warriorBuffs[T.BUFF_LIGHT], true, "DPS warriors should receive blessing of light when slots allow")
	assertEquals(warriorBuffs[T.BUFF_SANCTUARY], true, "DPS warriors should receive sanctuary when slots allow")
	assertEquals(rogueBuffs[T.BUFF_LIGHT], true, "rogues should receive blessing of light when slots allow")
	assertEquals(rogueBuffs[T.BUFF_SANCTUARY], true, "rogues should receive sanctuary when slots allow")
end)

test("improved might ret paladin is preferred for might", function()
	local context = {
		playerName = "Holyone",
		pallyCount = 3,
		healingPaladinPresent = true,
		improvedWisdomPaladinPresent = true,
		paladins = {
			{name = "Holyone", role = "HEALER", hasAddon = true, skills = {[T.BUFF_WISDOM] = skill(7, 2), [T.BUFF_MIGHT] = skill(7), [T.BUFF_KINGS] = skill(1), [T.BUFF_SALVATION] = skill(1), [T.BUFF_LIGHT] = skill(4), [T.BUFF_SANCTUARY] = skill(5)}},
			{name = "Tankadin", role = "TANK", hasAddon = true, skills = {[T.BUFF_WISDOM] = skill(7), [T.BUFF_MIGHT] = skill(7), [T.BUFF_KINGS] = skill(1), [T.BUFF_SALVATION] = skill(1), [T.BUFF_LIGHT] = skill(4), [T.BUFF_SANCTUARY] = skill(5, 2)}},
			{name = "Retadin", role = "DAMAGER", hasAddon = true, skills = {[T.BUFF_WISDOM] = skill(7), [T.BUFF_MIGHT] = skill(7, 2), [T.BUFF_KINGS] = skill(1), [T.BUFF_SALVATION] = skill(1), [T.BUFF_LIGHT] = skill(4), [T.BUFF_SANCTUARY] = skill(5)}},
		},
		players = {
			{name = "Sneaky", class = "ROGUE", classID = 2, role = "DAMAGER"},
			{name = "Backstab", class = "ROGUE", classID = 2, role = "DAMAGER"},
		},
	}

	local plan = T.BuildSmartPlan(context)
	assertEquals(plan.assignments.Retadin[2], T.BUFF_MIGHT, "ret paladin with improved might should cover rogue might")
end)

test("improved wisdom paladin is reserved for wisdom", function()
	local context = T.BuildSimulationContext(1)
	local plan = T.BuildSmartPlan(context)
	local wisdomPaladin
	for paladinName, classMap in pairs(plan.assignments) do
		if classMap[5] == T.BUFF_WISDOM then
			wisdomPaladin = paladinName
		end
	end
	assertEquals(wisdomPaladin, "PpaSimHoly", "improved wisdom paladin should cover paladin wisdom")
end)

test("plain sanctuary paladin is fallback when no prot sanctuary exists", function()
	local context = {
		playerName = "Holyone",
		pallyCount = 2,
		healingPaladinPresent = true,
		improvedWisdomPaladinPresent = true,
		paladins = {
			{name = "Holyone", role = "HEALER", hasAddon = true, skills = {[T.BUFF_WISDOM] = skill(7, 2), [T.BUFF_MIGHT] = skill(7), [T.BUFF_KINGS] = skill(1), [T.BUFF_SALVATION] = skill(1), [T.BUFF_LIGHT] = skill(4)}},
			{name = "Retadin", role = "DAMAGER", hasAddon = true, skills = {[T.BUFF_WISDOM] = skill(7), [T.BUFF_MIGHT] = skill(7, 2), [T.BUFF_KINGS] = skill(1), [T.BUFF_SALVATION] = skill(1), [T.BUFF_LIGHT] = skill(4), [T.BUFF_SANCTUARY] = skill(5)}},
		},
		players = {
			{name = "Shieldwall", class = "WARRIOR", classID = 1, role = "TANK"},
			{name = "Slammer", class = "WARRIOR", classID = 1, role = "DAMAGER"},
		},
	}

	local plan = T.BuildSmartPlan(context)
	assertEquals(plan.normalAssignments.Retadin[1].Shieldwall, T.BUFF_SANCTUARY, "plain sanctuary should be used when improved sanctuary is unavailable")
end)

test("uncertain damage druid and shaman are reported for manual choice", function()
	local context = {
		players = {
			{name = "Maybekin", class = "DRUID", classID = 4, role = "DAMAGER"},
			{name = "Maybetotem", class = "SHAMAN", classID = 9, role = "DAMAGER"},
			{name = "Sneaky", class = "ROGUE", classID = 2, role = "DAMAGER"},
		},
	}
	local uncertain = T.GetUncertainPlayers(context)
	assertEquals(#uncertain, 2, "only ambiguous hybrid damage specs should be uncertain")
end)

test("guess mode defaults ambiguous druid and shaman to physical damage specs", function()
	local druid = {name = "Maybekin", class = "DRUID", classID = 4, role = "DAMAGER"}
	local shaman = {name = "Maybetotem", class = "SHAMAN", classID = 9, role = "NONE"}

	T.ApplyGuess(druid)
	T.ApplyGuess(shaman)

	assertEquals(druid.spec, "FERAL", "druid damage guess")
	assertEquals(shaman.role, "DAMAGER", "shaman role guess")
	assertEquals(shaman.spec, "ENHANCEMENT", "shaman damage guess")
end)

test("manual no-addon paladin can receive chat-only easy salvation assignment", function()
	local context = {
		playerName = "Holyone",
		pallyCount = 2,
		healingPaladinPresent = true,
		paladins = {
			{
				name = "Holyone",
				role = "HEALER",
				hasAddon = true,
				skills = {
					[T.BUFF_KINGS] = skill(1, 0),
					[T.BUFF_WISDOM] = skill(7, 2),
				},
			},
			{
				name = "Retwithout",
				role = "DAMAGER",
				hasAddon = false,
				skills = {},
			},
		},
		players = {
			{name = "Sneaky", class = "ROGUE", classID = 2, role = "DAMAGER"},
			{name = "Backstab", class = "ROGUE", classID = 2, role = "DAMAGER"},
		},
	}

	local plan = T.BuildSmartPlan(context)
	assertEquals(plan.manualAssignments.Retwithout.greater[2], T.BUFF_SALVATION, "no-addon DPS paladin should get manual salvation")
	assertEquals(plan.assignments.Holyone[2], T.BUFF_KINGS, "addon paladin should handle kings")
end)

test("missing warlock class still receives assumed class-wide assignments", function()
	local context = baseContext()
	context.players = {
		{name = "Sneaky", class = "ROGUE", classID = 2, role = "DAMAGER"},
		{name = "Backstab", class = "ROGUE", classID = 2, role = "DAMAGER"},
	}

	local plan = T.BuildSmartPlan(context)
	local warlockBuffs = {
		[plan.assignments.Holyone[8]] = true,
		[plan.assignments.Tankadin[8]] = true,
	}
	assertEquals(warlockBuffs[T.BUFF_SALVATION], true, "assumed warlocks should get salvation")
	assertEquals(warlockBuffs[T.BUFF_KINGS], true, "assumed warlocks should get kings")
	assertEquals(plan.normalAssignments.Tankadin and plan.normalAssignments.Tankadin[8], nil, "assumed classes should not create single-target overrides")
end)

test("two paladin tank healer class assignment chooses kings and wisdom", function()
	local context = baseContext()
	context.players = {
		{name = "Holyone", class = "PALADIN", classID = 5, role = "HEALER"},
		{name = "Tankadin", class = "PALADIN", classID = 5, role = "TANK"},
	}

	local plan = T.BuildSmartPlan(context)
	local buffs = {
		[plan.assignments.Holyone[5]] = true,
		[plan.assignments.Tankadin[5]] = true,
	}
	assertEquals(buffs[T.BUFF_KINGS], true, "paladin class should get kings")
	assertEquals(buffs[T.BUFF_WISDOM], true, "paladin class should get wisdom")
	assertEquals(buffs[T.BUFF_SALVATION], nil, "paladin tank/healer pair should not spend a slot on salvation")
end)

test("improved wisdom paladin target gets wisdom even when role is stale", function()
	local context = {
		playerName = "Holyone",
		pallyCount = 1,
		healingPaladinPresent = false,
		paladins = {
			{
				name = "Holyone",
				role = "DAMAGER",
				hasAddon = true,
				skills = {
					[T.BUFF_WISDOM] = skill(7, 2),
					[T.BUFF_KINGS] = skill(1, 0),
					[T.BUFF_SALVATION] = skill(1, 0),
				},
			},
		},
		players = {
			{name = "Holyone", class = "PALADIN", classID = 5, role = "DAMAGER"},
		},
	}

	local plan = T.BuildSmartPlan(context)
	assertEquals(plan.assignments.Holyone[5], T.BUFF_WISDOM, "improved wisdom paladin should prefer wisdom over kings")
end)

test("unimproved healer paladin target gets kings over wisdom", function()
	local context = {
		playerName = "Holyone",
		pallyCount = 1,
		healingPaladinPresent = true,
		improvedWisdomPaladinPresent = false,
		paladins = {
			{
				name = "Holyone",
				role = "HEALER",
				hasAddon = true,
				skills = {
					[T.BUFF_WISDOM] = skill(7, 0),
					[T.BUFF_KINGS] = skill(1, 0),
					[T.BUFF_SALVATION] = skill(1, 0),
				},
			},
		},
		players = {
			{name = "Holyone", class = "PALADIN", classID = 5, role = "HEALER"},
		},
	}

	local plan = T.BuildSmartPlan(context)
	assertEquals(plan.assignments.Holyone[5], T.BUFF_KINGS, "unimproved wisdom healer should prefer kings")
end)

test("healer druid with tank paladin gets kings when wisdom is unimproved", function()
	local context = {
		playerName = "Turing",
		pallyCount = 1,
		healingPaladinPresent = false,
		improvedWisdomPaladinPresent = false,
		paladins = {
			{
				name = "Turing",
				role = "TANK",
				hasAddon = true,
				skills = {
					[T.BUFF_WISDOM] = skill(7, 0),
					[T.BUFF_KINGS] = skill(1, 0),
					[T.BUFF_SALVATION] = skill(1, 0),
					[T.BUFF_SANCTUARY] = skill(5, 2),
				},
			},
		},
		players = {
			{name = "Turing", class = "PALADIN", classID = 5, role = "TANK"},
			{name = "Lopedope", class = "DRUID", classID = 4, role = "HEALER"},
			{name = "Smallpimp", class = "DRUID", classID = 4, role = "DAMAGER", spec = "FERAL"},
		},
	}

	local plan = T.BuildSmartPlan(context)
	assertEquals(plan.assignments.Turing[4], T.BUFF_KINGS, "druid class should get kings when healer druid is present and wisdom is unimproved")
end)

test("healer druid with tank paladin gets wisdom override when wisdom is improved", function()
	local context = {
		playerName = "Turing",
		pallyCount = 1,
		healingPaladinPresent = false,
		improvedWisdomPaladinPresent = true,
		paladins = {
			{
				name = "Turing",
				role = "TANK",
				hasAddon = true,
				skills = {
					[T.BUFF_WISDOM] = skill(7, 2),
					[T.BUFF_KINGS] = skill(1, 0),
					[T.BUFF_SALVATION] = skill(1, 0),
					[T.BUFF_SANCTUARY] = skill(5, 2),
				},
			},
		},
		players = {
			{name = "Turing", class = "PALADIN", classID = 5, role = "TANK"},
			{name = "Lopedope", class = "DRUID", classID = 4, role = "HEALER"},
			{name = "Smallpimp", class = "DRUID", classID = 4, role = "DAMAGER", spec = "FERAL"},
		},
	}

	local plan = T.BuildSmartPlan(context)
	assertEquals(plan.normalAssignments.Turing[4].Lopedope, T.BUFF_WISDOM, "improved wisdom should override the healer druid's class blessing")
end)

test("tank paladin without improved wisdom gives healer priest kings", function()
	local context = {
		playerName = "Tankadin",
		pallyCount = 1,
		healingPaladinPresent = false,
		paladins = {
			{
				name = "Tankadin",
				role = "TANK",
				hasAddon = true,
				skills = {
					[T.BUFF_WISDOM] = skill(7, 0),
					[T.BUFF_KINGS] = skill(1, 0),
				},
			},
		},
		players = {
			{name = "Prayer", class = "PRIEST", classID = 3, role = "HEALER"},
		},
	}

	local plan = T.BuildSmartPlan(context)
	assertEquals(plan.assignments.Tankadin[3], T.BUFF_KINGS, "unimproved wisdom tank should give healer priests kings")
end)

test("improved wisdom paladin gives healer priest wisdom", function()
	local context = {
		playerName = "Holyone",
		pallyCount = 1,
		healingPaladinPresent = true,
		paladins = {
			{
				name = "Holyone",
				role = "HEALER",
				hasAddon = true,
				skills = {
					[T.BUFF_WISDOM] = skill(7, 2),
					[T.BUFF_KINGS] = skill(1, 0),
				},
			},
		},
		players = {
			{name = "Prayer", class = "PRIEST", classID = 3, role = "HEALER"},
		},
	}

	local plan = T.BuildSmartPlan(context)
	assertEquals(plan.assignments.Holyone[3], T.BUFF_WISDOM, "improved wisdom should stay preferred for healer priests")
end)

test("aura assignment gives improved devotion paladin devo first", function()
	local context = baseContext()
	context.players = {
		{name = "Holyone", class = "PALADIN", classID = 5, role = "HEALER"},
		{name = "Tankadin", class = "PALADIN", classID = 5, role = "TANK"},
	}

	local plan = T.BuildSmartPlan(context)
	assertEquals(plan.auraAssignments.Holyone, T.AURA_DEVOTION, "improved devotion paladin should get devo")
	assertEquals(plan.auraAssignments.Tankadin, T.AURA_RETRIBUTION, "next aura should follow devo > ret > concentration")
end)

test("paladin role can be inferred from improved blessing talents", function()
	assertEquals(T.InferPaladinRoleFromSkills({[T.BUFF_SANCTUARY] = skill(5, 2)}), "TANK", "improved sanctuary implies tank")
	assertEquals(T.InferPaladinRoleFromSkills({[T.BUFF_WISDOM] = skill(7, 2)}), "HEALER", "improved wisdom implies healer")
end)

test("runtime context refresh repairs PallyPower cooldown tables after ScanSpells", function()
	local old = {
		PallyPower = _G.PallyPower,
		AllPallys = _G.AllPallys,
		IsInRaid = _G.IsInRaid,
		UnitExists = _G.UnitExists,
		MAX_PARTY_MEMBERS = _G.MAX_PARTY_MEMBERS,
	}
	local scanCalls, cooldownCalls, inventoryCalls, updateCalls = 0, 0, 0, 0

	_G.AllPallys = {}
	_G.IsInRaid = function()
		return false
	end
	_G.UnitExists = function()
		return false
	end
	_G.MAX_PARTY_MEMBERS = 0
	_G.PallyPower = {
		player = "Turing",
		ScanSpells = function()
			scanCalls = scanCalls + 1
			_G.AllPallys.Turing = {
				CooldownInfo = {
					[1] = {},
					[2] = {},
				},
			}
		end,
		ScanCooldowns = function()
			cooldownCalls = cooldownCalls + 1
			_G.AllPallys.Turing.CooldownInfo[1].start = 0
			_G.AllPallys.Turing.CooldownInfo[1].duration = 0
		end,
		ScanInventory = function()
			inventoryCalls = inventoryCalls + 1
		end,
		UpdateRoster = function()
			updateCalls = updateCalls + 1
		end,
	}

	T.BuildRuntimeContext(false)

	assertEquals(scanCalls, 1, "ScanSpells should run")
	assertEquals(cooldownCalls, 1, "ScanCooldowns should follow ScanSpells")
	assertEquals(inventoryCalls, 1, "ScanInventory should run")
	assertEquals(updateCalls, 1, "UpdateRoster should run")
	assertEquals(_G.AllPallys.Turing.CooldownInfo[1].start, 0, "first cooldown start should be safe")
	assertEquals(_G.AllPallys.Turing.CooldownInfo[2].start, 0, "second cooldown start should be repaired")
	assertEquals(_G.AllPallys.Turing.CooldownInfo[2].duration, 0, "second cooldown duration should be repaired")

	_G.PallyPower = old.PallyPower
	_G.AllPallys = old.AllPallys
	_G.IsInRaid = old.IsInRaid
	_G.UnitExists = old.UnitExists
	_G.MAX_PARTY_MEMBERS = old.MAX_PARTY_MEMBERS
end)

test("runtime context marks battlegrounds and arenas as pvp assignment contexts", function()
	local old = {
		PallyPower = _G.PallyPower,
		AllPallys = _G.AllPallys,
		IsInInstance = _G.IsInInstance,
		CollectRoster = PPA.CollectRoster,
	}

	_G.PallyPower = {player = "Holyone"}
	_G.AllPallys = {}
	PPA.CollectRoster = function()
		return {}
	end

	_G.IsInInstance = function()
		return true, "pvp"
	end
	local context = T.BuildRuntimeContext(false)
	assertEquals(context.pvpInstance, true, "battleground should be a pvp assignment context")
	assertEquals(context.pvpInstanceType, "pvp", "battleground instance type")

	_G.IsInInstance = function()
		return true, "arena"
	end
	context = T.BuildRuntimeContext(false)
	assertEquals(context.pvpInstance, true, "arena should be a pvp assignment context")
	assertEquals(context.pvpInstanceType, "arena", "arena instance type")

	_G.IsInInstance = function()
		return true, "raid"
	end
	context = T.BuildRuntimeContext(false)
	assertEquals(context.pvpInstance, false, "raid should keep normal assignment priorities")
	assertEquals(context.pvpInstanceType, nil, "non-pvp instance type")

	_G.PallyPower = old.PallyPower
	_G.AllPallys = old.AllPallys
	_G.IsInInstance = old.IsInInstance
	PPA.CollectRoster = old.CollectRoster
end)

test("assignment alert reports class-wide changes for the local paladin", function()
	local old = {
		PallyPower = _G.PallyPower,
		PallyPower_Assignments = _G.PallyPower_Assignments,
		PallyPower_NormalAssignments = _G.PallyPower_NormalAssignments,
		PALLYPOWER_MAXCLASSES = _G.PALLYPOWER_MAXCLASSES,
		DEFAULT_CHAT_FRAME = _G.DEFAULT_CHAT_FRAME,
	}
	local messages = {}

	_G.PallyPower = {player = "Holyone"}
	_G.PALLYPOWER_MAXCLASSES = 9
	_G.PallyPower_Assignments = {Holyone = {[1] = 0}}
	_G.PallyPower_NormalAssignments = {Holyone = {}}
	_G.DEFAULT_CHAT_FRAME = {
		AddMessage = function(_, message)
			messages[#messages + 1] = message
		end,
	}

	local before = T.SnapshotOwnAssignments()
	_G.PallyPower_Assignments.Holyone[1] = T.BUFF_KINGS
	local after = T.SnapshotOwnAssignments()
	T.ReportAssignmentChanges("Leadadin", before, after)

	assertEquals(
		messages[1],
		"|cff33ff99PPA|r: Leadadin has assigned you to Blessing of Kings all Warriors.",
		"class-wide assignment alert"
	)

	_G.PallyPower = old.PallyPower
	_G.PallyPower_Assignments = old.PallyPower_Assignments
	_G.PallyPower_NormalAssignments = old.PallyPower_NormalAssignments
	_G.PALLYPOWER_MAXCLASSES = old.PALLYPOWER_MAXCLASSES
	_G.DEFAULT_CHAT_FRAME = old.DEFAULT_CHAT_FRAME
end)

test("assignment alert reports single-buff changes for the local paladin", function()
	local old = {
		PallyPower = _G.PallyPower,
		PallyPower_Assignments = _G.PallyPower_Assignments,
		PallyPower_NormalAssignments = _G.PallyPower_NormalAssignments,
		PALLYPOWER_MAXCLASSES = _G.PALLYPOWER_MAXCLASSES,
		DEFAULT_CHAT_FRAME = _G.DEFAULT_CHAT_FRAME,
	}
	local messages = {}

	_G.PallyPower = {player = "Holyone"}
	_G.PALLYPOWER_MAXCLASSES = 9
	_G.PallyPower_Assignments = {Holyone = {}}
	_G.PallyPower_NormalAssignments = {Holyone = {[1] = {}}}
	_G.DEFAULT_CHAT_FRAME = {
		AddMessage = function(_, message)
			messages[#messages + 1] = message
		end,
	}

	local before = T.SnapshotOwnAssignments()
	_G.PallyPower_NormalAssignments.Holyone[1].Billwarrior = T.BUFF_KINGS
	local after = T.SnapshotOwnAssignments()
	T.ReportAssignmentChanges("Leadadin", before, after)

	assertEquals(
		messages[1],
		"|cff33ff99PPA|r: Leadadin has assigned you to single buff Blessing of Kings to Billwarrior.",
		"single-buff assignment alert"
	)

	_G.PallyPower = old.PallyPower
	_G.PallyPower_Assignments = old.PallyPower_Assignments
	_G.PallyPower_NormalAssignments = old.PallyPower_NormalAssignments
	_G.PALLYPOWER_MAXCLASSES = old.PALLYPOWER_MAXCLASSES
	_G.DEFAULT_CHAT_FRAME = old.DEFAULT_CHAT_FRAME
end)

test("assignment alert ignores local paladin changes", function()
	local old = {
		PallyPower = _G.PallyPower,
		PallyPower_Assignments = _G.PallyPower_Assignments,
		PallyPower_NormalAssignments = _G.PallyPower_NormalAssignments,
		PALLYPOWER_MAXCLASSES = _G.PALLYPOWER_MAXCLASSES,
		DEFAULT_CHAT_FRAME = _G.DEFAULT_CHAT_FRAME,
	}
	local messages = {}

	_G.PallyPower = {player = "Holyone"}
	_G.PALLYPOWER_MAXCLASSES = 9
	_G.PallyPower_Assignments = {Holyone = {[1] = 0}}
	_G.PallyPower_NormalAssignments = {Holyone = {}}
	_G.DEFAULT_CHAT_FRAME = {
		AddMessage = function(_, message)
			messages[#messages + 1] = message
		end,
	}

	local before = T.SnapshotOwnAssignments()
	_G.PallyPower_Assignments.Holyone[1] = T.BUFF_KINGS
	local after = T.SnapshotOwnAssignments()
	T.ReportAssignmentChanges("Holyone", before, after)

	assertEquals(#messages, 0, "local changes should stay quiet")

	_G.PallyPower = old.PallyPower
	_G.PallyPower_Assignments = old.PallyPower_Assignments
	_G.PallyPower_NormalAssignments = old.PallyPower_NormalAssignments
	_G.PALLYPOWER_MAXCLASSES = old.PALLYPOWER_MAXCLASSES
	_G.DEFAULT_CHAT_FRAME = old.DEFAULT_CHAT_FRAME
end)

test("assignment alert hook reports after PallyPower accepts incoming assignments", function()
	local old = {
		PallyPower = _G.PallyPower,
		PallyPower_Assignments = _G.PallyPower_Assignments,
		PallyPower_NormalAssignments = _G.PallyPower_NormalAssignments,
		PALLYPOWER_MAXCLASSES = _G.PALLYPOWER_MAXCLASSES,
		DEFAULT_CHAT_FRAME = _G.DEFAULT_CHAT_FRAME,
		assignmentAlertsHooked = PPA.assignmentAlertsHooked,
	}
	local messages = {}

	PPA.assignmentAlertsHooked = false
	_G.PALLYPOWER_MAXCLASSES = 9
	_G.PallyPower_Assignments = {Holyone = {[1] = 0}}
	_G.PallyPower_NormalAssignments = {Holyone = {}}
	_G.DEFAULT_CHAT_FRAME = {
		AddMessage = function(_, message)
			messages[#messages + 1] = message
		end,
	}
	_G.PallyPower = {
		player = "Holyone",
		ParseMessage = function(_, _, message)
			if message == "ASSIGN Holyone 1 3" then
				_G.PallyPower_Assignments.Holyone[1] = T.BUFF_KINGS
			end
		end,
	}

	PPA:HookAssignmentAlerts()
	_G.PallyPower:ParseMessage("Leadadin", "ASSIGN Holyone 1 3")

	assertEquals(
		messages[1],
		"|cff33ff99PPA|r: Leadadin has assigned you to Blessing of Kings all Warriors.",
		"hooked ParseMessage assignment alert"
	)

	_G.PallyPower = old.PallyPower
	_G.PallyPower_Assignments = old.PallyPower_Assignments
	_G.PallyPower_NormalAssignments = old.PallyPower_NormalAssignments
	_G.PALLYPOWER_MAXCLASSES = old.PALLYPOWER_MAXCLASSES
	_G.DEFAULT_CHAT_FRAME = old.DEFAULT_CHAT_FRAME
	PPA.assignmentAlertsHooked = old.assignmentAlertsHooked
end)

test("assignment trace hook reports external changes to other paladin rows", function()
	local old = {
		PallyPower = _G.PallyPower,
		PallyPower_Assignments = _G.PallyPower_Assignments,
		PallyPower_NormalAssignments = _G.PallyPower_NormalAssignments,
		PallyPower_AuraAssignments = _G.PallyPower_AuraAssignments,
		PALLYPOWER_MAXCLASSES = _G.PALLYPOWER_MAXCLASSES,
		DEFAULT_CHAT_FRAME = _G.DEFAULT_CHAT_FRAME,
		AllPallys = _G.AllPallys,
		PallyPowerAdvancedDB = _G.PallyPowerAdvancedDB,
		db = PPA.db,
		assignmentAlertsHooked = PPA.assignmentAlertsHooked,
	}
	local messages = {}

	PPA.assignmentAlertsHooked = false
	_G.PallyPowerAdvancedDB = {debug = false, specs = {}, assignmentTrace = true}
	PPA.db = nil
	_G.PALLYPOWER_MAXCLASSES = 9
	_G.AllPallys = {Holyone = {}, Tankadin = {}}
	_G.PallyPower_Assignments = {
		Holyone = {[5] = 0},
		Tankadin = {[5] = T.BUFF_KINGS},
	}
	_G.PallyPower_NormalAssignments = {Holyone = {}, Tankadin = {}}
	_G.PallyPower_AuraAssignments = {Holyone = 0, Tankadin = 0}
	_G.DEFAULT_CHAT_FRAME = {
		AddMessage = function(_, message)
			messages[#messages + 1] = message
		end,
	}
	_G.PallyPower = {
		player = "Holyone",
		ParseMessage = function(_, _, message)
			if message == "ASSIGN Tankadin 5 1" then
				_G.PallyPower_Assignments.Tankadin[5] = T.BUFF_WISDOM
			end
		end,
	}

	PPA:HookAssignmentAlerts()
	_G.PallyPower:ParseMessage("Leadadin", "ASSIGN Tankadin 5 1")

	assertEquals(
		messages[1],
		"|cff33ff99PPA|r: Trace: Leadadin set Tankadin to Blessing of Wisdom on all Paladins.",
		"assignment trace should identify sender for other rows"
	)

	_G.PallyPower = old.PallyPower
	_G.PallyPower_Assignments = old.PallyPower_Assignments
	_G.PallyPower_NormalAssignments = old.PallyPower_NormalAssignments
	_G.PallyPower_AuraAssignments = old.PallyPower_AuraAssignments
	_G.PALLYPOWER_MAXCLASSES = old.PALLYPOWER_MAXCLASSES
	_G.DEFAULT_CHAT_FRAME = old.DEFAULT_CHAT_FRAME
	_G.AllPallys = old.AllPallys
	_G.PallyPowerAdvancedDB = old.PallyPowerAdvancedDB
	PPA.db = old.db
	PPA.assignmentAlertsHooked = old.assignmentAlertsHooked
end)

test("assignment conflict warning waits for second external burst after local assign", function()
	local old = {
		PallyPower = _G.PallyPower,
		PallyPower_Assignments = _G.PallyPower_Assignments,
		PallyPower_NormalAssignments = _G.PallyPower_NormalAssignments,
		PallyPower_AuraAssignments = _G.PallyPower_AuraAssignments,
		PALLYPOWER_MAXCLASSES = _G.PALLYPOWER_MAXCLASSES,
		DEFAULT_CHAT_FRAME = _G.DEFAULT_CHAT_FRAME,
		AllPallys = _G.AllPallys,
		PallyPowerAdvancedDB = _G.PallyPowerAdvancedDB,
		GetTime = _G.GetTime,
		db = PPA.db,
		assignmentAlertsHooked = PPA.assignmentAlertsHooked,
		assignmentConflictWatch = PPA.assignmentConflictWatch,
	}
	local messages = {}
	local now = 100

	PPA.assignmentAlertsHooked = false
	PPA.assignmentConflictWatch = nil
	_G.PallyPowerAdvancedDB = {debug = false, specs = {}, assignmentTrace = false}
	PPA.db = nil
	_G.GetTime = function()
		return now
	end
	_G.PALLYPOWER_MAXCLASSES = 9
	_G.AllPallys = {Holyone = {}, Tankadin = {}}
	_G.PallyPower_Assignments = {
		Holyone = {[5] = 0},
		Tankadin = {[5] = T.BUFF_KINGS},
	}
	_G.PallyPower_NormalAssignments = {Holyone = {}, Tankadin = {}}
	_G.PallyPower_AuraAssignments = {Holyone = 0, Tankadin = 0}
	_G.DEFAULT_CHAT_FRAME = {
		AddMessage = function(_, message)
			messages[#messages + 1] = message
		end,
	}
	_G.PallyPower = {
		player = "Holyone",
		ParseMessage = function(_, _, message)
			if message == "ASSIGN Tankadin 5 1" then
				_G.PallyPower_Assignments.Tankadin[5] = T.BUFF_WISDOM
			elseif message == "ASSIGN Tankadin 5 3" then
				_G.PallyPower_Assignments.Tankadin[5] = T.BUFF_KINGS
			end
		end,
	}

	PPA:HookAssignmentAlerts()
	PPA:NoteLocalAssignmentAction("Auto-Assign")
	_G.PallyPower:ParseMessage("Leadadin", "ASSIGN Tankadin 5 1")
	assertEquals(#messages, 0, "first external burst should be quiet")

	now = 100.5
	_G.PallyPower:ParseMessage("Leadadin", "ASSIGN Tankadin 5 3")
	assertEquals(#messages, 0, "same sender burst should stay grouped")

	now = 103
	_G.PallyPower:ParseMessage("Leadadin", "ASSIGN Tankadin 5 1")

	assertEquals(
		messages[1],
		"|cff33ff99PPA|r: Assignment conflict: Leadadin overwrote assignments again 3.0s after your Auto-Assign.",
		"conflict warning headline"
	)
	assertEquals(
		messages[2],
		"|cff33ff99PPA|r: Reason: your client accepted a second external PallyPower assignment burst inside 5s; Free Assignment or raid lead/assist can allow that override.",
		"conflict warning reason"
	)
	assertEquals(
		messages[3],
		"|cff33ff99PPA|r: Last change: Tankadin -> Blessing of Wisdom on all Paladins.",
		"conflict warning detail"
	)

	_G.PallyPower = old.PallyPower
	_G.PallyPower_Assignments = old.PallyPower_Assignments
	_G.PallyPower_NormalAssignments = old.PallyPower_NormalAssignments
	_G.PallyPower_AuraAssignments = old.PallyPower_AuraAssignments
	_G.PALLYPOWER_MAXCLASSES = old.PALLYPOWER_MAXCLASSES
	_G.DEFAULT_CHAT_FRAME = old.DEFAULT_CHAT_FRAME
	_G.AllPallys = old.AllPallys
	_G.PallyPowerAdvancedDB = old.PallyPowerAdvancedDB
	_G.GetTime = old.GetTime
	PPA.db = old.db
	PPA.assignmentAlertsHooked = old.assignmentAlertsHooked
	PPA.assignmentConflictWatch = old.assignmentConflictWatch
end)

test("buff warning sound temporarily unmutes and restores audio cvars", function()
	local old = {
		SOUNDKIT = _G.SOUNDKIT,
		PlaySound = _G.PlaySound,
		GetCVar = _G.GetCVar,
		GetCVarBool = _G.GetCVarBool,
		SetCVar = _G.SetCVar,
		C_Timer = _G.C_Timer,
	}
	local cvars = {
		Sound_EnableAllSound = "0",
		Sound_EnableSFX = "0",
		Sound_MasterVolume = "0",
	}
	local playedSound, playedChannel

	_G.SOUNDKIT = {
		READY_CHECK = 12345,
		UI_PROFESSIONS_NEW_RECIPE_LEARNED_TOAST = 67890,
	}
	_G.GetCVar = function(name)
		return cvars[name]
	end
	_G.GetCVarBool = function(name)
		return cvars[name] == "1"
	end
	_G.SetCVar = function(name, value)
		cvars[name] = tostring(value)
	end
	_G.C_Timer = {
		After = function(_, callback)
			callback()
		end,
	}
	_G.PlaySound = function(sound, channel)
		playedSound = sound
		playedChannel = channel
		assertEquals(cvars.Sound_EnableAllSound, "1", "all sound should be enabled before alert")
		assertEquals(cvars.Sound_EnableSFX, "1", "sfx should be enabled before alert")
		assertEquals(cvars.Sound_MasterVolume, "0.5", "master volume should be raised before alert")
	end

	assertEquals(T.IsGameSoundMuted(), true, "sound should start muted")
	assertEquals(T.PlayBuffWarningSound(), true, "sound playback should be attempted")
	assertEquals(playedSound, 67890, "chime-style warning sound should play")
	assertEquals(playedChannel, "Master", "warning should use master channel")
	assertEquals(cvars.Sound_EnableAllSound, "0", "all sound should be restored")
	assertEquals(cvars.Sound_EnableSFX, "0", "sfx should be restored")
	assertEquals(cvars.Sound_MasterVolume, "0", "master volume should be restored")

	_G.SOUNDKIT = old.SOUNDKIT
	_G.PlaySound = old.PlaySound
	_G.GetCVar = old.GetCVar
	_G.GetCVarBool = old.GetCVarBool
	_G.SetCVar = old.SetCVar
	_G.C_Timer = old.C_Timer
end)

test("buff warning sound fires once for a new expiring assigned blessing", function()
	local old = {
		db = PPA.db,
		PallyPowerAdvancedDB = _G.PallyPowerAdvancedDB,
		FindExpiringAssignedBuffs = PPA.FindExpiringAssignedBuffs,
		PlayBuffWarningSound = PPA.PlayBuffWarningSound,
		buffWarningState = PPA.buffWarningState,
		lastBuffWarningSound = PPA.lastBuffWarningSound,
	}
	local plays = 0

	_G.PallyPowerAdvancedDB = {debug = false, specs = {}, buffWarningSound = true}
	PPA.db = nil
	PPA.buffWarningState = nil
	PPA.lastBuffWarningSound = nil
	PPA.FindExpiringAssignedBuffs = function()
		return {
			{
				unitName = "Billwarrior",
				classID = 1,
				buffID = T.BUFF_KINGS,
				assignmentType = "normal",
				remaining = 55,
			},
		}
	end
	PPA.PlayBuffWarningSound = function()
		plays = plays + 1
		return true
	end

	T.CheckBuffWarnings(100)
	T.CheckBuffWarnings(110)
	assertEquals(plays, 1, "same active warning should only play once")

	PPA.FindExpiringAssignedBuffs = function()
		return {}
	end
	T.CheckBuffWarnings(120)
	PPA.FindExpiringAssignedBuffs = old.FindExpiringAssignedBuffs
	PPA.FindExpiringAssignedBuffs = function()
		return {
			{
				unitName = "Billwarrior",
				classID = 1,
				buffID = T.BUFF_KINGS,
				assignmentType = "normal",
				remaining = 50,
			},
		}
	end
	T.CheckBuffWarnings(131)
	assertEquals(plays, 2, "warning should re-arm after the buff leaves and re-enters threshold")

	PPA.db = old.db
	_G.PallyPowerAdvancedDB = old.PallyPowerAdvancedDB
	PPA.FindExpiringAssignedBuffs = old.FindExpiringAssignedBuffs
	PPA.PlayBuffWarningSound = old.PlayBuffWarningSound
	PPA.buffWarningState = old.buffWarningState
	PPA.lastBuffWarningSound = old.lastBuffWarningSound
end)

test("expiring assigned blessings are detected from PallyPower assignments", function()
	local old = {
		PallyPower = _G.PallyPower,
		PallyPower_Assignments = _G.PallyPower_Assignments,
		PallyPower_NormalAssignments = _G.PallyPower_NormalAssignments,
		CollectRoster = PPA.CollectRoster,
	}

	_G.PallyPower = {
		player = "Holyone",
		Spells = {[T.BUFF_KINGS] = "Blessing of Kings"},
		GSpells = {[T.BUFF_KINGS] = "Greater Blessing of Kings"},
		IsBuffActive = function(_, spell, greaterSpell, unit)
			assertEquals(spell, "Blessing of Kings", "normal spell should be checked")
			assertEquals(greaterSpell, "Greater Blessing of Kings", "greater spell should be checked")
			assertEquals(unit, "raid8", "unit token should be checked")
			return 55, 600, "Greater Blessing of Kings"
		end,
	}
	_G.PallyPower_Assignments = {Holyone = {[8] = T.BUFF_KINGS}}
	_G.PallyPower_NormalAssignments = {Holyone = {}}
	PPA.CollectRoster = function()
		return {
			{name = "Billwarlock", unit = "raid8", classID = 8},
		}
	end

	local warnings = T.FindExpiringAssignedBuffs(60)
	assertEquals(#warnings, 1, "one assigned buff should be expiring")
	assertEquals(warnings[1].unitName, "Billwarlock", "warning target")
	assertEquals(warnings[1].buffID, T.BUFF_KINGS, "warning buff")

	_G.PallyPower = old.PallyPower
	_G.PallyPower_Assignments = old.PallyPower_Assignments
	_G.PallyPower_NormalAssignments = old.PallyPower_NormalAssignments
	PPA.CollectRoster = old.CollectRoster
end)

test("simulation context creates a full raid with expected coverage", function()
	local context = T.BuildSimulationContext(42)
	local classes = {}
	local roles = {TANK = 0, HEALER = 0, DAMAGER = 0}
	local paladinNames = {}

	assertEquals(#context.players, 25, "simulated raid size")
	for _, unit in ipairs(context.players) do
		classes[unit.class] = true
		roles[unit.role] = (roles[unit.role] or 0) + 1
		if unit.class == "PALADIN" then
			paladinNames[unit.name] = true
			assertEquals(string.find(unit.name, "PpaSimPally") == nil, true, "simulated paladin names should include role")
		end
		assertEquals(unit.unit, "raid" .. tostring(_), "simulated unit token")
	end

	assertEquals(roles.TANK >= 2 and roles.TANK <= 3, true, "simulated tank count")
	assertEquals(roles.HEALER >= 4 and roles.HEALER <= 9, true, "simulated healer count")
	assertEquals(roles.DAMAGER, 25 - roles.TANK - roles.HEALER, "simulated dps count")
	for _, classFile in ipairs({"WARRIOR", "ROGUE", "PRIEST", "DRUID", "PALADIN", "HUNTER", "MAGE", "WARLOCK", "SHAMAN"}) do
		assertEquals(classes[classFile], true, "simulated class coverage for " .. classFile)
	end
	assertEquals(context.pallyCount >= 3 and context.pallyCount <= 5, true, "simulated paladin count")
	assertEquals(context.playerName, "PpaSimHoly", "simulated local paladin")
	assertEquals(paladinNames.PpaSimHoly, true, "simulation should include a holy paladin")
	assertEquals(paladinNames.PpaSimProt1, true, "simulation should include a prot paladin")
	assertEquals(paladinNames.PpaSimRet1, true, "simulation should include a ret paladin")
	assertEquals(#T.GetUncertainPlayers(context), 0, "simulation should not prompt for specs")
end)

test("simulation names identify ambiguous roles and specs", function()
	local context = T.BuildSimulationContext(1)
	local sawTankWar = false
	local sawDpsWar = false
	local sawFeralDruid = false
	local sawBalanceDruid = false
	local sawRestoShaman = false
	local sawEleShaman = false

	for _, unit in ipairs(context.players) do
		if unit.class == "WARRIOR" and unit.role == "TANK" then
			assertEquals(string.find(unit.name, "TankWar") ~= nil, true, "tank warrior name")
			sawTankWar = true
		elseif unit.class == "WARRIOR" and unit.role == "DAMAGER" then
			assertEquals(string.find(unit.name, "DpsWar") ~= nil, true, "DPS warrior name")
			sawDpsWar = true
		elseif unit.class == "DRUID" and unit.spec == "FERAL" then
			assertEquals(string.find(unit.name, "FeralDruid") ~= nil, true, "feral druid name")
			sawFeralDruid = true
		elseif unit.class == "DRUID" and unit.spec == "BALANCE" then
			assertEquals(string.find(unit.name, "BalanceDruid") ~= nil, true, "balance druid name")
			sawBalanceDruid = true
		elseif unit.class == "SHAMAN" and unit.role == "HEALER" then
			assertEquals(string.find(unit.name, "RestoShaman") ~= nil, true, "restoration shaman name")
			sawRestoShaman = true
		elseif unit.class == "SHAMAN" and unit.spec == "ELEMENTAL" then
			assertEquals(string.find(unit.name, "EleShaman") ~= nil, true, "elemental shaman name")
			sawEleShaman = true
		end
	end

	assertEquals(sawTankWar, true, "seed should include a tank warrior")
	assertEquals(sawDpsWar, true, "seed should include a DPS warrior")
	assertEquals(sawFeralDruid, true, "seed should include a feral druid")
	assertEquals(sawBalanceDruid, true, "seed should include a balance druid")
	assertEquals(sawRestoShaman, true, "seed should include a restoration shaman")
	assertEquals(sawEleShaman, true, "seed should include an elemental shaman")
end)

test("simulation context is auto-assignable", function()
	local context = T.BuildSimulationContext(73)
	local plan = T.BuildSmartPlan(context)

	assertEquals(#plan.warnings, 0, "simulation should have paladins")
	assertEquals(#plan.classPlans, 9, "simulation should plan every class")
	assertEquals(plan.assignments.PpaSimHoly ~= nil, true, "local simulated paladin should receive assignments")
	assertEquals(type(plan.auraAssignments.PpaSimHoly), "number", "local simulated paladin should receive an aura assignment")
end)

test("simulation prot paladin provides blessing of sanctuary", function()
	local context = T.BuildSimulationContext(73)
	local protName
	for _, paladin in ipairs(context.paladins) do
		if paladin.name == "PpaSimProt1" then
			protName = paladin.name
			assertEquals(paladin.role, "TANK", "prot paladin role")
			assertEquals(T.CanPaladinBuff(paladin, T.BUFF_SANCTUARY), true, "prot paladin can cast sanctuary")
		end
		if paladin.name == "PpaSimRet1" then
			assertEquals(T.CanPaladinBuff(paladin, T.BUFF_SANCTUARY), true, "ret paladin can cast plain sanctuary")
			assertEquals(paladin.skills[T.BUFF_MIGHT].talent, 2, "ret paladin should model improved might")
		end
	end
	assertEquals(protName, "PpaSimProt1", "simulation should include prot paladin")

	local plan = T.BuildSmartPlan(context)
	local protProvidesSanctuary = false
	for _, buff in pairs(plan.assignments[protName] or {}) do
		if buff == T.BUFF_SANCTUARY then
			protProvidesSanctuary = true
		end
	end
	for _, targets in pairs(plan.normalAssignments[protName] or {}) do
		for _, buff in pairs(targets or {}) do
			if buff == T.BUFF_SANCTUARY then
				protProvidesSanctuary = true
			end
		end
	end
	assertEquals(protProvidesSanctuary, true, "prot paladin should provide sanctuary")

	for _, unit in ipairs(context.players) do
		if unit.role == "TANK" then
			local hasSanctuary = false
			for _, classMap in pairs(plan.assignments or {}) do
				if classMap[unit.classID] == T.BUFF_SANCTUARY then
					hasSanctuary = true
				end
			end
			for _, classMap in pairs(plan.normalAssignments or {}) do
				if classMap[unit.classID] and classMap[unit.classID][unit.name] == T.BUFF_SANCTUARY then
					hasSanctuary = true
				end
			end
			assertEquals(hasSanctuary, true, unit.name .. " should have sanctuary coverage")
		end
	end
end)

test("last pass simplifies prot toward kings without downgrading improved sanctuary", function()
	local context = T.BuildSimulationContext(1)
	local plan = T.BuildSmartPlan(context)
	local distinct = countDistinctBuffs(plan.assignments.PpaSimProt1)

	assertEquals(plan.assignments.PpaSimProt1[1], T.BUFF_SANCTUARY, "improved sanctuary should stay on prot for warriors")
	assertEquals(plan.assignments.PpaSimProt1[2], T.BUFF_KINGS, "prot should take rogue kings after safe swap")
	assertEquals(plan.assignments.PpaSimProt1[6], T.BUFF_KINGS, "prot should take hunter kings after safe swap")
	assertEquals(plan.assignments.PpaSimHoly[2], T.BUFF_SALVATION, "holy should receive rogue salvation after swap")
	assertEquals(plan.assignments.PpaSimHoly[6], T.BUFF_SALVATION, "holy should receive hunter salvation after swap")
	assertEquals(distinct, 2, "prot should only keep kings plus protected sanctuary")
end)

test("last pass can create a one-blessing specialist with equal-quality swaps", function()
	local context = T.BuildSimulationContext(1)
	for _, paladin in ipairs(context.paladins) do
		if paladin.name == "PpaSimProt1" then
			paladin.skills[T.BUFF_SANCTUARY].talent = 0
		end
	end

	local plan = T.BuildSmartPlan(context)
	local distinct, buffs = countDistinctBuffs(plan.assignments.PpaSimProt1)

	assertEquals(distinct, 1, "prot should become a one-blessing specialist")
	assertEquals(buffs[T.BUFF_KINGS], true, "prot should become the kings paladin")
	for classID = 1, 9 do
		assertEquals(plan.assignments.PpaSimProt1[classID], T.BUFF_KINGS, "prot kings class " .. tostring(classID))
	end
end)

test("runtime context uses active simulation instead of live unit APIs", function()
	local old = {
		simulation = PPA.simulation,
		IsInRaid = _G.IsInRaid,
	}

	PPA.simulation = {
		active = true,
		context = T.BuildSimulationContext(19),
	}
	_G.IsInRaid = function()
		error("live raid API should not be called during simulation")
	end

	local context = T.BuildRuntimeContext(false)
	assertEquals(context.simulation, true, "runtime context should stay marked as simulation")
	assertEquals(#context.players, 25, "runtime simulation player count")
	assertEquals(context.playerName, "PpaSimHoly", "runtime simulation player")

	PPA.simulation = old.simulation
	_G.IsInRaid = old.IsInRaid
end)

test("simulation PallyPower hooks do not replace live unit APIs", function()
	local old = {
		PallyPower = _G.PallyPower,
		simulation = PPA.simulation,
		simulationHooksInstalledFor = PPA.simulationHooksInstalledFor,
		IsInRaid = _G.IsInRaid,
		GetRaidRosterInfo = _G.GetRaidRosterInfo,
	}
	local updateRosterCalls = 0
	local autoAssignCalls = 0

	_G.IsInRaid = function()
		return false
	end
	local liveIsInRaid = _G.IsInRaid
	_G.GetRaidRosterInfo = function()
		error("live roster API should not be called by simulation hooks")
	end
	_G.PallyPower = {
		UpdateRoster = function()
			updateRosterCalls = updateRosterCalls + 1
		end,
		AutoAssign = function()
			autoAssignCalls = autoAssignCalls + 1
		end,
	}
	PPA.simulationHooksInstalledFor = nil
	PPA:InstallSimulationHooks()
	PPA.simulation = {
		active = true,
		context = T.BuildSimulationContext(23),
	}

	_G.PallyPower:UpdateRoster()
	_G.PallyPower:AutoAssign()
	assertEquals(updateRosterCalls, 0, "simulation should skip live PallyPower roster refresh")
	assertEquals(autoAssignCalls, 0, "simulation should skip live PallyPower auto assign")
	assertEquals(_G.IsInRaid, liveIsInRaid, "unit API global should remain assigned")

	PPA.simulation = nil
	_G.PallyPower:UpdateRoster()
	_G.PallyPower:AutoAssign()
	assertEquals(updateRosterCalls, 1, "normal roster refresh should still call original")
	assertEquals(autoAssignCalls, 1, "normal auto assign should still call original")

	_G.PallyPower = old.PallyPower
	PPA.simulation = old.simulation
	PPA.simulationHooksInstalledFor = old.simulationHooksInstalledFor
	_G.IsInRaid = old.IsInRaid
	_G.GetRaidRosterInfo = old.GetRaidRosterInfo
end)

test("PallyPower auto assign starts conflict watch", function()
	local old = {
		PallyPower = _G.PallyPower,
		simulation = PPA.simulation,
		assignmentActionHooksInstalledFor = PPA.assignmentActionHooksInstalledFor,
		assignmentConflictWatch = PPA.assignmentConflictWatch,
		GetTime = _G.GetTime,
	}
	local autoAssignCalls = 0

	PPA.simulation = nil
	PPA.assignmentActionHooksInstalledFor = nil
	PPA.assignmentConflictWatch = nil
	_G.GetTime = function()
		return 200
	end
	_G.PallyPower = {
		AutoAssign = function()
			autoAssignCalls = autoAssignCalls + 1
		end,
	}

	PPA:InstallAssignmentActionHooks()
	_G.PallyPower:AutoAssign()

	assertEquals(autoAssignCalls, 1, "wrapped auto assign should still call original")
	assertEquals(PPA.assignmentConflictWatch.source, "Auto-Assign", "auto assign should start conflict watch")
	assertEquals(PPA.assignmentConflictWatch.startedAt, 200, "conflict watch should use current time")

	_G.PallyPower = old.PallyPower
	PPA.simulation = old.simulation
	PPA.assignmentActionHooksInstalledFor = old.assignmentActionHooksInstalledFor
	PPA.assignmentConflictWatch = old.assignmentConflictWatch
	_G.GetTime = old.GetTime
end)

test("simulation unit API shim refuses live client globals", function()
	local old = {
		simulation = PPA.simulation,
		CreateFrame = _G.CreateFrame,
		UIParent = _G.UIParent,
		IsInRaid = _G.IsInRaid,
	}

	PPA.simulation = {
		active = true,
		context = T.BuildSimulationContext(29),
	}
	_G.CreateFrame = function()
	end
	_G.UIParent = {}
	_G.IsInRaid = function()
		return false
	end
	local liveIsInRaid = _G.IsInRaid

	local ok, err = pcall(function()
		T.WithSimulationUnitAPIs(function()
			error("callback should not run in live-client mode")
		end)
	end)
	assertEquals(ok, false, "live-client simulation unit shim should fail closed")
	assertEquals(string.find(tostring(err), "avoid UI taint") ~= nil, true, "taint guard error")
	assertEquals(_G.IsInRaid, liveIsInRaid, "unit API global should not be replaced by failed shim")

	PPA.simulation = old.simulation
	_G.CreateFrame = old.CreateFrame
	_G.UIParent = old.UIParent
	_G.IsInRaid = old.IsInRaid
end)

test("simulation unit APIs support PallyPower string raid roster indexes", function()
	local old = {
		simulation = PPA.simulation,
	}
	local context = T.BuildSimulationContext(31)
	PPA.simulation = {
		active = true,
		context = context,
	}
	T.PrepareSimulationUnitMaps(context)

	T.WithSimulationUnitAPIs(function()
		local expected = context.players[9]
		local name, _, subgroup, _, _, classFile = _G.GetRaidRosterInfo("9")
		assertEquals(name, expected.fullName, "string roster index should resolve player name")
		assertEquals(subgroup, expected.subgroup, "string roster index should resolve subgroup")
		assertEquals(classFile, expected.class, "string roster index should resolve class")
		assertEquals(_G.UnitExists("raid9"), true, "raid token should exist")
		assertEquals(_G.UnitClassBase("raid9"), expected.class, "raid token class")
	end)

	PPA.simulation = old.simulation
end)

test("applying a simulation plan stays local and does not broadcast", function()
	local old = {
		PallyPower = _G.PallyPower,
		PallyPower_Assignments = _G.PallyPower_Assignments,
		PallyPower_NormalAssignments = _G.PallyPower_NormalAssignments,
		PallyPower_AuraAssignments = _G.PallyPower_AuraAssignments,
		PALLYPOWER_MAXCLASSES = _G.PALLYPOWER_MAXCLASSES,
		C_Timer = _G.C_Timer,
	}
	local messages = {}
	local clears = 0
	local updateRoster = 0
	local updateLayout = 0

	_G.PALLYPOWER_MAXCLASSES = 9
	_G.PallyPower_Assignments = {}
	_G.PallyPower_NormalAssignments = {}
	_G.PallyPower_AuraAssignments = {}
	_G.C_Timer = {
		After = function(_, callback)
			callback()
		end,
	}
	_G.PallyPower = {
		player = "PpaSimHoly",
		ClearAssignments = function()
			clears = clears + 1
		end,
		SendMessage = function(_, message)
			messages[#messages + 1] = message
		end,
		UpdateRoster = function()
			updateRoster = updateRoster + 1
		end,
		UpdateLayout = function()
			updateLayout = updateLayout + 1
		end,
	}

	local context = T.BuildSimulationContext(11)
	local plan = T.BuildSmartPlan(context)
	assertEquals(T.ApplyPlan(plan, context), true, "simulation plan should apply")
	assertEquals(clears, 0, "simulation should not clear via PallyPower broadcast path")
	assertEquals(#messages, 0, "simulation should not broadcast assignments")
	assertEquals(updateRoster, 1, "simulation should refresh roster")
	assertEquals(updateLayout, 1, "simulation should refresh layout")
	assertEquals(_G.PallyPower_Assignments.PpaSimHoly ~= nil, true, "simulation assignments should be written locally")

	_G.PallyPower = old.PallyPower
	_G.PallyPower_Assignments = old.PallyPower_Assignments
	_G.PallyPower_NormalAssignments = old.PallyPower_NormalAssignments
	_G.PallyPower_AuraAssignments = old.PallyPower_AuraAssignments
	_G.PALLYPOWER_MAXCLASSES = old.PALLYPOWER_MAXCLASSES
	_G.C_Timer = old.C_Timer
end)

local failures = 0
for _, entry in ipairs(tests) do
	local ok, err = pcall(entry.fn)
	if ok then
		print("ok - " .. entry.name)
	else
		failures = failures + 1
		print("not ok - " .. entry.name)
		print(err)
	end
end

if failures > 0 then
	error(failures .. " test(s) failed")
end

print(#tests .. " tests passed")
