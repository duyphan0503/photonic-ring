@tool
extends EditorPlugin

var dock_panel: Control

func _enter_tree() -> void:
	# Load the dock panel UI
	dock_panel = preload("res://addons/photonic_ring/ui/texture_generator_panel.tscn").instantiate()
	
	# Add the panel to the editor's dock
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock_panel)
	
	print("Photonic Ring plugin loaded!")

func _exit_tree() -> void:
	# Clean up
	if dock_panel:
		remove_control_from_docks(dock_panel)
		dock_panel.queue_free()
	
	print("Photonic Ring plugin unloaded!")
