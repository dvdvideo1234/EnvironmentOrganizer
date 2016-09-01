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
local envFlogs = bit.bor(FCVAR_ARCHIVE, FCVAR_ARCHIVE_XBOX, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY)

CreateConVar(envPrefx.."logsuse", " 0", envFlogs, "Enable logging on error")
CreateConVar(envPrefx.."enabled", " 0", envFlags, "Enable organizer addon")

local enLog = GetConVar(envPrefx.."logsuse"):GetBool()

local function envPrint(...)
  if(not enLog) then return end
  print(...)
end

if(GetConVar(envPrefx.."enabled"):GetBool()) then

  local function envSwitchConvarMode(oVar, sMode, sName) -- Called inside only
    local sMode = tostring(sMode or "")
    if(not oVar) then envPrint("EnvironmentOrganizer: envSwitchConvarMode: Cvar missing"); return nil end
    if(sMode == "float" ) then return oVar:GetFloat () end
    if(sMode == "int"   ) then return oVar:GetInt   () end
    if(sMode == "string") then return oVar:GetString() end
    if(sMode == "bool"  ) then return oVar:GetBool  () end
    envPrint("EnvironmentOrganizer: envSwitchConvarMode: Missed <"..sMode.."> for <"..tostring(sName)..">"); return nil
  end

  local function envGetConvarValue(sName, sMode, tMembers, nID)
    local sNam = tostring(sName or ""); if(sNam == "") then
      envPrint("EnvironmentOrganizer: envGetConvarValue: Name empty"); return nil end
    local oVar = GetConVar(envPrefx..sNam); if(not oVar) then
      envPrint("EnvironmentOrganizer: envGetConvarValue: Cvar <"..sNam.."> missing"); return nil end
    if(tMembers and nID) then
      local uID = (tonumber(nID) or 0); if(uID <= 0) then
        envPrint("EnvironmentOrganizer: envGetConvarValue(m): ID <"..tostring(uID).."> invalid"); return nil end
      local sMode = tostring(tMembers[uID][4]); if(sMode == "") then
        envPrint("EnvironmentOrganizer: envGetConvarValue(m): Mode missing"); return nil end
      local anyVal = envSwitchConvarMode(oVar, sMode, sName); if(not anyVal) then
        envPrint("EnvironmentOrganizer: envGetConvarValue(m): Missed mode["..tostring(uID).."] <"..sMode.."> in "..tMembers.NAM); return nil end
    else
      local sMode = tostring(sMode or ""); if(sMode == "") then
        envPrint("EnvironmentOrganizer: envGetConvarValue(x): Mode missing"); return nil end
      local anyVal = envSwitchConvarMode(oVar, sMode, sName); if(not anyVal) then
        envPrint("EnvironmentOrganizer: envGetConvarValue(x): Missed mode["..tostring(uID).."] <"..sMode.."> in "..tMembers.NAM); return nil end
    end; return anyVal
  end

  local function envCreateMemberConvars(tMembers)
    for ID = 1, #tMembers, 1 do
      local envMember = tMembers[ID]
      CreateConVar(envPrefx..envMember[1], tMembers.OLD[ID], envFlags, envMember[2])
    end
  end

  local function envLoadMemberValues(tMembers)
    for ID = 1, #tMembers, 1 do
      local envMember  = tMembers[ID]
      if(envMember[3] ~= nil) then
        tMembers.NEW[envMember[3]] = envGetConvarValue(envMember[1], envMember[4], tMembers, ID)
        envPrint(tMembers.NAM.."."..envMember[3], tMembers.OLD[envMember[2]], tMembers.NEW[envMember[2]])
      else -- Scalar, non-table value
        tMembers.NEW = envGetConvarValue(envMember[1], envMember[4], tMembers, ID)
        envPrint(tMembers.NAM, tMembers.OLD, tMembers.NEW)
      end
    end
  end

  local function envDumpConvars(tMembers)
    local Out = (tMembers.NAM.."\n")
    for ID = 1, #prefMembers, 1 do
      local envMember = prefMembers[ID]
      Out = Out.."  "..envMember[3]..": <"..tostring(envGetConvarValue(envMember[1], envMember[4], tMembers, ID))..">\n"
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
    envPrint("EnvironmentOrganizer: ["..tostring(anyParam).."] Old<"..tostring(anyOld).."> New<"..tostring(anyNew)..">")
  end

  -- ENVIRONMENT MODIFIERS
  function envSetAirDensity(oPly,oCom,oArgs)
    envLoadMemberValues(airMembers) -- Sets the air density on proper key
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    if(not (Key == "NEW" or Key == "OLD")) then
      envPrint("EnvironmentOrganizer: envSetAirDensity: Invalid key <"..Key..">"); return end
    physenv.SetAirDensity(airMembers[Key])
  end

  function envSetGravity(oPly,oCom,oArgs)
    envLoadMemberValues(gravMembers) -- Sets the gravity vector for props on proper key
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    if(not (Key == "NEW" or Key == "OLD")) then
      envPrint("EnvironmentOrganizer: envSetAirDensity: Invalid key <"..Key..">"); return end
    physenv.SetGravity(gravMembers[Key])
  end

  function envSetPerformance(oPly,oCom,oArgs)
    envLoadMemberValues(prefMembers) -- Sets the performance on proper key
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    if(not (Key == "NEW" or Key == "OLD")) then
      envPrint("EnvironmentOrganizer: envSetAirDensity: Invalid key <"..Key..">"); return end
    physenv.SetPerformanceSettings(prefMembers[Key])
  end

  function envDumpConvarValues() -- The values in the convars. Does not affect NEW key
    envPrint(envDumpConvars(airMembers)..envDumpConvars(gravMembers)..envDumpConvars(prefMembers))
  end

  function envDumpStatusValues(oPly,oCom,oArgs) -- Dumps whatever is found under the given key
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    envPrint(envDumpStatus(airMembers,Key)..envDumpStatus(gravMembers,Key)..envDumpStatus(prefMembers,Key))
  end

  function envLogRefresh(oPly,oCom,oArgs) -- Dumps whatever is found under the given key
    oPly:ConCommand(envPrefx.."logsuse "..tostring(tonumber(oArgs[1]) or 0))
    enLog = GetConVar(envPrefx.."logsuse"):GetBool()
  end

  if(SERVER) then -- Refresh the NEW key on change
    envAddCallBacks(airMembers , envSetAirDensity)
    envAddCallBacks(gravMembers, envSetGravity)
    envAddCallBacks(prefMembers, envSetPerformance)
  end

  if(CLIENT) then -- User control commands
    concommand.Add(envPrefx.."logrefresh"    ,envLogRefresh)
    concommand.Add(envPrefx.."dumpconvars"   ,envDumpConvarValues)
    concommand.Add(envPrefx.."dumpstatus"    ,envDumpStatusValues)
    concommand.Add(envPrefx.."setairdensity" ,envSetAirDensity)
    concommand.Add(envPrefx.."setgravity"    ,envSetGravity)
    concommand.Add(envPrefx.."setperformance",envSetPerformance)
  end

end
