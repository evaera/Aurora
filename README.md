# Aurora

**Aurora** is a library that can manage status Effects (known as "Auras") in your Roblox game.

Using Aurora can help you stay sane while managing complex game state when multiple parts of your game need to keep track or change the same resource.

## Example use case

A classic example of the problem that Aurora aims to solve is changing the player's walk speed. Let's say you have a heavy weapon that you want to slow the player down when he equips it. That's easy enough, you just set the walk speed when the weapon is equipped, and set it back to default when the weapon is unequiped.

But, what if you want something else to change the player's walk speed as well, potentially at the same time? For example, in addition to the heavy weapon, say the player could equip a shield which also slows them down a bit. If we follow the same flow as when we implemented the logic for the heavy weapon above, we now have a problem: The player can equip both the heavy weapon and the shield, and then unequip the heavy weapon. Now, the player can walk around at full speed with a shield up, when they should still be slowed!

Aurora solves this problem correctly by allowing you to apply a movement speed Aura from each of your equipped items. Each Aura would then provide a movement-speed altering *Effect*, each of which can have different intensities. Then, every update cycle, Aurora will group all similar *Effects*, and feed all of their values into a reducer function. In this case, the function will find the lowest value from all of the Effects, and then set the player's WalkSpeed to that number.

Now, there is only one source of truth for the player's WalkSpeed, which solves all of our problems. When there are no longer any Auras that provide the walk speed Effect, Aurora will clean up by setting the player's walk speed back to default.

Of course, this is only one example of what Aurora can be used for. Auras can be used for tracking player state (such as marking a player as "infected" in a zombie game), modifying combat values (such as +10% damage), and as a means of communicating modifiers to the player directly (by directly displaying what Auras a player has on their screen).

## House rules

- All properties should always be treated as **read-only**. There is nothing in the library stopping you from changing a property, but you may experience unexpected or unwanted behavior if you do, and your code may be broken by future releases.
- Classes have more methods and properties than are documented in this file, but they should serve no significant purpose to the end developer. If you use undocumented members, you may experience unexpected behavior and your code may be broken by future releases.

## Library

The main Aurora library provides access to Agents, registering custom containers for your Auras and Effects, and changing global settings.

Note that these methods must be called from both your client and server code. Calling a method from this main library on the server will not change anything on the client, and vice-versa. (This is not the case for Agent methods, which are mirrored on clients.)

### Methods
#### Aurora.GetAgent(instance: Instance): Agent
Returns the Agent for the given instance. Each instance will only ever have one Agent, and this method will keep track of created Agents. 

* If the previous Agent is Destroyed, either manually or due to configured settings, then a new one will be created.

#### Aurora.RegisterAurasIn(instance: Instance): void
Registers the given instance as a container where ModuleScripts returning Aura definitions are kept. 

##### Structure and search strategy
The ModuleScript must have the same name as the Aura. Auras are lazy-loaded: the first time an aura is applied, it is matched with a recursive `FindFirstChild` call for every registered Aura container until it's found, and then it is cached. Feel free to nest folders organizing your auras, but be aware that *folder names* must also be unique with all module names. If a non-ModuleScript instance is returned from that root, then it will be discarded and will continue searching in other roots (if there are any).

##### Server shadowing
ModuleScripts under the container with an Aura name affixed with "Server" (case-sensitive) will also be automatically loaded and its top-level section keys will be applied *on top of* the table members exported by the base Aura ModuleScript. This optional feature is only active on the server; even if a "Server"-affixed module is replicated to the client, it will not be loaded.

#### Aurora.RegisterEffectsIn(instance: Instance): void
See *RegisterAurasIn* just above. Everything is exactly the same. Except, of course, that ModuleScripts inside these containers must export Effects, not Auras.

#### Aurora.SetTickRate(seconds: number): void
Sets how often, in seconds, that all Auras and Effects will be updated. "Updating" in this context refers to lowering remaining duration on Auras, removing expired Auras, and most importantly calling the "Reducer" method on Effects.

The default value is `0.5` seconds.

