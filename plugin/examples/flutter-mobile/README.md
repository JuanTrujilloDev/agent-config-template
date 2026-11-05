# Flutter mobile app preset

`project_type=mobile-app` renders `ui-designer`, the design system and the mobile
pattern references (offline, lifecycle, platform bridges); web-only pieces
(the `frontend-style` skill, Playwright) are dropped automatically.

```bash
cp examples/flutter-mobile/answers.env ./answers.env
./setup.sh --target /path/to/app --answers ./answers.env
```
