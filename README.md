# Star Wars Vehicles Redux

[![Build Status](https://travis-ci.org/star-wars-vehicles/star-wars-vehicles-redux.svg?branch=master)](https://travis-ci.org/star-wars-vehicles/star-wars-vehicles-redux)
![](https://img.shields.io/github/last-commit/star-wars-vehicles/star-wars-vehicles-redux.svg)
[![](https://img.shields.io/steam/downloads/495762961.svg)](https://steamcommunity.com/sharedfiles/filedetails/?id=495762961)

## Installation

Create a folder inside `addons` called anything you want (preferably something like 'swvr').

Place the contents of the `lua`, `materials`, `models`, and `sounds` folders inside.

## Creating New Vehicles

Please refer to the main documentation for extensive details on creating new vehicles.

Here are some tips for creating them:

**Use a Folder**

If you can, please do not shove all your entity code in one file called `new_vehicle.lua`.

Instead, use a folder called `swvr_new_vehicle` with `init.lua`, `cl_init.lua`, and `shared.lua` files inside.

This makes it clearer what code can and will be executed on clients and/or the server.

**Prefix Entity Folder**

Please use the `swvr_` prefix before the name of your entity folder/file.

This prevents collisions with other vehicle addons that might also have Star Wars vehicles.

**Overriding Functions**

Please only ever override functions specified as meant to be in the documentation.

Overriding a base function could cause many problems. Even if the base doesn't appear to need it, in the future that can change!

## Configuration

Configuration of the basic settings of the ship.

**Basic Configuration**

**Flight Physics Configuration**

## Settings

Settings allow clients and servers to customize vehicles.

**Adding Custom Settings**

This is currently being explored as an option for developers.

## Seats

### Adding Seats

There are current two ways to add seats to vehicles.

The first way is what I will refer to as the *hard-coded* way. This is manually specifying the seat details inside the `ENT.Seats` table inside of the `shared.lua` file.

The second way is the *dyanmic* way. This means adding the seats at run-time when the ship is initialized. This method should be used inside of the `ENT:OnInitialize()` method inside of the `init.lua` file.

You are allowed to mix these methods if you so desire. Note that any hard-coded seats will be registered before the dynamic seats.

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

### Adding Weapons

Similar to seats, weapons can both be added using the same two ways.

The first way is what I will refer to as the *hard-coded* way. This is manually specifying the weapon details inside the `ENT.Weapons` table inside of the `shared.lua` file.

The second way is the *dyanmic* way. This means adding the weapons at run-time when the ship is initialized. This method should be used inside of the `ENT:OnInitialize()` method inside of the `init.lua` file.

You are allowed to mix these methods if you so desire. Note that any hard-coded weapons will be registered before the dynamic weapons.

**Hard-Coded**

```lua
ENT.Weapons = {
  ["Main"] = {
    Pos = Vector(50, -60, 0),
    Callback = nil
  }
}
```

**Dynamic**

```lua
function ENT:OnInitialize()
  self:AddWeapon("Main", Vector(50, -60, 0), nil)
end
```

### Using Weapons

Using the added weapons are extremely easy. The built in function `ENT:FireWeapon(name, options)` is designed to be able to easily fire any weapon added, even custom firing functions.

Firing the weapon might look something like this.

```lua
function ENT:PrimaryAttack()
  if self:GetNextPrimaryFire() > CurTime() then return end

  self:SetNextPrimaryFire(CurTime() + 0.1)

  self:EmitSound("AWING_FIRE1")

  for _, name in ipairs({"FrontL", "FrontR"}) do
    self:FireWeapon(name)
  end
end
```

In this example, the second parameter `options` of `ENT:FireWeapon(name, options)` is ignored. This is usually alright if you're just firing a cannon.

Often times though, you'll want to customize the weapon you're firing. Use the `options` parameter to customize the weapon before firing it.

```lua
self:FireWeapon("Main", {
  Type = "proton_torpedo",
  Damage = 500
})
```

Internally, the specific weapon firing function gets called by translating the `Type` field from `snake_case` to `CamelCase`.

In this case, `proton_torpedo` becomes `ProtonTorpedo` and thus the function `ENT:FireProtonTorpedo(name, options)` is automatically called for you!

Any options passed into `ENT;FireWeapon()` are also passed into the specific firing function automatically.

## Effects

While not recommended, all of the effects on the vehicles can be completely overriden or disabled.
