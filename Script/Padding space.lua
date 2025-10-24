--Delete Spacer More than 1
local CoreGui = game:GetService("CoreGui")
local spacer = CoreGui.TopBarApp.TopBarApp.UnibarLeftFrame.StackedElements.LeaderboardSpacer

if spacer then
    local parent = spacer.Parent
    local spacers = parent:GetChildren()
    local foundFirst = false
    
    for i, child in ipairs(spacers) do
        if child.Name == "LeaderboardSpacer" then
            if not foundFirst then
                foundFirst = true
            else
                child:Destroy()
            end
        end
    end
end
