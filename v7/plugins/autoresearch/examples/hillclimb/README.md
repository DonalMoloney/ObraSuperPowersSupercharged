# hillclimb example

A dependency-light demo (Python 3 only) proving the loop end-to-end. The proposer edits
`VALUE` in `knob.py`; the metric is the distance from 0.7; lower is better.

Real run (uses `claude -p`):

```bash
cd examples/hillclimb && git init -q && git add -A && git commit -qm init
bash ../../scripts/autoresearch.sh autoresearch.config.json
```

The journal under `.autoresearch/<run-id>/journal.md` should show the metric improving
toward 0, with KEPT commits only when it improves.
