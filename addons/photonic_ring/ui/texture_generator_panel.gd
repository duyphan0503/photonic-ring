@tool
extends PanelContainer

@onready var albedo_path_edit: LineEdit = %AlbedoPathEdit
@onready var output_path_edit: LineEdit = %OutputPathEdit
@onready var browse_albedo_button: Button = %BrowseAlbedoButton
@onready var browse_output_button: Button = %BrowseOutputButton
@onready var generate_button: Button = %GenerateButton
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var progress_label: Label = %ProgressLabel
@onready var result_container: VBoxContainer = %ResultContainer
@onready var height_result: Label = %HeightResult
@onready var normal_result: Label = %NormalResult
@onready var roughness_result: Label = %RoughnessResult
@onready var performance_label: Label = %PerformanceLabel

var texture_generator: Node
var albedo_file_dialog: EditorFileDialog
var output_dir_dialog: EditorFileDialog
var generation_start_time: int = 0

func _ready() -> void:
	# Create the texture generator node from the Rust extension
	if ClassDB.class_exists("TextureGenerator"):
		texture_generator = ClassDB.instantiate("TextureGenerator")
		add_child(texture_generator)
	else:
		_show_error("TextureGenerator class not found! Is the GDExtension loaded?")
		print("❌ Error: TextureGenerator class not found in ClassDB.")
	
	# Connect signals
	browse_albedo_button.pressed.connect(_on_browse_albedo_pressed)
	browse_output_button.pressed.connect(_on_browse_output_pressed)
	generate_button.pressed.connect(_on_generate_pressed)
	
	# Setup albedo file dialog
	albedo_file_dialog = EditorFileDialog.new()
	albedo_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	albedo_file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	albedo_file_dialog.add_filter("*.png", "PNG Images")
	albedo_file_dialog.add_filter("*.jpg,*.jpeg", "JPEG Images")
	albedo_file_dialog.add_filter("*.tga", "TGA Images")
	albedo_file_dialog.add_filter("*.bmp", "BMP Images")
	albedo_file_dialog.add_filter("*.webp", "WebP Images")
	albedo_file_dialog.file_selected.connect(_on_albedo_file_selected)
	add_child(albedo_file_dialog)
	
	# Setup output directory dialog
	output_dir_dialog = EditorFileDialog.new()
	output_dir_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	output_dir_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	output_dir_dialog.dir_selected.connect(_on_output_dir_selected)
	add_child(output_dir_dialog)
	
	result_container.visible = false
	progress_bar.visible = false
	performance_label.visible = false

func _on_browse_albedo_pressed() -> void:
	albedo_file_dialog.popup_centered_ratio(0.6)

func _on_browse_output_pressed() -> void:
	output_dir_dialog.popup_centered_ratio(0.6)

func _on_albedo_file_selected(path: String) -> void:
	albedo_path_edit.text = path
	
	# Auto-fill output directory with same folder as albedo
	if output_path_edit.text.is_empty():
		output_path_edit.text = path.get_base_dir()

func _on_output_dir_selected(path: String) -> void:
	output_path_edit.text = path

func _on_generate_pressed() -> void:
	var albedo_path = albedo_path_edit.text
	var output_path = output_path_edit.text
	
	if albedo_path.is_empty():
		_show_error("Please select an albedo texture first!")
		return
	
	if not FileAccess.file_exists(albedo_path):
		_show_error("File does not exist: " + albedo_path)
		return
	
	# Show progress
	progress_bar.visible = true
	progress_bar.value = 0
	progress_label.text = "⏳ Initializing..."
	progress_label.modulate = Color.YELLOW
	result_container.visible = false
	performance_label.visible = false
	generate_button.disabled = true
	
	# Record start time
	generation_start_time = Time.get_ticks_msec()
	
	# Generate maps using the Rust extension
	print("🚀 Starting texture generation...")
	print("  Albedo: ", albedo_path)
	print("  Output: ", output_path if not output_path.is_empty() else "(same as albedo)")
	
	if not texture_generator:
		_show_error("Texture generator not initialized!")
		return
		
	var result = texture_generator.generate_maps(albedo_path, output_path)
	
	# Calculate generation time
	var generation_time = (Time.get_ticks_msec() - generation_start_time) / 1000.0
	
	generate_button.disabled = false
	progress_bar.value = 100
	
	if result.get("success", false):
		# Success!
		progress_label.text = "✅ Generation complete!"
		progress_label.modulate = Color.GREEN
		
		# Show results
		result_container.visible = true
		height_result.text = "🏔️ Height Map: " + result.get("height_path", "").get_file()
		normal_result.text = "🌊 Normal Map: " + result.get("normal_path", "").get_file()
		roughness_result.text = "✨ Roughness Map: " + result.get("roughness_path", "").get_file()
		
		# Show performance stats
		performance_label.visible = true
		performance_label.text = "⚡ Generated in %.2f seconds" % generation_time
		performance_label.modulate = Color.CYAN
		
		# Refresh the file system
		EditorInterface.get_resource_filesystem().scan()
		
		print("✅ Generation successful!")
		print("  Time: %.2f seconds" % generation_time)
		print("  Height: ", result.get("height_path"))
		print("  Normal: ", result.get("normal_path"))
		print("  Roughness: ", result.get("roughness_path"))
	else:
		# Error
		var error_msg = result.get("error", "Unknown error")
		_show_error(error_msg)
		print("❌ Generation failed: ", error_msg)

func _show_error(message: String) -> void:
	progress_bar.visible = true
	progress_bar.value = 0
	progress_label.text = "❌ " + message
	progress_label.modulate = Color.RED
	push_error(message)
