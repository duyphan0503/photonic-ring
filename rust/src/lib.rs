use godot::prelude::*;

mod texture_generator;
mod height_map;
mod normal_map;
mod roughness_map;

struct PhotonicRingExtension;

#[gdextension]
unsafe impl ExtensionLibrary for PhotonicRingExtension {}
