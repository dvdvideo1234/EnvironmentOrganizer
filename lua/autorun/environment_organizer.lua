-- https://wiki.garrysmod.com/page/Category:physenv
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

  local ID = 0 -- General identification number

  -- INITIALIZE AIR DENSITY
  local envOldAirDensity = physenv.GetAirDensity()
  local airMembers = {"airdensity", "Aid density affecting props"}
  CreateConVar(envPrefx..airMembers[1], envOldAirDensity, envFlags, airMemberss[2])

  -- INITIALIZE GRAVITY
  local envOldVecGravity = physenv.GetGravity()
  local gravMembers = {
    {"gravitydrx", "X compoinent of the gravity affecting props"}, -- VecGravity[1]
    {"gravitydry", "Y compoinent of the gravity affecting props"}, -- VecGravity[2]
    {"gravitydrz", "Z compoinent of the gravity affecting props"}  -- VecGravity[3]
  }
  for ID = 1, #gravMembers, 1 do
    local envMember = gravMembers[ID]
    CreateConVar(envPrefx..envMember[1], envOldVecGravity[ID], envFlags, envMember[2])
  end

  -- INITIALIZE ENVIRONMENT SETTINGS
  local envOldPerformance = physenv.GetPerformanceSettings()
  local prefMembers = {
    {"prefmaxangvel", "MaxAngularVelocity"               , "Maximum rotation velocity"                                        },
    {"prefmaxlinvel", "MaxVelocity"                      , "Maximum speed of an object"                                       },
    {"prefminfrmass", "MinFrictionMass"                  , "Minimum mass of an object to be affected by friction"             },
    {"prefmaxfrmass", "MaxFrictionMass"                  , "Maximum mass of an object to be affected by friction"             },
    {"preflooktmovo", "LookAheadTimeObjectsVsObject"     , "Maximum amount of seconds to precalculate collisions with objects"},
    {"preflooktmovw", "LookAheadTimeObjectsVsWorld"      , "Maximum amount of seconds to precalculate collisions with world"  },
    {"prefmaxcolchk", "MaxCollisionChecksPerTimestep"    , "Maximum collision checks per tick"                                },
    {"prefmaxcolobj", "MaxCollisionsPerObjectPerTimestep", "Maximum collision per object per tick"                            }
  }
  for ID = 1, #prefMembers, 1 do
    local envMember = prefMembers[ID]
    CreateConVar(envPrefx..envMember[1], envOldPerformance[envMember[2]], envFlags, envMember[3])
  end

  -- LOGGING
  function envPrint(anyParam, anyOld, anyNew)
    print("EnvironmentOrganizer: ["..tostring(anyParam).."] Old<"..tostring(anyOld).."> New<"..tostring(anyNew)..">")
  end

  -- ENVIRONMENT MODIFIERS
  function envSetAirDensity()
    local envEn = GetConVar(envPrefx.."enabled"):GetBool()
    if(envEn) then
      local envNewAirDensity = GetConVar(envPrefx..airMembers[1]):GetFloat()
      physenv.SetAirDensity(envNewAirDensity)
      envPrint("envSetAirDensity",envOldAirDensity,envNewAirDensity)
    end
  end

  function envSetGravity()
    local envEn = GetConVar(envPrefx.."enabled"):GetBool()
    if(envEn) then
      local envNewVecGravity, ID = Vector()
      for ID = 1, #gravMembers, 1 do
        local envMember = gravMembers[ID]
        envNewVecGravity[ID] = GetConVar(envPrefx..envMember[1]):GetFloat()
      end
      physenv.SetGravity(envNewVecGravity)
      envPrint("envSetGravity",envOldVecGravity,envNewVecGravity)
    end
  end

  function envSetPerformance()
    local envEn = GetConVar(envPrefx.."enabled"):GetBool()
    if(envEn) then
      local envNewPerformance, ID = {}; table.Merge(envNewPerformance,envOldPerformance)
      for ID = 1, #prefMembers, 1 do
        local envMember = prefMembers[ID]
        envNewPerformance[envMember[2]] = GetConVar(envPrefx..envMember[1]):GetFloat()
        envPrint("envSetPerformance."..envMember[2], envOldPerformance[envMember[2]], envNewPerformance[envMember[2]])
      end
      physenv.SetPerformanceSettings(envNewPerformance)
    end
  end

  -- ENVIRONMENT STATS CONTROL
  function envDumpConvars()
    local sDump, ID = "", 0; print("envDumpConvars: Dumping\n")
          sDump = sDump.."  envSetAirDensity: <"..tostring(GetConVar(envPrefx..airMembers[1]):GetFloat())..">\n"
    for ID = 1, #gravMembers, 1 do
      local envMember = gravMembers[ID]
      sDump = sDump.."  envSetGravity."..envMember[2]:sub(1,1)..": <"..tostring(GetConVar(envPrefx..envMember[1]):GetFloat())..">\n"
    end
    for ID = 1, #prefMembers, 1 do
      local envMember = prefMembers[ID]
      sDump = sDump.."  envSetPerformance."..envMember[2]..": <"..tostring(GetConVar(envPrefx..envMember[1]):GetFloat())..">\n"
    end; print(sDump.."\n")
  end

  function envDumpStatus()
    local sDump, ID = "", 0; print("envDumpConvars: Dumping\n")
          sDump = sDump.."  envSetAirDensity: <"..tostring(envOldAirDensity)..">\n"
          sDump = sDump.."  envSetGravity   : <"..tostring(envOldVecGravity)..">\n"
    for ID = 1, #prefMembers, 1 do
      local envMember = prefMembers[ID]
      sDump = sDump.."  envSetPerformance."..envMember[2]..": <"..tostring(envOldPerformance)..">\n"
    end; print(sDump.."\n")
  end

  if(SERVER) then -- INITIALIZE CALLBACKS
    cvars.AddChangeCallback(envPrefx..airMembers[1], envSetAirDensity, "envSetAirDensity")

    for ID = 1, #gravMembers, 1 do
      local envMember = gravMembers[ID]
      cvars.AddChangeCallback(envPrefx..gravMembers[1], envSetGravity, "envSetGravity_"..gravMembers[2]:sub(1,1))
    end

    for ID = 1, #prefMembers, 1 do
      local envMember = prefMembers[ID]
      cvars.AddChangeCallback(envPrefx..envMember[1], envSetPerformance, "envSetPerformance_"..envMember[2])
    end
  end

  if(CLIENT) then -- INITIALIZE DIRECT COMMANDS
    concommand.Add(envPrefx.."envdumpconvars"   ,envDumpConvars)
    concommand.Add(envPrefx.."envdumpstatus"    ,envDumpStatus)
    concommand.Add(envPrefx.."envsetairdensity" ,envSetAirDensity)
    concommand.Add(envPrefx.."envsetgravity"    ,envSetGravity)
    concommand.Add(envPrefx.."envsetperformance",envSetPerformance)
  end

end









