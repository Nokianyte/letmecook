extends SceneTree
# Every character in game text must exist in Godot's default font: the web build has no
# system fonts to fall back on, so a missing glyph shows as a box in the browser only.
var fails := 0
const SCANNED := ["res://scenes", "res://ui", "res://rules", "res://data"]
const EXTENSIONS := ["gd", "tres", "tscn"]


func check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond: fails += 1


func _initialize() -> void:
	var font: Font = ThemeDB.fallback_font
	var missing := {}
	var checked := 0
	for dir in SCANNED:
		for path in _files(dir):
			for line in FileAccess.get_file_as_string(path).split("\n"):
				if line.strip_edges().begins_with("#"):
					continue  # comments never render
				for i in line.length():
					var code := line.unicode_at(i)
					if code > 127:
						checked += 1
						if not font.has_char(code):
							missing["U+%04X in %s" % [code, path]] = true
	for entry in missing:
		print("  missing glyph: ", entry)
	check(missing.is_empty(), "all %d non-ASCII characters in game text exist in the web font" % checked)
	print("RESULT: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(0 if fails == 0 else 1)


func _files(dir: String) -> Array[String]:
	var result: Array[String] = []
	for sub in DirAccess.get_directories_at(dir):
		result.append_array(_files(dir.path_join(sub)))
	for file in DirAccess.get_files_at(dir):
		if file.get_extension() in EXTENSIONS:
			result.append(dir.path_join(file))
	return result
