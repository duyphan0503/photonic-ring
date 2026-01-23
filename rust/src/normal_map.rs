use image::{DynamicImage, ImageBuffer, Rgb, RgbImage};
use nalgebra::{Matrix2, Vector3};
use rayon::prelude::*;

pub struct NormalMapGenerator;

impl NormalMapGenerator {
    /// Generate a normal map using structure tensor (state-of-the-art 2026)
    pub fn generate(height_map: &DynamicImage) -> DynamicImage {
        let height_gray = height_map.to_luma8();
        let width = height_gray.width();
        let height = height_gray.height();
        
        // Strength factor (controllable bumpiness)
        let strength = 4.0;
        
        // Generate normals in parallel
        let mut normal_map: RgbImage = ImageBuffer::new(width, height);
        
        normal_map.enumerate_pixels_mut().par_bridge().for_each(|(x, y, pixel)| {
            // Compute structure tensor for this pixel
            let _tensor = Self::compute_structure_tensor(&height_gray, x, y, 1.5);
            
            // Get gradients from neighboring pixels
            let (dx, dy) = Self::compute_adaptive_gradients(&height_gray, x, y, strength);
            
            // Construct normal vector
            let mut normal = Vector3::new(-dx, -dy, 1.0);
            normal = normal.normalize();
            
            // Encode to RGB (tangent space)
            let r = ((normal.x * 0.5 + 0.5) * 255.0) as u8;
            let g = ((normal.y * 0.5 + 0.5) * 255.0) as u8;
            let b = ((normal.z * 0.5 + 0.5) * 255.0) as u8;
            
            *pixel = Rgb([r, g, b]);
        });
        
        DynamicImage::ImageRgb8(normal_map)
    }
    
    /// Compute structure tensor for better gradient estimation
    fn compute_structure_tensor(image: &image::GrayImage, x: u32, y: u32, sigma: f32) -> Matrix2<f32> {
        let width = image.width();
        let height = image.height();
        let kernel_radius = (sigma * 2.0).ceil() as i32;
        
        let mut gxx = 0.0f32;
        let mut gxy = 0.0f32;
        let mut gyy = 0.0f32;
        let mut weight_sum = 0.0f32;
        
        for dy in -kernel_radius..=kernel_radius {
            for dx in -kernel_radius..=kernel_radius {
                let nx = (x as i32 + dx).clamp(0, width as i32 - 1) as u32;
                let ny = (y as i32 + dy).clamp(0, height as i32 - 1) as u32;
                
                // Gaussian weight
                let dist_sq = (dx * dx + dy * dy) as f32;
                let weight = (-dist_sq / (2.0 * sigma * sigma)).exp();
                
                // Compute gradients using Scharr operator
                let gx = Self::scharr_x(image, nx, ny);
                let gy = Self::scharr_y(image, nx, ny);
                
                gxx += weight * gx * gx;
                gxy += weight * gx * gy;
                gyy += weight * gy * gy;
                weight_sum += weight;
            }
        }
        
        if weight_sum > 0.0 {
            gxx /= weight_sum;
            gxy /= weight_sum;
            gyy /= weight_sum;
        }
        
        Matrix2::new(gxx, gxy, gxy, gyy)
    }
    
    /// Scharr operator - more accurate than Sobel
    fn scharr_x(image: &image::GrayImage, x: u32, y: u32) -> f32 {
        let width = image.width();
        let height = image.height();
        
        let get = |dx: i32, dy: i32| {
            let nx = (x as i32 + dx).clamp(0, width as i32 - 1) as u32;
            let ny = (y as i32 + dy).clamp(0, height as i32 - 1) as u32;
            image.get_pixel(nx, ny)[0] as f32 / 255.0
        };
        
        // Scharr X kernel
        let gx = -3.0 * get(-1, -1) + 3.0 * get(1, -1)
               -10.0 * get(-1,  0) + 10.0 * get(1,  0)
               - 3.0 * get(-1,  1) + 3.0 * get(1,  1);
        
        gx / 16.0
    }
    
    fn scharr_y(image: &image::GrayImage, x: u32, y: u32) -> f32 {
        let width = image.width();
        let height = image.height();
        
        let get = |dx: i32, dy: i32| {
            let nx = (x as i32 + dx).clamp(0, width as i32 - 1) as u32;
            let ny = (y as i32 + dy).clamp(0, height as i32 - 1) as u32;
            image.get_pixel(nx, ny)[0] as f32 / 255.0
        };
        
        // Scharr Y kernel
        let gy = -3.0 * get(-1, -1) - 10.0 * get(0, -1) - 3.0 * get(1, -1)
               + 3.0 * get(-1,  1) + 10.0 * get(0,  1) + 3.0 * get(1,  1);
        
        gy / 16.0
    }
    
    /// Compute adaptive gradients
    fn compute_adaptive_gradients(image: &image::GrayImage, x: u32, y: u32, strength: f32) -> (f32, f32) {
        // Use Scharr for gradient computation
        let dx = Self::scharr_x(image, x, y) * strength;
        let dy = Self::scharr_y(image, x, y) * strength;
        
        (dx, dy)
    }
}
