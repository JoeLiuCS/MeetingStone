BuildEnv(...)

-- 依赖库导入
local memorize = require('NetEaseMemorize-1.0')
local nepy = require('NetEasePinyin-1.0')
local Base64 = LibStub('NetEaseBase64-1.0')
local AceSerializer = LibStub('AceSerializer-3.0')

_G.Base64 = Base64

-- 角色图标纹理
local RoleIconTextures = {
  [1] = "Interface/AddOns/MeetingStone/Media/SunUI/TANK.tga",
  [2] = "Interface/AddOns/MeetingStone/Media/SunUI/Healer.tga",
  [3] = "Interface/AddOns/MeetingStone/Media/SunUI/DPS.tga",
}

-- 专精相关映射表
local classNameToSpecIcon = {}
local classNameToSpecId = {}
-- 初始化专精信息
for classID = 1, 13 do
  local classFile = select(2, GetClassInfo(classID)) -- "WARRIOR"
  if classFile then
    for specIndex = 1, 4 do
      local specId, localizedSpecName, _, icon = GetSpecializationInfoForClassID(classID, specIndex)
      if specId and localizedSpecName and icon then
        classNameToSpecIcon[classFile .. localizedSpecName] = icon
        classNameToSpecId[classFile .. localizedSpecName] = specId
      end
    end
  end
end

-- 玩家和团队相关函数

-- 获取职业颜色文本
function GetClassColorText(className, text)
  return MSUtils.Player.getClassColorText(className, text)
end

-- 获取带颜色的职业文本
function GetClassColoredText(class, text)
  return MSUtils.Player.getClassColoredText(class, text)
end

-- 获取完整名称 (角色名-服务器名)
function GetFullName(name, realm)
  return MSUtils.Player.getFullName(name, realm)
end

-- 获取单位的完整名称
function UnitFullName(unit)
  return MSUtils.Player.unitFullName(unit)
end

-- 分割玩家姓名
function SplitPlayerName(input)
  return MSUtils.Player.splitPlayerName(input)
end

-- 检查是否为团队队长
function IsGroupLeader()
  return MSUtils.Group.isGroupLeader()
end

-- 检查是否为活动管理员
function IsActivityManager()
  return MSUtils.Group.isActivityManager()
end

-- 获取玩家职业ID
function GetPlayerClass()
  return MSUtils.Player.getPlayerClass()
end

-- 获取玩家装等
function GetPlayerItemLevel(isPvP)
  return MSUtils.Player.getPlayerItemLevel(isPvP)
end

-- 获取玩家完整姓名
function GetPlayerFullName()
  return MSUtils.Player.getPlayerFullName()
end

-- 获取玩家战网标签
function GetPlayerBattleTag()
  return MSUtils.Player.getPlayerBattleTag()
end

-- 获取公会名称
function GetGuildName()
  return MSUtils.Group.getGuildName()
end

-- 获取公会会长服务器
function GetGuildMasterRealm()
  return MSUtils.Group.getGuildMasterRealm()
end

-- 获取公会会长名字
function GetGuildMasterName()
  return MSUtils.Group.getGuildMasterName()
end

-- 获取大秘分数
function GetMythicPlusScore()
  return MSUtils.Player.getMythicPlusScore()
end

-- UI 相关函数
function ToggleCreatePanel(...)
  MainPanel:SelectPanel(ManagerPanel)
  if not CreatePanel:IsActivityCreated() then
    CreatePanel:SelectActivity(...)
  end
end

-- 数据编解码相关函数

-- 数字压缩处理
function CompressNumber(n)
  return MSUtils.Data.compressNumber(n)
end

-- 解码评论数据
function DecodeCommetData(comment)
  return MSUtils.Data.decodeCommetData(comment)
end

-- 编码评论数据
function CodeCommentData(activity)
  return MSUtils.Data.codeCommentData(activity)
end

-- 编码描述数据
function CodeDescriptionData(activity)
  return MSUtils.Data.codeDescriptionData(activity)
end

-- 解码描述数据
function DecodeDescriptionData(description)
  return MSUtils.Data.decodeDescriptionData(description)
