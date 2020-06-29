local DMW = DMW
local Mage = DMW.Rotations.MAGE
local Rotation = DMW.Helpers.Rotation
local Setting = DMW.Helpers.Rotation.Setting
local Player, MovingToSafeSpot, safeSpot, safeX, safeY, safeZ, Buff, Debuff, Spell, Target, Talent, Item, GCD, CDs, HUD, Enemy20Y, Enemy20YC, Enemy30Y, Enemy30YC, Enemy10Y, Enemy10YC, Hostile10, Hostile10C, Hostile6, Hostile6C
local WandTime = GetTime()
local ItemUsage = GetTime()

local function Locals()
    Player = DMW.Player
    Buff = Player.Buffs
    Debuff = Player.Debuffs
    Spell = Player.Spells
    Talent = Player.Talents
    Item = Player.Items
    Target = Player.Target or false
    HUD = DMW.Settings.profile.HUD
    CDs = Player:CDs() 
    Enemy20Y, Enemy20YC = Player:GetEnemies(20)
    Enemy30Y, Enemy30YC = Player:GetEnemies(30)
	Enemy13Y, Enemy13YC = Player:GetEnemies(13)
	Enemy10Y, Enemy10YC = Player:GetEnemies(10)
    Enemy35Y, Enemy35YC = Player:GetEnemies(35)
    Hostile10, Hostile10C = Player:GetHostiles(10)
    Hostile6, Hostile6C = Player:GetHostiles(6)
end

local function CheckWaterCount()
    local waterRank = Spell.ConjureWater:HighestRank()
    if waterRank == 1 then
        return GetItemCount(5350)
    elseif waterRank == 2 then
        return GetItemCount(2288)
    elseif waterRank == 3 then
        return GetItemCount(2136)
    elseif waterRank == 4 then
        return GetItemCount(3772)
    elseif waterRank == 5 then
        return GetItemCount(8077)
    elseif waterRank == 6 then
        return GetItemCount(8078)
    elseif waterRank == 7 then
        return GetItemCount(8079)
    end
end

local function CheckFoodCount()
    local FoodRank = Spell.ConjureFood:HighestRank()
    if FoodRank == 1 then
        return GetItemCount(5349)
    elseif FoodRank == 2 then
        return GetItemCount(1113)
    elseif FoodRank == 3 then
        return GetItemCount(1114)
    elseif FoodRank == 4 then
        return GetItemCount(1487)
    elseif FoodRank == 5 then
        return GetItemCount(8075)
    elseif FoodRank == 6 then
        return GetItemCount(8076)
    elseif FoodRank == 7 then
        return GetItemCount(22895)
    end
end

local function ConjureHandler()
    local waterCount = CheckWaterCount()
    local foodCount = CheckFoodCount()

    if Spell.ConjureWater:IsReady() and waterCount == 0 then
        if Spell.ConjureWater:Cast(Player) then return true end
    end
    if Spell.ConjureFood:IsReady() and foodCount == 0 then
        if Spell.ConjureFood:Cast(Player) then return true end
    end
    return false
end

local function CreateManaAgent()
    if Spell.ConjureManaRuby:Known() then
        if not Spell.ConjureManaRuby:LastCast() and not Item.ManaRuby:InBag() and Spell.ConjureManaRuby:Cast(Player) then
            return true
        end
    elseif Spell.ConjureManaCitrine:Known() then
        if not Spell.ConjureManaCitrine:LastCast() and not Item.ManaCitrine:InBag() and Spell.ConjureManaCitrine:Cast(Player) then
            return true
        end
    elseif Spell.ConjureManaJade:Known() then
        if not Spell.ConjureManaJade:LastCast() and not Item.ManaJade:InBag() and Spell.ConjureManaJade:Cast(Player) then
            return true
        end
    elseif Spell.ConjureManaAgate:Known() then
        if not Spell.ConjureManaAgate:LastCast() and not Item.ManaAgate:InBag() and Spell.ConjureManaAgate:Cast(Player) then
            return true
        end
    end
end

local function Wand()
    if not Player.Moving and not DMW.Helpers.Queue.Spell and not IsAutoRepeatSpell(Spell.Shoot.SpellName) and (DMW.Time - WandTime) > 0.7 and (Target.Distance > 1 or not Setting("Auto Attack In Melee")) and Spell.Shoot:Cast(Target) then
        WandTime = DMW.Time
        return true
    end
end

local function NoAoe()
    local Enemies = Player:GetAttackable(15)
    for i, Unit in ipairs(Enemies) do
        if Debuff.Polymorph:Exist(Unit) then
            return true
        end
    end

    for i, Unit in ipairs(Enemies) do
        if not Unit.Target and Unit.HP >= 20 then
            return true
        end
    end

    return false
end

