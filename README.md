# Star Wars Vehicles Redux

##Installation

Create a folder inside `addons` called anything you want (preferably something like 'swvr').

Place the contents of the `lua`, `materials`, `models`, and `sounds` folders inside.

##Creating New Vehicles

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

##Generating Documentation

Generating documentation assumes you have `ldoc` as well as `lua-discount` installed.

Please install them using a tool like *luarocks* before continuing.

Run `ldoc .` inside the root directory to generate documentation into the `docs` folder.

The `doc.md` file inside of the documentation folder can bbe customized beforehand to change the manual.