end

-- 解包ID数据
function UnpackIds(data)
  return MSUtils.Data.unpackIds(data)
end

-- ============================================================================
-- 活动相关函数 - 桥接到 MSUtils
-- ============================================================================

-- 获取活动代码
function GetActivityCode(activityId, customId, categoryId, groupId)
  return MSUtils.Activity.getActivityCode(activityId, customId, categoryId, groupId)
end

-- 活动类型检查函数
function IsUseHonorLevel(activityId)
  return MSUtils.Activity.isUseHonorLevel(activityId)
end

function IsMythicPlusActivity(activityId)
  return MSUtils.Activity.isMythicPlusActivity(activityId)
end

function IsRatedPvpActivity(activityId)
  return MSUtils.Activity.isRatedPvpActivity(activityId)
end

-- 活动名称获取函数
function GetActivityName(activityId, customId)
  return MSUtils.Activity.getActivityName(activityId, customId)
end

function GetActivityShortName(activityId, customId)
  return MSUtils.Activity.getActivityShortName(activityId, customId)
end

function GetModeName(mode)
  return MSUtils.Activity.getModeName(mode)
end

function GetLootName(loot)
  return MSUtils.Activity.getLootName(loot)
end

function GetLootShortName(loot)
  return MSUtils.Activity.getLootShortName(loot)
end

-- 生成活动标题
function CodeActivityTitle(activityId, customId, mode, loot)
  return MSUtils.Activity.codeActivityTitle(activityId, customId, mode, loot)
end

-- 获取活动分类名称
function GetActivityCategoryName(activity)
  return MSUtils.Activity.getActivityCategoryName(activity)
end

-- 获取安全摘要长度
function GetSafeSummaryLength(activityId, customId, mode, loot)
  local data = format('(%s)', AceSerializer:Serialize(customId, ADDON_VERSION_SHORT, mode, loot, GetPlayerClass(),
    GetPlayerItemLevel(IsUseHonorLevel(activityId)),
    GetPlayerRaidProgression(activityId, customId),
    GetPlayerPvPRating(activityId), 999, 999,
    IsUsePvPRating(activityId) and 9999 or nil, GetAddonSource(),
    GetPlayerFullName(), GetPlayerSavedInstance(customId), format(
      '%s-%s-%s', GetModeName(mode), GetLootName(loot),
      GetActivityName(activityId, customId)), CompressNumber(
      IsUseHonorLevel(activityId) and UnitHonorLevel('player') or
        nil)))
  return min(MAX_MEETINGSTONE_SUMMARY_LETTERS, MAX_SUMMARY_LETTERS - strlenutf8(data))
end

-- ============================================================================
-- PVP 相关函数 - 桥接到 MSUtils
-- ============================================================================

-- 检查是否使用PVP评分
function IsUsePvPRating(activityId)
  return MSUtils.PvP.isUsePvPRating(activityId)
end

-- 获取玩家PVP评分
function GetPlayerPvPRating(activityId)
  return MSUtils.PvP.getPlayerPvPRating(activityId)
end

-- ============================================================================
-- 团本进度相关函数 - 桥接到 MSUtils
-- ============================================================================

-- 获取团本进度数据
function GetRaidProgressionData(activityId, customId)
  return MSUtils.Raid.getRaidProgressionData(activityId, customId)
end

-- 获取玩家团本进度
function GetPlayerRaidProgression(activityId, customId)
  return MSUtils.Raid.getPlayerRaidProgression(activityId, customId)
end

-- 获取玩家已保存副本
function GetPlayerSavedInstance(customId)
  return MSUtils.Raid.getPlayerSavedInstance(customId)
end

-- 获取进度纹理
function GetProgressionTex(value, bossIndex)
  return MSUtils.Raid.getProgressionTex(value, bossIndex)
end

-- ============================================================================
-- 文本格式化相关函数 - 桥接到 MSUtils
-- ============================================================================

-- 格式化版本号
function GetFullVersion(version)
  return MSUtils.Text.getFullVersion(version)
end

