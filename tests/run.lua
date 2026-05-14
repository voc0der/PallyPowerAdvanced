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

test("elemental shaman damage prefers wisdom where enhancement prefers might", function()
	local elemental = {name = "Stormbolt", class = "SHAMAN", classID = 9, role = "DAMAGER", spec = "ELEMENTAL"}
	local enhancement = {name = "Windfury", class = "SHAMAN", classID = 9, role = "DAMAGER", spec = "ENHANCEMENT"}
	local context = {healingPaladinPresent = true, pallyCount = 2}

	assertEquals(T.GetPriorityForUnit(elemental, context)[3], T.BUFF_WISDOM, "elemental third priority")
	assertEquals(T.GetPriorityForUnit(enhancement, context)[3], T.BUFF_MIGHT, "enhancement third priority")
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
	assertEquals(plan.assignments.Holyone[8], T.BUFF_SALVATION, "assumed warlocks should get salvation")
	assertEquals(plan.assignments.Tankadin[8], T.BUFF_KINGS, "assumed warlocks should get kings")
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
