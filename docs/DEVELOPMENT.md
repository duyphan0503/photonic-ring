# Photonic Ring - Development Guide

## Project Structure

```
photonic-ring/
├── rust/                           # Rust core library
│   ├── src/
│   │   ├── lib.rs                 # GDExtension entry point
│   │   ├── texture_generator.rs   # Main generator class
│   │   ├── height_map.rs          # Height map algorithms
│   │   ├── normal_map.rs          # Normal map algorithms
│   │   └── roughness_map.rs       # Roughness map algorithms
│   └── Cargo.toml                 # Rust dependencies
├── addons/
│   └── photonic_ring/
│       ├── plugin.cfg             # Plugin metadata
│       ├── plugin.gd              # Plugin registration
│       ├── bin/
│       │   └── libphotonic_ring.gdextension  # GDExtension config
│       └── ui/
│           ├── texture_generator_panel.gd    # UI controller
│           └── texture_generator_panel.tscn  # UI scene
└── project.godot                  # Godot project config
```

## Building the Plugin

### Option 1: Using the Build Script (Recommended)

```bash
chmod +x build.sh
./build.sh
```

### Option 2: Manual Build

```bash
cd rust
cargo build --release
mkdir -p ../addons/photonic_ring/bin
cp target/release/libphotonic_ring.so ../addons/photonic_ring/bin/  # Linux
# Or for macOS: cp target/release/libphotonic_ring.dylib ../addons/photonic_ring/bin/
# Or for Windows: cp target/release/photonic_ring.dll ../addons/photonic_ring/bin/
cd ..
```

## Development Workflow

### 1. Testing Changes

After modifying Rust code:

```bash
./build.sh
```

Then in Godot:

- Close the project
- Reopen the project
- The plugin will reload with your changes

### 2. Debugging

To see debug output:

- In Godot, go to **Output** panel
- Run the plugin
- Check for `godot_print!()` messages from Rust

To enable Rust debug mode:

```bash
cd rust
cargo build  # Without --release flag
```

### 3. Adding New Features

To add a new map type:

1. Create a new file in `rust/src/` (e.g., `metallic_map.rs`)
2. Implement your algorithm
3. Add the module to `lib.rs`
4. Update `texture_generator.rs` to call your new generator
5. Update the UI in `texture_generator_panel.gd` and `.tscn`

## Algorithm Details

### Height Map Generation

**File:** `rust/src/height_map.rs`

**Process:**

1. Convert albedo to grayscale using luminance formula
2. Apply Sobel edge detection to identify depth boundaries
3. Combine luminance (70%) with edge information (30%)
4. Apply Gaussian blur for smoothing
5. Enhance contrast using histogram equalization

**Key Parameters:**

- Blur sigma: 1.0 (adjust for smoother/sharper results)
- Edge weight: 0.3 (adjust for more/less edge detail)

### Normal Map Generation

**File:** `rust/src/normal_map.rs`

**Process:**

1. Convert height map to grayscale
2. Calculate gradients using Sobel operator
3. Compute surface normals: `(-dx, -dy, 1)`
4. Normalize vectors
5. Encode to RGB: `(x, y, z) → (r, g, b)` mapping `[-1,1] → [0,255]`

**Key Parameters:**

- Strength factor: 3.0 (controls bumpiness, increase for stronger normals)

### Roughness Map Generation

**File:** `rust/src/roughness_map.rs`

**Process:**

1. Calculate local color variance (roughness indicator)
2. Analyze saturation (low saturation = metals = smoother)
3. Detect high-frequency details (more detail = rougher)
4. Weighted combination: 40% variance + 30% detail + 30% saturation
5. Apply Gaussian blur to smooth noise

**Key Parameters:**

- Window size: 3 (for local variance calculation)
- Blur sigma: 0.5 (adjust for smoother results)
- Weights: Adjust in `compute_roughness()` function

## Customization Guide

### Adjusting Quality vs Performance

In `Cargo.toml`, you can adjust the optimization level:

```toml
[profile.release]
opt-level = 3        # 0-3, higher = slower build but faster runtime
```

### Enabling Parallelization

The project includes `rayon` for parallel processing. To enable it:

```rust
use rayon::prelude::*;

// Instead of:
for y in 0..height {
    // process
}

// Use:
(0..height).into_par_iter().for_each(|y| {
    // process
});
```

### Adding Custom Presets

You can create presets for different material types:

1. Add preset types to `texture_generator.rs`
2. Implement different parameter sets for each preset
3. Update UI to allow preset selection

## Troubleshooting

### Plugin doesn't appear in Godot

1. Check that `addons/photonic_ring/plugin.cfg` exists
2. Go to **Project → Project Settings → Plugins**
3. Enable "Photonic Ring"
4. Check the Output panel for errors

### Rust library not loading

1. Verify the `.gdextension` file path is correct
2. Check that the library file exists in `addons/photonic_ring/bin/`
3. Ensure you built for the correct platform
4. Try rebuilding: `./build.sh`

### Generation produces poor results

1. Check input image quality (higher resolution = better results)
2. Adjust algorithm parameters in the Rust files
3. Try different strength factors in normal map generation
4. Adjust weights in roughness map computation

### Build errors

**"cannot find crate godot":**

```bash
cd rust
cargo update
cargo build --release
```

**"linker error":**

- Ensure you have a C compiler installed
- Linux: `sudo apt install build-essential`
- macOS: Install Xcode Command Line Tools
- Windows: Install Visual Studio Build Tools

## Performance Optimization Tips

1. **Use release builds** for production: `cargo build --release`
2. **Reduce image resolution** before processing for faster results
3. **Enable LTO** (Link Time Optimization) in `Cargo.toml` (already enabled)
4. **Profile the code** to find bottlenecks:
   ```bash
   cargo install flamegraph
   cargo flamegraph --bin photonic-ring
   ```

## Contributing

When submitting improvements:

1. Test with various image types (photos, hand-painted, procedural)
2. Benchmark performance before/after changes
3. Document algorithm changes in code comments
4. Update this guide if adding new features

## Resources

- [gdext Documentation](https://godot-rust.github.io/book/)
- [Godot GDExtension](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/what_is_gdextension.html)
- [Image Processing Theory](https://en.wikipedia.org/wiki/Digital_image_processing)
- [Normal Map Generation](https://en.wikipedia.org/wiki/Normal_mapping)

## License

MIT License - See ../LICENSE file