-- 格式化活动摘要URL
function FormatActivitiesSummaryUrl(summary, url)
  return MSUtils.Text.formatActivitiesSummaryUrl(summary, url)
end

-- 摘要转HTML
function SummaryToHtml(text)
  return MSUtils.Text.summaryToHtml(text)
end

-- 格式化摘要
function FormatSummary(text, tbl)
  return MSUtils.Text.formatSummary(text, tbl)
end

-- ============================================================================
-- 团队和单位相关函数 - 桥接到 MSUtils
-- ============================================================================

-- 遍历团队单位
function IterateGroupUnits()
  return MSUtils.Group.iterateGroupUnits()
end

-- ============================================================================
-- 过滤和检查函数
-- ============================================================================

-- 检查垃圾词汇
CheckSpamWord, ClearSpamWordCache = memorize.normal(function(word)
  if not word then
    return
  end
  for i, v in ipairs(Profile:GetSpamWords()) do
    if strfind(word, v.text, 1, v.pain) then
      return true
    end
  end
  return false
end)

-- 检查内容过滤
CheckContent, ClearCheckContentCache = memorize.normal(function(content)
  if content == nil then
    return
  end
  local filterPinyin, filterNormal = Addon:GetFilterData()
  if filterPinyin then
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
end)

-- 检查职位过滤器
function CheckJobsFilter(data, tcount, hcount, dcount, ignore_same_job, activity)
  if ignore_same_job and Profile.gdb.global.UIMemory.FILTER_JOB then
    local _, myclass, _2 = UnitClass("player")
    for i = 1, activity:GetNumMembers() do
      local role, class = LfgService:GetSearchResultMemberInfo(activity:GetID(), i)
      if role == 'DAMAGER' and class == myclass then
        return false
      end
    end
  end
  if Profile.gdb.global.UIMemory.FILTER_MULTY then
    local show = false
    if not Profile.gdb.global.UIMemory.FILTER_TANK and not Profile.gdb.global.UIMemory.FILTER_HEALTH and not Profile.gdb.global.UIMemory.FILTER_DAMAGE then
      show = true
    end
    if Profile.gdb.global.UIMemory.FILTER_TANK and data.TANK < tcount then
      show = true
    end
    if Profile.gdb.global.UIMemory.FILTER_HEALTH and data.HEALER < hcount then
      show = true
    end
    if Profile.gdb.global.UIMemory.FILTER_DAMAGE and data.DAMAGER < dcount then
      show = true
    end
    return show
  else
    if Profile.gdb.global.UIMemory.FILTER_TANK and data.TANK >= tcount then
      return false
    end
    if Profile.gdb.global.UIMemory.FILTER_HEALTH and data.HEALER >= hcount then
      return false
    end
    if Profile.gdb.global.UIMemory.FILTER_DAMAGE and data.DAMAGER >= dcount then
      return false
    end
    return true
  end
end

-- 检查PVP职位过滤器
function CheckPVPJobsFilter(data, hcount, dcount)
  if Profile.gdb.global.UIMemory.FILTER_HEALTH and data.HEALER >= hcount then
    return false
  end
  if (Profile.gdb.global.UIMemory.FILTER_TANK or Profile.gdb.global.UIMemory.FILTER_DAMAGE) and data.TANK + data.DAMAGER >= dcount then
    return false
  end
  return true
end

-- ============================================================================
-- 玩家拥有检查函数 - 桥接到 MSUtils
-- ============================================================================

-- 检查玩家是否拥有宠物
function PlayerHasPet(name)
  return MSUtils.Inventory.playerHasPet(name)
end

-- 检查玩家是否拥有物品
function PlayerHasItem(id)
  return MSUtils.Inventory.playerHasItem(id)
end

-- 检查玩家是否拥有坐骑
function PlayerHasMount(id)
  return MSUtils.Inventory.playerHasMount(id)
end

-- ============================================================================
-- 聊天相关函数 - 桥接到 MSUtils
-- ============================================================================

-- 聊天目标转换函数
function ChatTargetAppToSystem(chatTarget)
  return MSUtils.Chat.chatTargetAppToSystem(chatTarget)
end

