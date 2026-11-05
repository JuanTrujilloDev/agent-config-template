# Desktop patterns — application structure

Read this only when `.claude/rules/patterns.md` routed a desktop force here.
Every row's *simplest alternative* is tried before the pattern is named.

| Force | Pattern | Simplest alternative |
|---|---|---|
| View logic must be testable without the UI toolkit, or one model feeds several views | MVVM / MVC | Handlers on the view with a plain model object |
| Users expect undo/redo, macros, or an action history | Command pattern | Direct mutation, when undo is not a requirement |
| Several windows/views edit one file's contents and must stay consistent | Document model (single source of truth + change notification) | One window, one in-memory struct |
| Long or blocking work freezes the UI | Background work off the UI thread | Make the work fast enough; show a busy cursor |
| The same menu action is reachable from menu, toolbar, shortcut, and context menu | Command / action objects | One handler wired to each control |

## Simplest default first

1. A view with handlers and a plain model before any MV* layering.
2. Direct mutation before commands; commands only when undo or replay is a stated requirement.
3. One in-memory document struct before a document model with observers.
4. A synchronous call before a background job — but never a blocking call on the UI thread.
5. The toolkit's built-in action/binding mechanism before a hand-rolled one.

## When each earns its keep / when it is a smell

**MVVM / MVC.** Earns its keep when view logic (enabled states, formatting,
validation) needs unit tests without instantiating widgets, or one model drives
several views. Use the toolkit's native binding flavor. Smell: a view model per
dialog with one field; three layers for a settings pane; a "model" that is a
view model that is a controller.

**Command pattern for undo.** Earns its keep when undo/redo is a requirement:
every user edit becomes a command with `execute`/`undo`, pushed on a history
stack; commands are the only way to mutate the document. Smell: commands with
no undo; a command class for each button when no history exists; undo stacks
that capture whole-document snapshots for every keystroke.

**Document model.** Earns its keep when multiple views (editor, outline,
preview) show one document and must agree: the document is the single source of
truth, views subscribe to change notifications, dirty-tracking and save live in
one place. Smell: each view holding its own copy and syncing; the document
knowing about widgets.

**Background work off the UI thread.** Earns its keep for anything over a few
tens of milliseconds: file I/O, network, indexing, rendering thumbnails. Run it
on a worker, marshal results back to the UI thread, support cancellation, report
progress. Smell: blocking calls in event handlers; touching widgets from a
worker; fire-and-forget tasks with no cancellation when the window closes.

**Command / action objects for shared menu actions.** Earn their keep when one
action has several entry points and a shared enabled state. Smell: an action
object for something reachable from exactly one place.

## Domain anti-patterns

- **Business logic in event handlers.** `onSaveClicked` that validates, transforms, writes, and updates three widgets.
- **UI thread blocked.** Synchronous I/O in the handler; the app "hangs".
- **Cross-thread widget access.** Updating a control from a worker thread.
- **Copies of the document per view.** Views diverge; save writes the wrong one.
- **Undo by snapshot.** Full-document clones on every edit; memory grows without bound.
- **Global application state singleton.** Every window reaches into `App.Instance`; pass the document or a scoped service instead.
