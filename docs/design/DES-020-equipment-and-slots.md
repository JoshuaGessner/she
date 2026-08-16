---
id: DES-020
title: Equipment & Gear Slots
status: accepted
owner: design
tags: [equipment, gear, slots, inventory, visual, first-person]
updated: 2026-08-16
related: [DES-008, DES-009, DES-019, ART-004, ART-005, TEC-006]
---

# Equipment & Gear Slots

Every other document referenced "slots" and none of them defined the list. This is that list, and it doubles as the spec for **what gear looks like on you** — the two questions turn out to be the same one.

---

## First, a reconciliation

`DES-008` is firm that **gear is sidegrades with pronounced identity, not a rarity ladder.** No green→blue→purple, no +12% tiers. That is what keeps late runs from trivialising.

So what does *"better gear"* mean, and what is the player watching improve?

> **Better means more appropriate, better preserved, and better provenance — never bigger numbers.**

A Dvergar king's mail is *extraordinary* to look at and is still a **sidegrade** to a good leather coat: heavier, louder, better against pierce, worse for a Veiðimaðr. The visual progression is real and satisfying, and it tracks **where you have been rather than how strong you are** — exactly like the trophies in `DES-016`.

That is a better fantasy than a stat ladder anyway. Your gear becomes a *record*.

---

## The slots

Six. Deliberately few — every slot multiplies against every armour set in art cost.

| Slot | Holds | Seen by you (FP) | Seen by teammates |
|---|---|---|---|
| **Main hand** | Weapon, tool | ✅ constantly | ✅ |
| **Off hand** | Shield · lantern · map · compass · second weapon | ✅ constantly | ✅ |
| **Arms** | Bracers, gauntlets, gloves | ✅ **the only armour you ever see on yourself** | ✅ |
| **Head** | Helm, hood, mask | ❌ | ✅ |
| **Body** | Torso **and** legs, one piece | ❌ | ✅ |
| **Pack** | Bag, satchel, frame | ❌ | ✅ |

**No trinket or charm slots.** `DES-009` already rejected a stat block because Aspects plus gear cover build identity, and a third axis makes balance materially harder. Trinkets would be that third axis wearing a different hat.

### Why Body is one piece

Torso and legs as a single slot **halves the armour mesh count** for a difference stylised low-poly barely registers. This is the single largest art saving available in the equipment system, and it costs almost nothing in expressiveness.

### The Pack slot is the greed enabler

Your bag is **equipment**, and it is the most interesting armour slot in the game:

- It sets your **inventory grid size** (`DES-019`).
- Bigger pack → more grid → more weight → more Clamor. **The upgrade that makes you more powerful is the upgrade that makes you louder.**
- It is visible on your back, so **teammates can see who is hauling** — *"you're the loud one"* becomes a thing you can read across a room, not just off the party frame.

That is Pillar P1 expressed as a piece of gear.

### The off hand is the contested space

The economy `DES-019` already designed lives here: **shield, lantern, map, and compass all compete for one hand.**

- **Two-handed weapons occupy both slots** — no lantern, no shield, no map without stowing.
- Everything not equipped lives in the bag; **raising a tool takes time and leaves you vulnerable** (`DES-019` — no pause).
- A player with a lantern in the off hand is lit, visible, and one-handed. A player with a shield is blind in the dark.

---

## How gear looks — and where the arms question lands

> **DECIDED (ADR-056):** Shared skeleton, shared animation set, **per-class bare arms**, and **all armour is visible.**

### The layering

1. **Bare arms are per-class** — six meshes, one per class. Húskarl's scarred forearms, Völva's inked hands and bone charms, Skald's stained fingers, Úlfheðinn's fur wraps, Veiðimaðr's taped draw-fingers, Haugbrjótr's grave-dirt and wrist tools.
2. **The Arms slot renders over them.** Equip bracers and you see bracers; strip them and the class shows through.
3. **All six classes share one skeleton and one animation set** (`ART-004`) — so every armour mesh, once made, works for everyone.

**This is the cheap version of an expensive-feeling system.** The costly part of first-person arms is animation, and we author it once.

### The rule that keeps first-person cost bounded

> **Body armour stops at the elbow. The Arms slot owns everything below it.**

Because of that, **only the Arms slot ever needs a first-person mesh variant.** Head, Body, and Pack are never in your own view, so they need one full-body mesh each and nothing more.

Without this rule, every chest piece would need an FP sleeve variant and the armour budget would roughly double. With it, the first-person art cost is bounded to a single slot — the one that most rewards the attention anyway.

### One mesh, two views

Armour is **skinned to the shared skeleton and rendered in both views.** Teammates see your full silhouette in third person (`DES-012`); you see your own forearms. No separate third-person art.

### Condition is visible

`DES-008` makes durability *degrading identity* rather than breakage. Show it: worn gear reads as worn. Under the ink shader (`ART-005`) that is line roughness and hatch density rather than texture work — **near-free, and it means a glance at your own hands tells you how the run is going.**

---

## Rig attachment spec (ADR-057)

**Decided now, because adding a socket later means re-exporting every mesh on the rig.**

The distinction that matters: **skinned meshes deform with the body; socketed meshes are rigid and ride a bone.**

