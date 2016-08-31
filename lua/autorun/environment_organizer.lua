-- https://wiki.garrysmod.com/page/Category:physenv
local Vector       = Vector
local GetConVar    = GetConVar
local CreateConVar = CreateConVar
local bit          = bit
local cvars        = cvars
local physenv      = physenv

local envPrefx = "envorganiser_"
local envFlags = bit.bor(FCVAR_ARCHIVE, FCVAR_ARCHIVE_XBOX, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)

CreateConVar(envPrefx.."enabled", " 0", envFlags, "Enable organizer")

local envEn = GetConVar(envPrefx.."enabled"):GetBool()
if(envEn) then
  local ID -- General identification number

  -- INITIALIZE AIR DENSITY
  local envAirDensityOld = physenv.GetAirDensity()
  local airMember = {"airdensity", "Aid density affecting props"}
  CreateConVar(envPrefx..airMember[1], envAirDensityOld, envFlags, airMember[2])

  -- INITIALIZE GRAVITY
  local envVecGravityOld = physenv.GetGravity()
  local gravMembers = {
    {"gravitydrx", "X compoinent of the gravity affecting props"}, -- VecGravity[1]
    {"gravitydry", "Y compoinent of the gravity affecting props"}, -- VecGravity[2]
    {"gravitydrz", "Z compoinent of the gravity affecting props"}  -- VecGravity[3]
  }
  ID = 1
  while(gravMembers[ID]) do
    local envMember = gravMembers[ID]
    CreateConVar(envPrefx..envMember[1], envVecGravityOld[ID], envFlags, envMember[2])
    ID = ID + 1
  end

  -- INITIALIZE ENVIRONMENT SETTINGS
  local envPrSettingsOld = physenv.GetPerformanceSettings()
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
  ID = 1
  while(prefMembers[ID]) do
    local envMember = prefMembers[ID]
    CreateConVar(envPrefx..envMember[1], envPrSettingsOld[envMember[2]], envFlags, envMember[3])
    ID = ID + 1
  end

  -- LOGGING
  function envPrint(anyParam, anyOld, anyNew)
    print("EnvironmentOrganizer: ["..tostring(anyParam).."] Old<"..tostring(anyOld).."> New<"..tostring(anyNew)..">")
  end

  -- ENVIRONMENT MODIFIERS
  function envSetAirDensity(sName,sOld,sNew)
    local envEn = GetConVar(envPrefx.."enabled"):GetBool()
    if(envEn) then
      local envAirDensityNew = GetConVar(envPrefx..airMember[1]):GetFloat()
      physenv.SetAirDensity(envAirDensityNew)
      envPrint("envSetAirDensity",envAirDensityOld,envAirDensityNew)
    end
  end

  function envSetGravity(sName,sOld,sNew)
    local envEn = GetConVar(envPrefx.."enabled"):GetBool()
    if(envEn) then
      local envVecGravityNew = Vector()
      local ID = 1
      while(gravMembers[ID]) do
        local envMember = gravMembers[ID]
        envVecGravityNew[ID] = GetConVar(envPrefx..envMember[1]):GetFloat()
        ID = ID + 1
      end
      physenv.SetGravity(envVecGravityNew)
      envPrint("envSetGravity",envVecGravityOld,envVecGravityNew)
    end
  end

  function envSetPerformanceSettings(sName,sOld,sNew)
    local envEn = GetConVar(envPrefx.."enabled"):GetBool()
    if(envEn) then
      local envPrSettingsNew = {}; table.Merge(envPrSettingsNew,envPrSettingsOld)
      local ID = 1
      while(prefMembers[ID]) do
        local envMember = prefMembers[ID]
        envPrSettingsNew[envMember[2]] = GetConVar(envPrefx..envMember[1]):GetFloat()
        envPrint(envMember[2], envPrSettingsOld[envMember[2]], envPrSettingsNew[envMember[2]])
        ID = ID + 1
      end
      physenv.SetPerformanceSettings(envPrSettingsNew)
    end
  end

  -- INITIALIZE CALLBACKS
  cvars.AddChangeCallback(envPrefx..airMember[1], envSetAirDensity, "envSetAirDensity")

  ID = 1
  while(gravMembers[ID]) do
    local envMember = gravMembers[ID]
    cvars.AddChangeCallback(envPrefx..gravMembers[1], envSetGravity, "envSetGravity"..gravMembers[2]:sub(1,1))
    ID = ID + 1
  end

  ID = 1
  while(prefMembers[ID]) do
    local envMember = prefMembers[ID]
    cvars.AddChangeCallback(envPrefx..envMember[1], envSetPerformanceSettings, "envSetPerformanceSettings_"..envMember[2])
    ID = ID + 1
  end

end









