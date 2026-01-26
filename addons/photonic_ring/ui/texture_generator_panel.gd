@tool
extends PanelContainer

# === Standard Mode References ===
@onready var mode_selector: OptionButton = %ModeSelector
@onready var standard_mode_container: VBoxContainer = %StandardModeContainer
@onready var albedo_path_edit: LineEdit = %AlbedoPathEdit
@onready var output_path_edit: LineEdit = %OutputPathEdit
@onready var browse_albedo_button: Button = %BrowseAlbedoButton
@onready var browse_output_button: Button = %BrowseOutputButton

# === Packer Mode References ===
@onready var packer_mode_container: VBoxContainer = %PackerModeContainer
@onready var auto_pack_checkbox: CheckButton = %AutoPackCheckbox
@onready var manual_pack_container: VBoxContainer = %ManualPackContainer
@onready var pack1_albedo_edit: LineEdit = %Pack1AlbedoEdit
@onready var pack1_height_edit: LineEdit = %Pack1HeightEdit
@onready var pack2_normal_edit: LineEdit = %Pack2NormalEdit
@onready var pack2_roughness_edit: LineEdit = %Pack2RoughnessEdit
@onready var pack1_albedo_browse: Button = %Pack1AlbedoBrowse
@onready var pack1_height_browse: Button = %Pack1HeightBrowse
@onready var pack2_normal_browse: Button = %Pack2NormalBrowse
@onready var pack2_roughness_browse: Button = %Pack2RoughnessBrowse
@onready var packer_output_edit: LineEdit = %PackerOutputEdit
@onready var packer_output_browse: Button = %PackerOutputBrowse

# === Common Controls ===
@onready var generate_button: Button = %GenerateButton
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var progress_label: Label = %ProgressLabel
@onready var result_container: VBoxContainer = %ResultContainer
@onready var height_result: Label = %HeightResult
@onready var normal_result: Label = %NormalResult
@onready var roughness_result: Label = %RoughnessResult
@onready var packed_result1: Label = %PackedResult1
@onready var packed_result2: Label = %PackedResult2
@onready var performance_label: Label = %PerformanceLabel

var texture_generator: RefCounted
var file_dialog: EditorFileDialog
var dir_dialog: EditorFileDialog
var current_target_edit: LineEdit = null
var generation_start_time: int = 0

enum Mode { STANDARD_PBR = 0, TERRAIN3D_PACKER = 1 }

func _ready() -> void:
	_ensure_generator()
	
	# Setup mode selector
	mode_selector.clear()
	mode_selector.add_item("🖼️ Standard PBR Generator (v0.0.1)", Mode.STANDARD_PBR)
	mode_selector.add_item("🗺️ Terrain3D Packer (v0.0.2)", Mode.TERRAIN3D_PACKER)
	mode_selector.item_selected.connect(_on_mode_selected)
	
	# === Standard Mode Connections ===
	browse_albedo_button.pressed.connect(_on_browse_albedo_pressed)
	browse_output_button.pressed.connect(_on_browse_output_pressed)
	
	# === Packer Mode Connections ===
	auto_pack_checkbox.toggled.connect(_on_auto_pack_toggled)
	pack1_albedo_browse.pressed.connect(func(): _open_file_dialog(pack1_albedo_edit))
	pack1_height_browse.pressed.connect(func(): _open_file_dialog(pack1_height_edit))
	pack2_normal_browse.pressed.connect(func(): _open_file_dialog(pack2_normal_edit))
	pack2_roughness_browse.pressed.connect(func(): _open_file_dialog(pack2_roughness_edit))
	packer_output_browse.pressed.connect(func(): _open_dir_dialog(packer_output_edit))
	
	# === Common ===
	generate_button.pressed.connect(_on_generate_pressed)
	
	# Setup file dialog
	file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialog.add_filter("*.png", "PNG Images")
	file_dialog.add_filter("*.jpg,*.jpeg", "JPEG Images")
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)
	
	# Setup directory dialog
	dir_dialog = EditorFileDialog.new()
	dir_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	dir_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	dir_dialog.dir_selected.connect(_on_dir_selected)
	add_child(dir_dialog)
	
	# Initial visibility
	result_container.visible = false
	progress_bar.visible = false
	performance_label.visible = false
	_update_mode_visibility()
	_update_packer_inputs_visibility()