| Slot | Method | Bone / socket |
|---|---|---|
| **Body** | **Skinned** — deforms with torso and legs | — |
| **Arms** | **Skinned** — deforms with the forearm | — |
| **Head** | Socket | `sock_head` |
| **Main hand** | Socket | `sock_hand_r` |
| **Off hand** | Socket | `sock_hand_l` |
| **Pack** | Socket | `sock_back` |
| *Stowed weapon* | Socket | `sock_hip_r` |
| *Stowed shield / second tool* | Socket | `sock_hip_l` |
| *Cloak / mantle (reserved)* | Socket | `sock_shoulders` |

**The two hip sockets are the cheap win.** A weapon you are not holding is **visible stowed on your hip**, so in co-op you can see at a glance that someone is carrying a hammer and a lantern rather than a spear. Readable party composition for the price of two bones and a transform.

`sock_shoulders` is reserved unused — costs nothing now, and prevents a re-export if a cloak ever happens.

**All sockets are authored on the shared humanoid rig before any character work begins** (`ART-004`).

### Why real bones, and not the reason first given (ADR-081)

ADR-057 justified authoring sockets up front with *"adding one later means re-exporting every mesh."* **That is not true in Godot.** `BoneAttachment3D` tracks any named bone at an arbitrary offset, added engine-side, without touching a source file — a socket genuinely can be bolted on years later.

The conclusion survives on a better argument: **armour is authored against the rig.** A modeller building a pack needs to see where `sock_back` actually lands while they work. As a bone they can; as an offset buried in a `.tscn` they are guessing, and every pack after the first inherits that guess. The cost of getting it wrong is not a re-export — it is a gear library that sits subtly wrong and nobody can say why.

Recorded because *a rule defended by a false reason gets discarded the first time somebody checks it.*

### The camera is never parented to `sock_head`

`sock_head` exists for helms. **The first-person camera stays an independent node**, driven by the rig only where deliberately chosen.

`DES-009` bans head bob at M1 and restricts camera shake to positional kick, explicitly because *"rotational screen shake in first person causes motion sickness"* — and `DES-018` makes shake, blur, head-bob and FOV independently adjustable. A camera parented to an animated head bone inherits **every rotation an animator authors, permanently**, and there is no per-effect opt-out. That single parenting decision would quietly override an accessibility guarantee.

### Socket orientation is one convention, fixed here

> **Every socket's −Z points the way the held object points; +Y is the object's up.**

Godot is Y-up, −Z forward. A weapon authored pointing +Y into a socket facing −Z is correct in Blender and ninety degrees wrong in game — and that is invisible until the whole weapon set exists. One line now, or a re-export of every weapon later.

### The off hand holds four unrelated things, and the offset is item data

`sock_hand_l` must carry a shield, a lantern, a map and a compass. A shield straps to the forearm, a lantern hangs from a grip, a map is held open in the palm; no single transform flatters all four.

**The socket stays single, and each item carries its own offset in its `.tres`.** That makes grip a property of the object rather than of the skeleton — tunable per item, by a designer, without touching the rig every other slot depends on.

## Art requirements this creates (`ART-004`)

- **Attachment sockets on the shared rig for all six slots**, defined once, before any character work. Adding a socket later means re-exporting every mesh that uses the rig.
- **Six bare-arm meshes** — class identity, Phase 2.
- **Per armour set: 4 meshes** (arms, head, body, pack). Not 5, and not doubled for first person.
- **Silhouette carries everything.** Under a near-monochrome ink shader the difference between leather and plate is *shape and line*, not texture — which makes armour both cheaper to author and more important to get right in form.

## Data (`TEC-006`)

Slots are a `WearableTrait` field, so nothing here needs new schema:

```gdscript
@export var slot: Slot                 # MAIN_HAND, OFF_HAND, ARMS, HEAD, BODY, PACK
@export var armour_class: ArmourClass  # UNARMOURED, MAILED, PLATED
@export var mesh: PackedScene
@export var grid_size: Vector2i        # PACK only — sets inventory dimensions
@export var two_handed: bool           # MAIN_HAND only — blocks OFF_HAND
```

## Open questions

> **DECIDED (ADR-057):** **Off-hand swapping is mid-run, slow, and interruptible.** You kneel or stow, it takes real time, and you are vulnerable throughout — the same rule as opening your bag (`DES-019`). Without the time cost the lantern-versus-shield tension evaporates entirely, because you would simply carry both and swap freely.

> **DECIDED (ADR-057):** **There is a *no pack* option.** Nothing on your back: tiny grid, minimal weight, near-silent. Almost free to build since it is the *absence* of a mesh, and it makes a genuine playstyle — *I came for one thing* — available to any class, not just the Veiðimaðr. It is also the purest possible expression of refusing the greed loop.

> **DECIDED (ADR-057):** **Rites visibly change your bare arms.** A mesh swap at two or three Rite thresholds — the Úlfheðinn's arms becoming more wolf, the Völva's ink spreading, the Haugbrjótr's hands more grave-stained. Cheap, and it is **non-numeric progression you can see on your own body**, which `DES-022` flags as the main mitigation for horizontal progression feeling flat.
