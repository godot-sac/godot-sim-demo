# Contributing to godot-sim-demo

Thank you for your interest. This document describes how to report problems and propose changes. godot-sim-demo is a
Godot project that shows the add-ons godot-dis, godot-geo, godot-jsbsim and godot-milsymbol in one scenario; it
ships no add-on of its own. Problems in an add-on's API or behaviour belong in that add-on's repository.

## Ways to contribute
- **Report a bug** or **suggest a feature**: open an issue with the matching template. Search existing issues first.
- **Ask a question**: open an issue; label it `question` if you can.
- **Fix or improve something**: for small fixes open a pull request directly; for larger changes (new scenario
  parts, new dependencies) open an issue first so the approach can be agreed before you invest time.

## Reporting bugs
Include the Godot version, the operating system, the version or commit of this repository and of each add-on, the
steps to reproduce, what you expected and what happened, and the relevant output (errors, logs, screenshots, the
`--check` report).

## Development setup
Requirements: Godot 4.7.x, Python 3.8+, the four add-on repositories cloned next to this one, godot-dis and
godot-jsbsim built, and the godot-geo terrain package `terrain/uskudar_10km` built (see the README of each).

```sh
git clone <repository url> && cd godot-sim-demo
python tools/link_addons.py --godot <path to the Godot executable>
godot --path .
```

## Making changes
- Work on a branch; keep one topic per pull request and the diff as small as the change allows.
- Follow the surrounding code: naming, comment density and structure.
- Use the add-ons through their public API only. If the demo needs something an add-on does not offer, open an
  issue in that add-on's repository instead of working around it here.
- Update `README.md` when keys, options or the scenario change, and add a line to the `[Unreleased]` section of
  `CHANGELOG.md`.
- The self-test must pass locally before you open the pull request.

## Tests
```sh
godot --headless --path . -- --check 480 --report check.json
```
The run exits with code 0 when every check passes; the report lists each check with its value. It uses DIS port
3290 unless `--port` is given.

## Style
- **GDScript:** the [official style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html);
  tabs; static types everywhere; `##` documentation comments on classes and public methods.
- **Python:** PEP 8 with lines up to 120 characters.
- Code, comments, documentation and commit messages are in English.

## Commit messages
- Subject line in the imperative mood, at most 72 characters ("Fix map overlay under the symbols").
- A blank line, then a body that explains why the change is needed when it is not obvious.
- Reference issues as `Fixes #123` where it applies.

## Licensing and sources
- godot-sim-demo is MIT licensed. By contributing you agree that your contribution is licensed under the same terms.
- Do not add GPL, AGPL or non-commercial code, data or dependencies. LGPL libraries only when linked dynamically.
- Third-party code or data must have a compatible licence; record its notice in `THIRD_PARTY_NOTICES.md`.
- Use only open standards and publicly available data. Never contribute classified, export-controlled, proprietary
  or employer-internal information. Scenario data is invented; keep it that way.
- Aircraft models need the licence history check described in godot-jsbsim before they are used here.

## Review
Maintainers review pull requests as time allows. Expect questions and change requests; they are about the code,
not about you. A pull request is merged when the self-test passes, the review is resolved and the change fits the
scope of the project.

## Code of conduct
Participation is governed by the [code of conduct](CODE_OF_CONDUCT.md).
