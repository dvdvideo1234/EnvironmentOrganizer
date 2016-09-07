local tonumber     = tonumber
local tostring     = tostring
local print        = print
local Vector       = Vector
local GetConVar    = GetConVar
local CreateConVar = CreateConVar
local bit          = bit
local file         = file
local cvars        = cvars
local string       = string
local physenv      = physenv
local concommand   = concommand

local envFile  = "#" -- File load prefix ( setgravity #propfly loads propfly file )
local envDiv   = " " -- File storage delimiter
local envDir   = "envorganiser/" -- Place where data is saved
local envPrefx = "envorganiser_"
local envAddon = "envOrganizer: "
local envFvars = bit.bor(FCVAR_ARCHIVE, FCVAR_ARCHIVE_XBOX, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)
local envFlogs = bit.bor(FCVAR_ARCHIVE, FCVAR_ARCHIVE_XBOX, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY)

CreateConVar(envPrefx.."logused", "0", envFlogs, "Enable logging on error")
CreateConVar(envPrefx.."enabled", "1", envFvars, "Enable organizer addon")

local enLog = GetConVar(envPrefx.."logused"):GetBool()

if(GetConVar(envPrefx.."enabled"):GetBool()) then

  CreateConVar(envPrefx.."hashvar", "user", envFvars, "Custom hash settings to be loaded instead")

  local hashVar = GetConVar(envPrefx.."hashvar"):GetString()

  local function envPrint(...) if(not enLog) then return end; print(...) end

  local function envMayPlayer(oPly)
    if(not (oPly and oPly:IsValid())) then return false end
    if(not oPly:IsAdmin()) then return false end
    if(not oPly:IsFrozen()) then return false end
    if(not oPly:IsBot()) then return false end
    return true
  end

  local function envIsAplphaNum(sIn)
    if(string.match(sIn,"%w")) then return false end
    return true
  end

  local function envGetConvarType(oVar, sTyp) -- Called inside only
    local sTyp = tostring(sTyp or "")
    if(not oVar) then envPrint(envAddon.."envGetConvarType: Cvar missing"); return nil end
    if(sTyp == "float" ) then return oVar:GetFloat () end
    if(sTyp == "int"   ) then return oVar:GetInt   () end
    if(sTyp == "string") then return oVar:GetString() end
    if(sTyp == "bool"  ) then return oVar:GetBool  () end
    envPrint(envAddon.."envGetConvarType: Missed <"..sTyp..">"); return nil
  end

  local function envGetConvarValue(envMember)
    if(not envMember) then envPrint(envAddon.."envGetConvarValue: Member missing"); return nil end
    local sNam = tostring(envMember[1] or ""); if(sNam == "") then
      envPrint(envAddon.."envGetConvarValue: Name empty"); return nil end
    local oVar = GetConVar(envPrefx..sNam); if(not oVar) then
      envPrint(envAddon.."envGetConvarValue: Cvar <"..sNam.."> missing"); return nil end
    local sTyp = tostring(envMember[4] or ""); if(sTyp == "") then
      envPrint(envAddon.."envGetConvarValue: Mode missing"); return nil end
    local anyVal = envGetConvarType(oVar, sTyp, sNam); if(not anyVal) then
      envPrint(envAddon.."envGetConvarValue: Missed <"..tostring(anyVal).."> type <"..sTyp.."> for <"..sNam.."> in "..tMembers.Name); return nil end
    return anyVal
  end

  local function envCreateMemberConvars(tMembers)
    local envList = tMembers.List
    for ID = 1, #tMembers, 1 do
      local envMember = tMembers[ID]
      CreateConVar(envPrefx..envMember[1], envList["INIT"][ID], envFvars, envMember[2])
    end
  end

  local function envValidateMember(envMember, envValue)
    local sType = tostring(envMember[4] or ""); if(sType == "") then
      envPrint(envAddon.."envValidateMember: Type missing for <"..tostring(envMember[4])..">"); return nil end
    if(sType == "float" or sType == "int") then
      local envValue = (tonumber(envValue) or 0)
      local envLimit = tostring(envMember[5] or ""); if(envLimit == "") then return envValue end
      if    (envLimit ==  "+" and envValue and envValue >  0) then return envValue
      elseif(envLimit == "0+" and envValue and envValue >= 0) then return envValue
      elseif(envLimit ==  "-" and envValue and envValue <  0) then return envValue
      elseif(envLimit == "0-" and envValue and envValue <= 0) then return envValue
      else envPrint(envAddon.."envValidateMember: Limit <"..envLimit.."> mismatched <"..envMember[1]..">"); return nil end
    else return envValue end
  end

  local function envLoadMemberValues(tMembers)
    if(not tMembers) then
      envPrint(envAddon.."envLoadMemberValues: Members missing"); return nil end
    for ID = 1, #tMembers, 1 do
      local envMember = tMembers[ID]
      local envKeyID  = envMember[3]
      local envList   = tMembers.List
      if(not envList) then
        envPrint(envAddon.."envLoadMemberValues: Members list missing"); return nil end
      if(envKeyID ~= nil) then
        local envValue = envValidateMember(envMember, envGetConvarValue(envMember))
        envList["USER"][envKeyID] = envValue and envValue or envList["INIT"][envKeyID]
        envPrint(tMembers.Name.."."..envKeyID, envList["INIT"][envKeyID], envList["USER"][envKeyID])
      else -- Scalar, non-table value
        local envValue = envValidateMember(envMember, envGetConvarValue(envMember))
        envList["USER"] = envValue and envValue or envList["INIT"]
        envPrint(tMembers.Name, envList["INIT"], envList["USER"])
      end
    end
  end

  local function envDumpConvars(tMembers)
    if(not tMembers) then
      envPrint(envAddon.."envDumpStatus: No mebers"); return nil end
    local Out = (tMembers.Name.."\n")
    for ID = 1, #tMembers, 1 do
      local envMember = tMembers[ID]
      Out = Out.."  "..envMember[3]..": <"..tostring(envGetConvarValue(envMember))..">\n"
    end; return (Out.."\n")
  end

  local function envDumpStatus(tMembers, sKey)
    local sKey = tostring(sKey or "")
    if(not tMembers) then
      envPrint(envAddon.."envDumpStatus: No mebers"); return nil end
    if(not tMembers.List) then
      envPrint(envAddon.."envDumpStatus: No mebers list"); return nil end
    if(not tMembers.List[sKey]) then
      envPrint(envAddon.."envDumpStatus: No mebers list key"); return nil end
    local Out = (tMembers.Name.."["..sKey.."]\n")
    for ID = 1, #tMembers, 1 do
      local envMember = tMembers[ID]
      local envDatakv = envMember[3]
      Out = Out.."  "..envDatakv..": <"..tostring(tMembers[sKey][envDatakv])..">\n"
    end; return (Out.."\n")
  end

  local function envAddCallBacks(tMembers, fCall)
    for ID = 1, #tMembers, 1 do
      local envMember = tMembers[ID]
      cvars.AddChangeCallback(envPrefx..envMember[1], fCall, tMembers.Name.."_"..envMember[3])
    end
  end

  local function envFindMenberID(tMembers, sValue)
    if(not tMembers) then
      envPrint(envAddon.."envFindMenberID: Members missing"); return 0 end
    local sValue = tostring(sValue or "")
    for ID = 1, #tMembers, 1 do
      local envMember = tMembers[ID]
      if(sValue == envMember[1])) then return ID end
    end; return 0
  end

  local function envStoreCustom(tMembers, sStore)
    if(not tMembers) then
      envPrint(envAddon.."envStoreCustom: Members missing"); return nil end
    local sStore = tostring(sStore or "")
    if(not envIsAplphaNum(sStore)) then
      envPrint(envAddon.."envStoreCustom: Store key mismatch <"..sStore..">"); return nil end
    local envList = tMembers.List
    if(not envList) then
      envPrint(envAddon.."envStoreCustom: Members list missing"); return nil end
    if(not file.Exists(envDir,"DATA")) then file.CreateDir(envDir) end
    local sName = envDir..tMembers.Name.."_"..sStore..".txt"
    local fStore = file.Open(sName, "w", "DATA" )
    if(not fStore) then envPrint(envAddon.."envStoreCustom: file.Open("..sName..") Failed") end
    for ID = 1, #tMembers, 1 do
      local envMember = tMembers[ID]
      local envKeyID  = envMember[3]
      if(envKeyID ~= nil) then
        fStore:Write(envMember[1]..envDiv..tostring(envList["USER"][envKeyID]).."\n")
      else
        fStore:Write(envMember[1]..envDiv..tostring(envList["USER"]).."\n")
      end
    end
    fStore:Flush()
    fStore:Close()
  end

  local function envLoadCustom(tMembers, sStore)
    if(not tMembers) then
      envPrint(envAddon.."envLoadCustom: Members missing"); return nil end
    local sStore = tostring(sStore or "")
    if(not envIsAplphaNum(sStore)) then
      envPrint(envAddon.."envLoadCustom: Store key mismatch <"..sStore..">"); return nil end
    local envList = tMembers.List
    if(not envList) then
      envPrint(envAddon.."envLoadCustom: Members list missing"); return nil end
    if(not file.Exists(envDir,"DATA")) then envPrint(envAddon..) end
    local sName = envDir..tMembers.Name.."_"..sStore..".txt"
    local fStore = file.Open(sName, "r", "DATA" )
    if(not fStore) then envPrint(envAddon.."envLoadCustom: file.Open("..sName..") Failed") end
    local sLine, sChar, nLen = "", "X", 0
    while(sChar) do
      sChar = fStore:Read(1)
      if(not sChar) then return end
      if(sChar == "\n") then
        nLen = string.len(sLine)
        if(string.sub(sLine,nLen,nLen) == "\r") then -- Handle windows format
          sLine = string.sub(sLine,1,nLen-1); nLen = nLen - 1 end
        sLine = string.gsub(sLine, "%s+", envDiv) -- All separators to default
        sLine = string.Trim(sLine, envDiv)
        tBoom = string.Explode(envDiv,sLine)
        if(tBoom and tBoom[1] and tBoom[2]) then
          local ID = envFindMenberID(tMembers, tBoom[1])
          if(ID and ID > 0)
            local envMember = tMembers[ID]
            local envValue  = envValidateMember(envMember, tBoom[2])
            local envKeyID  = envMember[3]
            if(envKeyID ~= nil) then
              envList["USER"][envKeyID] = envValue and envValue or envList["INIT"][envKeyID]
            else
              envList["USER"] = envValue and envValue or envList["INIT"]
            end
          else envPrint(envAddon.."envLoadCustom: Failed to find <"..tostring(tBoom[1]).."> in "..tMembers.Name) end
        else envPrint(envAddon.."envLoadCustom: Failed to explode <"..sLine..">") end; sLine = ""
      else sLine = sLine..sChar end
    end; fStore:Close()
  end

  -- https://wiki.garrysmod.com/page/Category:number
  local airMembers = { -- INITIALIZE AIR DENSITY
    Name = "envSetAirDensity",
    List = {INIT = physenv.GetAirDensity(), USER = 0},
    {"airdensity", "Air density affecting props", nil, "float", "+"}
  }; envCreateMemberConvars(airMembers)

  -- https://wiki.garrysmod.com/page/Category:Vector
  local gravMembers = { -- INITIALIZE GRAVITY
    Name = "envSetGravity",
    List = {INIT = physenv.GetGravity(), USER = Vector()},
    {"gravitydrx", "Component X of the gravity affecting props", "x", "float", nil},
    {"gravitydry", "Component Y of the gravity affecting props", "y", "float", nil},
    {"gravitydrz", "Component Z of the gravity affecting props", "z", "float", nil}
  }; envCreateMemberConvars(gravMembers)

  -- https://wiki.garrysmod.com/page/Category:physenv
  local perfMembers = { -- INITIALIZE ENVIRONMENT SETTINGS
    Name = "envSetPerformance",
    List = {INIT = physenv.GetPerformanceSettings(), USER = {}},
    {"perfmaxangvel", "Maximum rotation velocity"                                        , "MaxAngularVelocity"               , "float", "+"},
    {"perfmaxlinvel", "Maximum speed of an object"                                       , "MaxVelocity"                      , "float", "+"},
    {"perfminfrmass", "Minimum mass of an object to be affected by friction"             , "MinFrictionMass"                  , "float", "+"},
    {"perfmaxfrmass", "Maximum mass of an object to be affected by friction"             , "MaxFrictionMass"                  , "float", "+"},
    {"perflooktmovo", "Maximum amount of seconds to precalculate collisions with objects", "LookAheadTimeObjectsVsObject"     , "float", "+"},
    {"perflooktmovw", "Maximum amount of seconds to precalculate collisions with world"  , "LookAheadTimeObjectsVsWorld"      , "float", "+"},
    {"perfmaxcolchk", "Maximum collision checks per tick"                                , "MaxCollisionChecksPerTimestep"    , "float", "+"},
    {"perfmaxcolobj", "Maximum collision per object per tick"                            , "MaxCollisionsPerObjectPerTimestep", "float", "+"}
  }; envCreateMemberConvars(perfMembers)

  local function envPrintDelta(anyParam, anyOld, anyNew) -- Log the delta
    envPrint(envAddon.."["..tostring(anyParam).."] Old<"..tostring(anyOld).."> New<"..tostring(anyNew)..">")
  end

  function envSetAirDensity(oPly,oCom,oArgs) -- Sets the air density on proper key
    if(not envMayPlayer(oPly)) then envPrint(envAddon.."envSetAirDensity: "..oPly:Nick().." not admin"); return nil end
    local Key = string.upper(tostring((type(oArgs) == "table") and oArgs[1] or ""))
    local Len = string.len(envFile)
    if(airMembers.List[Key]) then
      envLoadMemberValues(airMembers)
      physenv.SetAirDensity(airMembers.List[Key])
    elseif(string.sub(Key,1,Len) == envFile) then
      envLoadCustom(airMembers,string.sub(Key,1+Len,-1))
      physenv.SetAirDensity(airMembers.List["USER"])
    else envPrint(envAddon.."envSetAirDensity: Missed key <"..Key..">"); return end
  end

  function envSetGravity(oPly,oCom,oArgs) -- Sets the gravity on proper key
    if(not envMayPlayer(oPly)) then envPrint(envAddon.."envSetGravity: "..oPly:Nick().." not admin"); return nil end
    local Key = string.upper(tostring((type(oArgs) == "table") and oArgs[1] or ""))
    local Len = string.len(envFile)
    if(gravMembers.List[Key]) then
      envLoadMemberValues(gravMembers)
      physenv.SetGravity(gravMembers.List[Key])
    elseif(string.sub(Key,1,Len) == envFile) then
      envLoadCustom(gravMembers,string.sub(Key,1+Len,-1))
      physenv.SetGravity(gravMembers.List["USER"])
    else envPrint(envAddon.."envSetGravity: Missed key <"..Key..">"); return end
  end

  function envSetPerformance(oPly,oCom,oArgs) -- Sets the performance on proper key
    if(not envMayPlayer(oPly)) then envPrint(envAddon.."envSetPerformance: "..oPly:Nick().." not admin"); return nil end
    local Key = string.upper(tostring((type(oArgs) == "table") and oArgs[1] or ""))
    local Len = string.len(envFile)
    if(perfMembers.List[Key]) then
      envLoadMemberValues(perfMembers)
      physenv.SetPerformanceSettings(perfMembers.List[Key])
    elseif(string.sub(Key,1,Len) == envFile) then
      envLoadCustom(perfMembers,string.sub(Key,1+Len,-1))
      physenv.SetPerformanceSettings(perfMembers.List["USER"])
    else envPrint(envAddon.."envSetPerformance: Missed key <"..Key..">"); return end
  end

  function envDumpConvarValues() -- The values in the convars. Does not affect user key
    if(not envMayPlayer(oPly)) then envPrint(envAddon.."envDumpConvarValues: "..oPly:Nick().." not admin"); return nil end
    envPrint(envDumpConvars(airMembers)..envDumpConvars(gravMembers)..envDumpConvars(perfMembers))
  end

  function envDumpStatusValues(oPly,oCom,oArgs) -- Dumps whatever is found under the given key
    if(not envMayPlayer(oPly)) then envPrint(envAddon.."envDumpStatusValues: "..oPly:Nick().." not admin"); return nil end
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    envPrint(envDumpStatus(airMembers,Key)..envDumpStatus(gravMembers,Key)..envDumpStatus(perfMembers,Key))
  end

  function envLogRefresh(oPly,oCom,oArgs) -- Dumps whatever is found under the given key
    if(not envMayPlayer(oPly)) then envPrint(envAddon.."envLogRefresh: "..oPly:Nick().." not admin"); return nil end
    oPly:ConCommand(envPrefx.."logused "..tostring(tonumber(oArgs[1]) or 0))
    enLog = GetConVar(envPrefx.."logused"):GetBool()
  end

  function envStoreValues(oPly,oCom,oArgs)
    if(not envMayPlayer(oPly)) then envPrint(envAddon.."envStoreValues: "..oPly:Nick().." not admin"); return nil end
    local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
    if(not envIsAplphaNum(Key)) then return end
    envStoreCustom(airMembers , Key)
    envStoreCustom(gravMembers, Key)
    envStoreCustom(perfMembers, Key)
  end

  if(SERVER) then -- Refresh the user key on change
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
    concommand.Add(envPrefx.."storevalues"   ,envStoreValues)
  end

  -- Apply the values in the console variables on the server environment
  envSetAirDensity (nil,nil,{hashVar})
  envSetGravity    (nil,nil,{hashVar})
  envSetPerformance(nil,nil,{hashVar})

  print(envAddon.."Enabled: <"..hashVar..">")
else
  print(envAddon.."Disabled")
end
