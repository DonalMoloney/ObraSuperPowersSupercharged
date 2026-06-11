# Fixture manifest — planted bugs

Acceptance criterion: each hunter, scoped to its fixture file, finds every bug
listed for it, and the finding-verifier confirms them all. Fixture files contain
NO comments marking the bugs (hunters must not be able to cheat). Fixtures are
syntax-checked but never executed.

## silent_failures.py → silent-failure-hunter (3 bugs)
1. `load_config` — bare `except Exception: return {}` makes a corrupt config file indistinguishable from a missing one.
2. `sync_inventory` — `except ConnectionError: pass` drops failed items; `failed` list is never populated, so the function always reports zero failures.
3. `push_item` — `subprocess.run` return code never checked; sync failures look like success.

## boundary_bugs.py → boundary-bug-hunter (4 bugs)
1. `average` — ZeroDivisionError on empty list.
2. `top_n` — `range(1, n)` skips the top score (index 0) and returns n-1 items. (This function contains more than one genuine defect — it also raises IndexError when n > len(scores); hunters may legitimately report these as multiple distinct findings, and the acceptance check should not score extra genuine findings in the same function as false positives.)
3. `label_for` — no return for score <= 50; returns None where callers expect a string.
4. `first_initial` — IndexError on empty string.

## race_conditions.py → race-condition-hunter (3 bugs)
1. `get_cache` — unsafe lazy init; two pool threads can both observe None and build separate caches.
2. `record_download` — unsynchronized `+=` on a global from threaded fetch pool.
3. `write_once` — exists-check then write is a TOCTOU gap.

## resource_leaks.py → resource-leak-hunter (3 bugs)
1. `read_header` — file handle never closed.
2. `fetch_status` — socket leaks on the empty-response raise path. (The socket also leaks if `sendall` or `recv` raise; hunters may legitimately report these as multiple distinct findings, and the acceptance check should not score extra genuine findings in the same function as false positives.)
3. `append_log` — an exception while writing skips `close()`; no with/finally.

## contract_drift.py → contract-drift-hunter (3 bugs)
1. `sorted_names` — docstring promises sorted output; nothing sorts.
2. `find_user` — docstring promises KeyError; returns None instead.
3. `normalize` — final `return name` is unreachable (strict/not-strict branches are exhaustive).

## injection_bugs.py → injection-and-trust-hunter (4 bugs)
1. `find_orders` — SQL built with `%` formatting from request parameter.
2. `archive_logs` — `os.system` with concatenated request parameter.
3. `read_attachment` — path join with user filename, no traversal containment.
4. `load_session` — `pickle.loads` on request-supplied blob.

**Total: 20 planted bugs.**
