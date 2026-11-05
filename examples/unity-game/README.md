# Unity game preset

`project_type=game` renders `ui-designer`, the design system and the game pattern
references (frame budgets, serialization, pooling); web-only pieces are dropped automatically.
Test/build commands assume the Unity CLI — adjust to your editor version and CI.

```bash
cp examples/unity-game/answers.env ./answers.env
./setup.sh --target /path/to/game --answers ./answers.env
```
