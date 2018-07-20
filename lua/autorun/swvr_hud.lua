SWVR = SWVR or {}

if CLIENT then
    function SWVR:XYIn3D(pos)
        local x, y
        for k, v in pairs(pos:ToScreen()) do
            if k == "x" then
                x = v
            end

            if k == "y" then
                y = v
            end
        end

        return x, y
    end
end
