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
			},
			{
				name = "Tankadin",
				role = "TANK",
				hasAddon = true,
				skills = {
					[T.BUFF_MIGHT] = skill(7, 0),
					[T.BUFF_KINGS] = skill(1, 0),
					[T.BUFF_SALVATION] = skill(1, 0),
					[T.BUFF_LIGHT] = skill(4, 0),
					[T.BUFF_SANCTUARY] = skill(5, 2),
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
