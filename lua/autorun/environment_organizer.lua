local tonumber     = tonumber
local tostring     = tostring
local print        = print
local Vector       = Vector
local GetConVar    = GetConVar
local CreateConVar = CreateConVar
local bit          = bit
local cvars        = cvars
local physenv      = physenv
local concommand   = concommand

local envPrefx = "envorganiser_"
local envFlags = bit.bor(FCVAR_ARCHIVE, FCVAR_ARCHIVE_XBOX, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)

local function envGetConvarValue(tMembers, nID)
  local nID = (tonumber(nID) or 0)
  if((nID <= 0) or (nID > #tMembers)) then
    print("EnvironmentOrganizer: envGetConvarValue: Invalid ID "..tostring(nID)); return nil end
  local oVar = GetConVar(envPrefx..tMembers[nID][1])
  local sMod = tostring(tMembers[nID][4])
  if(not oVar) then
    print("EnvironmentOrganizer: envGetConvarValue: Cvar missing"); return nil end
  if(sMod == "") then
    print("EnvironmentOrganizer: envGetConvarValue: Mode missing"); return nil end
  if(sMod == "float" ) then return oVar:GetFloat () end
  if(sMod == "int"   ) then return oVar:GetInt   () end
  if(sMod == "string") then return oVar:GetString() end
  if(sMod == "bool"  ) then return oVar:GetBool  () end
  print("EnvironmentOrganizer: envGetConvarValue: Missed mode["..tostring(nID).."] <"..sMod.."> in "..tMembers.NAM); return nil
end

CreateConVar(envPrefx.."enabled", " 0", envFlags, "Enable environment organizer")

local envEn = envGetConvarValue("enabled")

if(envEn) then

  local function envCreateMemberConvars(tMembers)
    for ID = 1, #tMembers, 1 do
      local envMember = tMembers[ID]
      CreateConVar(envPrefx..envMember[1], tMembers.OLD[ID], envFlags, envMember[2])
    end
  end

  local function envLoadMemberValues(tMembers)
    local envEn = envGetConvarValue("enabled")
    if(envEn) then
      for ID = 1, #tMembers, 1 do
        local envMember  = tMembers[ID]
        if(envMember[3] ~= nil) then
          tMembers.NEW[envMember[3]] = envGetConvarValue(envMember[1])
          envPrint(tMembers.NAM.."."..envMember[3], tMembers.OLD[envMember[2]], tMembers.NEW[envMember[2]])
        else -- Scalar, non-table value
          tMembers.NEW = envGetConvarValue(envMember[1])
          envPrint(tMembers.NAM, tMembers.OLD, tMembers.NEW)
        end
      end
    else
      print("EnvironmentOrganizer: "..tMembers.NAM..": Extension disabled")
    end
  end

  local function envDumpConvars(tMembers)
    local Out = (tMembers.NAM.."\n")
    for ID = 1, #prefMembers, 1 do
      local envMember = prefMembers[ID]
      Out = Out.."  "..envMember[3]..": <"..tostring(envGetConvarValue(envMember[1]))..">\n"
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

  local function envAddCallBacks(tMembers, fCall)
    for ID = 1, #tMembers, 1 do
      local envMember = tMembers[ID]
      cvars.AddChangeCallback(envPrefx..envMember[1], fCall, tMembers.NAM.."_"..envMember[3])
    end
  end

  -- https://wiki.garrysmod.com/page/Category:number
  local airMembers = { -- INITIALIZE AIR DENSITY
    NAM = "envSetAirDensity", OLD = physenv.GetAirDensity(), NEW = 0,
    {"airdensity", "Air density affecting props", nil, "float"}
  }; envCreateMemberConvars(airMembers)

  -- https://wiki.garrysmod.com/page/Category:Vector
  local gravMembers = { -- INITIALIZE GRAVITY
    NAM = "envSetGravity", OLD = physenv.GetGravity(), NEW = Vector(),
    {"gravitydrx", "Compoinent X of the gravity affecting props", "x", "float"},
    {"gravitydry", "Compoinent Y of the gravity affecting props", "y", "float"},
    {"gravitydrz", "Compoinent Z of the gravity affecting props", "z", "float"}
  }; envCreateMemberConvars(gravMembers)

  -- https://wiki.garrysmod.com/page/Category:physenv
  local prefMembers = { -- INITIALIZE ENVIRONMENT SETTINGS
    NAM = "envSetPerformance", OLD = physenv.GetPerformanceSettings(), NEW = {},
    {"prefmaxangvel", "Maximum rotation velocity"                                        , "MaxAngularVelocity"               , "float"},
    {"prefmaxlinvel", "Maximum speed of an object"                                       , "MaxVelocity"                      , "float"},
    {"prefminfrmass", "Minimum mass of an object to be affected by friction"             , "MinFrictionMass"                  , "float"},
    {"prefmaxfrmass", "Maximum mass of an object to be affected by friction"             , "MaxFrictionMass"                  , "float"},
    {"preflooktmovo", "Maximum amount of seconds to precalculate collisions with objects", "LookAheadTimeObjectsVsObject"     , "float"},
    {"preflooktmovw", "Maximum amount of seconds to precalculate collisions with world"  , "LookAheadTimeObjectsVsWorld"      , "float"},
    {"prefmaxcolchk", "Maximum collision checks per tick"                                , "MaxCollisionChecksPerTimestep"    , "float"},
    {"prefmaxcolobj", "Maximum collision per object per tick"                            , "MaxCollisionsPerObjectPerTimestep", "float"}
  }; envCreateMemberConvars(prefMembers)

  -- LOGGING
  local function envPrintDelta(anyParam, anyOld, anyNew)
    print("EnvironmentOrganizer: ["..tostring(anyParam).."] Old<"..tostring(anyOld).."> New<"..tostring(anyNew)..">")
  end

  -- ENVIRONMENT MODIFIERS
  function envSetAirDensity(oPly,oCom,oArgs)
    envLoadMemberValues(airMembers) -- Sets the air density on proper key
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    if(not (Key == "NEW" or Key == "OLD")) then
      print("EnvironmentOrganizer: envSetAirDensity: Invalid key <"..Key..">"); return end
    physenv.SetAirDensity(airMembers[Key])
  end

  function envSetGravity(oPly,oCom,oArgs)
    envLoadMemberValues(gravMembers) -- Sets the gravity vector for props on proper key
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    if(not (Key == "NEW" or Key == "OLD")) then
      print("EnvironmentOrganizer: envSetAirDensity: Invalid key <"..Key..">"); return end
    physenv.SetGravity(gravMembers[Key])
  end

  function envSetPerformance(oPly,oCom,oArgs)
    envLoadMemberValues(prefMembers) -- Sets the performance on proper key
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    if(not (Key == "NEW" or Key == "OLD")) then
      print("EnvironmentOrganizer: envSetAirDensity: Invalid key <"..Key..">"); return end
    physenv.SetPerformanceSettings(prefMembers[Key])
  end

  function envDumpConvarValues() -- The values in the convars. Does not affect NEW key
    print(envDumpConvars(airMembers)..envDumpConvars(gravMembers)..envDumpConvars(prefMembers))
  end

  function envDumpStatusValues(oPly,oCom,oArgs) -- Dumps whatever is found under the given key
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    print(envDumpStatus(airMembers,Key)..envDumpStatus(gravMembers,Key)..envDumpStatus(prefMembers,Key))
  end

  if(SERVER) then -- Refresh the NEW key on change
    envAddCallBacks(airMembers , envSetAirDensity)
    envAddCallBacks(gravMembers, envSetGravity)
    envAddCallBacks(prefMembers, envSetPerformance)
  end

  if(CLIENT) then -- User control commands
    concommand.Add(envPrefx.."dumpconvars"   ,envDumpConvarValues)
    concommand.Add(envPrefx.."dumpstatus"    ,envDumpStatusValues)
    concommand.Add(envPrefx.."setairdensity" ,envSetAirDensity)
    concommand.Add(envPrefx.."setgravity"    ,envSetGravity)
    concommand.Add(envPrefx.."setperformance",envSetPerformance)
  end

end