function ChatTargetSystemToApp(chatTarget)
  return MSUtils.Chat.chatTargetSystemToApp(chatTarget)
end

function IsChatTargetApp(chatTarget)
  return MSUtils.Chat.isChatTargetApp(chatTarget)
end

-- ============================================================================
-- 工具函数 - 桥接到 MSUtils
-- ============================================================================

-- 检查是否为单人自定义ID
function IsSoloCustomID(customId)
  return MSUtils.Filter.isSoloCustomID(customId)
end

-- 列表转映射表
function ListToMap(list)
  return MSUtils.Data.listToMap(list)
end

-- 获取插件来源
function GetAddonSource()
  return MSUtils.System.getAddonSource()
end

--[=[@bigfoot@
function GetAddonSource()
end
--@end-bigfoot@]=]

-- 自动补全项目元表
GetAutoCompleteItem = setmetatable({}, {
  __index = function(t, activityId)
    local activityInfo = C_LFGList.GetActivityInfoTable(activityId)
    local name = activityInfo.fullName
    local category = activityInfo.categoryID
    local group = activityInfo.groupFinderActivityGroupID

    t[activityId] = {
      name = name,
      order = 0xffff - (ACTIVITY_ORDER.A[activityId] or ACTIVITY_ORDER.G[group] or 0),
      activityId = activityId,
      code = GetActivityCode(activityId, nil, category, group),
    }
    return t[activityId]
  end,
  __call = function(t, activityId)
    return t[activityId]
  end,
})

-- URL按钮处理
local function UrlButtonOnClick(self)
  GUI:CallUrlDialog(self.url)
end

function ApplyUrlButton(button, url)
  if url then
    button:SetScript('OnClick', UrlButtonOnClick)
    button.url = url
  else
    button:SetScript('OnClick', nil)
    button.url = nil
  end
end


-- ============================================================================
-- NDui MOD - 职业图标显示系统
-- ============================================================================
local UnitClass = UnitClass
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local hooksecurefunc = hooksecurefunc

-- 角色缓存和配置
local roleCache = {}
local roleOrder = {
  ["TANK"] = 1,
  ["HEALER"] = 2,
  ["DAMAGER"] = 3,
}
local roleAtlas = {
  [1] = "groupfinder-icon-role-large-tank",
  [2] = "groupfinder-icon-role-large-heal",
  [3] = "groupfinder-icon-role-large-dps",
}

-- 角色排序函数
local function sortRoleOrder(a, b)
  if a and b then
    return a[1] < b[1]
  end
end

-- 获取队伍成员信息
local function GetPartyMemberInfo(index)
  local unit = "player"
  if index > 1 then
    unit = "party" .. (index - 1)
  end

  local class = select(2, UnitClass(unit))
  if not class then
    return
  end
  local role = UnitGroupRolesAssigned(unit)
  if role == "NONE" then
    role = "DAMAGER"
  end
  return role, class
end

-- 获取正确的角色信息
local function GetCorrectRoleInfo(frame, i)
  if frame.resultID then
    return LfgService:GetSearchResultMemberInfo(frame.resultID, i)
  elseif frame == ApplicationViewerFrame then
    return GetPartyMemberInfo(i)
  end
end

-- 更新团队角色信息
local function UpdateGroupRoles(self)
  wipe(roleCache)
  if not self.__owner then
    self.__owner = self:GetParent():GetParent()
  end

  local count = 0
  for i = 1, 5 do
    local role, class, classCN, spec = GetCorrectRoleInfo(self.__owner, i)
    local roleIndex = role and roleOrder[role]
    if roleIndex then
      count = count + 1
      if not roleCache[count] then
        roleCache[count] = {}
      end
      roleCache[count][1] = roleIndex
      roleCache[count][2] = class
      roleCache[count][3] = i == 1
      roleCache[count][4] = spec
    end
  end

  sort(roleCache, sortRoleOrder)
end

