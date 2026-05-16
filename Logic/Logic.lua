BuildEnv(...)

Logic = Addon:NewModule('Logic', 'AceEvent-3.0', 'NetEaseSocket-2.0', 'AceSerializer-3.0')

local function isMoreThan24Hours(time1, time2)
    if not time1 or not time2 then
        return true
    end
    local differenceInSeconds = math.abs(time1 - time2)
    local hoursDifference = differenceInSeconds / (60 * 60)
    return hoursDifference < 24
end

function Logic:OnInitialize()
    if not ADDON_REGIONSUPPORT then
        return
    end
    self.IsConnectServer = false
    self.ExtraAttributesMap = {}
    self.ServerCQGLIBNames = {}  -- hash set: key=name, value=true
    C_Timer.NewTicker(60, function() self:SendServerCQGLIB() end)

    self:ListenSocket('NERB', ADDON_SERVER)

    self:RegisterServer('SDV', 'SOCKET_DATA_VALUE')
    self:RegisterServer('SRGD', 'SOCKET_SYSTEM_MESSAGE')
    self:RegisterServer('SVERSION', 'SOCKET_VERSION')

    self:RegisterServer('SERVER_CONNECTED')
    self:RegisterServer('SERVER_DISCONNECTED', 'ServerConnect')
    self:RegisterServer('CHANNEL_DISCONNECTED', 'ConnectChannel')

    self:RegisterServer('SQTB')
    self:RegisterServer('SQGLIB')

    self:RegisterServerEvent('EXCHANGE_RESULT', 'MEETINGSTONE_REWARD_RESULT')
    self:RegisterServerEvent('MALLPURCHASE_RESULT', 'MEETINGSTONE_MALLPURCHASE_RESULT')
    self:RegisterServerEvent('MALLQUERY_RESULT', 'MEETINGSTONE_MALLQUERY_RESULT')
    self:RegisterServerEvent('SH', 'MEETINGHORN_SH')
    self:RegisterServerEvent('STB', 'MEETINGHORN_STB')

    self:ServerConnect()
end

function Logic:RegisterServerEvent(cmd, event)
    self:RegisterServer(cmd, function(_, ...)
        self:SendMessage(event, ...)
    end)
end

function Logic:ServerConnect()
    if self:IsCanConnect() then
        self:ConnectServer()
    end
    self:SendMessage('MEETINGSTONE_SERVER_STATUS_UPDATED', false)
    self.IsConnectServer = false
end

function Logic:IsCanConnect()
    return not IsTrialAccount() and not self.notSupport
end

function Logic:IsSupport()
    return not self.notSupport
end

function Logic:SOCKET_DATA_VALUE(_, key, data, ...)
    local version = 3

    if select('#', ...) == 0 and type(data) == 'string' then
        if data:match('^^1^S.+^t^^$') then
            version = 1
        elseif data:match('^$1.+$$$') then
            version = 2
        end
    end

    if version == 3 then
        data = self:Serialize(data, ...)
    end
    DataCache:SaveCache(key, data)
end

function Logic:SOCKET_SYSTEM_MESSAGE(_, msg)
    SendSystemMessage(msg.msg)
end

function Logic:SOCKET_VERSION(_, ...)
    self.notSupport = not select(3, ...)
    self:SendMessage('MEETINGSTONE_NEW_VERSION', ...)
end

function Logic:SERVER_CONNECTED()
    self:SendServer('SLOGIN', ADDON_VERSION, UnitGUID('player'), GetAddonSource(), select(2, BNGetInfo()),
                    DataCache:GetQueryData())
    self.IsConnectServer = true
    self:SendMessage('MEETINGSTONE_SERVER_STATUS_UPDATED', true)
    self:SendServer('CQTB')

    local playerName = UnitName("player")
    self:InsertServerCQGLIB(playerName)

end

---- Mall API

function Logic:MallQueryPoint()
    self:SendServer('MALLQUERY', UnitGUID('player'), ADDON_VERSION_SHORT)
end

function Logic:MallPurchase(id, price, confirm)
    if not id then
        debug('MallPurchase args #1 is null', 2)
        return
    end

    self:SendServer('MALLPURCHASE', id, UnitGUID('player'), ADDON_VERSION_SHORT, confirm, price)
    debug(format('MALLPURCHASE: %s %s', id, price))
end

function Logic:Exchange(text)
    if not text or text == '' then
        debug('code is null', 2)
        return
    end

    self:SendServer('EXCHANGE', text, UnitGUID('player'), ADDON_VERSION_SHORT)
    debug('EXCHANGE: ' .. text)
end

function Logic:SEI(activity, title, summary, isDeal, ExtraAttributes)
  if not activity then
    return
  end

  title = title or ''
  summary = summary or ''
  isDeal = isDeal or false
  if isDeal and self:IsDeal() then
    local Leader = activity:GetLeader() or UnitName("player") .. '-' .. GetRealmName()
    self.ExtraAttributesMap[Leader] = ExtraAttributes
    self:SendServer('SEI', UnitGUID('player'), GetPlayerBattleTag(), ADDON_VERSION, activity:GetActivityID(),
      activity:GetCustomID(), activity:GetMode(), activity:GetLoot(), title .. ' ' .. summary,
      activity:GetItemLevel(), activity:GetPvPRating(), (select(3, UnitClass('player'))), isDeal,
      ExtraAttributes)
  else
    self:SendServer('SEI', UnitGUID('player'), GetPlayerBattleTag(), ADDON_VERSION, activity:GetActivityID(),
      activity:GetCustomID(), activity:GetMode(), activity:GetLoot(), title .. ' ' .. summary,
      activity:GetItemLevel(), activity:GetPvPRating(), (select(3, UnitClass('player'))), isDeal,
      {})
  end

