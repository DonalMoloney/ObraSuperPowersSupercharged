#!/usr/bin/env bash
# Prints metric=<distance from target 0.7>. Lower is better.
val="$(python3 -c 'import knob; print(knob.VALUE)')"
python3 -c "print('metric=%.6f' % abs(${val} - 0.7))"