-- 检查是否显示图标
local function CheckShowIcons(frame)
  local isLFGList
  while true do
    if frame == LFGListFrame then
      isLFGList = true
      break
    elseif frame == nil then
      isLFGList = false
      break
    end
    frame = frame:GetParent()
  end

  if not isLFGList then
    if not Profile:GetShowClassIco() then
      return "orig"
    elseif C_AddOns.IsAddOnLoaded("ElvUI_WindTools") and Profile:GetShowWindClassIco() then
      if not C_AddOns.IsAddOnLoaded("PremadeGroupsFilter") and WindTools[3].private.WT.misc.lfgList.enable then
        return "wind"
      else
        return "orig"
      end
    else
      return "meet"
    end
  else
    if C_AddOns.IsAddOnLoaded("PremadeGroupsFilter") then
      return "orig"
    elseif C_AddOns.IsAddOnLoaded("ElvUI_WindTools") and WindTools[3].private.WT.misc.lfgList.enable then
      return "wind"
    elseif Profile:GetShowClassIco() and not Profile:GetClassIcoMsOnly() then
      return "meet"
    else
      return "orig"
    end
  end
end

-- 替换团队角色显示
local function ReplaceGroupRoles(self, numPlayers, _, disabled)
  local flagCheckShowIcons = CheckShowIcons(self)
  if flagCheckShowIcons == "orig" then
    return
  elseif flagCheckShowIcons == "wind" then
    return WindTools[1]:GetModule("LFGList"):UpdateEnumerate(self)
  end

  local flagCheckShowSpecIcon = Profile:GetShowSpecIco()
  local flagCheckShowSmRoleIcon = Profile:GetShowSmRoleIco()

  UpdateGroupRoles(self)
  for i = 1, 5 do
    local icon = self.Icons[i]
    if not icon.role then
      icon.role = self:CreateTexture(nil, "OVERLAY")
      icon.role:SetSize(24, 24)
      if i == 1 then
        icon.role:SetPoint("RIGHT", -5, -2)
      else
        icon.role:ClearAllPoints()
        icon.role:SetPoint("RIGHT", self.Icons[i - 1].role, "LEFT", 0, 0)
      end

      icon.leader = self:CreateTexture(nil, "OVERLAY")
      icon.leader:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
      icon.leader:SetRotation(rad(-15))
    end

    if i > numPlayers then
      icon.role:Hide()
    else
      icon.role:Show()
      icon.role:SetDesaturated(disabled)
      icon.role:SetAlpha(disabled and .5 or 1)
      icon.leader:SetDesaturated(disabled)
      icon.leader:SetAlpha(disabled and .5 or 1)
    end
    icon.leader:Hide()
  end

  local iconIndex = numPlayers
  for i = 1, #roleCache do
    local roleInfo = roleCache[i]
    if roleInfo then
      local icon = self.Icons[iconIndex]

      if flagCheckShowSmRoleIcon then
        icon:SetSize(15, 15)
        icon:SetPoint("TOPLEFT", icon.role, -4, 6)
        icon.leader:SetSize(13, 13)
        icon.leader:SetPoint("TOP", icon.role, 4, 8)
      else
        icon:SetSize(18, 18)
        icon:SetPoint("TOPLEFT", icon.role, -4, 5)
        icon.leader:SetSize(16, 16)
        icon.leader:SetPoint("TOP", icon.role, 4, 8)
      end

      if roleInfo[4] and flagCheckShowSpecIcon then
        local spec_id = classNameToSpecId[roleInfo[2] .. roleInfo[4]]
        if spec_id == nil then
          icon.role:SetTexture(classNameToSpecIcon[roleInfo[2] .. roleInfo[4]])
        else
          icon.role:SetTexture("Interface/AddOns/MeetingStone/Media/SpellIcon/circular_" .. spec_id)
        end
      else
        icon.role:SetTexture("Interface/AddOns/MeetingStone/Media/ClassIcon/" .. string.lower(roleInfo[2]) .. "_flatborder2")
      end

      if roleInfo[1] and RoleIconTextures[roleInfo[1]] then
        icon.RoleIconWithBackground:SetAtlas(roleAtlas[roleInfo[1]])
      end

      icon.leader:SetShown(roleInfo[3])
      iconIndex = iconIndex - 1
    end
  end

  for i = 1, iconIndex do
    self.Icons[i].role:SetAtlas(nil)
  end
