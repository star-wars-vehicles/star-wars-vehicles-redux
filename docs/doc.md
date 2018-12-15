# Developer Information

## Configuration

Configuration of the basic settings of the ship.

**Basic Configuration**

**Flight Physics Configuration**

## Settings

Settings allow clients and servers to customize vehicles.

**Adding Custom Settings**

## Seats

There are current two ways to add seats to vehicles.

The first way is what I will refer to as the *hard-coded* way. This is manually specifying the seat details inside the `ENT.Seats` table inside of the `shared.lua` file.

The second way is the *dyanmic* way. This means adding the seats at run-time when the ship is initialized. This method should be used inside of the `ENT:OnInitialize()` method inside of the `init.lua` file.

You are allowed to mix these methods if you so desire.

**Hard-Coded**

```lua
ENT.Seats = {
  ["Pilot"] = {
    Pos = Vector(-20),
    Ang = Angle(0, -90, 0)
  }
}
```

**Dynamic**

```lua
function ENT:OnInitialize()
  self:AddSeat("Pilot", Vector(-20), Angle(0, -90, 0))
end
```

**NOTE: The first seat added will ALWAYS be considered the pilot seat, regardless of whether or not you call it pilot!**

## Weapons
