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
local envAddon = "envOrganizer: "
local envFlags = bit.bor(FCVAR_ARCHIVE, FCVAR_ARCHIVE_XBOX, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)
local envFlogs = bit.bor(FCVAR_ARCHIVE, FCVAR_ARCHIVE_XBOX, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY)

CreateConVar(envPrefx.."logused", " 0", envFlogs, "Enable logging on error")
CreateConVar(envPrefx.."enabled", " 0", envFlags, "Enable organizer addon")

local enLog = GetConVar(envPrefx.."logused"):GetBool()

local function envPrint(...)
  if(not enLog) then return end; print(...)
end

if(GetConVar(envPrefx.."enabled"):GetBool()) then

  local function envGetConvarMode(oVar, sMode, sName) -- Called inside only
    local sMode = tostring(sMode or "")
    if(not oVar) then envPrint(envAddon.."envGetConvarMode: Cvar missing"); return nil end
    if(sMode == "float" ) then return oVar:GetFloat () end
    if(sMode == "int"   ) then return oVar:GetInt   () end
    if(sMode == "string") then return oVar:GetString() end
    if(sMode == "bool"  ) then return oVar:GetBool  () end
    envPrint(envAddon.."envGetConvarMode: Missed <"..sMode.."> for <"..tostring(sName)..">"); return nil
  end

  local function envGetConvarValue(sName, sMode, tMembers, nID)
    local sNam = tostring(sName or ""); if(sNam == "") then
      envPrint(envAddon.."envGetConvarValue: Name empty"); return nil end
    local oVar = GetConVar(envPrefx..sNam); if(not oVar) then
      envPrint(envAddon.."envGetConvarValue: Cvar <"..sNam.."> missing"); return nil end
    if(tMembers and nID) then
      local uID = (tonumber(nID) or 0); if(uID <= 0) then
        envPrint(envAddon.."envGetConvarValue(m): ID <"..tostring(uID).."> invalid"); return nil end
      local sMode = tostring(tMembers[uID][4]); if(sMode == "") then
        envPrint(envAddon.."envGetConvarValue(m): Mode missing"); return nil end
      local anyVal = envGetConvarMode(oVar, sMode, sName); if(not anyVal) then
        envPrint(envAddon.."envGetConvarValue(m): Missed mode["..tostring(uID).."] <"..sMode.."> in "..tMembers.NAM); return nil end
    else
      local sMode = tostring(sMode or ""); if(sMode == "") then
        envPrint(envAddon.."envGetConvarValue(x): Mode missing"); return nil end
      local anyVal = envGetConvarMode(oVar, sMode, sName); if(not anyVal) then
        envPrint(envAddon.."envGetConvarValue(x): Missed mode["..tostring(uID).."] <"..sMode.."> in "..tMembers.NAM); return nil end
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
        local envValue = envGetConvarValue(envMember[1], envMember[4], tMembers, ID)
        tMembers.NEW[envMember[3]] = ((envValue > 0) and envValue or 0)
        if(envValue and envValue > 0) then tMembers.NEW = envValue else tMembers.NEW = tMembers.OLD end
        envPrint(tMembers.NAM.."."..envMember[3], tMembers.OLD[envMember[2]], tMembers.NEW[envMember[2]])
      else -- Scalar, non-table value
        local envValue = envGetConvarValue(envMember[1], envMember[4], tMembers, ID)
        if(envValue and envValue > 0) then tMembers.NEW = envValue else tMembers.NEW = tMembers.OLD end
        envPrint(tMembers.NAM, tMembers.OLD, tMembers.NEW)
      end
    end
  end

  local function envDumpConvars(tMembers)
    local Out = (tMembers.NAM.."\n")
    for ID = 1, #perfMembers, 1 do
      local envMember = perfMembers[ID]
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
    {"gravitydrx", "Component X of the gravity affecting props", "x", "float"},
    {"gravitydry", "Component Y of the gravity affecting props", "y", "float"},
    {"gravitydrz", "Component Z of the gravity affecting props", "z", "float"}
  }; envCreateMemberConvars(gravMembers)

  -- https://wiki.garrysmod.com/page/Category:physenv
  local perfMembers = { -- INITIALIZE ENVIRONMENT SETTINGS
    NAM = "envSetPerformance", OLD = physenv.GetPerformanceSettings(), NEW = {},
    {"perfmaxangvel", "Maximum rotation velocity"                                        , "MaxAngularVelocity"               , "float"},
    {"perfmaxlinvel", "Maximum speed of an object"                                       , "MaxVelocity"                      , "float"},
    {"perfminfrmass", "Minimum mass of an object to be affected by friction"             , "MinFrictionMass"                  , "float"},
    {"perfmaxfrmass", "Maximum mass of an object to be affected by friction"             , "MaxFrictionMass"                  , "float"},
    {"perflooktmovo", "Maximum amount of seconds to precalculate collisions with objects", "LookAheadTimeObjectsVsObject"     , "float"},
    {"perflooktmovw", "Maximum amount of seconds to precalculate collisions with world"  , "LookAheadTimeObjectsVsWorld"      , "float"},
    {"perfmaxcolchk", "Maximum collision checks per tick"                                , "MaxCollisionChecksPerTimestep"    , "float"},
    {"perfmaxcolobj", "Maximum collision per object per tick"                            , "MaxCollisionsPerObjectPerTimestep", "float"}
  }; envCreateMemberConvars(perfMembers)

  -- LOGGING
  local function envPrintDelta(anyParam, anyOld, anyNew)
    envPrint(envAddon.."["..tostring(anyParam).."] Old<"..tostring(anyOld).."> New<"..tostring(anyNew)..">")
  end

  -- ENVIRONMENT MODIFIERS
  function envSetAirDensity(oPly,oCom,oArgs)
    envLoadMemberValues(airMembers) -- Sets the air density on proper key
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    if(not (Key == "NEW" or Key == "OLD")) then
      envPrint(envAddon.."envSetAirDensity: Invalid key <"..Key..">"); return end
    physenv.SetAirDensity(airMembers[Key])
  end

  function envSetGravity(oPly,oCom,oArgs)
    envLoadMemberValues(gravMembers) -- Sets the gravity vector for props on proper key
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    if(not (Key == "NEW" or Key == "OLD")) then
      envPrint(envAddon.."envSetAirDensity: Invalid key <"..Key..">"); return end
    physenv.SetGravity(gravMembers[Key])
  end

  function envSetPerformance(oPly,oCom,oArgs)
    envLoadMemberValues(perfMembers) -- Sets the performance on proper key
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    if(not (Key == "NEW" or Key == "OLD")) then
      envPrint(envAddon.."envSetAirDensity: Invalid key <"..Key..">"); return end
    physenv.SetPerformanceSettings(perfMembers[Key])
  end

  function envDumpConvarValues() -- The values in the convars. Does not affect NEW key
    envPrint(envDumpConvars(airMembers)..envDumpConvars(gravMembers)..envDumpConvars(perfMembers))
  end

  function envDumpStatusValues(oPly,oCom,oArgs) -- Dumps whatever is found under the given key
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    envPrint(envDumpStatus(airMembers,Key)..envDumpStatus(gravMembers,Key)..envDumpStatus(perfMembers,Key))
  end

  function envLogRefresh(oPly,oCom,oArgs) -- Dumps whatever is found under the given key
    oPly:ConCommand(envPrefx.."logused "..tostring(tonumber(oArgs[1]) or 0))
    enLog = GetConVar(envPrefx.."logused"):GetBool()
  end

  if(SERVER) then -- Refresh the NEW key on change
    envAddCallBacks(airMembers , envSetAirDensity)
    envAddCallBacks(gravMembers, envSetGravity)
    envAddCallBacks(perfMembers, envSetPerformance)
  end

  if(CLIENT) then -- User control commands
    concommand.Add(envPrefx.."logrefresh"    ,envLogRefresh)
    concommand.Add(envPrefx.."dumpconvars"   ,envDumpConvarValues)
    concommand.Add(envPrefx.."dumpstatus"    ,envDumpStatusValues)
    concommand.Add(envPrefx.."setairdensity" ,envSetAirDensity)
    concommand.Add(envPrefx.."setgravity"    ,envSetGravity)
    concommand.Add(envPrefx.."setperformance",envSetPerformance)
  end

  -- Apply the values in the consola variables on the server environment
  envSetAirDensity (nil,nil,{"NEW"})
  envSetGravity    (nil,nil,{"NEW"})
  envSetPerformance(nil,nil,{"NEW"})

end
