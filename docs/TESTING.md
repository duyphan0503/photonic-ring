# Testing Guide

## Manual Testing

### Test Case 1: Basic Texture Generation

**Input:** A simple albedo texture (e.g., brick wall, wood, stone)

**Expected Output:**

- Height Map: Should show proper depth (mortar lines dark, brick faces bright)
- Normal Map: Should be predominantly blue with red/green variations showing surface bumps
- Roughness Map: Should show variation (rough bricks, smoother mortar)

**Steps:**

1. Open Godot with the plugin enabled
2. Find the "Photonic Ring" panel
3. Click "Browse..." and select an albedo texture
4. Click "Generate Maps"
5. Check the output directory for three new files

### Test Case 2: Photo-realistic Textures

**Input:** A high-resolution photograph (e.g., concrete, fabric, metal)

**Expected Output:**

- Height Map: Should capture subtle depth variations
- Normal Map: Should create realistic surface normals
- Roughness Map: Should correctly identify rough vs smooth regions

### Test Case 3: Hand-painted Textures

**Input:** A stylized/cartoon albedo texture

**Expected Output:**

- Height Map: Should infer depth from color/shading
- Normal Map: Should create appropriate surface details
- Roughness Map: May be more uniform for stylized art

### Test Case 4: Various File Formats

Test with:

- `.png` files
- `.jpg` files
- `.tga` files
- `.bmp` files

All should work correctly.

## Automated Testing

### Unit Tests (Rust)

Create `rust/src/tests.rs`:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use image::{RgbImage, ImageBuffer};

    #[test]
    fn test_height_map_generation() {
        // Create a simple test image
        let img = ImageBuffer::from_fn(256, 256, |x, y| {
            let value = ((x + y) % 255) as u8;
            image::Rgb([value, value, value])
        });

        let dynamic_img = DynamicImage::ImageRgb8(img);
        let height_map = HeightMapGenerator::generate(&dynamic_img);

        assert_eq!(height_map.width(), 256);
        assert_eq!(height_map.height(), 256);
    }

    #[test]
    fn test_normal_map_generation() {
        // Create a gradient height map
        let height_map = ImageBuffer::from_fn(256, 256, |x, _y| {
            let value = (x % 255) as u8;
            image::Luma([value])
        });

        let dynamic_img = DynamicImage::ImageLuma8(height_map);
        let normal_map = NormalMapGenerator::generate(&dynamic_img);

        assert_eq!(normal_map.width(), 256);
        assert_eq!(normal_map.height(), 256);
    }
}
```

Run tests:

```bash
cd rust
cargo test
```

## Performance Testing

### Benchmark Different Image Sizes

Test with images of different resolutions:

| Resolution | Expected Time | Memory Usage |
| ---------- | ------------- | ------------ |
| 512x512    | < 1 second    | < 50 MB      |
| 1024x1024  | < 3 seconds   | < 150 MB     |
| 2048x2048  | < 10 seconds  | < 500 MB     |
| 4096x4096  | < 40 seconds  | < 2 GB       |

### Benchmarking Code

Add to `rust/Cargo.toml`:

```toml
[dev-dependencies]
criterion = "0.5"

[[bench]]
name = "texture_generation"
harness = false
```

Create `rust/benches/texture_generation.rs`:

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};
use photonic_ring::*;

fn benchmark_height_map(c: &mut Criterion) {
    let img = image::open("test_assets/test_texture.png").unwrap();

    c.bench_function("height_map_generation", |b| {
        b.iter(|| {
            HeightMapGenerator::generate(black_box(&img))
        });
    });
}

criterion_group!(benches, benchmark_height_map);
criterion_main!(benches);
```

Run benchmarks:

```bash
cd rust
cargo bench
```

## Visual Quality Testing

### Compare with Professional Tools

Generate maps using:

1. Photonic Ring
2. Professional tools (e.g., Substance Designer, CrazyBump)
3. Compare results visually

### Quality Checklist

- [ ] Height map has appropriate contrast
- [ ] Normal map is not too flat or too extreme
- [ ] Roughness map captures material properties correctly
- [ ] No visible artifacts or banding
- [ ] Maps tile correctly (if albedo tiles)

## Integration Testing

### Test in Actual Godot Scene

1. Create a test scene with a 3D model
2. Apply generated textures to a material
3. Check results under different lighting conditions
4. Verify that:
   - Height/normal maps create convincing depth
   - Roughness map affects specular reflections properly

## Regression Testing

Keep a set of reference images and their expected outputs. After any code changes:

1. Generate maps from reference images
2. Compare with saved "golden" outputs
3. Ensure quality hasn't degraded

## Error Handling Tests

Test error cases:

- [ ] Missing file
- [ ] Corrupted image file
- [ ] Unsupported file format
- [ ] Very large file (> 8192x8192)
- [ ] Invalid file path

## Test Results Log

Template for documenting test results:

```
Date: YYYY-MM-DD
Version: 0.1.0
Tester: [Name]

Test Case: [Name]
Input: [Description]
Expected: [Expected outcome]
Actual: [Actual outcome]
Status: PASS/FAIL
Notes: [Any observations]
```

## Continuous Integration

For automated testing, you can set up GitHub Actions:

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - name: Run tests
        run: |
          cd rust
          cargo test --verbose
      - name: Run clippy
        run: |
          cd rust
          cargo clippy -- -D warnings
      - name: Check formatting
        run: |
          cd rust
          cargo fmt -- --check
```
