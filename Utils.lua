BuildEnv(...)

-- ============================================================================
-- MeetingStone 工具模块化重构
-- 将全局函数按功能组织到命名空间中，保持向后兼容
-- ============================================================================

-- 创建主要的工具命名空间
MSUtils = {}

-- ============================================================================
-- 玩家和角色相关工具
-- ============================================================================
MSUtils.Player = {
  -- 获取职业颜色文本
  getClassColorText = function(className, text)
    local color = RAID_CLASS_COLORS[className]
    return format('|c%s%s|r', color.colorStr, text)
  end,

  -- 获取带颜色的职业文本
  getClassColoredText = function(class, text)
    if not class or not text then
      return text
    end
    local color = RAID_CLASS_COLORS[class]
    if color then
      return format('|c%s%s|r', color.colorStr, text)
    end
    return text
  end,

  -- 获取完整名称 (角色名-服务器名)
  getFullName = function(name, realm)
    if not name then
      return
    end
    if not realm or realm == '' then
      name, realm = strsplit('-', name)
      realm = realm or GetRealmName()
    end
    return format('%s-%s', name, realm)
  end,

  -- 获取单位的完整名称
  unitFullName = function(unit)
    return MSUtils.Player.getFullName(UnitName(unit))
  end,

  -- 分割玩家姓名
  splitPlayerName = function(input)
    local delimiterPos = string.find(input, "-")
    if not delimiterPos then
      return input, nil
    end

    local name = string.sub(input, 1, delimiterPos - 1)
    local realm = string.sub(input, delimiterPos + 1)
    realm = string.gsub(realm, "%(%d+%)", "")

    return name, realm
  end,

  -- 获取玩家职业ID
  getPlayerClass = function()
    return (select(3, UnitClass('player')))
  end,

  -- 获取玩家装等
  getPlayerItemLevel = function(isPvP)
    if isPvP then
      return floor(select(3, GetAverageItemLevel()))
    else
      return floor(GetAverageItemLevel())
    end
  end,

  -- 获取玩家完整姓名
  getPlayerFullName = function()
    return (format('%s-%s', UnitName('player'), GetRealmName()):gsub('%s+', ''))
  end,

  -- 获取玩家战网标签
  getPlayerBattleTag = function()
    return (select(2, BNGetInfo()))
  end,

  -- 获取大秘分数
  getMythicPlusScore = function()
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
      local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
      if summary and summary.currentSeasonScore then
        return summary.currentSeasonScore
      end
    end
    return 0
  end
}

-- ============================================================================
-- 团队和组队相关工具
-- ============================================================================
MSUtils.Group = {
  -- 检查是否为团队队长
  isGroupLeader = function()
    return not IsInGroup(LE_PARTY_CATEGORY_HOME) or UnitIsGroupLeader('player', LE_PARTY_CATEGORY_HOME)
  end,

  -- 检查是否为活动管理员
  isActivityManager = function()
    return UnitIsGroupLeader('player', LE_PARTY_CATEGORY_HOME) or
      (IsInRaid(LE_PARTY_CATEGORY_HOME) and UnitIsGroupAssistant('player', LE_PARTY_CATEGORY_HOME))
  end,

  -- 遍历团队单位
  iterateGroupUnits = function()
    local RAID_UNITS = {}
    local PARTY_UNITS = {}

    -- 初始化单位列表
    for i = 1, 40 do
      tinsert(RAID_UNITS, 'raid' .. i)
    end

    for i = 1, 4 do
      tinsert(PARTY_UNITS, 'party' .. i)
    end
    tinsert(PARTY_UNITS, 'player')

    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then
      return nop
    elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
      return ipairs(RAID_UNITS)
    else
      return ipairs(PARTY_UNITS)
    end
  end,

  -- 获取公会名称
  getGuildName = function()
    local name, _, _, realm = GetGuildInfo('player')
    return name and MSUtils.Player.getFullName(name, realm) or nil
  end,

  -- 获取公会会长服务器
  getGuildMasterRealm = function()
    for i = 1, GetNumGuildMembers() do
      local name, _, rankIndex = GetGuildRosterInfo(i)
      if rankIndex == 0 then  -- 0 表示会长
        local _, realm = strsplit("-", name)
        return realm or GetRealmName()
      end
    end
    return nil
  end,

  -- 获取公会会长名字
  getGuildMasterName = function()
    for i = 1, GetNumGuildMembers() do
      local name, _, rankIndex = GetGuildRosterInfo(i)
      if rankIndex == 0 then  -- 0 表示会长
        local playerName = strsplit("-", name)
        return playerName
      end
    end
    return nil
  end
}

