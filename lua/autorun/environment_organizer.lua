-- https://wiki.garrysmod.com/page/Category:physenv
local Vector       = Vector
local GetConVar    = GetConVar
local CreateConVar = CreateConVar
local bit          = bit
local physenv      = physenv

local envPrefx = "envorganiser_"
local envFlags = bit.bor(FCVAR_ARCHIVE, FCVAR_ARCHIVE_XBOX, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)

CreateConVar(envPrefx.."enabled", " 0", envFlags, "Enable organizer")

local envEn = GetConVar(envPrefx.."enabled"):GetBool()
if(envEn) then
  CreateConVar(envPrefx.."airdensity", " 0", envFlags, "Aid density affecting props")
  CreateConVar(envPrefx.."gravitydrx", " 0", envFlags, "X compoinent of the gravity affecting props")
  CreateConVar(envPrefx.."gravitydry", " 0", envFlags, "Y compoinent of the gravity affecting props")
  CreateConVar(envPrefx.."gravitydrz", "-1", envFlags, "Z compoinent of the gravity affecting props")

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
  local ID = 1
  while(prefMembers[ID]) do
    local envMember = prefMembers[ID]
    CreateConVar(envPrefx..envMember[1], envPrSettingsOld[envMember[2]], envFlags, envMember[3])
    ID = ID + 1
  end

  function envPrint(anyParam, anyOld, anyNew)
    print("EnvironmentOrganizer: ["..tostring(anyParam).."] Old<"..tostring(anyOld).."> New<"..tostring(anyNew)..">")
  end

  function envSetAirDensity()
    local envEn = GetConVar(envPrefx.."enabled"):GetBool()
    if(envEn) then
      local envAirDensityOld = physenv.GetAirDensity()
      local envAirDensityNew = GetConVar(envPrefx.."airdensity"):GetFloat()
      physenv.SetAirDensity(envAirDensityNew)
      envPrint("envSetAirDensity",envAirDensityOld,envAirDensityNew)
    end
  end

  function envSetGravity()
    local envEn = GetConVar(envPrefx.."enabled"):GetBool()
    if(envEn) then
      local envVecGravityOld = physenv.GetGravity()
      local envVecGravityNew = Vector()
      envVecGravityNew[1] = GetConVar(envPrefx.."gravx"):GetFloat()
      envVecGravityNew[2] = GetConVar(envPrefx.."gravy"):GetFloat()
      envVecGravityNew[3] = GetConVar(envPrefx.."gravz"):GetFloat()
      physenv.SetGravity(envVecGravityNew)
      envPrint("envSetGravity",envVecGravityOld,envVecGravityNew)
    end
  end

  function envSetPerformanceSettings()
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

end









