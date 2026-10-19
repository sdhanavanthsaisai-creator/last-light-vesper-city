--!strict
--[[
	PurchaseService.luau
	Server-side validation for optional cosmetic GamePasses and Developer Products
	following Section 10 of the Master Development Plan (no pay-to-win, no lootboxes).
	Location: ServerScriptService/Services/PurchaseService
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local PurchaseService = {}

function PurchaseService.GrantCosmeticPass(player: Player, passKey: string)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return
	end
	profile.ownedCosmetics[passKey] = true
	PlayerDataService.SyncToClient(player)
end

function PurchaseService.CheckOwnedGamePasses(player: Player)
	for passKey, passInfo in pairs(Config.GAME_PASSES) do
		if passInfo.passId > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passInfo.passId)
			end)
			if ok and owns then
				PurchaseService.GrantCosmeticPass(player, passKey)
			end
		end
	end
end

function PurchaseService.Init()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, gamePassId: number, wasPurchased: boolean)
		if not wasPurchased then
			return
		end
		for passKey, passInfo in pairs(Config.GAME_PASSES) do
			if passInfo.passId == gamePassId then
				PurchaseService.GrantCosmeticPass(player, passKey)
				PlayerDataService.SaveProfile(player)
			end
		end
	end)

	-- Safe ProcessReceipt handler preventing duplicate grants
	MarketplaceService.ProcessReceipt = function(receiptInfo): Enum.ProductPurchaseDecision
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local profile = PlayerDataService.GetProfile(player)
		if not profile then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local purchaseId = tostring(receiptInfo.PurchaseId)
		if profile.processedReceipts[purchaseId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		profile.processedReceipts[purchaseId] = true
		local savedOk = PlayerDataService.SaveProfile(player)
		if savedOk then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return PurchaseService