func _on_mode_selected(index: int) -> void:
	_update_mode_visibility()
	_update_generate_button_text()

func _update_mode_visibility() -> void:
	var current_mode = mode_selector.selected
	standard_mode_container.visible = (current_mode == Mode.STANDARD_PBR)
	packer_mode_container.visible = (current_mode == Mode.TERRAIN3D_PACKER)
	_update_result_labels_visibility()

func _update_result_labels_visibility() -> void:
	var current_mode = mode_selector.selected
	height_result.visible = (current_mode == Mode.STANDARD_PBR)
	normal_result.visible = (current_mode == Mode.STANDARD_PBR)
	roughness_result.visible = (current_mode == Mode.STANDARD_PBR)
	packed_result1.visible = (current_mode == Mode.TERRAIN3D_PACKER)
	packed_result2.visible = (current_mode == Mode.TERRAIN3D_PACKER)

func _update_generate_button_text() -> void:
	var current_mode = mode_selector.selected
	if current_mode == Mode.STANDARD_PBR:
		generate_button.text = "🚀 Generate Maps"
	else:
		generate_button.text = "📦 Pack for Terrain3D"

func _on_auto_pack_toggled(enabled: bool) -> void:
	_update_packer_inputs_visibility()

func _update_packer_inputs_visibility() -> void:
	var auto_mode = auto_pack_checkbox.button_pressed
	manual_pack_container.visible = not auto_mode

func _open_file_dialog(target: LineEdit) -> void:
	current_target_edit = target
	file_dialog.popup_centered_ratio(0.6)

func _open_dir_dialog(target: LineEdit) -> void:
	current_target_edit = target
	dir_dialog.popup_centered_ratio(0.6)

func _on_file_selected(path: String) -> void:
	if current_target_edit:
		current_target_edit.text = path
	current_target_edit = null

func _on_dir_selected(path: String) -> void:
	if current_target_edit:
		current_target_edit.text = path
	current_target_edit = null

func _on_browse_albedo_pressed() -> void:
	_open_file_dialog(albedo_path_edit)

func _on_browse_output_pressed() -> void:
	_open_dir_dialog(output_path_edit)

func _on_generate_pressed() -> void:
	var current_mode = mode_selector.selected
	if current_mode == Mode.STANDARD_PBR:
		_run_standard_generation()
	else:
		_run_terrain3d_packing()

# ========================
# Standard PBR Generation
# ========================
func _run_standard_generation() -> void:
	var albedo_path = albedo_path_edit.text
	var output_path = output_path_edit.text
	
	if albedo_path.is_empty():
		_show_error("Please select an albedo texture first!")
		return
	
	if not FileAccess.file_exists(albedo_path):
		_show_error("File does not exist: " + albedo_path)
		return
	
	_start_progress("Generating PBR maps...")
	generation_start_time = Time.get_ticks_msec()
	
	if not _ensure_generator():
		return
	
	print("🚀 Generating maps...")
	var result = texture_generator.generate_maps(albedo_path, output_path)
	
	_process_standard_result(result)

func _process_standard_result(result: Dictionary) -> void:
	var generation_time = (Time.get_ticks_msec() - generation_start_time) / 1000.0
	generate_button.disabled = false
	progress_bar.value = 100
	
	if result.get("success", false):
		progress_label.text = "✅ Generation complete!"
		progress_label.modulate = Color.GREEN
		
		result_container.visible = true
		_update_result_labels_visibility()
		height_result.text = "🏔️ Height Map: " + result.get("height_path", "").get_file()
		normal_result.text = "🌊 Normal Map: " + result.get("normal_path", "").get_file()
		roughness_result.text = "✨ Roughness Map: " + result.get("roughness_path", "").get_file()
		
		performance_label.visible = true
		performance_label.text = "⚡ Generated in %.2f seconds" % generation_time
		performance_label.modulate = Color.CYAN
		
		EditorInterface.get_resource_filesystem().scan()
		print("✅ Generation successful in %.2f seconds" % generation_time)
	else:
		var error_msg = result.get("error", "Unknown error")
		_show_error(error_msg)
		print("❌ Generation failed: ", error_msg)

# ========================
# Terrain3D Packing
# ========================
func _run_terrain3d_packing() -> void:
	var auto_mode = auto_pack_checkbox.button_pressed
	
	if auto_mode:
		_run_auto_pack()
	else:
		_run_manual_pack()

