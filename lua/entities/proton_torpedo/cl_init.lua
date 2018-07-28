include("shared.lua")

function ENT:Initialize()
    self.FXEmitter = ParticleEmitter(self:GetPos())
end

function ENT:Draw()
    self:DrawModel()

    local isWhite = self:GetNWBool("IsWhite")
    local sprite = isWhite and "sprites/white_blast" or "sprites/bluecore"

    local fx = self.FXEmitter:Add(sprite, self:GetPos())
    fx:SetVelocity((self:GetForward() * -1):GetNormalized())
    fx:SetDieTime(0.2)
    fx:SetStartAlpha(255)
    fx:SetEndAlpha(255)
    fx:SetStartSize(self:GetNWFloat("StartSize"))
    fx:SetEndSize(self:GetNWFloat("EndSize"))
    fx:SetRoll(math.Rand(-90, 90))
    fx:SetColor(self:GetNWVector("Color"):ToColor())
end
