TL = TL or {}

function TL.CombatZoneResize(LeftPosition, TopPosition, RightPosition, BottomPosition)
    -- Store old zone
    TL.old_zone.left = TL.zone.left
    TL.old_zone.top = TL.zone.top
    TL.old_zone.right = TL.zone.right
    TL.old_zone.bottom = TL.zone.bottom

    -- Set new target zone
    TL.target_zone.left = LeftPosition
    TL.target_zone.top = TopPosition
    TL.target_zone.right = RightPosition
    TL.target_zone.bottom = BottomPosition

    -- Reset anim timer
    TL.anim_time = 0
end

function TL.EndAttack()
    TL.MENU.state = true
    TL.CombatZoneResize(33, 251, 608, 391)

    -- -- Hide everything except not all of them lol
    -- TL.HideAllImages({ HP = true, KR = true, PlayerHeart = true })

    -- Destroy all attacks
    TL.DestroyAllAttacks()

    -- Reset all icon states (will prolly change when i get to the attack loader)
    for name, _ in pairs(TL.MENU.icons) do
        if name ~= "previous_highlight" then
            TL.MENU.icons[name] = false
        end
    end

    -- Get last highlighted
    local last = TL.MENU.icons.previous_highlight or "UIFight"

    -- Set the right one in highlight mode, the others no
    for _, name in ipairs({ "UIFight", "UIAct", "UIItem", "UIMercy" }) do
        local normal = TL.images[name]
        local highlight = TL.images[name .. "_Highlight"]

        if normal then
            normal.visible = (name ~= last)
        end
        if highlight then
            highlight.visible = (name == last)
        end
    end
end