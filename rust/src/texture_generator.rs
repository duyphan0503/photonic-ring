use godot::prelude::*;
use image::DynamicImage;
use std::path::{Path, PathBuf};

use crate::height_map::HeightMapGenerator;
use crate::normal_map::NormalMapGenerator;
use crate::roughness_map::RoughnessMapGenerator;

#[derive(GodotClass)]
#[class(base=Node)]
pub struct TextureGenerator {
    base: Base<Node>,
}

#[godot_api]
impl INode for TextureGenerator {
    fn init(base: Base<Node>) -> Self {
        Self { base }
    }
}

#[godot_api]
impl TextureGenerator {
    /// Generate all maps (height, normal, roughness) from an albedo texture
    /// 
    /// # Arguments
    /// * `albedo_path` - Path to the albedo texture
    /// * `output_dir` - Optional output directory (if empty, saves next to source)
    /// 
    /// # Returns
    /// Dictionary with keys: success (bool), error (string), height_path, normal_path, roughness_path
    #[func]
    fn generate_maps(&mut self, albedo_path: GString, output_dir: GString) -> VarDictionary {
        let mut result = VarDictionary::new();
        let _ = result.insert("success", false);
        let _ = result.insert("error", "");
        let _ = result.insert("progress", 0);
        
        // Convert GString to String
        let path_str = albedo_path.to_string();
        let output_str = output_dir.to_string();
        
        // Load the albedo image
        godot_print!("📖 Loading albedo texture: {}", path_str);
        let albedo_image = match self.load_image(&path_str) {
            Ok(img) => img,
            Err(e) => {
                let _ = result.insert("error", format!("Failed to load image: {}", e));
                return result;
            }
        };
        
        godot_print!("✓ Loaded image: {}x{} pixels", albedo_image.width(), albedo_image.height());
        let _ = result.insert("progress", 10);
        
        // Determine output directory
        let output_path = if output_str.is_empty() {
            PathBuf::from(&path_str).parent().unwrap_or(Path::new("")).to_path_buf()
        } else {
            PathBuf::from(&output_str)
        };
        
        let stem = PathBuf::from(&path_str)
            .file_stem()
            .unwrap_or(std::ffi::OsStr::new("texture"))
            .to_string_lossy()
            .to_string();
        
        // Generate maps - height and normal can be parallelized
        godot_print!("🚀 Generating maps (using multi-threading)...");
        
        let albedo_clone = albedo_image.clone();
        
        // Generate height and normal in parallel using rayon::join
        let (height_map, normal_map) = rayon::join(
            || {
                godot_print!("  ⛰️  Generating height map...");
                HeightMapGenerator::generate(&albedo_image)
            },
            || {
                // Normal map needs height map, so generate it here
                let height = HeightMapGenerator::generate(&albedo_clone);
                godot_print!("  🌊 Generating normal map...");
                NormalMapGenerator::generate(&height)
            },
        );
        
        // Generate roughness map sequentially (uses albedo)
        godot_print!("  ✨ Generating roughness map...");
        let roughness_map = RoughnessMapGenerator::generate(&albedo_image);
        
        let _ = result.insert("progress", 70);
        
        // Build output paths
        let height_path = output_path.join(format!("{}_height.png", stem));
        let normal_path = output_path.join(format!("{}_normal.png", stem));
        let roughness_path = output_path.join(format!("{}_roughness.png", stem));
        
        // Save all images
        godot_print!("💾 Saving generated maps...");
        
        if let Err(e) = height_map.save(&height_path) {
            let _ = result.insert("error", format!("Failed to save height map: {}", e));
            return result;
        }
        godot_print!("  ✓ Height map: {}", height_path.display());
        
        if let Err(e) = normal_map.save(&normal_path) {
            let _ = result.insert("error", format!("Failed to save normal map: {}", e));
            return result;
        }
        godot_print!("  ✓ Normal map: {}", normal_path.display());
        
        if let Err(e) = roughness_map.save(&roughness_path) {
            let _ = result.insert("error", format!("Failed to save roughness map: {}", e));
            return result;
        }
        godot_print!("  ✓ Roughness map: {}", roughness_path.display());
        
        // Success!
        let _ = result.insert("success", true);
        let _ = result.insert("progress", 100);
        let _ = result.insert("height_path", height_path.to_string_lossy().to_string());
        let _ = result.insert("normal_path", normal_path.to_string_lossy().to_string());
        let _ = result.insert("roughness_path", roughness_path.to_string_lossy().to_string());
        
        godot_print!("🎉 All maps generated successfully!");
        result
    }
    
    /// Load an image from a Godot resource path or filesystem path
    fn load_image(&self, path: &str) -> Result<DynamicImage, String> {
        let absolute_path = if path.starts_with("res://") {
            let relative = path.strip_prefix("res://").unwrap_or(path);
            let project_path = std::env::current_dir()
                .map_err(|e| format!("Failed to get current directory: {}", e))?;
            project_path.join(relative)
        } else {
            PathBuf::from(path)
        };
        
        image::open(&absolute_path)
            .map_err(|e| format!("Failed to open image at '{}': {}", absolute_path.display(), e))
    }
}
