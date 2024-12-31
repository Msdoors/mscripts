local InfiniteJumpEnabled = false
game:GetService("UserInputService").JumpRequest:connect(function()
    if InfiniteJumpEnabled then
        game:GetService"Players".LocalPlayer.Character:FindFirstChildOfClass'Humanoid':ChangeState("Jumping")
    end
end)
 
local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:connect(function()
    vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    wait(1)
    vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)
 game.StarterGui:SetCore("SendNotification", {
    Title = "Fornecido por mscripts";
    Text = "https://dsc.gg/betterstar";
    Duration = 20;
})
game.StarterGui:SetCore("SendNotification", {
    Title = "não fazemos promoções 🙏";
    Text = "Cala a boca!! "; -- what the text says (ofc)
    Duration = 1;
})
wait(1)
game.StarterGui:SetCore("SendNotification", {
    Title = "Divirta-se matando";
    Text = "Aproveite"; -- what the text says (ofc)
    Duration = 1;
})
_G.HeadSize = 18.5
_G.Disabled = true
 
game:GetService('RunService').RenderStepped:connect(function()
if _G.Disabled then
for i,v in next, game:GetService('Players'):GetPlayers() do
if v.Name ~= game:GetService('Players').LocalPlayer.Name then
pcall(function()
v.Character.HumanoidRootPart.Size = Vector3.new(_G.HeadSize,_G.HeadSize,_G.HeadSize)
v.Character.HumanoidRootPart.Transparency = 0.5
v.Character.HumanoidRootPart.BrickColor = BrickColor.new("Really black")
v.Character.HumanoidRootPart.Material = "Neon"
v.Character.HumanoidRootPart.CanCollide = false
end)
end
end
end
end)