-- ============================================================================
-- 活动和副本相关工具
-- ============================================================================
MSUtils.Activity = {
  -- 获取活动代码
  getActivityCode = function(activityId, customId, categoryId, groupId)
    if activityId and (not categoryId or not groupId) then
      local activityInfo = C_LFGList.GetActivityInfoTable(activityId)
      categoryId = activityInfo.categoryID
      groupId = activityInfo.groupFinderActivityGroupID
    end
    return format('%d-%d-%d-%d', categoryId or 0, groupId or 0, activityId or 0, customId or 0)
  end,

  -- 活动类型检查函数
  isUseHonorLevel = function(activityId)
    if activityId then
      local activityInfo = C_LFGList.GetActivityInfoTable(activityId)
      return activityId and activityInfo.useHonorLevel
    end
  end,

  isMythicPlusActivity = function(activityId)
    if activityId then
      local activityInfo = C_LFGList.GetActivityInfoTable(activityId)
      return activityId and activityInfo.isMythicActivity
    end
  end,

  isRatedPvpActivity = function(activityId)
    if activityId then
      local activityInfo = C_LFGList.GetActivityInfoTable(activityId)
      return activityId and activityInfo.isRatedPvpActivity
    end
  end,

  -- 活动名称获取函数
  getActivityName = function(activityId, customId)
    return customId and ACTIVITY_CUSTOM_NAMES[customId] or ACTIVITY_NAME_CACHE[activityId]
  end,

  getActivityShortName = function(activityId, customId)
    return customId and ACTIVITY_CUSTOM_SHORT_NAMES[customId] or select(2, C_LFGList.GetActivityInfo(activityId))
  end,

  getModeName = function(mode)
    return ACTIVITY_MODE_NAMES[mode]
  end,

  getLootName = function(loot)
    return ACTIVITY_LOOT_LONG_NAMES[loot]
  end,

  getLootShortName = function(loot)
    return ACTIVITY_LOOT_NAMES[loot]
  end,

  -- 生成活动标题
  codeActivityTitle = function(activityId, customId, mode, loot)
    return format('%s-%s-%s-%s', L['集合石'],
      MSUtils.Activity.getLootName(loot),
      MSUtils.Activity.getModeName(mode),
      MSUtils.Activity.getActivityName(activityId, customId))
  end,

  -- 获取活动分类名称
  getActivityCategoryName = function(activity)
    if not activity then return "未知" end

    local activityID = activity:GetActivityID()
    local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
    if not activityInfo then return "未知" end

    local categoryID = activityInfo.categoryID
    local categoryName = "其他"

    if categoryID == 2 then
      categoryName = "地下城"
    elseif categoryID == 3 then
      categoryName = "团队副本"
    elseif categoryID == 121 then
      categoryName = "地下堡"
    elseif categoryID == 1 then
      categoryName = "任务"
    end

    return categoryName
  end
}

