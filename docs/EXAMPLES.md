# Example Usage

## Example 1: Natural Stone Texture

### Input

- File: `stone_albedo.png`
- Type: Photo-realistic stone wall

### Process

1. Open Godot Editor
2. Navigate to Photonic Ring panel
3. Select `stone_albedo.png`
4. Click "Generate Maps"

### Output

- `stone_albedo_height.png`: Shows depth of grooves and surface irregularities
- `stone_albedo_normal.png`: Creates realistic bumps and crevices
- `stone_albedo_roughness.png`: Captures the rough, natural surface

### Using in Godot

```gdscript
# Create a StandardMaterial3D
var material = StandardMaterial3D.new()

# Assign textures
material.albedo_texture = load("res://textures/stone_albedo.png")
material.normal_texture = load("res://textures/stone_albedo_normal.png")
material.heightmap_texture = load("res://textures/stone_albedo_height.png")
material.roughness_texture = load("res://textures/stone_albedo_roughness.png")

# Configure normal mapping
material.normal_enabled = true
material.normal_scale = 1.0

# Configure heightmap
material.heightmap_enabled = true
material.heightmap_scale = 0.05  # Adjust for depth

# Configure roughness
material.roughness_texture_channel = StandardMaterial3D.TEXTURE_CHANNEL_RED

# Apply to mesh
$MeshInstance3D.material_override = material
```

## Example 2: Wooden Floor

### Input

- File: `wood_floor_albedo.png`
- Type: Hand-painted wooden planks

### Generated Maps

- **Height Map**: Wood grain depth, plank separations
- **Normal Map**: Surface texture details
- **Roughness Map**: Varying roughness across grain patterns

### shader_type spatial

```glsl
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform sampler2D albedo_texture : source_color;
uniform sampler2D normal_texture : hint_normal;
uniform sampler2D height_texture;
uniform sampler2D roughness_texture;

uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
uniform float height_scale : hint_range(0.0, 0.2) = 0.05;

void fragment() {
    // Sample textures
    ALBEDO = texture(albedo_texture, UV).rgb;
    NORMAL_MAP = texture(normal_texture, UV).rgb;
    NORMAL_MAP_DEPTH = normal_strength;
    ROUGHNESS = texture(roughness_texture, UV).r;

    // Parallax occlusion mapping
    float height = texture(height_texture, UV).r;
    vec2 parallax_uv = UV - VIEW.xy * (height * height_scale);
    ALBEDO = texture(albedo_texture, parallax_uv).rgb;
}
```

## Example 3: Metal Surface

### Input

- File: `metal_albedo.png`
- Type: Brushed metal

### Notable Features

- **Height Map**: Captures brush stroke direction
- **Normal Map**: Creates micro-scratches
- **Roughness Map**: Lower roughness (smoother) due to metallic nature

### Material Setup

```gdscript
var material = StandardMaterial3D.new()

# Set as metallic
material.metallic = 1.0
material.metallic_specular = 0.5

# Assign generated textures
material.albedo_texture = load("res://textures/metal_albedo.png")
material.normal_texture = load("res://textures/metal_albedo_normal.png")
material.roughness_texture = load("res://textures/metal_albedo_roughness.png")

# Adjust for metal appearance
material.roughness = 0.3  # Metals are generally smoother
```

## Example 4: Fabric/Cloth

### Input

- File: `fabric_albedo.png`
- Type: Woven fabric

### Map Characteristics

- **Height Map**: Weave pattern depth
- **Normal Map**: Thread direction and texture
- **Roughness Map**: Higher roughness for matte fabric

### Application

```gdscript
# For clothing/cloth simulation
var material = StandardMaterial3D.new()

material.albedo_texture = load("res://textures/fabric_albedo.png")
material.normal_texture = load("res://textures/fabric_albedo_normal.png")
material.roughness_texture = load("res://textures/fabric_albedo_roughness.png")

# Fabric properties
material.roughness = 0.8  # Fabrics are typically rough
material.metallic = 0.0
material.specular_mode = StandardMaterial3D.SPECULAR_DISABLED  # Matte look
```

## Example 5: Batch Processing Multiple Textures

### GDScript Automation

```gdscript
extends Node

@onready var generator = TextureGenerator.new()

func batch_generate_textures():
    var textures = [
        "res://textures/wall_01_albedo.png",
        "res://textures/floor_01_albedo.png",
        "res://textures/ceiling_01_albedo.png",
        # Add more...
    ]

    for texture_path in textures:
        print("Processing: ", texture_path)
        var result = generator.generate_maps(texture_path)

        if result.get("success"):
            print("✓ Generated maps for ", texture_path)
        else:
            print("✗ Failed: ", result.get("error"))
```

## Example 6: Runtime Texture Generation

### Dynamic Generation in Game

```gdscript
extends Node3D

func create_procedural_material(albedo_path: String) -> StandardMaterial3D:
    # Generate maps at runtime
    var generator = TextureGenerator.new()
    var result = generator.generate_maps(albedo_path)

    if not result.get("success"):
        push_error("Failed to generate textures")
        return null

    # Load generated textures
    var material = StandardMaterial3D.new()
    material.albedo_texture = load(albedo_path)
    material.normal_texture = load(result.get("normal_path"))
    material.roughness_texture = load(result.get("roughness_path"))

    # Configure material
    material.normal_enabled = true
    material.normal_scale = 1.0

    return material

func _ready():
    var material = create_procedural_material("res://textures/terrain_albedo.png")
    $MeshInstance3D.material_override = material
```

## Example 7: Quality Comparison

### Side-by-Side Comparison Scene

```gdscript
extends Node3D

func _ready():
    create_comparison_spheres()

func create_comparison_spheres():
    # Left sphere: Albedo only
    var sphere_basic = MeshInstance3D.new()
    sphere_basic.mesh = SphereMesh.new()
    sphere_basic.position = Vector3(-2, 0, 0)
    var mat_basic = StandardMaterial3D.new()
    mat_basic.albedo_texture = load("res://textures/test_albedo.png")
    sphere_basic.material_override = mat_basic
    add_child(sphere_basic)

    # Right sphere: With generated maps
    var sphere_enhanced = MeshInstance3D.new()
    sphere_enhanced.mesh = SphereMesh.new()
    sphere_enhanced.position = Vector3(2, 0, 0)
    var mat_enhanced = StandardMaterial3D.new()
    mat_enhanced.albedo_texture = load("res://textures/test_albedo.png")
    mat_enhanced.normal_texture = load("res://textures/test_albedo_normal.png")
    mat_enhanced.roughness_texture = load("res://textures/test_albedo_roughness.png")
    mat_enhanced.normal_enabled = true
    sphere_enhanced.material_override = mat_enhanced
    add_child(sphere_enhanced)
```

## Tips for Best Results

1. **Input Resolution**: Higher resolution albedo = better quality maps
2. **Normal Strength**: Adjust in material settings (0.5 - 2.0)
3. **Height Scale**: Start with 0.05, adjust based on desired depth
4. **Roughness**: May need manual tweaking based on material type

## Common Material Presets

### Rough Stone

```gdscript
material.roughness = 0.9
material.metallic = 0.0
material.normal_scale = 1.5
```

### Smooth Metal

```gdscript
material.roughness = 0.2
material.metallic = 1.0
material.normal_scale = 0.5
```

### Polished Wood

```gdscript
material.roughness = 0.4
material.metallic = 0.0
material.normal_scale = 1.0
```

### Concrete

```gdscript
material.roughness = 0.8
material.metallic = 0.0
material.normal_scale = 1.2
```
