# Unity game preset

`project_type=game` renders the `game-dev` agent (frame-budget/serialization/
god-object gotchas) plus `ui-designer`; web-only pieces are dropped automatically.
Test/build commands assume the Unity CLI — adjust to your editor version and CI.

```bash
cp examples/unity-game/answers.env ./answers.env
./setup.sh --target /path/to/game --answers ./answers.env
```
