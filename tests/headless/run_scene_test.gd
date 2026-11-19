extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var user_args := OS.get_cmdline_user_args()
	if user_args.is_empty():
		push_error("Pass a test scene after -- when using the headless scene runner.")
		quit(2)
		return
	var scene_path := String(user_args[0])
	var test_scene := load(scene_path) as PackedScene
	if test_scene == null:
		push_error("Headless test scene failed to load: %s" % scene_path)
		quit(2)
		return
	root.add_child(test_scene.instantiate())
