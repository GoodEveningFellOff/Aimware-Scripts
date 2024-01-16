callbacks.Register("Draw", function()
    for _, pEnt in pairs(entities.FindByClass("C_CSGOViewModel")) do
        pEnt:SetPropBool(true, "m_bShouldIgnoreOffsetAndAccuracy")
    end
end)