func _run_auto_pack() -> void:
	# Auto-pack uses the last generated albedo from Standard mode
	var albedo = albedo_path_edit.text
	if albedo.is_empty():
		_show_error("Auto-Pack requires running Standard PBR Generator first!")
		return
	
	var base_dir = albedo.get_base_dir()
	var stem = albedo.get_file().get_basename()
	
	# Scan for existing files
	var height_file = base_dir.path_join(stem + "_height.png")
	var normal_file = base_dir.path_join(stem + "_normal.png")
	var roughness_file = base_dir.path_join(stem + "_roughness.png")
	
	if not FileAccess.file_exists(height_file):
		_show_error("Height map not found: " + height_file.get_file() + "\nPlease run Standard PBR Generator first.")
		return
	if not FileAccess.file_exists(normal_file):
		_show_error("Normal map not found: " + normal_file.get_file() + "\nPlease run Standard PBR Generator first.")
		return
	if not FileAccess.file_exists(roughness_file):
		_show_error("Roughness map not found: " + roughness_file.get_file() + "\nPlease run Standard PBR Generator first.")
		return
	
	# Use packer output or base_dir
	var output_dir = packer_output_edit.text
	if output_dir.is_empty():
		output_dir = base_dir
	
	_execute_packing(albedo, height_file, normal_file, roughness_file, output_dir)

func _run_manual_pack() -> void:
	var p1_albedo = pack1_albedo_edit.text
	var p1_height = pack1_height_edit.text
	var p2_normal = pack2_normal_edit.text
	var p2_roughness = pack2_roughness_edit.text
	var output_dir = packer_output_edit.text
	
	if p1_albedo.is_empty() or p1_height.is_empty() or p2_normal.is_empty() or p2_roughness.is_empty():
		_show_error("Please select all 4 input textures for manual packing.")
		return
	
	_execute_packing(p1_albedo, p1_height, p2_normal, p2_roughness, output_dir)

func _execute_packing(albedo: String, height: String, normal: String, roughness: String, output_dir: String) -> void:
	_start_progress("Packing for Terrain3D (DDS)...")
	generation_start_time = Time.get_ticks_msec()
	
	if not _ensure_generator():
		return
	
	print("📦 Packing for Terrain3D...")
	var result = texture_generator.pack_terrain_3d_manual(albedo, height, normal, roughness, output_dir)
	
	_process_packer_result(result)

func _process_packer_result(result: Dictionary) -> void:
	var generation_time = (Time.get_ticks_msec() - generation_start_time) / 1000.0
	generate_button.disabled = false
	progress_bar.value = 100
	
	if result.get("success", false):
		progress_label.text = "✅ Packing complete!"
		progress_label.modulate = Color.GREEN
		
		result_container.visible = true
		_update_result_labels_visibility()
		packed_result1.text = "📦 Albedo+H: " + result.get("albedo_h_path", "").get_file()
		packed_result2.text = "📦 Normal+R: " + result.get("normal_r_path", "").get_file()
		
		performance_label.visible = true
		performance_label.text = "⚡ Packed in %.2f seconds" % generation_time
		performance_label.modulate = Color.CYAN
		
		EditorInterface.get_resource_filesystem().scan()
		print("✅ Packing successful in %.2f seconds" % generation_time)
	else:
		var error_msg = result.get("error", "Unknown error")
		_show_error(error_msg)
		print("❌ Packing failed: ", error_msg)

# ========================
# Helpers
# ========================
func _start_progress(text: String) -> void:
	progress_bar.visible = true
	progress_bar.value = 0
	progress_label.text = "⏳ " + text
	progress_label.modulate = Color.YELLOW
	result_container.visible = false
	performance_label.visible = false
	generate_button.disabled = true

func _ensure_generator() -> bool:
	if texture_generator and is_instance_valid(texture_generator):
		return true
	
	if ClassDB.class_exists("TextureGenerator"):
		texture_generator = ClassDB.instantiate("TextureGenerator")
		return true
	
	_show_error("TextureGenerator class not found! Please restart Godot Editor.")
	print("❌ Error: TextureGenerator class not found in ClassDB.")
	return false

func _show_error(message: String) -> void:
	progress_bar.visible = true
	progress_bar.value = 0
	progress_label.text = "❌ " + message
	progress_label.modulate = Color.RED
	generate_button.disabled = false
	push_error(message)