#### Aurora.SetMaxAgentTimeInactive(seconds: number): void
Sets how long, in seconds, that an Agent can exist without any Auras before it is automatically destroyed on the next update cycle. You should set this if you intend to have a large number of instances with Auras that remain in the game world for a long time. This feature will make the inital Aurora snapshot sent to newly joined players less expensive, make the update cycle slightly less expensive, and free up memory.

This is a potentially dangerous feature. If enabled, then you must take care to always call `Aurora.GetAgent` after your code yields (WaitForChild, wait, even listeners, etc). If you hold on to a reference to an old agent, then in addition to leaking memory, your code will error because you can't call methods on destroyed Agents.

The default value is `math.huge` (disabled).

#### Aurora.SetSafeMemoryMode(isSafeMode: boolean): void
Under "Safe Memory Mode", if an Agent's associated Instance is not a descendant of the DataModel (`game`, or the *game tree*) then that Agent will be automatically destroyed so as to prevent memory leaks.

Agents being attached to an instance *will* prevent that instance from being garbage collected automatically if it's just detached from the game tree (parent set to `nil`). However, if the instance (or an ancestor of that instance) is destroyed, then the Agent and instance will be correctly garbage collected, even if "Safe Memory Mode" is off.

This is an important consideration, because not all instances are destroyed automatically when they are removed, chiefly player characters, which are not destroyed when the player dies or leaves the game. This means that if "Safe Memory Mode" is off, and you attach Auras to the character, then that character will exist in memory forever even after the player dies and gets a new character.

If you are willing to take on the responsibility of ensuring everything you attach Auras to are properly destroyed (e.g. destroying characters after the player dies manually), then it's safe to turn this off. Otherwise, for most applications it's safer to keep this at the default (on).

### Properties
#### Aurora.TickRate: number
The current update cycle tick rate; see *SetTickRate*.

#### Aurora.MaxAgentTimeInactive: number
The current maximum time an Agent may be inactive before being destroyed, see *SetMaxAgentTimeInactive*.

#### Aurora.SafeMemoryMode: boolean
Whether or not "Safe Memory Mode" is enabled, see *SetSafeMemoryMode*.

#### Aurora.InitialSyncCompleted: boolean
When a player first joins a server, a *snapshot* of every replicated Aura on every Agent is created and sent to that player. The client will then re-create the Agents and Auras it received. After this process has been completed, `InitialSyncCompleted` will be `true`. On the server, it is always `true`.

## Agents

An Agent is an object that keeps track of Auras and Effects on behalf of the Instance that it is linked to. When it comes time to apply, remove, or otherwise alter the Auras that are applied to a specific Instance, you do so through its Agent. Each Instance will only ever have one Agent, and the Aurora library will be sure to keep track of this for you and always return the same one when called on the same Instance.

Agents also handle updating the state of each Aura attached to it, which happens every update cycle. The frequency of the update cycle is configurable by the developer.

### Methods
#### Agent:Apply(auraName: string, props?: dictionary): boolean
Creates a new Aura of the given name under this Agent. Because Auras are lazy-loaded, this method call will be the first time your Aura definition is validated. If the given aura is defined as being replicated, then this method will also mirror over to all clients.

##### Props
`props` is an optional table dictionary, in which you can override properties from the Aura definition. *Props* must always contain at least one sub-dictionary, because Aura definitions are split into several section dictionaries, as can be seen under *Auras* below. Only the section properties you list here explicitly will be overridden; section properties you omit from Props will still fall back to the section properties from the definition.

These custom Props will also be sent to clients to ensure proper replication. You can use Props to override any or all sections, but you must take care when it comes to using function values here. Function values, as in normal definitions, are valid, but because functions are not serializable, any functions that appear in Props will be called immediately and their static return values will be sent to the clients. Functions will continue to be called on-the-fly on the server.

The `Effects` section is an exception to this system. If `Effects` is included as a Prop then that table will completely replace the `Effects` table from the definition, they will not be merged as with other sections. It is recommended to not override the `Effects` section, but rather override properties in the `Params` section, and then have your Effects in your Aura Definition be dynamic based on values from the Params. This can be seen in action under "Auras" below.

* Note: Snapshot serialization currently acts differently from mirror serialization; snapshot serialization works per-section, whereas if an Aura is applied when a client is already connected it works per-property. This will definitely be changed to be per-property in the future so that there are no disagreements between clients.

