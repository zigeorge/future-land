class_name TestCase
extends RefCounted
## Base class for tests. See tests/README.md.

var failures: Array[String] = []


func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if actual != expected:
		failures.append("expected %s, got %s. %s" % [expected, actual, message])


func assert_true(condition: bool, message := "") -> void:
	if not condition:
		failures.append("expected true. %s" % message)


func assert_false(condition: bool, message := "") -> void:
	if condition:
		failures.append("expected false. %s" % message)
