local Vector       = Vector
local GetConVar    = GetConVar
local CreateConVar = CreateConVar
local bit          = bit
local cvars        = cvars
local physenv      = physenv
local concommand   = concommand

local envPrefx = "envorganiser_"
local envFlags = bit.bor(FCVAR_ARCHIVE, FCVAR_ARCHIVE_XBOX, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)

CreateConVar(envPrefx.."enabled", " 0", envFlags, "Enable environment organizer")

local envEn = GetConVar(envPrefx.."enabled"):GetBool()
if(envEn) then

  local function envCreateMemberConvars(tMembers)
    for ID = 1, #tMembers, 1 do
      local envMember = tMembers[ID]
      CreateConVar(envPrefx..envMember[1], tMembers.OLD[ID], envFlags, envMember[2])
    end
  end

  local function envSetMemberValues(tMembers, fModify)
    local envEn = GetConVar(envPrefx.."enabled"):GetBool()
    if(envEn) then
      for ID = 1, #tMembers, 1 do
        local envMember  = tMembers[ID]
        tMembers.NEW[envMember[3]] = GetConVar(envPrefx..envMember[1]):GetFloat()
        envPrint(tMembers.NAM.."."..envMember[3], prefMembers.OLD[envMember[2]], prefMembers.NEW[envMember[2]])
      end
      fModify(tMembers.NEW)
    else
      print("EnvironmentOrganizer: "..tMembers.NAM..": Extension disabled")
    end
  end

  local function envDumpConvars(tMembers)
    local Out = (tMembers.NAM.."\n")
    for ID = 1, #prefMembers, 1 do
      local envMember = prefMembers[ID]
      Out = Out.."  "..envMember[3]..": <"..tostring(GetConVar(envPrefx..envMember[1]):GetFloat())..">\n"
    end; return (Out.."\n")
  end

  local function envDumpStatus(tMembers, sStatus)
    local Key = tostring(sStatus or "")
    if(not (Key == "NEW" or Key == "OLD")) then return end
    local Out = (tMembers.NAM.."["..Key.."]\n")
    for ID = 1, #tMembers, 1 do
      local envMember = tMembers[ID]
      local envDatakv = envMember[3]
      Out = Out.."  "..envDatakv..": <"..tostring(tMembers[Key][envDatakv])..">\n"
    end; return (Out.."\n")
  end

  local function anvAddCallbacks(tMembers, fCallback)
    for ID = 1, #tMembers, 1 do
      local envMember = tMembers[ID]
      cvars.AddChangeCallback(envPrefx..envMember[1], fCallback, tMembers.NAM.."_"..envMember[3])
    end
  end

  -- https://wiki.garrysmod.com/page/Category:number
  local airMembers = { -- INITIALIZE AIR DENSITY
    NAM = "envSetAirDensity", OLD = {Data = physenv.GetAirDensity()}, NEW = {Data = 0},
    {"airdensity", "Air density affecting props", "Data"}
  }; envCreateMemberConvars(airMembers)

  -- https://wiki.garrysmod.com/page/Category:Vector
  local gravMembers = { -- INITIALIZE GRAVITY
    NAM = "envSetGravity", OLD = physenv.GetGravity(), NEW = Vector(),
    {"gravitydrx", "Compoinent X of the gravity affecting props", "x"}, -- VecGravity[1]
    {"gravitydry", "Compoinent Y of the gravity affecting props", "y"}, -- VecGravity[2]
    {"gravitydrz", "Compoinent Z of the gravity affecting props", "z"}  -- VecGravity[3]
  }; envCreateMemberConvars(gravMembers)

  -- https://wiki.garrysmod.com/page/Category:physenv
  local prefMembers = { -- INITIALIZE ENVIRONMENT SETTINGS
    NAM = "envSetPerformance", OLD = physenv.GetPerformanceSettings(), NEW = {},
    {"prefmaxangvel", "Maximum rotation velocity"                                        , "MaxAngularVelocity"               },
    {"prefmaxlinvel", "Maximum speed of an object"                                       , "MaxVelocity"                      },
    {"prefminfrmass", "Minimum mass of an object to be affected by friction"             , "MinFrictionMass"                  },
    {"prefmaxfrmass", "Maximum mass of an object to be affected by friction"             , "MaxFrictionMass"                  },
    {"preflooktmovo", "Maximum amount of seconds to precalculate collisions with objects", "LookAheadTimeObjectsVsObject"     },
    {"preflooktmovw", "Maximum amount of seconds to precalculate collisions with world"  , "LookAheadTimeObjectsVsWorld"      },
    {"prefmaxcolchk", "Maximum collision checks per tick"                                , "MaxCollisionChecksPerTimestep"    },
    {"prefmaxcolobj", "Maximum collision per object per tick"                            , "MaxCollisionsPerObjectPerTimestep"}
  }; envCreateMemberConvars(prefMembers)

  -- LOGGING
  local function envPrintDelta(anyParam, anyOld, anyNew)
    print("EnvironmentOrganizer: ["..tostring(anyParam).."] Old<"..tostring(anyOld).."> New<"..tostring(anyNew)..">")
  end

  -- ENVIRONMENT MODIFIERS
  function envSetAirDensity()
    envSetMemberValues(airMembers, physenv.SetAirDensity)
  end

  function envSetGravity()
    envSetMemberValues(gravMembers, physenv.SetGravity)
  end

  function envSetPerformance()
    envSetMemberValues(prefMembers, physenv.SetPerformanceSettings)
  end

  -- ENVIRONMENT STATS CONTROL
  function envDumpConvarValues()
    print(envDumpConvars(airMembers)..envDumpConvars(gravMembers)..envDumpConvars(prefMembers))
  end

  function envDumpStatusValues(oPly,oCom,oArgs)
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    print(envDumpStatus(airMembers,Key)..envDumpStatus(gravMembers,Key)..envDumpStatus(prefMembers,Key))
  end

  if(SERVER) then -- INITIALIZE CALLBACKS
    anvAddCallbacks(airMembers , envSetAirDensity)
    anvAddCallbacks(gravMembers, envSetGravity)
    anvAddCallbacks(prefMembers, envSetPerformance)
  end

  if(CLIENT) then -- INITIALIZE DIRECT COMMANDS
    concommand.Add(envPrefx.."envdumpconvars"   ,envDumpConvarValues)
    concommand.Add(envPrefx.."envdumpstatus"    ,envDumpStatusValues)
    concommand.Add(envPrefx.."envsetairdensity" ,envSetAirDensity)
    concommand.Add(envPrefx.."envsetgravity"    ,envSetGravity)
    concommand.Add(envPrefx.."envsetperformance",envSetPerformance)
  end

end









