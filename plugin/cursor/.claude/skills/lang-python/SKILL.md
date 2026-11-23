---
name: lang-python
description: "Python written well anywhere: data shapes, enums, typing, querysets, exceptions, time. Loaded when reading or editing a .py file, next to the project's backend-style skill; it never repeats the project's formatting or layout rules."
paths: ["**/*.py"]
---

# lang-python

How Python is written well in any project. Formatting, file layout and test style are the project's (`backend-style`, `.claude/rules/architecture-map.md`); Deslop is in the principles. Where the project's code already does it differently, the project wins.

| Rule | Do |
| --- | --- |
| Data shapes | `@dataclass(frozen=True)` or `TypedDict` for a shape that travels; never a dict passed through three functions |
| Enums | `StrEnum` or the framework's choices (`TextChoices`); look up with a dict or `match`, not an if chain |
| Typing | type every public function; `X \| None`, not `Optional[X]`; no `Any` past the boundary that received it |
| Collections | comprehension for a plain map or filter; a loop once it needs a second statement |
| Truthiness | `if items:` for emptiness; `is None` for absence; never `== None` or `len(x) == 0` |
| Querysets | `.exists()` for presence, `.count()` for a number, never `len(qs)`; `select_related` / `prefetch_related` before a loop that touches relations |
| Large sets | `.iterator()` or pagination; never load a table to filter it in Python |
| Exceptions | raise the most specific built-in or domain error; `raise X from error` when translating; never `except Exception` |
| Defaults | no mutable default arguments; `field(default_factory=list)` in dataclasses |
| Time | `timezone.now()` or `datetime.now(tz=UTC)`; never a naive `datetime.now()` |
| Money and quantities | `Decimal` built from a string, never from a float |
| Paths and files | `pathlib.Path`; `with open(...)` with an explicit `encoding` |
| Strings | f-strings; `str.removeprefix` / `removesuffix` over slicing |
| Imports | absolute, at the top; no import inside a function to dodge a cycle: fix the cycle |
