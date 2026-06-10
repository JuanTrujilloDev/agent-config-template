# Flutter mobile app preset

`project_type=mobile-app` renders the `mobile-dev` agent (offline/lifecycle/platform
gotchas) plus `ui-designer`; the web-only pieces (`backend-dev`, `frontend-dev`,
layer split, Playwright) are dropped automatically.

```bash
cp examples/flutter-mobile/answers.env ./answers.env
./setup.sh --target /path/to/app --answers ./answers.env
```
