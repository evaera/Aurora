<div align="center">
    <img src="assets/Aurora.png" alt="Aurora" height="139" />
</div>

> I recommend checking out [Fabric](https://github.com/evaera/Fabric) which will be replacing Aurora in all of my projects as soon as it's ready for production. Fabric solves the same problems that Aurora solves, but with less assumptions and more flexibility.

# Aurora

**Aurora** is a library that can manage status effects (known as "Auras") in your Roblox game. These Auras are much akin to "buffs" and "debuffs" as seen in many games.

Using Aurora can help you stay sane while managing complex game state when multiple parts of your game need to keep track of or change the same resource.

## How it works

A classic example of the problem that Aurora aims to solve is changing the player's walk speed. Let's say you have a heavy weapon that you want to have slow down the player when he equips it. That's easy enough, you just set the walk speed when the weapon is equipped, and set it back to default when the weapon is unequipped.

But what if you want something else to change the player's walk speed as well, potentially at the same time? For example, in addition to the heavy weapon, say the player could equip a shield which also slows them down a bit. If we follow the same flow as when we implemented the logic for the heavy weapon above, we now have a problem: The player can equip both the heavy weapon and the shield, and then unequip the heavy weapon. Now, the player can walk around at full speed with a shield up when they should still be slowed!

Aurora solves this problem correctly by allowing you to apply a movement speed Aura from each of your equipped items. Each Aura would then provide the movement speed altering *Effect*, each of which can have different intensities. Then, every time an Aura is added or removed, Aurora will group all similar *Effects* and feed all of their values into a single reducer function. In this case, the function will find the lowest value from all of the Auras, and then the player's WalkSpeed will be set to that number.

<img src="assets/Diagram.svg" alt="Aurora" />

Now, there is only one source of truth for the player's WalkSpeed, which solves all of our problems. When there are no longer any Auras that provide the walk speed Effect, Aurora will clean up by setting the player's walk speed back to default.

Of course, this is only one example of what Aurora can be used for. Auras can be used for tracking player state (such as marking a player as "infected" in a zombie game), modifying combat values (such as +10% damage for the next 10 seconds), and as a means of communicating modifiers to the player directly (by directly displaying what Auras a player has on their screen).

## Installation
### Build in Studio from GitHub

The easiest way to get started with Aurora is to install the [RoStrap Roblox Studio plugin](https://www.roblox.com/library/725884332/RoStrap), open the RoStrap interface in a place, and then install "Aurora". This will instantly download and build the newest version of Aurora right from GitHub.

![Installation](https://user-images.githubusercontent.com/2489210/49001088-9f197900-f129-11e8-98a6-74bda8d5d532.png)

## House rules

- All properties should always be treated as **read-only**. There is nothing in the library stopping you from changing a property, but you may experience unexpected or unwanted behavior if you do and your code may be broken by future releases.
- Classes have more methods and properties than are documented in this file, but they should serve no significant purpose to the end developer. If you use undocumented members, you may experience unexpected behavior and your code may be broken by future releases.

## Library

The main Aurora library provides access to Agents, registering custom containers for your Auras and Effects, and changing global settings.

Note that these methods must be called from both your client and server code. Calling a method from this main library on the server will not change anything on the client, and vice-versa. (This is not the case for Agent methods, which are mirrored to clients.)

### Methods
#### `Aurora.GetAgent(instance: Instance): Agent`
Returns the Agent for the given instance. Each instance will only ever have one Agent, and this method will keep track of created Agents.

* If the previous Agent is destroyed, either manually or due to configured settings, then a new one will be created.

Ensure that you have registered your Auras and Effects before this method is called.

#### `Aurora.RegisterAurasIn(instance: Instance): void`
Registers the given instance as a container where ModuleScripts returning Aura definitions are kept. 

##### Structure and search strategy
The ModuleScript must have the same name as the Aura. Auras are lazy-loaded: the first time an Aura is applied, it is matched with a recursive `FindFirstChild` call for every registered Aura container until it's found, and then it is cached. Feel free to nest folders organizing your Auras, but be aware that *folder names* must also be unique with all module names. If a non-ModuleScript instance is returned from that root, then it will be discarded and will continue searching in other roots (if there are any).

##### Server shadowing
ModuleScripts under the container with an Aura name appended with "Server" (case-sensitive) will also be automatically loaded and its sections will entirely replace (not merge with) sections exported by the base Aura ModuleScript. This optional feature is only active on the server; even if a "Server"-appended module is replicated to the client, it will not be loaded.

#### `Aurora.RegisterEffectsIn(instance: Instance): void`
See *RegisterAurasIn* just above. Everything is exactly the same. Except, of course, that ModuleScripts inside these containers must export Effects, not Auras.

#### `Aurora.SetTickRate(seconds: number): void`
Sets how often, in seconds, that all Auras will have their `TimeLeft` property reduced. The default value is `0.5` seconds.

#### `Aurora.SetMaxAgentTimeInactive(seconds: number): void`
Sets how long, in seconds, that an Agent can exist without any Auras before it is automatically destroyed on the next update cycle. You should set this if you intend to have a large number of instances with Auras that remain in the game world for a long time. This feature will make the initial Aurora snapshot sent to newly joined players less expensive, make the update cycle slightly less expensive, and free up memory.

This is a potentially dangerous feature. If enabled, then you must take care to always call `Aurora.GetAgent` after your code yields (WaitForChild, wait, event listeners, etc). If you hold on to a reference to an old Agent, then in addition to leaking memory, your code will error because you can't call methods on destroyed Agents.

The default value is `math.huge` (disabled).

#### `Aurora.SetSafeMemoryMode(isSafeMode: boolean): void`
Under "Safe Memory Mode", if an Agent's associated Instance is not a descendant of the DataModel (i.e. `game`, or the *game tree*) then that Agent will be automatically destroyed so as to prevent memory leaks.

Agents being attached to an instance *will* prevent that instance from being garbage collected automatically if it's just detached from the game tree (parent set to `nil`). However, if the instance (or an ancestor of that instance) is destroyed, then the Agent and instance will be correctly garbage collected, even if "Safe Memory Mode" is off.

This is an important consideration, because not all instances are destroyed automatically when they are removed, chiefly player characters, which are not destroyed when the player dies or leaves the game. This means that if "Safe Memory Mode" is off, and you attach Auras to the character, then that character will exist in memory forever even after the player dies and gets a new character.

If you are willing to take on the responsibility of ensuring everything you attach Auras to are properly destroyed (e.g. destroying characters after the player dies manually), then it's safe to turn this off. Otherwise, for most applications it's safer to keep this at the default (on).

### Properties
#### `Aurora.TickRate: number`
The current update cycle tick rate; see *SetTickRate*.

#### `Aurora.MaxAgentTimeInactive: number`
The current maximum time an Agent may be inactive before being destroyed; see *SetMaxAgentTimeInactive*.

#### `Aurora.SafeMemoryMode: boolean`
Whether or not "Safe Memory Mode" is enabled; see *SetSafeMemoryMode*.

#### `Aurora.InitialSyncCompleted: boolean`
When a player first joins a server, a *snapshot* of every replicated Aura on every Agent is created and sent to that player. The client will then re-create the Agents and Auras it received. After this process has been completed, `InitialSyncCompleted` will be `true`. On the server, it is always `true`.

## Agents

An Agent is an object that keeps track of Auras and Effects on behalf of the Instance that it is linked to. When it comes time to apply, remove, or otherwise alter the Auras that are applied to a specific Instance, you do so through its Agent. Each Instance will only ever have one Agent, and the Aurora library will be sure to keep track of this for you and always return the same one when called on the same Instance (unless the previous one was destroyed).

Agents also handle updating the state of each Aura attached to it, which happens every time an Aura is added or removed.

### Methods
#### `Agent:Apply(auraName: string, props?: dictionary): boolean`
Creates a new Aura of the given name under this Agent. Because Auras are lazy-loaded, this method call will be the first time your Aura definition is validated. If the given Aura is defined as being replicated, then this method will also mirror over to all clients. Effects are immediately reified as soon as Apply is called.

##### Props
`props` is an optional table dictionary, in which you can override properties from the Aura definition. *Props* must always contain at least one sub-dictionary, because Aura definitions are split into several section dictionaries, as can be seen under *Auras* below. Only the section properties you list here explicitly will be overridden; section properties you omit from Props will still fall back to the section properties from the definition.

These custom Props will also be sent to clients to ensure proper replication. You can use Props to override any or all sections, but you must take care when it comes to using function values here. Function values, as in normal definitions, are valid, but because functions are not serializable, any functions that appear in Props will be called immediately and their static return values will be sent to the clients. Functions will continue to be called on-the-fly on the server.

The `Effects` section is an exception to this system. If `Effects` is included as a Prop then that table will completely replace the `Effects` table from the definition, they will not be merged as with other sections. It is recommended to not override the `Effects` section, but rather override properties in the `Params` section, and then have your Effects in your Aura Definition be dynamic based on values from the Params. This can be seen in action under "Auras" below.

##### Stacks and refreshes
If an Aura is stackable and isn't at its `MaxStacks` value, then a new stack will be added to this Aura. This will fire the "AuraStackAdded" event instead of "AuraAdded". If the `ShouldAuraRefresh` property is true, then the old Aura is replaced with the new one (which implicitly also resets the duration to full). If `ShouldAuraRefresh` is false, then the old Aura is retained (which implicitly retains the same duration).

If an Aura is not stackable, or if it is already at maximum stacks, it will instead "refresh" the Aura if it is allowed. This means that the old Aura is replaced with the new one, and the "AuraRefreshed" event will be fired instead of "AuraAdded".

If an Aura is not stackable, or if it's already at maximum stacks, and `ShouldAuraRefresh` is false, then nothing will happen, and the method will return `false`. Under all other circumstances, `true` will be returned.

##### Custom Aura Names
When adding an Aura, you can specify a custom name that will be used for internal tracking. This will let the Aura be nonunique with other Auras of the same type. It won't stack with other Auras of the same type (unless they also have the same custom name). Remember, Effects will still always be unique with other Auras providing the same Effects: If more than one of the same Aura exist with custom names, all of their Effect values will be passed into the single Effect reducer, just as if they were distinct Auras. 

To specify a custom name, pass a property `Name` in as a Prop when applying this Aura. The `Name` property must be a string that begins with a colon (`:`). When calling any other methods (like `Remove`, `Get`, `Consume`, and `Has`), you must now refer to the Aura as the custom name you provided, colon included. You can still access the true type of this Aura with the `Id` property of the Aura.

This feature is useful for when you need to add multiple of the same Aura at the same time but with different Params, so adding a stack or refreshing duration wouldn't be appropriate.

As a shorthand, you may also simply send a string in place of a Props table in order to set a custom name succinctly. For example, `agent:Apply("auraName", ":customName")` is shorthand for `agent:Apply("auraName", { Name = ":customName" })`.

Note: Aurora will throw an error if you attempt to apply two *distinct* Auras with the same custom name at the same time.

##### Inline Auras
Sometimes, it's easier to define an Aura inline where you need it instead of defining it in its own file, especially if you're only using a specific set of Effects in one place. If you send a string that begins with a colon (`:`) as the first parameter to `agent:Apply`, this will create a new, blank Aura with its custom name set to what you supplied. Then, you can define the entire Aura contents as Props as the second parameter. However, you should remember that using any functions in Props will be made static upon replication.

```lua
agent:Apply(":MyInlineAura", {
  Effects = {
    SomeEffect = true
  }
})
```

#### `Agent:Remove(auraName: string, reason = "REMOVED"): boolean`
Removes the Aura of the given name from this Agent. If the given Aura is defined as being replicated, then this method will also mirror over to all clients. Effects are immediately reified after Remove is called.

Fires the `AuraRemoved` event and hook.

`reason` is optional, and is sent along with the "AuraRemoved" event and hook. By default, the reason is `"REMOVED"` (unless the Aura is removed automatically due to expiration, in which case it is `"EXPIRED"`).

Returns `true` if an Aura was actually removed, `false` if nothing happened because the Aura didn't exist on this Agent.

#### `Agent:Consume(auraName: string, reason = "CONSUMED"): boolean`
Consumes a stack from the Aura of the given name. If the given Aura is defined as being replicated, then this method will also mirror over to all clients. Effects are immediately reified after Consume is called.

Fires the `AuraStackRemoved` event and hook. If the Aura only has one stack, the `AuraRemoved` event and hook will *also* be fired.

`reason` is optional, and is sent along with the "AuraRemoved" event and hook. By default, the reason is `"CONSUMED"`.

Returns `true` if an Aura was actually consumed, `false` if nothing happened because the Aura didn't exist on this Agent.

#### `Agent:Has(auraName: string): boolean`
Returns `true` if an Aura of the given name is currently applied to this Agent, `false` otherwise.

#### `Agent:Get(auraName: string): Aura?`
Returns the Aura of the given name if it's currently applied to this Agent, `nil` otherwise.

Do not store the return value from this method for long, because Auras can be created and destroyed quickly. Storing this value or trapping it in a closure will cause memory leaks.

#### `Agent:GetAuras(): array<Aura>`
Returns an array of all Auras currently applied to this Agent.

Do not store the return values from this method for long, because Auras can be created and destroyed quickly. Storing these values or trapping them in a closure will cause memory leaks.

#### `Agent:HasEffect(effectName: string): boolean`
Returns `true` if an Effect of the given name is currently active on this Agent, `false` otherwise.

#### `Agent:GetLastReducedValue(effectName: string): any`
Returns the last value that was returned by the given Effect's Reducer function, or `nil` if the Effect doesn't exist on this Agent. This method is most useful for when it's more appropriate for your code to "reach in" to Aurora and pull out the value from an Effect, rather than "reaching out" from Aurora and making a change in the world with the Apply function.

#### `Agent:ApplyAuras(auras: dictionary, runHooks?: boolean): void`
Accepts a dictionary map of Aura name => dictionary of Props, and applies the given Auras en masse. By default, any Hooks defined in the given Auras will be skipped, but you can allow them to run by sending `true` as the second parameter.

This function is called internally during network replication, and the output of `Agent:Serialize()` may be fed directly into this function.

#### `Agent:RemoveAuras(filter?: function(aura) => boolean): boolean`
Removes all Auras that match the given filter function, or all Auras if no filter function is provided. Returns `true` if at least one Aura was removed.

#### `Agent:Serialize(filter?: function(aura) => boolean): dictionary`
Returns a serializable "snapshot" of the Auras on this Agent. Accepts an optional filter function, which should accept a single Aura, and return a boolean that determines if the Aura should be present in the returned dictionary.

It should be noted that this function creates a *static representation* of the Auras on this Agent. Because you can override certain properties with Props in the `Apply` function, special care is taken to replicate these across the network. Aurora tracks which properties you changed with Props and explicitly stores those in the snapshot. Additionally, it is possible to send functions as values in Props in order to return a dynamic value. Because functions are not serializable, function in Props will be ran immediately and their return value will be present inside the snapshot.

You may feed the output of this function directly into `Agent:ApplyAuras` to apply all serialized Auras at once. The built-in Aurora network code uses this function internally in order to replicate the Auras on this Agent.

#### `Agent:CopyAurasTo(otherAgent: Agent, function(aura) => boolean): void`
Copies all Auras from this Agent that match the filter function (or all if no filter function is given) to a provided Agent. This function uses `Agent:Serialize()` internally, so all caveats listed above also apply here.

#### `Agent:TransferAurasTo(otherAgent: Agent, function(aura) => boolean): void`
The same as CopyAurasTo as described above, except that the matching Auras are also removed from this Agent in the process.

#### `Agent:ReifyEffects(): void`
Recalculates all active Effects from the current set of Auras, and runs their Reducer/Apply methods. This function is run automatically whenever you run `agent:Apply` and `agent:Remove`, but it is deferred to the end of the frame as an optimization. You should only use this function if you need to update active Effects immediately.

#### `Agent:Destroy(): void`
Destroys this Agent, rendering it unusable. All events will be disconnected, Effects will be deconstructed, Auras will be removed, it will no longer be updated or kept in memory internally, and calling any further methods on this Agent will raise an error.

### Properties
#### `Agent.Instance: Instance`
The instance that this Agent is attached to. 

### Events

#### `AuraAdded (aura: Aura)`
#### `AuraRemoved (aura: Aura, reason: string)`
#### `AuraRefreshed (newAura: Aura, oldAura: Aura)`
#### `AuraStackAdded (aura: Aura)`
#### `AuraStackRemoved (aura: Aura)`

## Auras

Auras can be applied to any Instance (e.g. a Player, a player's Character, or an NPC). Auras hold information such as duration and number of stacks (if an Aura is stackable, that means that if the same Aura already exists when it is applied once more, the existing Aura will simply gain another "stack"), and user-facing information such as title, description, and icons. Auras are only optionally replicated to the client, and also optionally directly displayed to the player.

### Definition

Auras have a "definition", which is a ModuleScript that returns a table containing known properties. You should put your Auras in a folder (nesting allowed), and then call `Aurora.RegisterAurasIn` with the folder. See *RegisterAurasIn* for more details on how the matching process works.

In Aura definitions, every property value is expected to be a static (serializable) value. In every case, a function is also acceptable in place of a value, but the function must **never yield**, must **have no side effects**, and **return the expected type** for the property. The function is passed one argument, which is the Aura itself.

The definition is split into sections, each containing a different type of information. A sample Movement Speed Aura definition is provided below:

```lua
-- Encumbered.lua

return {
  Display = {
    Title = "Encumbered!";
    Description = function(self)
      return ("Reduces movement speed by %d%% for %d seconds.")
      :format(100 - math.floor((self.Params.Speed / 16 * 100), self.Status.Duration)
    end;
    Icon = "rbxassetid://1234567";
    Visible = true;
  };

  Status = {
    Duration = function (self)
      return self.Stacks * 5 -- Increase duration with stacks
    end;
    Replicated = true;
    ShouldAuraRefresh = true;
    MaxStacks = 2;
  };

  Params = {
    Speed = 10;
  };
  
  Effects = {
    -- Effects may either be functions that return a value, or just a value.
    ChainAnimation = function (self)
      return self.Status.Stacks;
    end;
    AnotherEffect = 50;
    -- In either case, these values (the number of stacks, and 50) will be sent
    -- to the Effect Reducer function.
  };
  
  Hooks = {
    AuraAdded = function()
      print("Encumbered added! Maybe this could play a sound.")
    end;
  }
}
```

As described in [*Server shadowing*](#server-shadowing), we can apply a different set of properties over top of our main definition on the server only:

```lua
-- EncumberedServer.lua

return {
  Effects = {
    WalkSpeedMax = function(self)
      return self.Params.Speed
    end
  }
}
```

After the Aura definition is loaded (and merged together, if on the server), it's sent along internally and initialized.

The `Status` section may only have specific properties inside, but `Params` and `Display` are free for the developer to customize. Properties in `Effects` must correspond to names of Effects that you have registered with `RegisterEffectsIn`.

All sections in an Aura definition are optional.

### Properties

Aura properties are all loaded from the Aura definition, overshadowed by any Props specific to this Aura.

#### `Aura.Id: string`
The name of this Aura from its definition.

#### `Aura.Name: string`
If this Aura has a custom name, then this is the custom name. Otherwise, it's the same as `Id`.

#### `Aura.Remote: boolean`
On the client, this property is `true` if this Aura originated from the server. On the server, it is always `false`.

#### `Aura.Agent: Agent`
The Agent that this Aura belongs to.

#### `Aura.Instance: Instance`
The instance that this Aura's Agent is for.

#### `Aura.Display: dictionary`
An dictionary where you could include display-related properties such as:

- Title
- Description
- Icon

#### `Aura.Config: dictionary`
An dictionary where you could include generic Aura-related properties such as:

- Should persist through death
- Remove on death
- Should the Aura be removed when the player does X

#### `Aura.Params: dictionary`
A dictionary where you should include any parameters for Effects (for example, for an Aura/Effect that increased movement speed, a good property for the Params section would be "Speed")

#### `Aura.Effects: dictionary`
A dictionary containing the Effect values/functions for this Aura.

#### `Aura.Status: dictionary`
A dictionary containing the state used by Aurora internally (which can also be referenced by your own code)

#### `Aura.Status.Duration: number`
The original duration of this Aura in seconds. If unspecified in the definition, defaults to `math.huge`.

#### `Aura.Status.TimeLeft: number`
The number of seconds remaining on this Aura.

#### `Aura.Status.Stacks: number`
The number of stacks that this Aura has. This always starts at `1`, even for unstackable Auras.

#### `Aura.Status.Replicated?: boolean`
If true, this Aura will be sent to all clients. Otherwise, it will only exist on the server.

#### `Aura.Status.MaxStacks?: number`
The maximum number of stacks this Aura can reach.

#### `Aura.Status.ShouldAuraRefresh?: boolean`
Whether or not this Aura is allowed to refresh its duration when a new stack is applied (or if unstackable, when it is applied again). True if omitted.

#### `Aura.Status.ServerOnly?: boolean`
If true, Aurora will throw an error if you attempt to apply this Aura from the client. Mutually exclusive with `Replicated` and `ClientOnly`.

#### `Aura.Status.ClientOnly?: boolean`
If true, Aurora will throw an error if you attempt to apply this Aura from the server. Mutually exclusive with `Replicated` and `ServerOnly`.

### Hooks

Auras also have "Hooks", which are life cycle methods directly attached to a specific Aura, rather than an Effect. Hooks could be used for things like playing a specific sound when the Aura is applied or removed or showing a notice on a player's screen. However, they shouldn't be used to modify the game world.

Note: Hooks do not fire during the initial world snapshot playback when a player joins the game, so that the player is not flooded with messages and/or sounds.

#### `AuraAdded`
#### `AuraRemoved`
#### `AuraRefreshed`
#### `AuraStackAdded`
#### `AuraStackRemoved`

## Effects 

Auras can provide Effects (with various parameters), which are used to actually make changes to the world. Effects are explicitly defined by the developer just like Auras. Unlike Auras, however, an Effect can only exist once per Agent, and they are automatically created and destroyed based on what Effects are provided by the current set of Auras.

Effects are made up of a few functions, which are all optional:

- The `Constructor` is called whenever one of the Auras starts providing this Effect. It can be used to create any necessary objects needed to enact or display this Effect.
  - For example, if you want to display a "dizzy" indicator above a player when they are stunned, this function could create that and put it inside the character.
- The `Reducer` is called every time Auras providing this effect are added or removed, and takes in any parameters given by Auras which are providing this Effect as an array. It is then this function's job to *reduce* these values into one value and then return it.
- The `Apply` function is called immediately after the Reducer, and it is given whatever `Apply` returned as arguments. This function should actually make a change in the world based on the reduced value it is given. This separation is enforced so that the reduced value can be captured for `Agent:GetLastReducedValue` to work as expected.
- The `Destructor` is called when there are no longer any Auras providing this Effect. It can be used to clean up any objects that were created in the Constructor.
- `ShouldApply`, which can override the default behavior of directly comparing the last reduced value with the current to decide if Apply should be called. `ShouldApply` accepts the parameters `self`, `currentReducedValue` (array), and `previousReducedValue` (array). (The last two are sent as arrays because the reducer can return multiple values.) The function should then return a boolean that decides if the `Apply` function is called following the Reducer.

Effect definitions may also have these optional properties:
- `AllowedInstanceTypes` - Table of strings that limits the types of instances that this Effect can be applied to. Aurora will produce a warning if an Effect is applied to an improper instance type, and the Effect wil be discarded. Uses :IsA comparison.
- `ServerOnly` - A boolean that determines if this Effect should only run on the server. `ServerOnly` effects are silently ignored on the client.
- `ClientOnly` - A boolean that determines if this Effect should only run on clients. `ClientOnly` effects are silently ignored on the server.
- `LocalPlayerOnly` - A boolean that determines if this Effect should only run on the client of the player who is associated with the Agent Instance. The Effect only runs if the Agent Instance is the local client's Player, Player character, or any descendant thereof. `LocalPlayerOnly` effects are silently ignored on other clients and on the server.

### Definition

```lua
return {
  -- Optional, limit the types of instances that this Effect can be applied to.
  -- Aurora will produce a warning if an Effect is applied to an improper instance
  -- type, and the Effect wil be discarded.
  -- Uses :IsA comparison.
  AllowedInstanceTypes = {"Humanoid"};

  Constructor = function (self) -- self is the Effect, not the Aura.
    -- For example, add a special part to the character
    -- (Not welded for the sake of example)
    self.SpecialEffectPart = game.ReplicatedStorage.Part:Clone()

    -- self.Instance is set to the Agent's Instance property.
    self.SpecialEffectPart.Parent = self.Instance.Parent
  end;

  -- This function gathers all values provided by the current set of Auras
  -- providing this Effect.
  Reducer = function (self, values)
    -- `values` is an array containing the resolved value from every Aura that
    -- is providing this Effect. Here, we need to take all of these values and
    -- then *reduce* them down into a single value.

    local walkSpeed = math.huge

    for _, maxSpeed in ipairs(values) do
      if maxSpeed < walkSpeed then
        walkSpeed = maxSpeed
      end
    end

    return walkSpeed
  end;

  -- The Apply function is called immediately after the Reducer returns.
  -- It is given any values that the Reducer function returns.
  -- We then take the reduced value and *apply* a change in the world.
  Apply = function (self, walkSpeed)
    self.Instance.WalkSpeed = walkSpeed
  end;

  Destructor = function (self)
    -- Clean up anything to set the world right now that we're done.
    self.Instance.WalkSpeed = 16
    self.SpecialEffectPart:Destroy()

    -- The Effect (what `self` refers to) is freed for garbage collection
    -- after this function runs.
  end;
}
```

### Methods
These may only be accessed via the `self` parameter in Effects.

#### `Effect:GetLastReducedValue(): any`

### Properties
These may only be accessed via the `self` parameter in Effects.

#### `Effect.Name: string`
#### `Effect.Agent: Agent`
#### `Effect.Instance: Instance`
#### `Effect.Definition: EffectDefinition`

## Replication

When a player joins the game, a snapshot of every Aura with `Status.Replicated` set to `true` from every Agent on the server is created, serialized, and sent to the player. The player then re-creates the entire world state on their end.

You can also modify Auras from the client, but be aware that if you work with the same Auras on both the server and the client you could run into world state disagreements. Take care to give your Auras custom names if you want to avoid collision.

Once a player is connected, all changes (Auras being applied or removed) to replicated Auras are mirrored to all clients in the game. All mirrored messages are played back on the client in order so that the server and client should always agree on the world state.

Each client runs its own version of the world, decreasing duration on Auras and updating Effects. However, the client will never remove any Auras that originated from the server when they expire, instead it waits for the server to mirror the Remove message back to the client. As a result, server-owned Auras may sit at `0` `TimeLeft` for an amount of time.

The ability to restrict Aura replication to specific players is forthcoming.

## Common Mistakes and Anti-Patterns

### Checking for existence before applying or removing Auras
It is not necessary to check if an Agent has an Aura before removing it. Instead, the `Remove` method returns `true` if it actually did remove an Aura, or `false` if it did not.

```lua
if ClientAgent:Has(":FieldOfViewRageMode") then -- Unnecessary!
  ClientAgent:Remove(":FieldOfViewRageMode")
end
```

Likewise, it is not necessary to check if an Aura is already present on an Aura before applying it. Instead, you can just call `Apply` again, and the Aura will either refresh duration, add a stack, or do nothing, depending on its configured settings. This is explained in detail under the Agent:Apply documentation.

### Applying many Auras at once
If you ever catch yourself applying many Auras at once, this should raise some red flags that you're doing something not quite right:

```lua
-- Not quite right!
Agent:Apply("MovementDisabled", ":MovementDisabledAttackHandler")
Agent:Apply("JumpingDisabled", ":JumpingDisabledAttackHandler")
Agent:Apply("LookingDisabled", ":LookingDisabledAttackHandler")
Agent:Apply("LeaningDisabled", ":LeaningDisabledAttackHandler")
```

Auras are meant to model one or more status effects that are grouped together. In this example, the author has made four generic Auras that each provide only one Effect, and is then giving each one a custom name for tracking. This can get unwieldy very quickly!

Instead, the correct solution is to only make one Aura specific to this use case that provides every effect that you need. **Auras should generally have *use-specific* names, while Effects should generally have generic names.**

For example, in this case, the correct solution would be to make one Aura -- perhaps named "Rooted" -- that provides four effects named `"MovementDisabled"`, `"JumpingDisabled"`, `"LookingDisabled"`, and `"LeaningDisabled"`.

### More than one Agent for the same entity
State related to the same entity (a player, an NPC, or anything really) should only have one Agent. It may be tempting to have one Agent for a player, and another Agent for that player's character -- but this can be a footgun. Falling into this trap can severely complicate state management because it is unclear which Agent certain Effects should operate on -- and can often lead to state duplication.

For example, if you had an Aura that provides two effects, but one of them expects to operate on the character, and the other expects to operate on the player you'd need to get the agent for both and apply the same Aura twice on both Agents. This can quickly get confusing and unmanageable.

Instead, the better solution is to pick *one* -- the player, or the character -- and then add logic and configuration for removing Auras that should not persist through death, or, transferring Auras that should persist to the new Agent. Generally, the recommended approach is to use an Agent for the Player object, and remove non-persistent Auras upon death with the `Agent:RemoveAuras` function, reading an option from the `Config` section that you would create in each Aura's definition.

### Functions in Props
In Aura definitions, you can provide a function in place of any value type, as long as it returns the expected type. You can also do this when overriding with Props, but it is important to remember that Props are also serialized over the network. If you provide a function value in a Prop, that function will be run on the server immediately as it is replicated, and only its return value will be sent to clients. Sending function values as Props in replicated Auras should be avoided.
