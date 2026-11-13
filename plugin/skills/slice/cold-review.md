# Cold review prompts

Adapted from [google/elephant-goldfish-model](https://github.com/google/elephant-goldfish-model) at commit `270b103` (`skills/egm-review/SKILL.md`, `agents/comprehension.md`, `agents/implementation_readiness.md`), Apache-2.0; notice in `LICENSE-elephant-goldfish-model.txt`. Rewritten and cut to two reviewers, one round, for slice files.

Each reviewer gets the shared preamble, then its own task. Fill in `<ID>`, `<n>` and the repo path; add nothing else.

## Shared preamble

```
You review a plan you have never seen, with no history of the conversation that wrote it. Read only:
- docs/epics/<ID>/epic.md: the approved epic (stories S<n>, acceptance criteria, test scenarios TS<n>)
- docs/epics/<ID>/slices/<n>.md: the slice draft under review
- the repository at <repo path>: check the seams, fixtures and names the slice mentions
Read-only: edit nothing, write no files, run no builds or tests. No praise, no filler, no narration.
You know software; you do not know this project. Flag a term only when it is specific to this project and defined nowhere in these files or the repo.
The slice lists no file paths on purpose; finding the code is not a gap.
```

## Comprehension

```
Task: say what you think this slice will build.
1. "What will be built": 3-5 sentences in your own words: the behaviour after this slice, its literal values, the stories it covers.
2. "What exists today, per these files": 2-4 sentences.
A part you cannot paraphrase is a Blocker.
3. Findings: terms, seams or fixtures used but defined nowhere; steps that assume unstated setup; vague lines ("handles it", "as usual").
Per finding: Blocker | Major | Nit, where (section or line), what is unclear in one or two sentences. Under 300 words.
```

## Readiness

```
Task: you write this slice's tests and code next. List everything you would have to guess.
For each line ask: do I know what to test, through which seam, with which fixtures and values, and what the code must do?
Flag: a decision left to you (an API shape, an error case, a status code, a default, which layer owns a check); a test in "## Tests" with no matching TS, or a TS literal missing from the expected behaviour; a seam or fixture the slice names that the repo lacks and the slice does not mark as new; behaviour outside the slice's layer or stories.
Per finding: Blocker | Major | Nit, where, the guess you would have to make in one line. Under 300 words.
```