end

function Logic:SEJ(activity, comment, tank, healer, damager)
    if not activity then
        return
    end

    self:SendServer('SEJ', UnitGUID('player'), GetPlayerBattleTag(), ADDON_VERSION, activity:GetLeader(),
                    activity:IsMeetingStone(), activity:GetActivityID(), activity:GetCustomID(), comment, tank, healer,
                    damager, activity:GetLeaderClass())
end

function Logic:AddIgnore(name, msg)
    if not name or UnitIsUnit('player', Ambiguate(name, 'none')) then
        return
    end

    self:SendServer('IGNORE', name, msg, UnitGUID('player'), GetPlayerBattleTag(), ADDON_VERSION)
end

function Logic:SendCommand(cmd, ...)
    self:SendServer(cmd, UnitGUID('player'), GetPlayerBattleTag(), ADDON_VERSION_SHORT, ...)
end

function Logic:IsServerLogon()
  return self.IsConnectServer
end

function Logic:SQTB(eventName, isDeal)
  Profile.gdb.global.IsDeal = isDeal
  self:SendMessage('MEETINGSTONE_SERVER_IS_DEAL', isDeal)
end

function Logic:IsDeal()
  return false -- 临时关闭
  --return Profile.gdb.global.IsDeal
end

function Logic:GetMedalList(LeaderName)
    -- 安全检查输入参数
    if not LeaderName or LeaderName == '' then
        return false
    end

    local Leader = LeaderName
    if not string.find(Leader, "-") then
      Leader = Leader .. '-' .. GetRealmName()
    end

    -- 确保数据表存在
    if not Profile.gdb.global.LocomotiveData then
      Profile.gdb.global.LocomotiveData = {}
    end

    -- 修复：使用处理后的 Leader 而不是原始的 LeaderName
    local regimentData = Profile.gdb.global.LocomotiveData[Leader]
    if regimentData == nil or regimentData.level == -1 or not regimentData.medalMap or regimentData.medalMap["medal"] == nil then
        return false
    end
    return regimentData.medalMap["medal"]
end

function Logic:GetExtraAttributes(LeaderName)
    if not self:IsDeal() then
      return nil, nil
    end
    local Leader = LeaderName or UnitName("player") .. '-' ..  GetRealmName()
    if not string.find(Leader, "-") then
      Leader = Leader .. '-' .. GetRealmName()
    end
    if self.ExtraAttributesMap[Leader] == nil then
        return nil, nil
    end
    return self.ExtraAttributesMap[Leader]
end

function Logic:SQGLIB(eventName, maps)
    if not Profile.gdb.global.LocomotiveData then
        Profile.gdb.global.LocomotiveData = {}
    end

    for LeaderName, data in pairs(maps) do
        local currentLevel = data['l']
        local starLevel = data['s']
        local currentRoomID = data['c']
        local currentBgID = data['b'] or 0
        local newbieFlag = data['n'] or 0
        local remainCount = data['r'] or 0

        local regimentData = Profile.gdb.global.LocomotiveData[LeaderName] or {
            level = currentLevel,
            starLevel = starLevel,
            roomID = currentRoomID,
            bgID = currentBgID,
            medalMap = {
                acc_exp = data.ae,
                next_star_level_threshold = data.ne,
                medal = data.m
            }
        }

        -- 更新数据
        regimentData.level = currentLevel
        regimentData.starLevel = starLevel
        regimentData.roomID = currentRoomID
        regimentData.bgID = currentBgID
        regimentData.medalMap = {
            acc_exp = data.ae,
            next_star_level_threshold = data.ne,
            medal = data.m
        }
        regimentData.medalTime = time()
        regimentData.isNewbie = (newbieFlag == 1)
        if newbieFlag == 1 then
            regimentData.newbieExpireTime = time() + remainCount * 30 * 60
        end

        Profile.gdb.global.LocomotiveData[LeaderName] = regimentData
    end

    self:SendMessage('MEETINGSTONE_SQGLIB_UPDATED')
end

function Logic:InsertServerCQGLIB(LeaderName)
    if LeaderName == nil or LeaderName == '' then
        return
    end
    local Leader = LeaderName
    if not string.find(Leader, "-") then
      Leader = Leader .. '-' .. GetRealmName()
    end
    if not Profile.gdb.global.LocomotiveData then
        Profile.gdb.global.LocomotiveData = {}
    end
    local regimentData =  Profile.gdb.global.LocomotiveData[Leader]
    if regimentData ~= nil and regimentData.medalTime ~= nil and isMoreThan24Hours(regimentData.medalTime, time()) then
        return
    end
    self.ServerCQGLIBNames[Leader] = true
end

function Logic:SendServerCQGLIB()
    local names = {}
    for name in pairs(self.ServerCQGLIBNames) do
        names[#names + 1] = name
    end
    if #names > 0 then
    --[[@debug@
        print('Send CQGLIB', table.concat(names, ","))
    --@end-debug@]]
        self:SendServer('CQGLIB', table.concat(names, ","))
        self.ServerCQGLIBNames = {}
    end
end