##### Stacks and refreshes
If an Aura is stackable and isn't at its `MaxStacks` value, then a new stack will be added to this Aura. This will fire the "AuraStackAdded" event instead of "AuraAdded". If the `ShouldAuraRefresh` property is true, then the old Aura is replaced with the new one (which implicitly also resets the duration to full). If `ShoudlAuraRefresh` is false, then the old Aura is retained (which implicitly retains the same duration).

If an Aura is not stackable, or if it is already at maximum stacks, it will instead "refresh" the Aura if it is allowed. This means that the old Aura is replaced with the new one, and the "AuraRefreshed" event will be fired instead of "AuraAdded".

If an Aura is not stackable, or if it's already at maximum stacks, and `ShouldAuraRefresh` is false, then nothing will happen, and the method will return `false`. Under all other circumstances, `true` will be returned.

#### Agent:Remove(auraName: string, reason?: string): boolean
Removes the Aura of the given name from this Agent. If the given aura is defined as being replicated, then this method will also mirror over to all clients.

`reason` is optional, and is sent along with the "AuraRemoved" event and hook. By default, the reason is `"REMOVED"` (unless the Aura is removed automatically due to expiration, in which case it is `"EXPIRED"`).

Returns `true` if an Aura was actually removed, `false` if nothing happened because the Aura didn't exist on this Agent.

#### Agent:Has(auraName: string): boolean
Returns `true` if an Aura of the given name is currently applied to this Agent, `false` otherwise.

#### Agent:Get(auraName: string): Aura
Returns the Aura of the given name if it's currently applied to this Agent, `nil` otherwise.

Do not store the return value from this method for long, because Auras can be created and destroyed quickly. Storing this value or trapping it in a closure will cause memory leaks.

#### Agent:GetAuras(): array<Aura>
Returns an array of all Auras currently applied to this Agent.

Do not store the return values from this method for long, because Auras can be created and destroyed quickly. Storing these values or trapping them in a closure will cause memory leaks.

#### Agent:Destroy(): void
Destroys this Agent, rendering it unusable. All events will be disconnected, Effects will be deconstructed, Auras will be removed, it will no longer be updated or kept in memory internally, and calling any further methods on this Agent will raise an error.

### Properties
#### Agent.Instance: Instance
The instance that this Agent is attached to. 

#### Agent.Instance: Instance

### Events

#### AuraAdded (aura: Aura)
#### AuraRemoved (auraName: string)
#### AuraRefreshed (newAura: Aura, oldAura: Aura)
#### AuraStackAdded (aura: Aura)
#### AuraStackRemoved (aura: Aura)

## Auras