-- ============================================================================
-- PVP 相关工具
-- ============================================================================
MSUtils.PvP = {
  -- PVP活动索引映射
  PVP_INDEXS = { [6] = 1, [7] = 1, [8] = 1, [19] = 2 },

  -- 检查是否使用PVP评分
  isUsePvPRating = function(activityId)
    return MSUtils.PvP.PVP_INDEXS[activityId]
  end,

  -- 获取玩家PVP评分
  getPlayerPvPRating = function(activityId)
    local ratingType = MSUtils.PvP.PVP_INDEXS[activityId]
    if not ratingType then
      return
    end

    if ratingType == 2 then
      return (GetPersonalRatedInfo(4))
    else
      return max((GetPersonalRatedInfo(1)), (GetPersonalRatedInfo(2)), (GetPersonalRatedInfo(3)))
    end
  end
}

-- ============================================================================
-- 数据编解码工具
-- ============================================================================
MSUtils.Data = {
  -- 数字压缩处理
  compressNumber = function(n)
    n = tonumber(n)
    return n and n > 0 and n or nil
  end,

  -- 解码评论数据
  decodeCommetData = function(comment)
    if not comment or comment == '' then
      return true, ''
    end
    local summary, data = comment:match('^(.*)%((^1^.+^^)%)$')
    if not data then
      return true, comment
    end

    local proto = ActivityProto:New()
    local ok, valid = proto:Deserialize(data)
    if not valid then
      return false
    end
    if not ok then
      return true, comment
    end
    return true, summary, proto
  end,

  -- 编码评论数据
  codeCommentData = function(activity)
    local AceSerializer = LibStub('AceSerializer-3.0')
    local activityId = activity:GetActivityID()
    local customId = activity:GetCustomID()
    local data = format('(%s)',
      AceSerializer:Serialize(MSUtils.Data.compressNumber(customId), ADDON_VERSION_SHORT, activity:GetMode(),
        activity:GetLoot(), GetPlayerClass(),
        GetPlayerItemLevel(activity:IsUseHonorLevel()),
        GetPlayerRaidProgression(activityId, customId),
        GetPlayerPvPRating(activityId), MSUtils.Data.compressNumber(activity:GetMinLevel()),
        MSUtils.Data.compressNumber(activity:GetMaxLevel()),
        MSUtils.Data.compressNumber(activity:GetPvPRating()), GetAddonSource(),
        GetPlayerFullName(), GetPlayerSavedInstance(customId), nil,
        MSUtils.Data.compressNumber(
          activity:IsUseHonorLevel() and UnitHonorLevel('player') or nil)))
    return data
  end,

  -- 编码描述数据
  codeDescriptionData = function(activity)
    local AceSerializer = LibStub('AceSerializer-3.0')
    if not activity:IsMeetingStone() then
      return nil, 0
    else
      local activityId = activity:GetActivityID()
      local data = format('(%s)',
        AceSerializer:Serialize(GetPlayerRaidProgression(activityId, activity:GetCustomID()),
          GetPlayerPvPRating(activityId), GetAddonSource()))
      return data, strlenutf8(data)
    end
  end,

  -- 解码描述数据
  decodeDescriptionData = function(description)
    local AceSerializer = LibStub('AceSerializer-3.0')
    if not description or description == '' then
      return
    end
    local summary, data = description:match('^(.*)%((.+)%)$')
    if data then
      return summary, AceSerializer:Deserialize(data)
    else
      return description
    end
  end,

  -- 解包ID数据
  unpackIds = function(data)
    local Base64 = LibStub('NetEaseBase64-1.0')
    local min_id, data = data:match('^(%d+):(.+)$')
    min_id = tonumber(min_id)

    data = Base64:DeCode(data)

    local list = {}
    local offset = 0
    local byte, b
    for i = 1, #data do
      byte = data:byte(i)
      for j = 7, 0, -1 do
        b = bit.band(byte, bit.lshift(1, j)) > 0 and 1 or 0
        if b == 1 then
          table.insert(list, min_id + offset)
        end
        offset = offset + 1
      end
    end
    return list
  end,

  -- 列表转映射表
  listToMap = function(list)
    local map = {}
    for i, v in pairs(list) do
      map[v] = true
    end
    return map
  end,

  -- 表大小计算
  tableSize = function(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
  end,

  -- 表转JSON格式
  tableToJson = function(tbl)
    local function isArray(t)
      local maxIndex = 0
      for k, _ in pairs(t) do
        if type(k) ~= "number" then return false end
        if k > maxIndex then maxIndex = k end
      end
      for i = 1, maxIndex do
        if t[i] == nil then return false end
      end
      return true
    end

    local function serialize(tbl, level)
      local result = {}
      local indent = string.rep("  ", level)

      if isArray(tbl) then
        table.insert(result, "[\n")
        for i, v in ipairs(tbl) do
          local value
          if type(v) == "table" then
            value = serialize(v, level + 1)
          elseif type(v) == "string" then
            value = string.format("%q", v)
          else
            value = tostring(v)
          end
          local comma = (i == #tbl) and "\n" or ",\n"
          table.insert(result, string.format("%s  %s%s", indent, value, comma))
        end
        table.insert(result, indent .. "]")
      else
        table.insert(result, "{\n")
        local count = 0
        for k, v in pairs(tbl) do
          count = count + 1
          local key = (type(k) == "string" and string.format("%q", k)) or tostring(k)
          local value
          if type(v) == "table" then
            value = serialize(v, level + 1)
          elseif type(v) == "string" then
            value = string.format("%q", v)
          else
            value = tostring(v)
          end
          local comma = (count == MSUtils.Data.tableSize(tbl)) and "\n" or ",\n"
          table.insert(result, string.format("%s  %s: %s%s", indent, key, value, comma))
        end
        table.insert(result, indent .. "}")
      end

      return table.concat(result)
    end

    return serialize(tbl, 0)
  end
}

-- ============================================================================
-- 文本格式化工具
-- ============================================================================
MSUtils.Text = {
  -- 格式化版本号
  getFullVersion = function(version)
    return version:gsub('(%d)(%d)(%d%d)', '%10%200.%3')
  end,

  -- 摘要转HTML
  summaryToHtml = function(text)
    return text:gsub('^', '<html><body><p>　　'):gsub('$', '</p></body></html>'):gsub('[\r\n]+', '</p><p>　　')
  end,

  -- 格式化摘要
  formatSummary = function(text, tbl)
    return text:gsub('{{([%w_]+)}}', function(key)
      if type(tbl[key]) == 'function' then
        return tbl[key](tbl) or ''
      end
      return tbl[key] or ''
    end)
  end,

  -- 格式化活动摘要URL
  formatActivitiesSummaryUrl = function(summary, url)
    return (summary:gsub('{URL([^}]*)}', function(info)
      local path, text = info:match('^(.*):(.+)$')
      if not path then
        path = info
        text = url .. path
      end
      return format('|Hurl:%s%s|h|cff00ffff[%s]|r|h', url, path, text)
    end):gsub('{QR([^:}]+):([^}]+)}', function(title, info)
      return format('|Hqrcode:%s|h|cffff64ec[%s]|r|h', info, title)
    end))
  end
}

-- ============================================================================
-- 聊天相关工具
-- ============================================================================
MSUtils.Chat = {
  -- 聊天目标转换函数
  chatTargetAppToSystem = function(chatTarget)
    return chatTarget and chatTarget:gsub(APP_WHISPER_DOT, '-')
  end,

  chatTargetSystemToApp = function(chatTarget)
    return chatTarget and chatTarget:gsub('-', APP_WHISPER_DOT)
  end,

  isChatTargetApp = function(chatTarget)
    return chatTarget and chatTarget:find(APP_WHISPER_DOT, nil, true)
  end
}

-- ============================================================================
-- 进度和副本相关工具
-- ============================================================================
MSUtils.Raid = {
  -- 获取团本进度数据
  getRaidProgressionData = function(activityId, customId)
    return CUSTOM_PROGRESSION_LIST[customId] or RAID_PROGRESSION_LIST[activityId]
  end,

  -- 获取玩家团本进度
  getPlayerRaidProgression = function(activityId, customId)
    local list = MSUtils.Raid.getRaidProgressionData(activityId, customId)
    if not list then
      return
    end

    local result = 0
    for i, v in ipairs(list) do
      if tonumber((GetStatistic(v.id))) or (v.id2 and tonumber((GetStatistic(v.id2)))) then
        result = bit.bor(result, bit.lshift(1, i - 1))
      end
    end
    return result
  end,

  -- 获取玩家已保存副本
  getPlayerSavedInstance = function(customId)
    local data = ACTIVITY_CUSTOM_INSTANCE[customId]
    if not data then
      return
    end

    for i = 1, GetNumSavedInstances() do
      local name, id, _, difficulty, locked, extended, _, _, _, difficultyName, numEncounters = GetSavedInstanceInfo(i)
      if name == data.instance and (not data.difficulty or data.difficulty == difficultyName) then
        local result = 0
        for bossIndex = 1, numEncounters do
          if select(3, GetSavedInstanceEncounterInfo(i, bossIndex)) then
            result = bit.bor(result, bit.lshift(1, bossIndex - 1))
          end
        end
        return result ~= 0 and result or nil
      end
    end
  end,

  -- 获取进度纹理
  getProgressionTex = function(value, bossIndex)
    local killed = bit.band(value, bit.lshift(1, bossIndex - 1)) > 0
    return killed and [[|TINTERFACE\FriendsFrame\StatusIcon-Online:16|t]] or
      [[|TINTERFACE\FriendsFrame\StatusIcon-Offline:16|t]]
  end
}

-- ============================================================================
-- 过滤和验证工具
-- ============================================================================
MSUtils.Filter = {
  -- 检查垃圾词汇
  checkSpamWord = function(word)
    if not word then
      return
    end
    for i, v in ipairs(Profile:GetSpamWords()) do
      if strfind(word, v.text, 1, v.pain) then
        return true
      end
    end
    return false
  end,

  -- 检查内容过滤
  checkContent = function(content)
    if content == nil then
      return
    end
    local filterPinyin, filterNormal = Addon:GetFilterData()
    if filterPinyin then
      local nepy = require('NetEasePinyin-1.0')
      local pinyin = nepy.utf8topinyin(nepy.unchinesefilter(nepy.toutf8(content:lower():gsub('[\001-\127]+', ''))))

      for i, v in ipairs(filterPinyin) do
        if pinyin:match(v) then
          return true
        end
      end
    end
    if filterNormal then
      for i, v in ipairs(filterNormal) do
        if content:match(v) then
          return true
        end
      end
    end
    return false
  end,

  -- 检查是否为单人自定义ID
  isSoloCustomID = function(customId)
    return customId == SOLO_HIDDEN_CUSTOM_ID or customId == SOLO_VISIBLE_CUSTOM_ID
  end
}

-- ============================================================================
-- 玩家物品检查工具
-- ============================================================================
MSUtils.Inventory = {
  -- 检查玩家是否拥有宠物
  playerHasPet = function(name)
    return select(2, C_PetJournal.FindPetIDByName(name)) ~= nil
  end,

  -- 检查玩家是否拥有物品
  playerHasItem = function(id)
    for i = -3, 11 do
      for j = 1, GetContainerNumSlots(i) do
        if GetContainerItemID(i, j) == id then
          return true
        end
      end
    end
    return false
  end,

  -- 检查玩家是否拥有坐骑
  playerHasMount = function(id)
    return Addon:FindMount(id)
  end
}

-- ============================================================================
-- UI和界面工具
-- ============================================================================
MSUtils.UI = {
  -- 切换创建面板
  toggleCreatePanel = function(...)
    MainPanel:SelectPanel(ManagerPanel)
    if not CreatePanel:IsActivityCreated() then
      CreatePanel:SelectActivity(...)
    end
  end,

  -- URL按钮处理
  applyUrlButton = function(button, url)
    local function urlButtonOnClick(self)
      GUI:CallUrlDialog(self.url)
    end

    if url then
      button:SetScript('OnClick', urlButtonOnClick)
      button.url = url
    else
      button:SetScript('OnClick', nil)
      button.url = nil
    end
  end,

  -- 获取角色小圆圈纹理坐标
  getTexCoordsForRoleSmallCircle = function(role)
    if role == 'TANK' then
      return 0, 19 / 64, 22 / 64, 41 / 64
    elseif role == 'HEALER' then
      return 20 / 64, 39 / 64, 1 / 64, 20 / 64
    elseif role == 'DAMAGER' then
      return 20 / 64, 39 / 64, 22 / 64, 41 / 64
    end
  end
}

-- ============================================================================
-- 插件和系统工具
-- ============================================================================
MSUtils.System = {
  -- 获取插件来源
  getAddonSource = function()
    for line in gmatch(
      '\066\105\103\070\111\111\116\058\049\010\033\033\033\049\054\051\085\073\033\033\033\058\050\010\068\117\111\119\097\110\058\052\010\069\108\118\085\073\058\056',
      '[^\r\n]+') do
      local n, v = line:match('^(.+):(%d+)$')
      if C_AddOns.IsAddOnLoaded(n) then
        return tonumber(v)
      end
    end
    return 0
  end,

  -- 获取团队数据
  getRegimentData = function(leader)
    return Profile.gdb.global.LocomotiveData[leader]
  end,

  -- 数据构造器
  dataMake = function(allowCrossRealm)
    local function decode(v)
      return v:gsub('..', function(x)
        return string.char(tonumber(x, 16))
      end)
    end

    local currentRealm
    local currentLevel
    local currentRoomID
    local currentBgID

    local function Realm(realm)
      realm = decode(realm)
      if allowCrossRealm or realm == GetRealmName() then
        currentRealm = realm
        return
      end
      currentRealm = nil
    end

    local function Name(name)
      if not currentRealm then
        return nop
      end
    end

    local function Level(level)
      currentLevel = level
    end

    local function RoomID(roomid)
      currentRoomID = roomid
    end

    local function BgID(bgid)
      currentBgID = bgid
    end

    setfenv(2, { R = Realm, N = Name, L = Level, I = RoomID, B = BgID })
  end
}

-- ============================================================================
-- 按键绑定工具
-- ============================================================================
MSUtils.Keybinding = {
  -- 按键组合配置
  keyCombinations = {
    "CTRL-.", "CTRL-[", "CTRL-;",
    "CTRL-,", "CTRL-]", "CTRL-'",
    "ALT-,", "ALT-]", "ALT-'",
    "ALT-.", "ALT-[", "ALT-;",
    "SHIFT-.", "SHIFT-[", "SHIFT-;",
    "SHIFT-,", "SHIFT-]", "SHIFT-'",
  },

  -- 检查单键是否绑定
  isSingleKeyBound = function(key)
    return GetBindingAction(key) ~= ""
  end,

  -- 检查组合键和单键是否未绑定
  isKeyCombinationAndSingleKeyUnbound = function(keyCombination)
    if MSUtils.Keybinding.isSingleKeyBound(keyCombination) then
      return false
    end

    local singleKey = keyCombination:match("[^%-]+$")
    if singleKey then
      if MSUtils.Keybinding.isSingleKeyBound(singleKey) then
        return false
      end
    end

    return true
  end,

  -- 查找前两个未绑定的按键
  findFirstTwoUnboundKeys = function()
    local unboundKeys = {}
    for _, key in ipairs(MSUtils.Keybinding.keyCombinations) do
      if MSUtils.Keybinding.isKeyCombinationAndSingleKeyUnbound(key) then
        table.insert(unboundKeys, key)
        if #unboundKeys == 2 then
          break
        end
      end
    end
    return unboundKeys
  end
}
