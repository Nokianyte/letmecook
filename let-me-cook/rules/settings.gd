class_name Settings
## Player settings kept between sessions in a ConfigFile (on the web, in the browser's
## IndexedDB). The LETMECOOK_SETTINGS environment variable points tests elsewhere.

const DEFAULT_PATH := "user://settings.cfg"


static func path() -> String:
	var override := OS.get_environment("LETMECOOK_SETTINGS")
	return override if override != "" else DEFAULT_PATH


static func get_value(section: String, key: String, default: Variant) -> Variant:
	var config := ConfigFile.new()
	if config.load(path()) != OK:
		return default
	return config.get_value(section, key, default)


static func set_value(section: String, key: String, value: Variant) -> void:
	var config := ConfigFile.new()
	config.load(path())
	config.set_value(section, key, value)
	config.save(path())