end

-- ElvUI 兼容函数
local function ElvUI_Wind_ReplaceGroupRoles(enmuerate, numPlayers, _, disabled)
  ReplaceGroupRoles(enmuerate, numPlayers, _, disabled)
end

local function ElvUI_Icon_Align(enmuerate, numPlayers, _, disabled)
  for i = 1, 5 do
    local icon = enmuerate.Icons[i]
    if i == 1 then
      icon:SetPoint("RIGHT", -36, -2)
    end
  end
end

-- 初始化集合石职业显示
function InitMeetingStoneClass()
  Profile:OnInitialize()
  local showico = Profile:GetShowClassIco()
  if showico == nil or showico == false then
    if C_AddOns.IsAddOnLoaded("ElvUI") then
      hooksecurefunc("LFGListGroupDataDisplayEnumerate_Update", ElvUI_Icon_Align)
      return
    else
      return
    end
  end

  if C_AddOns.IsAddOnLoaded("ElvUI_WindTools") then
    local showWindClassIco = Profile:GetShowWindClassIco()
    if not showWindClassIco then
      local origLFGListGroupDataDisplayEnumerate_Update = LFGListGroupDataDisplayEnumerate_Update
      LFGListGroupDataDisplayEnumerate_Update = function(enmuerate, numPlayers, _, disabled, LFG_LIST_GROUP_DATA_ROLE_ORDER)
        origLFGListGroupDataDisplayEnumerate_Update(enmuerate, numPlayers, _, disabled, LFG_LIST_GROUP_DATA_ROLE_ORDER)
        ElvUI_Wind_ReplaceGroupRoles(enmuerate, numPlayers, _, disabled)
      end
    else
      hooksecurefunc("LFGListGroupDataDisplayEnumerate_Update", ElvUI_Icon_Align)
    end
  else
    hooksecurefunc("LFGListGroupDataDisplayEnumerate_Update", ReplaceGroupRoles)
  end

  local MSEnv = _G.LibStub("NetEaseEnv-1.0")._NSList.MeetingStone
  local MemberDisplay = MSEnv.MemberDisplay
  local origSetActivity = MemberDisplay.SetActivity
  MemberDisplay.SetActivity = function(self, activity)
    self.resultID = activity and activity.GetID and activity:GetID()
    origSetActivity(self, activity)
  end
end

-- 获取角色小圆圈纹理坐标
function GetTexCoordsForRoleSmallCircle(role)
  if role == 'TANK' then
    return 0, 19 / 64, 22 / 64, 41 / 64
  elseif role == 'HEALER' then
    return 20 / 64, 39 / 64, 1 / 64, 20 / 64
  elseif role == 'DAMAGER' then
    return 20 / 64, 39 / 64, 22 / 64, 41 / 64
  end
end

-- ============================================================================
-- 扩展工具函数 - 桥接到 MSUtils
-- ============================================================================

-- 表大小计算
function table_size(tbl)
  return MSUtils.Data.tableSize(tbl)
end

-- 表转JSON格式
function TableToJson(tbl)
  return MSUtils.Data.tableToJson(tbl)
end

-- 获取团队数据
function GetRegimentData(Leader)
  return MSUtils.System.getRegimentData(Leader)
end

-- 数据构造器
function DataMake(allowCrossRealm)
  return MSUtils.System.dataMake(allowCrossRealm)
end

-- ============================================================================
-- 按键绑定相关函数 - 桥接到 MSUtils
-- ============================================================================

-- 检查单键是否绑定
function IsSingleKeyBound(key)
  return MSUtils.Keybinding.isSingleKeyBound(key)
end

-- 检查组合键和单键是否未绑定
function IsKeyCombinationAndSingleKeyUnbound(keyCombination)
  return MSUtils.Keybinding.isKeyCombinationAndSingleKeyUnbound(keyCombination)
end

-- 查找前两个未绑定的按键
function FindFirstTwoUnboundKeys()
  return MSUtils.Keybinding.findFirstTwoUnboundKeys()
end