local function EvocationInCombat()
    local Enemies = Player:GetEnemies(25)
    for i, Unit in ipairs(Enemies) do
        if i <= 1 and not Unit.Casting and (Debuff.Polymorph:Exist(Unit) and not Unit.Target) or (Unit.Distance > 6 and Debuff.FrostNova:Remain(Unit) > 8) or (Unit.Distance > 11 and Debuff.FrostNova:Remain(Unit) > 6) then
            return true
        end
    end
end


local function Defensive()
    if Setting("Kite") and MovingToSafeSpot and not DMW.Player.Rooted then
        MoveTo(safeX, safeY, safeZ)
        return
    end

    if Setting("Kite") and not MovingToSafeSpot and (Debuff.FrostNova:Remain(Target) > 3 or Debuff.Frostbite:Remain(Target) > 3) and Target.Distance < 6 then
        local rx, ry, rz = GetPositionFromPosition(DMW.Player.Target.PosX, DMW.Player.Target.PosY, DMW.Player.Target.PosZ, -15, ObjectFacing('player'), 180 / 1000)
        local isSafe = false
        local inWater = TraceLine(rx, ry, rz, rx, ry, rz - 100, 0x10000)

        if not inWater then
            rz = select(3, TraceLine(rx, ry, 9999, rx, ry, -9999, 0x110)) or 0
            local heightdiff = math.abs(rz - DMW.Player.PosZ)
                isSafe = true
                safeX = rx
                safeY = ry
                safeZ = rz
        end
       
        if isSafe and not DMW.Player.Rooted  then 
            MovingToSafeSpot = true
            C_Timer.After(2, function() MovingToSafeSpot = false end)
        end
    end
    
    if Setting("Ice Barrier") and Spell.IceBarrier:IsReady() and not Buff.IceBarrier:Exist(player) and Spell.IceBarrier:Cast(Player) then
	    return true
	end
    if Setting("Healthstone") and Player.HP < Setting("Healthstone HP") and (Item.MajorHealthstone:Use(Player) or Item.GreaterHealthstone:Use(Player) or Item.Healthstone:Use(Player) or Item.LesserHealthstone:Use(Player) or Item.MinorHealthstone:Use(Player)) then
        return true
    end
    if Setting("Mana Gem Usage") and Player.PowerPct < Setting("Gem Mana") and (DMW.Time - ItemUsage) > 0.2 and (Item.ManaRuby:Use(Player) or Item.ManaCitrine:Use(Player) or Item.ManaJade:Use(Player) or Item.ManaAgate:Use(Player)) then
        ItemUsage = DMW.Time
        return true
    end 

	if Setting("Use Best HP Potion available") then
		if Player.HP <= Setting("Use Potion at % HP") and Player.Combat then
			if GetItemCount(13446) >= 1 and GetItemCooldown(13446) == 0 then
				name = GetItemInfo(13446)
				RunMacroText("/use " .. name)
				return true 
			elseif GetItemCount(3928) >= 1 and GetItemCooldown(3928) == 0 then
				name = GetItemInfo(3928)
				RunMacroText("/use " .. name)
				return true
			elseif GetItemCount(1710) >= 1 and GetItemCooldown(1710) == 0 then
				name = GetItemInfo(1710)
				RunMacroText("/use " .. name)
				return true
			elseif GetItemCount(929) >= 1 and GetItemCooldown(929) == 0 then
				name = GetItemInfo(929)
				RunMacroText("/use " .. name)
				return true
			elseif GetItemCount(858) >= 1 and GetItemCooldown(858) == 0 then
				name = GetItemInfo(858)
				RunMacroText("/use " .. name)
				return true
			elseif GetItemCount(118) >= 1 and GetItemCooldown(118) == 0 then
				name = GetItemInfo(118)
				RunMacroText("/use " .. name)
				return true
			end
		end
    end
    
    if Setting("Evocation") and not Player.Moving and EvocationInCombat() and Player.Combat and Player.PowerPct < 30 then 
	    if Spell.Evocation:IsReady() and Spell.Evocation:Cast(Player) then
		    return true
		end
	end
end

local function AutoBuff()
    if not Buff.ArcaneIntellect:Exist(Player) and Spell.ArcaneIntellect:Cast(Player) then
        return true
    end

    if Setting("Frost Armor") and Buff.FrostArmor:Remain() < 300 and Spell.FrostArmor:Cast(Player) then
        return true
    end

    if Setting("Dampen Magic") and Buff.DampenMagic:Remain() < 100 and Spell.DampenMagic:Cast(Player) then
        return true
    end

    if Setting("Ice Armor") and Buff.IceArmor:Remain() < 300 and Spell.IceArmor:Cast(Player) then
        return true
    end
	if Setting("Mage Armor") and Buff.MageArmor:Remain() < 300 and Spell.MageArmor:Cast(Player) then
        return true
    end
	if Setting("Ice Barrier") and Setting("Ice Barrier OOC") and Spell.IceBarrier:IsReady() and Buff.IceBarrier:Remain() < 15 and Spell.IceBarrier:Cast(Player) then
	    return true
	end
	if Setting("Mana Gem Usage") and not Player.Moving and not Player.Combat and CreateManaAgent() then
        return true
    end
