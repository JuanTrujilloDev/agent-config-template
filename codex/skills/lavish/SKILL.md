---
name: lavish
description: "Turn a plan, comparison, diagram, table, or report into a local HTML file the user can annotate in the browser, using pinned lavish-axi. Use when they asked for a visual review, including from a phone over Tailscale. Do not use it to build product UI."
---

# Visual review (lavish)

Pin `lavish-axi@0.1.90`. Do not run `update`.

Use this only for a page the user asked to mark up. Product UI follows this project's design system. Do not paste the lavish Tailwind or DaisyUI CDN snippet into the app.

## Command

```sh
LAVISH_AXI_TELEMETRY=0 npx -y lavish-axi@0.1.90 <file>
```

Leave `LAVISH_AXI_HOST` unset. Do not set it to `0.0.0.0` or `::`. When Tailscale is logged in, the CLI also binds the tailnet address and prints a MagicDNS link. The server has no password. Stop it when the review ends:

```sh
LAVISH_AXI_TELEMETRY=0 npx -y lavish-axi@0.1.90 stop
```

## Where the HTML goes

Write it outside this repository, never beside `.env` or other secrets. The review server can read every file in the HTML file's directory, including dotfiles.

## Do not

- `share` (that uploads the page publicly)
- `setup hooks` or `setup plugin`
- `poll`, except in the thread that is waiting on the user's marks

If Tailscale is logged out and the user is not at this machine, send the page as markdown instead of starting the server.
