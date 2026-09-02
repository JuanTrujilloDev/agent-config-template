# Game patterns — Unity-style component engines

Read this only when `.claude/rules/patterns.md` routed a gameplay/engine force
here. Every row's *simplest alternative* is tried before the pattern is named.

| Force | Pattern | Simplest alternative |
|---|---|---|
| Entities share behaviors in different combinations (a door that is also damageable) | Component composition | One script on the object |
| Designers tune values or author content without code changes | ScriptableObject data assets | Serialized fields on the component |
| Many short-lived objects (bullets, particles, popups) cause allocation spikes | Object pooling | Instantiate/Destroy, measured first |
| An entity has ≥4 behavioral states with transition rules (idle/patrol/chase/attack/stunned) | State machine | An enum + `switch` in `Update` |
| Many unrelated systems react to one gameplay event | Event bus / signals | A direct reference and a method call |
| Frame time exceeds budget from per-frame work | Update-loop budgeting (tick groups, spreading, jobs) | Do less in `Update`; cache lookups |

## Simplest default first

1. One component with serialized fields before a component graph.
2. Serialized fields before ScriptableObjects; ScriptableObjects before a custom data pipeline.
3. Instantiate/Destroy before pooling — pool only what the profiler shows.
4. An enum and a `switch` before a state-machine class hierarchy.
5. A direct reference before an event bus; an event bus before a global static event.

## When each earns its keep / when it is a smell

**Component composition over inheritance.** Earns its keep as soon as two
entities need overlapping-but-different behavior sets: `Health`, `Damageable`,
`Interactable` as separate components combined per prefab. Smell: an inheritance
tree (`Enemy → FlyingEnemy → FlyingBossEnemy`) where the third level exists to
turn one behavior off; a component per field.

**ScriptableObject data.** Earns its keep when the same tuning (weapon stats,
enemy definitions, dialog) is shared across prefabs or edited by designers
independently of scenes. Smell: a ScriptableObject for a single-use value; runtime
mutable state stored in a shared asset (it leaks across play sessions in the editor).

**Object pooling.** Earns its keep when the profiler shows GC spikes or
instantiate cost from many short-lived objects. Reset state on return; size the
pool from measured peaks. Smell: pooling everything by policy; pooled objects that
keep stale references or subscriptions.

**State machines.** Earn their keep when transitions have guards and enter/exit
work (play animation, reset timers) and the enum `switch` has grown side tables.
Smell: a state-machine framework for a two-state door; states that know about
every other state.

**Event bus vs direct references.** A direct reference earns its keep when the
listener is one known object (UI reading the player's health). A bus earns its
keep when many unrelated systems react (achievements, audio, analytics) and none
should know the others. Smell: a bus for one subscriber; events with no
unsubscribe, leaking across scene loads; game logic driven by string-named events.

**Update-loop budgeting.** Earns its keep when frame time is measured over
budget: move work to fixed ticks or coroutines, spread expensive scans across
frames, cache `GetComponent`/`Find` results, use jobs for parallel data work.
Smell: optimizing before profiling; `Find*` or allocation in `Update`.

## Domain anti-patterns

- **Deep inheritance for behavior.** Composition is the engine's native model; use it.
- **Singleton managers everywhere.** `GameManager.Instance` reached from every script; pass references or use a small service object owned by the scene.
- **Mutable ScriptableObjects as runtime state.** Data assets that change during play.
- **String-driven logic.** Tags, animator parameters, and events referenced by raw strings scattered across scripts.
- **Allocation in the hot loop.** LINQ, string concatenation, boxing, or `new` in `Update`.
- **Physics in `Update`.** Movement and forces outside `FixedUpdate`.
