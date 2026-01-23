# Photonic Ring - Quick Start Guide

## ✅ Bạn đã build thành công!

Plugin **Photonic Ring** đã được build và sẵn sàng để sử dụng với Godot Engine!

## 📦 Cài đặt vào Project Godot

### Bước 1: Copy Plugin

```bash
# Copy thư mục plugin vào project Godot của bạn
cp -r addons/photonic_ring /path/to/your/godot/project/addons/
```

### Bước 2: Enable Plugin

1. Mở project Godot của bạn
2. Vào **Project → Project Settings → Plugins**
3. Tìm "Photonic Ring - AI Texture Generator"
4. Bật checkbox để enable plugin

### Bước 3: Tìm Panel

Panel "Photonic Ring" sẽ xuất hiện ở dock bên phải của Godot Editor (thường ở góc trên bên phải).

## 🎨 Sử dụng

### Cách đơn giản nhất:

1. **Chọn ảnh Albedo**: Click nút "Browse..." và chọn texture màu của bạn (PNG, JPG, TGA, BMP)
2. **Generate**: Click nút "🚀 Generate Maps"
3. **Chờ**: Plugin sẽ tự động phân tích và tạo 3 ảnh mới:
   - `[tên_file]_height.png` - Height Map
   - `[tên_file]_normal.png` - Normal Map
   - `[tên_file]_roughness.png` - Roughness Map

### Sử dụng các map đã tạo:

```gdscript
# Tạo material mới
var material = StandardMaterial3D.new()

# Gán textures
material.albedo_texture = load("res://textures/brick_albedo.png")
material.normal_texture = load("res://textures/brick_albedo_normal.png")
material.heightmap_texture = load("res://textures/brick_albedo_height.png")
material.roughness_texture = load("res://textures/brick_albedo_roughness.png")

# Bật normal mapping
material.normal_enabled = true
material.normal_scale = 1.0  # Điều chỉnh từ 0.5 - 2.0

# Bật height mapping (parallax)
material.heightmap_enabled = true
material.heightmap_scale = 0.05  # Điều chỉnh độ sâu

# Apply lên mesh
$MeshInstance3D.material_override = material
```

## 🔧 Các thuật toán

### Height Map

- Sử dụng luminance (độ sáng) để tạo chiều sâu
- Áp dụng Sobel edge detection để tăng cường độ chi tiết
- Histogram equalization để cân bằng độ tương phản

### Normal Map

- Tính toán gradient từ height map
- Sử dụng Sobel operator
- Normalize surface normals
- Encode vào RGB channels

### Roughness Map

- Phân tích local color variance
- Phát hiện high-frequency details
- Xem xét saturation (kim loại vs. vật liệu diffuse)
- Kết hợp weighted để tạo kết quả tối ưu

## 💡 Tips

### Để có kết quả tốt nhất:

1. **Độ phân giải**: Càng cao càng tốt (khuyến nghị tối thiểu 1024x1024)
2. **Chất lượng albedo**: Ảnh rò ràng, không bị blur
3. **Lighting**: Albedo texture nên được bake với lighting đồng đều

###Điều chỉnh parameters:

Nếu kết quả không như ý, bạn có thể điều chỉnh trong material settings:

- `normal_scale`: 0.5 (subtle) → 2.0 (dramatic)
- `heightmap_scale`: 0.01 (flat) → 0.1 (deep)
- `roughness`: Override bằng constant value nếu cần

## 🎯 Use Cases

### Tốt cho:

- ✅ Stone walls, brick textures
- ✅ Wood planks, floors
- ✅ Fabric, cloth
- ✅ Terrain textures
- ✅ Metal surfaces
- ✅ Concrete, plaster

### Có thể cần điều chỉnh:

- ⚠️ Highly reflective surfaces
- ⚠️ Transparent materials
- ⚠️ Flat colors (không có variation)

## 🐛 Troubleshooting

### Plugin không xuất hiện?

- Kiểm tra console output cho errors
- Đảm bảo file `.gdextension` ở đúng vị trí
- Thử restart Godot

### Generated maps trông lạ?

- Kiểm tra albedo input có đúng không
- Thử với texture khác
- Điều chỉnh material parameters

### Performance chậm?

- Reduce image resolution trước khi generate
- Close Godot và re-open sau khi generate nhiều textures

## 📚 Tài liệu bổ sung

- `README.md` - Overview và features
- `DEVELOPMENT.md` - Hướng dẫn development
- `EXAMPLES.md` - Ví dụ chi tiết
- `TESTING.md` - Hướng dẫn testing

## 🚀 Nâng cao

### Batch Processing

Xem file `EXAMPLES.md` để biết cách tự động hóa việc generate cho nhiều textures cùng lúc.

### Customization

Nếu muốn điều chỉnh algorithms, xem file Rust trong `rust/src/`:

- `height_map.rs` - Điều chỉnh height generation
- `normal_map.rs` - Điều chỉnh normal mapping strength
- `roughness_map.rs` - Điều chỉnh roughness calculations

Rebuild bằng:

```bash
./build.sh
```

## ❤️ Enjoy!

Chúc bạn tạo được những texture tuyệt vời cho game của mình!
