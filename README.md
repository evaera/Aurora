Current Status: Active work in progress, do not use yet.

# Aurora

**Aurora** is a library that can manage status Effects (known as "Auras") in your Roblox game.

Using Aurora can help you stay sane while managing complex game state when multiple parts of your game need to keep track or change the same resource.

## Example use case

A classic example of the problem that Aurora aims to solve is changing the player's walk speed. Let's say you have a heavy weapon that you want to slow the player down when he equips it. That's easy enough, you just set the walk speed when the weapon is equipped, and set it back to default when the weapon is unequiped.

But, what if you want something else to change the player's walk speed as well, potentially at the same time? For example, in addition to the heavy weapon, say the player could equip a shield which also slows them down a bit. If we follow the same flow as when we implemented the logic for the heavy weapon above, we now have a problem: The player can equip both the heavy weapon and the shield, and then unequip the heavy weapon. Now, the player can walk around at full speed with a shield up, when they should still be slowed!

One may try to solve this problem a few ways...
- Manually checking if the player has a shield held up in the unequip logic of the heavy weapon and vice-versa for the shield.
  - This works for now, but as soon as you add more types of weapons or game mechanics that need to change the player's speed, it quickly becomes infeasible.
- Don't change the walk speed if it's already changed by something else.
  - This actually just inverts the problem we already had: instead of the player being able to use the first-equipped item at full speed, they can use the second-equipped item at full speed by just unequipping the first.
- Remember the current walk speed when equipping and restore it when unequipping:
  - This only works if the player unequips items in the reverse order than they equipped them. Otherwise, it's easy for the player to get stuck in a lower-than-normal walk speed. This method also doesn't play nicely with Effects that would slow the player down that aren't directly tied to equipping items.

Aurora solves this problem correctly by allowing you to apply a movement speed Aura from each of your equipped items. Each Aura would then provide a movement-speed altering *Effect*, each of which can have different intensities. Then, every update cycle, Aurora will group all similar *Effects*, and feed all of their values into a reducer function. In this case, the function will find the lowest value from all of the Effects, and then set the player's WalkSpeed to that number.

Now, there is only one source of truth for the player's WalkSpeed, which solves all of our problems. When there are no longer any Auras that provide the walk speed Effect, Aurora will clean up by setting the player's walk speed back to default.

Of course, this is only one example of what Aurora can be used for. Auras can be used for tracking player state (such as marking a player as "infected" in a zombie game), modifying combat values (such as +10% damage), and as a means of communicating modifiers to the player directly (by directly displaying what Auras a player has on their screen).

## Library

`The main library API goes here...`

## Agents

An Agent is an object that keeps track of Auras and Effects on behalf of the Instance that it is linked to. When it comes time to apply, remove, or otherwise alter the Auras that are applied to a specific Instance, you do so through its Agent. Each Instance will only ever have one Agent, and the Aurora library will be sure to keep track of this for you and always return the same one when called on the same Instance.

Agents also handle updating the state of each Aura attached to it, which happens every update cycle. The frequency of the update cycle is configurable by the developer.

`Agent methods go here...`

Agents provide the following events for when the Auras it contains change:

`List of Agent events goes here...`

## Auras

Auras can be applied to any Instance (e.g. a Player, a player's Character, or an NPC). Auras hold information such as duration and number of stacks (if an Aura is stackable, that means that if the same Aura already exists when it is applied once more, the existing Aura will simply gain another "stack"), and user-facing information such as title, description, and icons. Auras are only optionally replicated to the client, and also optionally directly displayed to the player.

`Aura API goes here...`

Auras also have "Hooks", which are lifecycle methods directly attached to a specific Aura, rather than an Effect. Hooks could be used for things like playing a specific sound when the Aura is applied or removed or showing a notice on a player's screen. However, they shouldn't be used to modify the game world.

`List of hooks goes here...`

## Effects 

Auras can provide Effects (with various parameters), which are used to actually make changes to the world. Effects are explicitly defined by the developer just like Auras. Unlike Auras, however, an Effect can only exist once per Agent, and they are automatically created and destroyed based on what Effects are provided by the current set of Auras.

Effects are made up of three functions: a `constructor`, a `destructor`, and a `reducer`.

- The `constructor` is called whenever one of the Auras starts providing this Effect. It can be used to create any necessary objects needed to enact or display this Effect.
  - For example, if you want to display a "dizzy" indicator above a player when they are stunned, this function could create that and put it inside the character.
- The `reducer` is called every update cycle, and takes in any parameters given by Auras which are providing this Effect. It is then the reducer's job to determine what changes to make to the world state.
- The `destructor` is called when there are no longer any Auras providing this Effect. It can be used to clean up any objects that were created in the constructor.

## Replication

`Server/client stuff goes here...`

## Next

- get networking done
- consider organizing data / display properties
- test hooks
- figure out what else needs done