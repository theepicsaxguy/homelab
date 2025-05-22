Exact commit-message rules that release-please parses

Element	Required?	Syntax rules release-please enforces	Effect on the version	Changelog section	Spec source

type	YES	Lower-case noun followed by : (optionally (scope) before the colon). Allowed values are at least feat, fix, perf, docs, style, refactor, test, build, ci, chore, revert.	feat → MINOR bump fix or perf → PATCH bump. All other types bump nothing unless combined with a breaking change.	Becomes top-level heading (e.g. Features, Bug Fixes, Performance Improvements).	
scope	optional	A noun inside () right after the type; e.g. feat(k8s): …. Any UTF-8, no spaces, no trailing dots.	None.	Shown in parentheses just after the type heading if present.	
description	YES	Imperative mood, ≤ 72 chars, no trailing period. Follows type (and optional scope) after exactly :␠.	None.	First line of bullet entry.	
body	optional	Starts after one blank line. Free text or bullet list. Wrap at 72 chars.	None.	Included verbatim under the bullet.	
BREAKING CHANGE	optional	Either add ! immediately before : → feat(api)!: … or add a footer line BREAKING CHANGE: <explanation> after one blank line.	Always bumps MAJOR.	Adds a ⚠ BREAKING CHANGES block with the explanation.	
other footers	optional	One per line, <Token>: <value> or <Token> #123. Typical tokens: Refs:, Reviewed-by:, Co-authored-by:.	None.	Shown beneath the bullet.	
revert commit	optional	Must start with revert: (lower-case) and contain a body line Reverts: <SHA or PR #>.	No direct bump; release-please shows it under Reverts.	Reverts section.	



---

Minimum valid commit line

fix(networking): correct DNS SRV lookup

Feature with body

feat(k8s): add Cilium network policy support

- default deny-all ingress/egress
- egress allow-list for kube-system

Breaking change (footer variant)

refactor(tofu): rename output variables

BREAKING CHANGE: destroys and recreates all outputs; state import needed.

Breaking change (shorthand !)

feat!: switch authentication to JWT


---

What NOT to do

Omit the type or the colon. Example wrong: update: make things faster → ignored.

Capitalise type. Example wrong: Fix: → ignored (types are case-insensitive in the spec but release-please’s regex assumes lower-case).

Forget the blank line before body or footer.

Put a trailing period in the description.



---

Why these rules matter

release-please’s versioning engine (DefaultVersioningStrategy) maps exactly feat, fix, BREAKING CHANGE/! to minor, patch, major bumps. 

Every other type is only cosmetic unless you add ! or a BREAKING CHANGE footer.

If a commit does not match the pattern ^(\w+)([\w\-]+)?(!)?:\s.+, release-please ignores it entirely.


Follow this table and all commits will be parsed, changelogs will be rich, and semantic version bumps will be automatic.

