extends SceneTree
## Minimal headless test runner. From the project root:
##   godot --headless -s tests/run_tests.gd
## Runs every method named test_* in every tests/test_*.gd file.

const TESTS_DIR := "res://tests/"


func _initialize() -> void:
	var total := 0
	var failed := 0
	for file in DirAccess.get_files_at(TESTS_DIR):
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		var script: GDScript = load(TESTS_DIR + file)
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			total += 1
			var test_case: TestCase = script.new()
			test_case.call(method_name)
			if test_case.failures.is_empty():
				print("  PASS  %s::%s" % [file, method_name])
			else:
				failed += 1
				for failure in test_case.failures:
					printerr("  FAIL  %s::%s - %s" % [file, method_name, failure])
	print("\n%d passed, %d failed" % [total - failed, failed])
	quit(1 if failed > 0 else 0)
