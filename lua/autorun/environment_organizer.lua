local tonumber     = tonumber
local tostring     = tostring
local print        = print
local Vector       = Vector
local GetConVar    = GetConVar
local CreateConVar = CreateConVar
local bit          = bit
local file         = file
local hook         = hook
local cvars        = cvars
local string       = string
local physenv      = physenv
local concommand   = concommand

local envFile  = "#"              -- File load prefix ( setgravity #propfly loads "data/envorganizer/propfly_envSetGravity.txt" )
local envDiv   = " "              -- File storage delimiter
local envIdnt  = "  "             -- key-value pair indent on printing
local envDir   = "envorganizer/"  -- Place where external storage data files are saved ( if any )
local envPrefx = "envorg_"        -- Prefix to create variables with
local envAddon = "envOrganizer: " -- Logging indicator to view the source addon
local envFvars = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)
local envFlogs = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY)

if(SERVER) then

  local varLogFile = CreateConVar(envPrefx.."logfile", "0", envFlogs, "Enable logging in a file")
  local varLogUsed = CreateConVar(envPrefx.."logused", "0", envFlogs, "Enable logging on error")
  local varAddonEn = CreateConVar(envPrefx.."enabled", "1", envFvars, "Enable organizer addon")

  local function envPrint(...)
    if(not varLogUsed:GetBool()) then return end;
    if(varLogFile:GetBool()) then
      local tData, nID, sLin = {...}, 1, ""
      while(tData[nID]) do
        sLin = sLin..tostring(tData[nID])
        if(tData[nID+1]) then sLin = sLin.."\t" end; nID = nID + 1
      end; file.Append(envDir..envPrefx.."log.txt",sLin.."\n")
    else print(envAddon,...) end
  end

  local function envValidateParams(tMembers)
    if(not tMembers) then
      envPrint("envValidateParams: Members missing"); return false end
    if(not tMembers.Name) then
      envPrint("envValidateParams: Members name missing"); return false end
    tMembers.Name = tostring(tMembers.Name)
    local envCtrl = tMembers.Ctrl; if(type(envCtrl) ~= "table") then
      envPrint("envValidateParams: Members list missing for "..tMembers.Name); return false end
    if(not envCtrl["get"]) then
      envPrint("envValidateParams: Get control missing for "..tMembers.Name); return false end
    if(type(envCtrl["get"]) ~= "function") then
      envPrint("envValidateParams: Get control not function but <"..type(envCtrl["get"]).."> "..tMembers.Name); return false end
    if(not envCtrl["set"]) then
      envPrint("envValidateParams: Set control missing for "..tMembers.Name); return false end
    if(type(envCtrl["set"]) ~= "function") then
      envPrint("envValidateParams: Set control not function but <"..type(envCtrl["get"]).."> "..tMembers.Name); return false end
    return true
  end

  local function envValidateListItems(tMembers, tKeys)
    if(not envValidateParams(tMembers)) then
      envPrint("envValidateListItems: Members invalid"); return false end
    if(type(tKeys) ~= "table") then
      envPrint("envValidateListItems: Keys <"..type(tKeys).."> mismatch for "..tMembers.Name); return false end
    local iCnt, envList = 1, tMembers.List; if(type(envList) ~= "table") then
      envPrint("envValidateListItems: List <"..type(envList).."> mismatch for "..tMembers.Name); return false end
    while(tKeys[iCnt]) do
      if(not envList[tKeys[iCnt]]) then
        envPrint("envValidateListItems: List["..tostring(tKeys[iCnt]).."] item <"..tostring(iCnt).."> missing for "..tMembers.Name); return false end
        iCnt = iCnt + 1
    end; return true
  end

  local function envCreateMemberConvars(tMembers)
    if(not envValidateParams(tMembers)) then
      envPrint("envCreateMemberConvars: Members invalid"); return nil end
    if(not envValidateListItems(tMembers, {"init"})) then
      envPrint("envCreateMemberConvars: List invalid"); return nil end
    local envList = tMembers.List
    for ID = 1, #tMembers, 1 do
      local envMember = tMembers[ID]
      local envKeyID  = envMember[3]
      if(envKeyID ~= nil) then
        envPrint("envCreateMemberConvars:",envPrefx..envMember[1],tostring(envList["init"][envKeyID]),envMember[2])
        envMember["var"] = CreateConVar(envPrefx..envMember[1], tostring(envList["init"][envKeyID]), envFvars, envMember[2])
      else -- Scalar value
        envPrint("envCreateMemberConvars:",envPrefx..envMember[1],tostring(envList["init"]),envMember[2])
        envMember["var"] = CreateConVar(envPrefx..envMember[1], tostring(envList["init"]), envFvars, envMember[2])
      end
    end
  end

  local function envInitMembers(tMembers)
    if(not envValidateParams(tMembers)) then
      envPrint("envInitMembers: Members invalid"); return nil end
    if(not envValidateListItems(tMembers, {"user"})) then
      envPrint("envInitMembers: List invalid"); return nil end
    tMembers.List["init"] = tMembers.Ctrl["get"]()
    envPrint("envInitMembers: Init "..tMembers.Name.." success")
  end

  -- https://wiki.garrysmod.com/page/Category:number
  local airMembers = { -- AIR DENSITY
    Name = "envSetAirDensity",
    List = {["user"] = 0},
    Ctrl = {["get"] = physenv.GetAirDensity, ["set"] = physenv.SetAirDensity},
    {"airdensity", "Air density affecting props", nil, "float", "+"}
  }

  -- https://wiki.garrysmod.com/page/Category:Vector
  local gravMembers = { -- GRAVITY
    Name = "envSetGravity",
    List = {["user"] = Vector()},
    Ctrl = {["get"] = physenv.GetGravity, ["set"] = physenv.SetGravity},
    {"gravitydrx", "Component X of the gravity affecting props", "x", "float", nil},
    {"gravitydry", "Component Y of the gravity affecting props", "y", "float", nil},
    {"gravitydrz", "Component Z of the gravity affecting props", "z", "float", nil}
  }

  -- https://wiki.garrysmod.com/page/Category:physenv
  local perfMembers = { -- PERFORMANCE SETTINGS
    Name = "envSetPerformance",
    List = {["user"] = {}},
    Ctrl = {["get"] = physenv.GetPerformanceSettings, ["set"] = physenv.SetPerformanceSettings},
    {"perfmaxangvel", "Maximum rotation velocity"                                        , "MaxAngularVelocity"               , "float", "+"},
    {"perfmaxlinvel", "Maximum speed of an object"                                       , "MaxVelocity"                      , "float", "+"},
    {"perfminfrmass", "Minimum mass of an object to be affected by friction"             , "MinFrictionMass"                  , "float", "+"},
    {"perfmaxfrmass", "Maximum mass of an object to be affected by friction"             , "MaxFrictionMass"                  , "float", "+"},
    {"perflooktmovo", "Maximum amount of seconds to precalculate collisions with objects", "LookAheadTimeObjectsVsObject"     , "float", "+"},
    {"perflooktmovw", "Maximum amount of seconds to precalculate collisions with world"  , "LookAheadTimeObjectsVsWorld"      , "float", "+"},
    {"perfmaxcolchk", "Maximum collision checks per tick"                                , "MaxCollisionChecksPerTimestep"    , "float", "+"},
    {"perfmaxcolobj", "Maximum collision per object per tick"                            , "MaxCollisionsPerObjectPerTimestep", "float", "+"}
  }

  local function envOrganizerInit()

    if(varAddonEn:GetBool()) then

      local varDataSrc = CreateConVar(envPrefx.."datasrc", "user", envFvars, "Custom hash settings to be loaded instead")
      
      local function envGetDataSource()
        local dataSrc = varDataSrc:GetString()
              dataSrc = tostring((dataSrc and (dataSrc ~= "")) and dataSrc or "init")
        envPrint("envGetDataSource: <"..dataSrc..">"); return dataSrc
      end

      envInitMembers(airMembers) ; envCreateMemberConvars(airMembers)
      envInitMembers(gravMembers); envCreateMemberConvars(gravMembers)
      envInitMembers(perfMembers); envCreateMemberConvars(perfMembers)

      local function envMayPlayer(oPly)
        if(not oPly) then
          envPrint("envMayPlayer: Player missing"); return false end
        if(not oPly:IsValid()) then
          envPrint("envMayPlayer: Player invalid"); return false end
        if(not oPly:IsAdmin()) then
          envPrint("envMayPlayer: Player <"..oPly:Nick().."> not admin"); return false end
        if(oPly:IsBot()) then
          envPrint("envMayPlayer: Player <"..oPly:Nick().."> not person"); return false end
        return true
      end

      local function envIsAlphaNum(sIn)
        return (sIn:match("[^%w]") == nil) end

      local function envGetConvarType(oVar, sTyp) -- Called inside only
        local sTyp = tostring(sTyp or "")
        if(not oVar) then envPrint("envGetConvarType: Cvar missing"); return nil end
        if(sTyp == "float" ) then return oVar:GetFloat () end
        if(sTyp == "int"   ) then return oVar:GetInt   () end
        if(sTyp == "string") then return oVar:GetString() end
        if(sTyp == "bool"  ) then return oVar:GetBool  () end
        envPrint("envGetConvarType: Missed <"..sTyp..">"); return nil
      end

      local function envGetConvarValue(envMember)
        if(not envMember) then envPrint("envGetConvarValue: Member missing"); return nil end
        local sNam = tostring(envMember[1] or ""); if(not sNam or sNam == "") then
          envPrint("envGetConvarValue: Name empty"); return nil end
        local oVar = envMember["var"]; if(not oVar) then
          envPrint("envGetConvarValue: Cvar <"..sNam.."> missing"); return nil end
        local sTyp = tostring(envMember[4] or ""); if(not sTyp or sTyp == "") then
          envPrint("envGetConvarValue: Mode missing"); return nil end
        local anyVal = envGetConvarType(oVar, sTyp, sNam); if(not anyVal) then
          envPrint("envGetConvarValue: Missed <"..tostring(anyVal).."> type <"..sTyp.."> for <"..sNam..">"); return nil end
        return anyVal
      end

      local function envValidateMember(envMember, envValue)
        local sType = tostring(envMember[4] or ""); if(sType == "") then
          envPrint("envValidateMember: Type missing for <"..tostring(envMember[4])..">"); return nil end
        if(sType == "float" or sType == "int") then
          local envValue = (tonumber(envValue) or 0)
          local envLimit = tostring(envMember[5] or ""); if(envLimit == "") then return envValue end
          if    (envLimit ==  "+" and envValue and envValue >  0) then return envValue
          elseif(envLimit == "0+" and envValue and envValue >= 0) then return envValue
          elseif(envLimit ==  "-" and envValue and envValue <  0) then return envValue
          elseif(envLimit == "0-" and envValue and envValue <= 0) then return envValue
          else envPrint("envValidateMember: Limit <"..envLimit.."> mismatched <"..envMember[1].."> for "..tostring(envValue)); return nil end
        else return envValue end
      end

      local function envLoadMemberValues(tMembers)
        if(not envValidateParams(tMembers)) then
          envPrint("envLoadMemberValues: Members missing"); return nil end
        if(not envValidateListItems(tMembers, {"init", "user"})) then
          envPrint("envLoadMemberValues: List invalid"); return nil end
        local envList = tMembers.List
        for ID = 1, #tMembers, 1 do
          local envMember = tMembers[ID]
          local envKeyID  = envMember[3]
          if(not envList) then
            envPrint("envLoadMemberValues: Members list missing"); return nil end
          if(envKeyID ~= nil) then
            local envValue = envValidateMember(envMember, envGetConvarValue(envMember))
            envList["user"][envKeyID] = envValue and envValue or envList["init"][envKeyID]
            envPrint("envLoadMemberValues:",tMembers.Name.."."..envKeyID,envList["init"][envKeyID].." > "..envList["user"][envKeyID])
          else -- Scalar, non-table value
            local envValue = envValidateMember(envMember, envGetConvarValue(envMember))
            envList["user"] = envValue and envValue or envList["init"]
            envPrint("envLoadMemberValues:",tMembers.Name,envList["init"].." > "..envList["user"])
          end
        end
      end

      local function envDumpConvars(tMembers)
        if(not envValidateParams(tMembers)) then
          envPrint("envDumpStatus: Members invalid"); return nil end
        local Out = envIdnt..tMembers.Name.."\n"
        for ID = 1, #tMembers, 1 do
          local envMember = tMembers[ID]
          local envDatakv = envMember[3]
          if(envDatakv) then
            Out = Out..envIdnt..envIdnt..envDatakv.." : <"..tostring(envGetConvarValue(envMember))..">\n"
          else
            Out = Out..envIdnt..envIdnt.."Value : <"..tostring(envGetConvarValue(envMember))..">\n"
          end
        end; return Out
      end

      local function envDumpStatus(tMembers, sKey)
        if(not envValidateParams(tMembers)) then
          envPrint("envDumpStatus: Members invalid"); return nil end
        local sKey = tostring(sKey or ""); if(not sKey or sKey == "") then
          envPrint("envDumpStatus: List key not provided"); return nil end
        if(not envValidateListItems(tMembers, {sKey})) then
          envPrint("envDumpStatus: List invalid"); return nil end
        local envList = tMembers.List
        local Out = envIdnt..tMembers.Name.."["..sKey.."]\n"
        for ID = 1, #tMembers, 1 do
          local envMember = tMembers[ID]
          local envDatakv = envMember[3]
          if(envDatakv) then
            Out = Out..envIdnt..envIdnt..envDatakv.." : <"..tostring(envList[sKey][envDatakv])..">\n"
          else
            Out = Out..envIdnt..envIdnt.."Value : <"..tostring(envList[sKey])..">\n"
          end
        end; return Out
      end

      local function envAddCallBacks(tMembers, fCall)
        if(not envValidateParams(tMembers)) then
          envPrint("envAddCallBacks: Members invalid"); return nil end
        if(type(fCall) ~= "function") then
          envPrint("envAddCallBacks: Call invalid"); return nil end
        for ID = 1, #tMembers, 1 do
          local envMember = tMembers[ID]
          local envKeyID  = envMember[3]
          if(envKeyID ~= nil) then
            cvars.AddChangeCallback(envPrefx..envMember[1], fCall, tMembers.Name.."_"..envMember[3])
          else
            cvars.AddChangeCallback(envPrefx..envMember[1], fCall, tMembers.Name)
          end
        end
      end

      local function envFindMenberID(tMembers, sValue)
        if(not envValidateParams(tMembers)) then
          envPrint("envFindMenberID: Members invalid"); return 0 end
        local sValue = tostring(sValue or "")
        for ID = 1, #tMembers, 1 do
          local envMember = tMembers[ID]
          if(sValue == envMember[1]) then return ID end
        end; return 0
      end

      local function envStoreMemberCustom(tMembers, sStore)
        if(not envValidateParams(tMembers)) then
          envPrint("envStoreMemberCustom: Members invalid"); return nil end
        local sStore = tostring(sStore or "")
        if(not envIsAlphaNum(sStore)) then
          envPrint("envStoreMemberCustom: Store key mismatch <"..sStore..">"); return nil end
        if(not envValidateListItems(tMembers, {"user"})) then
          envPrint("envStoreMemberCustom: List invalid"); return nil end
        local envList = tMembers.List
        if(not file.Exists(envDir,"DATA")) then file.CreateDir(envDir) end
        local sName  = envDir..sStore.."_"..tMembers.Name..".txt"
        local fStore = file.Open(sName, "w", "DATA" )
        if(not fStore) then envPrint("envStoreMemberCustom: file.Open("..sName..") Failed") end
        for ID = 1, #tMembers, 1 do
          local envMember = tMembers[ID]
          local envKeyID  = envMember[3]
          if(envKeyID ~= nil) then
            fStore:Write(envMember[1]..envDiv..tostring(envList["user"][envKeyID]).."\n")
          else
            fStore:Write(envMember[1]..envDiv..tostring(envList["user"]).."\n")
          end
        end
        fStore:Flush()
        fStore:Close()
      end

      local function envLoadMemberCustom(tMembers, sStore)
        if(not envValidateParams(tMembers)) then
          envPrint("envLoadMemberCustom: Members invalid"); return nil end
        local sStore = tostring(sStore or "")
        if(not envIsAlphaNum(sStore)) then
          envPrint("envLoadMemberCustom: Store key mismatch <"..sStore..">"); return nil end
        if(not envValidateListItems(tMembers, {"init", "user"})) then
          envPrint("envLoadMemberCustom: List invalid"); return nil end
        local envList = tMembers.List
        if(not file.Exists(envDir,"DATA")) then
          envPrint("envLoadMemberCustom: Path invalid <data/"..envDir..">"); end
        local sName  = envDir..sStore.."_"..tMembers.Name..".txt"
        local fStore = file.Open(sName, "r", "DATA" )
        if(not fStore) then envPrint("envLoadMemberCustom: file.Open("..sName..") Failed") end
        local sLine, sChar = "", "X"
        while(sChar) do
          sChar = fStore:Read(1)
          if(not sChar) then return end
          if(sChar == "\n") then -- Handle windows format
            if(sLine:sub(-1,-1) == "\r") then sLine = sLine:sub(1,-2) end
            sLine = sLine:gsub("%s+", envDiv) -- All separators to default
            sLine = sLine:Trim(envDiv)
            tBoom = envDiv:Explode(sLine)
            if(tBoom and tBoom[1] and tBoom[2]) then
              local ID = envFindMenberID(tMembers, tBoom[1])
              if(ID and ID > 0) then
                local envMember = tMembers[ID]
                local envValue  = envValidateMember(envMember, tBoom[2])
                local envKeyID  = envMember[3]
                if(envKeyID ~= nil) then
                  envList["user"][envKeyID] = envValue and envValue or envList["init"][envKeyID]
                else
                  envList["user"] = envValue and envValue or envList["init"]
                end
              else envPrint("envLoadMemberCustom: Failed to find <"..tostring(tBoom[1]).."> in "..tMembers.Name) end
            else envPrint("envLoadMemberCustom: Failed to explode <"..sLine..">") end; sLine = ""
          else sLine = sLine..sChar end
        end; fStore:Close()
      end

      local function envPrintDelta(anyParam, anyOld, anyNew) -- Log the delta
        envPrint("["..tostring(anyParam).."] Old<"..tostring(anyOld).."> New<"..tostring(anyNew)..">")
      end

      local function envApplyMembers(tMembers, oArgs)
        if(not envValidateParams(tMembers)) then
          envPrint("envApplyMembers: Members invalid"); return nil end
        local Key = (tostring((type(oArgs) == "table") and oArgs[1] or "")):lower()
        local Len = envFile:len()
        local envList, envCtrl = tMembers.List, tMembers.Ctrl
        if(envList[Key]) then
          if(not envValidateListItems(tMembers, {Key})) then
            envPrint("envApplyMembers: List <"..Key.."> invalid (cvar)"); return nil end
          envPrint("envApplyMembers: Source list <"..Key..">")
          envLoadMemberValues(tMembers)
          envCtrl["set"](tMembers.List[Key])
        elseif(Key:sub(1,Len) == envFile) then
          if(not envValidateListItems(tMembers, {"user"})) then
            envPrint("envApplyMembers: List <"..Key.."> invalid (file)"); return nil end
          envPrint("envApplyMembers: Source file <"..Key:gsub(envFile,"")..">")
          envLoadMemberCustom(tMembers,Key:sub(1+Len,-1))
          envCtrl["set"](tMembers.List["user"])
        else envPrint("envApplyMembers: Missed source <"..Key..">"); return end
      end

      local function envSetAirDensity(oPly,oCom,oArgs) -- Sets the air density on proper key
        return envApplyMembers(airMembers,oArgs)
      end

      local function envSetGravity(oPly,oCom,oArgs) -- Sets the gravity on proper key
        return envApplyMembers(gravMembers,oArgs)
      end

      local function envSetPerformance(oPly,oCom,oArgs) -- Sets the performance on proper key
        return envApplyMembers(perfMembers,oArgs)
      end

      local function envDumpConvarValues(oPly,oCom,oArgs) -- The values in the convars. Does not affect user key
        if(not envMayPlayer(oPly)) then envPrint("envDumpConvarValues: "..oPly:Nick().." not admin"); return nil end
        envPrint("envDumpConvarValues: Source <"..envGetDataSource()..">\n")
        envPrint(envDumpConvars(airMembers ))
        envPrint(envDumpConvars(gravMembers))
        envPrint(envDumpConvars(perfMembers))
      end

      local function envDumpStatusValues(oPly,oCom,oArgs) -- Dumps whatever is found under the given key
        if(not envMayPlayer(oPly)) then envPrint("envDumpStatusValues: "..oPly:Nick().." not admin"); return nil end
        local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
        envPrint("envDumpStatusValues:\n")
        envPrint(envDumpStatus(airMembers ,Key))
        envPrint(envDumpStatus(gravMembers,Key))
        envPrint(envDumpStatus(perfMembers,Key))
      end

      local function envStoreValues(oPly,oCom,oArgs)
        if(not envMayPlayer(oPly)) then
          envPrint("envStoreValues: "..oPly:Nick().." not admin"); return nil end
        local Key = tostring((type(oArgs) == "table") and oArgs[1] or "")
        if(not envIsAlphaNum(Key)) then
          envPrint("envStoreValues: Key not alphanum <"..Key..">"); return nil end
        envStoreMemberCustom(airMembers , Key)
        envStoreMemberCustom(gravMembers, Key)
        envStoreMemberCustom(perfMembers, Key)
        envPrint("envStoreValues: Stored under <"..Key..">")
      end

      envAddCallBacks(airMembers , envSetAirDensity)
      envAddCallBacks(gravMembers, envSetGravity)
      envAddCallBacks(perfMembers, envSetPerformance)

      concommand.Add(envPrefx.."dumpconvars"   ,envDumpConvarValues)
      concommand.Add(envPrefx.."dumpstatus"    ,envDumpStatusValues)
      concommand.Add(envPrefx.."setairdensity" ,envSetAirDensity)
      concommand.Add(envPrefx.."setgravity"    ,envSetGravity)
      concommand.Add(envPrefx.."setperformance",envSetPerformance)
      concommand.Add(envPrefx.."storevalues"   ,envStoreValues)

      -- Apply the values in the console variables on the server environment
      envSetAirDensity (nil,nil,{envGetDataSource()})
      envSetGravity    (nil,nil,{envGetDataSource()})
      envSetPerformance(nil,nil,{envGetDataSource()})

      print(envAddon.."Enabled: <"..envGetDataSource()..">")
    else
      print(envAddon.."Disabled")
    end
  end

  hook.Add("InitPostEntity", envPrefx.."server_init", envOrganizerInit)
end