end

function Mage.Rotation()
    Locals()
	if not Player.Combat and not Player.Moving and ConjureHandler() then return end
    if not Player.Combat then
        if Setting("Auto Buff") and AutoBuff() then
            return true
        end	
    end
    
    if Target and Target.ValidEnemy and Target.Distance < 40 then
        if Defensive() then
            return true
        end

        if Setting("Kite") and Target.HP >= Setting("Kite HP %")then
            if Hostile10C > 0 and not Hostile10[1]:HasMovementFlag(DMW.Enums.MovementFlags.Root) and Hostile10[1].TTD > 2.5 and not NoAoe() and not Debuff.Frostbite:Exist(Target) then
                if Spell.FrostNova:IsReady() and Spell.FrostNova:Cast(Player) then
                    return true
                end
            end
            
        end

        if Setting("Use Counterspell") then
            if Target and Target:Interrupt() then if Spell.Counterspell:Cast(Target) then return true end end

            if Enemy30YC > 1 then
                for i, Unit in ipairs(Enemy30Y) do
                    if i > 1 then
                        if Unit:Interrupt() and Spell.Counterspell:Cast(Unit) then
                            return true
                        end
                    end
                end
            end
        end

        if not Player.Moving and Player.Combat and Setting("Polly") and Debuff.Polymorph:Count() == 0 and (not Spell.Polymorph:LastCast() or (DMW.Player.LastCast[1].SuccessTime and (DMW.Time - DMW.Player.LastCast[1].SuccessTime) > 0.7)) then
            if Enemy30YC > 1 and not Player.InGroup then
                local CreatureType
                for i, Unit in ipairs(Enemy30Y) do
                    if i > 1 then
                        CreatureType = Unit.CreatureType
                        if Unit.TTD > 3 and (CreatureType == "Humanoid" or CreatureType == "Beast") and not Unit:IsBoss() and Spell.Polymorph:Cast(Unit) and Unit.HP > 80 then
                            return true
                        end
                    end
                end
            end
        end

        if Setting("Wand Execute") then
            if not Player.Moving and not IsAutoRepeatSpell(Spell.Shoot.SpellName) and (DMW.Time - WandTime) > 0.7 and DMW.Player.Equipment[18] and Target.HP <= Setting("Wand Execute %") then
                if Spell.Shoot:Cast(Target) then
                    WandTime = DMW.Time
                    return true
                end
                return
            end
            
            -- Wand Execution
            if DMW.Player.Equipment[18] and Target.HP <= Setting("Wand Execute %") then
                return
            end
        end
        

        if not DMW.Player.Combat and Setting("Frostbolt") then
            if Target and Target.Facing and not Player.Moving and Spell.Frostbolt:Cast(Target) then
                return true
            end
            return
        end

        if (not DMW.Player.Equipment[18] or (Target.Distance <= 1 and Setting("Auto Attack In Melee"))) and not IsCurrentSpell(Spell.Attack.SpellID) then
            StartAttack()
        end

        if Setting("Use Cone Of Cold") then
            if Target.Facing and not Debuff.Polymorph:Exist(Target) and Target.Distance <= 8 and Player.PowerPct >= Setting("Cone Of Cold Mana") and Spell.ConeOfCold:Cast(Player) then
                return true
            end
        end

        if Setting("Fire Blast") then
            if Target.Facing and not Debuff.Frostbite:Exist(Target) and not Debuff.Polymorph:Exist(Target) and not Debuff.FrostNova:Exist(Target) and Target.Distance <= 20 and Player.PowerPct >= Setting("Fire Blast Mana") and Spell.FireBlast:Cast(Target) then
                return true
            end
        end
        
        if Setting("Fireball") and Target.Facing and not Player.Moving and Player.PowerPct >= Setting("Fireball Mana") and (Target.TTD > Spell.Fireball:CastTime() or (Target.Distance > 5 and not DMW.Player.Equipment[18])) and (not Setting("Frostbolt") or Player.PowerPct < Setting("Frostbolt Mana") or Debuff.Frostbolt:Remain(Target) > Spell.Fireball:CastTime() or (Spell.Frostbolt:LastCast() and UnitIsUnit(Spell.Frostbolt.LastBotTarget, Target.Pointer))) and Spell.Fireball:Cast(Target) then
            return true
        end
        
        
        if Setting("Frostbolt") and Target.Facing and not Player.Moving and Player.PowerPct >= Setting("Frostbolt Mana") and Spell.Frostbolt:Cast(Target) then
            return true
        end

        if Target.Facing and DMW.Player.Equipment[18] and not Player.Moving and Wand() then
            return true
        end
    end
end