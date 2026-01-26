use image::{DynamicImage, GenericImageView, RgbaImage, Rgba};
use std::io::Write;
use std::path::Path;

/// Channel Packer for Terrain3D (v0.0.2)
/// Packs RGBA textures and saves them in DDS (BC3/DXT5) format.
pub struct ChannelPacker;

impl ChannelPacker {
    /// Pack RGB from `rgb_source` and Alpha from `alpha_source` into a single RGBA image.
    /// If dimensions differ, `alpha_source` will be resized to match `rgb_source`.
    pub fn pack_rgba(
        rgb_source: &DynamicImage,
        alpha_source: &DynamicImage,
    ) -> RgbaImage {
        let (width, height) = rgb_source.dimensions();
        
        // Resize alpha source if dimensions don't match
        let alpha_resized = if alpha_source.dimensions() != (width, height) {
            alpha_source.resize_exact(width, height, image::imageops::FilterType::Lanczos3)
        } else {
            alpha_source.clone()
        };
        
        let rgb_rgba = rgb_source.to_rgba8();
        let alpha_gray = alpha_resized.to_luma8();
        
        let mut output = RgbaImage::new(width, height);
        
        for y in 0..height {
            for x in 0..width {
                let rgb_pixel = rgb_rgba.get_pixel(x, y);
                let alpha_value = alpha_gray.get_pixel(x, y).0[0];
                output.put_pixel(x, y, Rgba([rgb_pixel[0], rgb_pixel[1], rgb_pixel[2], alpha_value]));
            }
        }
        
        output
    }
    
    /// Compress an RGBA image to BC3/DXT5 format and save as DDS file.
    pub fn save_as_dds(
        image: &RgbaImage,
        output_path: &Path,
    ) -> Result<(), String> {
        let (width, height) = image.dimensions();
        
        // BC3 requires dimensions to be multiples of 4
        if width % 4 != 0 || height % 4 != 0 {
            return Err(format!(
                "Image dimensions {}x{} must be multiples of 4 for BC3 compression",
                width, height
            ));
        }
        
        // Compress to BC3/DXT5
        let raw_pixels = image.as_raw();
        let block_count = ((width / 4) * (height / 4)) as usize;
        let mut compressed = vec![0u8; block_count * 16]; // BC3 is 16 bytes per 4x4 block
        
        texpresso::Format::Bc3.compress(
            raw_pixels,
            width as usize,
            height as usize,
            texpresso::Params {
                algorithm: texpresso::Algorithm::ClusterFit,
                weights: texpresso::COLOUR_WEIGHTS_PERCEPTUAL,
                weigh_colour_by_alpha: true,
            },
            &mut compressed,
        );
        
        // Create DDS header manually
        let mut dds_data = Vec::new();
        
        // DDS Magic number
        dds_data.extend_from_slice(b"DDS ");
        
        // DDS_HEADER (124 bytes)
        let header_size: u32 = 124;
        let flags: u32 = 0x1 | 0x2 | 0x4 | 0x1000 | 0x80000; // CAPS | HEIGHT | WIDTH | PIXELFORMAT | LINEARSIZE
        let pitch_or_linear_size: u32 = (block_count as u32) * 16;
        let depth: u32 = 0;
        let mipmap_count: u32 = 1;
        
        dds_data.extend_from_slice(&header_size.to_le_bytes());
        dds_data.extend_from_slice(&flags.to_le_bytes());
        dds_data.extend_from_slice(&height.to_le_bytes());
        dds_data.extend_from_slice(&width.to_le_bytes());
        dds_data.extend_from_slice(&pitch_or_linear_size.to_le_bytes());
        dds_data.extend_from_slice(&depth.to_le_bytes());
        dds_data.extend_from_slice(&mipmap_count.to_le_bytes());
        
        // Reserved1[11]
        for _ in 0..11 {
            dds_data.extend_from_slice(&0u32.to_le_bytes());
        }
        
        // DDS_PIXELFORMAT (32 bytes)
        let pf_size: u32 = 32;
        let pf_flags: u32 = 0x4; // DDPF_FOURCC
        let four_cc: [u8; 4] = *b"DXT5";
        let rgb_bit_count: u32 = 0;
        let r_bitmask: u32 = 0;
        let g_bitmask: u32 = 0;
        let b_bitmask: u32 = 0;
        let a_bitmask: u32 = 0;
        
        dds_data.extend_from_slice(&pf_size.to_le_bytes());
        dds_data.extend_from_slice(&pf_flags.to_le_bytes());
        dds_data.extend_from_slice(&four_cc);
        dds_data.extend_from_slice(&rgb_bit_count.to_le_bytes());
        dds_data.extend_from_slice(&r_bitmask.to_le_bytes());
        dds_data.extend_from_slice(&g_bitmask.to_le_bytes());
        dds_data.extend_from_slice(&b_bitmask.to_le_bytes());
        dds_data.extend_from_slice(&a_bitmask.to_le_bytes());
        
        // Caps
        let caps: u32 = 0x1000; // DDSCAPS_TEXTURE
        let caps2: u32 = 0;
        let caps3: u32 = 0;
        let caps4: u32 = 0;
        let reserved2: u32 = 0;
        
        dds_data.extend_from_slice(&caps.to_le_bytes());
        dds_data.extend_from_slice(&caps2.to_le_bytes());
        dds_data.extend_from_slice(&caps3.to_le_bytes());
        dds_data.extend_from_slice(&caps4.to_le_bytes());
        dds_data.extend_from_slice(&reserved2.to_le_bytes());
        
        // Append compressed data
        dds_data.extend_from_slice(&compressed);
        
        // Write to file
        let file = std::fs::File::create(output_path)
            .map_err(|e| format!("Failed to create file: {}", e))?;
        let mut writer = std::io::BufWriter::new(file);
        
        writer.write_all(&dds_data)
            .map_err(|e| format!("Failed to write DDS: {}", e))?;
        
        writer.flush()
            .map_err(|e| format!("Failed to flush file: {}", e))?;
        
        Ok(())
    }
    
    /// Convenience method: Pack and save directly to DDS.
    pub fn pack_and_save_dds(
        rgb_source: &DynamicImage,
        alpha_source: &DynamicImage,
        output_path: &Path,
    ) -> Result<(), String> {
        let packed = Self::pack_rgba(rgb_source, alpha_source);
        Self::save_as_dds(&packed, output_path)
    }
}