Auras can be applied to any Instance (e.g. a Player, a player's Character, or an NPC). Auras hold information such as duration and number of stacks (if an Aura is stackable, that means that if the same Aura already exists when it is applied once more, the existing Aura will simply gain another "stack"), and user-facing information such as title, description, and icons. Auras are only optionally replicated to the client, and also optionally directly displayed to the player.

### Definition

Auras have a "definition", which is a ModuleScript that returns a table containing known properties. You should put your Auras in a folder (nesting allowed), and then call `Aurora.RegisterAurasIn` with the folder. See *RegisterAurasIn* for more details on how the matching process works.

In Aura and Effect definitions, every property value is expected to be a static (serializable) value. In every case, a function is also acceptable in place of a value, but the function must **never yield**, must **have no side effects**, and **return the expected type** for the property. The function is passed one argument, which is the Aura itself.

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
  };

  Status = {
    Duration = function (self)
      return self.Stacks * 5 -- Increase duration with stacks
    end;
    Visible = true;
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

### Properties

Aura properties are all loaded from the Aura definition, overshadowed by any Props specific to this Aura.

#### Aura.Display: dictionary
A dictionary where you could include display-related properties such as:

- Title
- Description
- Icon

#### Aura.Params: dictionary
An optional dictionary where you should include any parameters for effects (for example, for an Aura/Effect that increased movement speed, a good property for the Params section would be "Speed")

#### Aura.Effects: dictionary
A dictionary containing the Effect values/functions for this Aura.

#### Aura.Status: dictionary
A dictionary containing the state used by Aurora internally (which can also be referenced by your own code)

#### Aura.Status.Duration: number
The number of seconds remaining on this Aura.

#### Aura.Status.Stacks: number
The number of stacks that this Aura has. This always starts at `1`, even for unstackable Auras.

#### Aura.Status.Visible?: boolean
Whether or not this Aura should be visible to the player (such as on a UI)

#### Aura.Status.Replicated?: boolean
If true, this Aura will be sent to all clients. Otherwise, it will only exist on the server.

#### Aura.Status.MaxStacks?: number
The maximum number of stacks this Aura can reach.

#### Aura.Status.ShouldAuraRefresh?: boolean
Whether or not this Aura is allowed to refresh its duration when a new stack is applied (or if unstackable, when it is applied again).

### Hooks

Auras also have "Hooks", which are lifecycle methods directly attached to a specific Aura, rather than an Effect. Hooks could be used for things like playing a specific sound when the Aura is applied or removed or showing a notice on a player's screen. However, they shouldn't be used to modify the game world.

Note: Hooks do not fire during the initial world snapshot playback when a player joins the game, so that the player is not flooded with messages and/or sounds.

#### AuraAdded
#### AuraRemoved
#### AuraRefreshed
#### AuraStackAdded
#### AuraStackRemoved

## Effects 

Auras can provide Effects (with various parameters), which are used to actually make changes to the world. Effects are explicitly defined by the developer just like Auras. Unlike Auras, however, an Effect can only exist once per Agent, and they are automatically created and destroyed based on what Effects are provided by the current set of Auras.

Effects are made up of three functions: a `Constructor`, a `Destructor`, and a `Reducer`.

- The `Constructor` is called whenever one of the Auras starts providing this Effect. It can be used to create any necessary objects needed to enact or display this Effect.
  - For example, if you want to display a "dizzy" indicator above a player when they are stunned, this function could create that and put it inside the character.
- The `Reducer` is called every update cycle, and takes in any parameters given by Auras which are providing this Effect. It is then the Reducer's job to determine what changes to make to the world state.
- The `Destructor` is called when there are no longer any Auras providing this Effect. It can be used to clean up any objects that were created in the Constructor.

### Definition

```lua
return {
  -- Optional, limit the types of instances that this effect can be applied to.
  -- Aurora will produce a warning if an effect is applied to an improper instance
  -- type, and the effect wil be discarded.
  -- Uses :IsA comparison.
  AllowedInstanceTypes = {"Humanoid"};

  Constructor = function (self) -- self is the Effect, not the Aura.
    -- For example, add a special part to the character
    -- (Not welded for the sake of example)
    self.SpecialEffectPart = game.ReplicatedStorage.Part:Clone()

    -- self.Instance is set to the Agent's Instance property.
    self.SpecialEffectPart.Parent = self.Instance.Parent
  end;

  -- This function is called every update cycle for as long as the Effect is
  -- active on this Agent.
  Reducer = function (self, values)
    -- `values` is an array containing the resolved value from every Aura that
    -- is providing this Effect. Here, we need to take all of these values and
    -- then *reduce* them down into a change we make into the world.

    local walkSpeed = math.huge

    for _, maxSpeed in ipairs(values) do
      if maxSpeed < walkSpeed then
        walkSpeed = maxSpeed
      end
    end

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

## Replication

When a player joins the game, a snapshot of every `Status.Replicated` Aura from every Agent on the server is created, serialized, and sent to the player. The player then re-creates the entire world state on their end.

Once a player is connected, all changes (Auras being applied or removed) to replicated Auras are mirrored to all clients in the game. Each client runs its own version of the world, decreasing duration on Auras and updating effects.

All mirrored messages are played back on the client in order. There is a message buffer in the client network system that will hold onto messages that arrive out of order and play them all back correctly so that the server and client should always agree on the world state.

You cannot `Apply` or `Remove` any Auras from the client, and attempting to do so will result in an error. Similarly, the client will never remove any Auras when they expire, instead it waits for the server to mirror the Remove message back to the client.

A mechanism for the client to request an Aura to be cancelled will be implemented at some point.

The ability to restrict Aura replication to specific players is also forthcoming.