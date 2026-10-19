#!/usr/bin/env bash
# Runs every headless test suite. Usage: GODOT=/path/to/godot tools/run_tests.sh
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
status=0
for t in tools/tests/test_*.gd; do
	echo "=== $t"
	out="$("$GODOT" --headless --path . --script "res://$t" --quit-after 20000 2>&1)"
	echo "$out" | grep -E "FAIL|RESULT|SCRIPT ERROR"
	echo "$out" | grep -q "RESULT: PASS" || status=1
done
exit $status
