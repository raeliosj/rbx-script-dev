local m ={}

local Window
local Core
local DataService
local QuestsController
local SeasonPassData
local SeasonPassStaticData
local SeasonPassUtils

function m:Init(_window, _core)
    Window = _window
    Core = _core

    DataService = require(Core.ReplicatedStorage.Modules.DataService)
    QuestsController = require(Core.ReplicatedStorage.Modules.QuestsController)
    SeasonPassData = require(Core.ReplicatedStorage.Data.SeasonPass.SeasonPassData)
    SeasonPassStaticData = require(Core.ReplicatedStorage.Data.SeasonPass.SeasonPassStaticData)
    SeasonPassUtils = require(Core.ReplicatedStorage.Modules.SeasonPass.SeasonPassUtils)

    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoClaimSeasonPassQuest")
    end, function()
        self:StartAutoClaimCompletedQuests()
    end)

    Core:MakeLoop(function()
        return Window:GetConfigValue("AutoClaimSeasonPassInfinityRewards")
    end, function()
        self:StartAutoClaimRewards()
    end)
end

function m:GetCompletedQuests()
    local questData = DataService:GetData()
    local questDetails = QuestsController:GetContainerFromId(questData.DailyQuests.ContainerId)
    if not questData then
        warn("No quest data found")
        return {}
    end

    if not questDetails then
        warn("No quest details found for container ID:", questData.DailyQuests.ContainerId)
        return {}
    end

    local completedQuests = {}
    for _, quest in pairs(questDetails.Quests) do
        local isClaimed = table.find(questData.SeasonPass[SeasonPassData.CurrentSeason].QuestsClaimed, quest.Id) and true or false

        if quest.Completed == true and not isClaimed then
            table.insert(completedQuests, quest.Id)
        end
    end

    return completedQuests
end

function m:StartAutoClaimCompletedQuests()
    if not Window:GetConfigValue("AutoClaimSeasonPassQuest") then
        return
    end

    for i, questId in ipairs(self:GetCompletedQuests()) do
        game:GetService("ReplicatedStorage").GameEvents.SeasonPass.ClaimSeasonPassQuest:FireServer(questId)
        task.wait(0.15) -- Wait for 0.15 seconds between claims to avoid spamming
    end
end

function m:StartAutoClaimRewards()
    if not Window:GetConfigValue("AutoClaimSeasonPassInfinityRewards") then
        return
    end

    local rewardData = DataService:GetData()
    local currentSeasonPassData = rewardData.SeasonPass[SeasonPassData.CurrentSeason]
    local totalXP = currentSeasonPassData.TotalExperience
    local infRewardsClaimed = currentSeasonPassData.InfRewardsClaimed
    -- local maxXP = SeasonPassStaticData.INF_REWARD_XP

    local currentXP = totalXP - SeasonPassUtils.CalculateXPForLevel(SeasonPassStaticData.MAX_LEVEL)
    local claimRewardCount = SeasonPassUtils.CalculateInfClaimCount(totalXP, infRewardsClaimed)

    if claimRewardCount <= 0 then
        return
    end

    game:GetService("ReplicatedStorage").GameEvents.SeasonPass.ClaimSeasonPassInfReward:FireServer(51, false)
end

return m