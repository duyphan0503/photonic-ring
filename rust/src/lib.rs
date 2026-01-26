use godot::prelude::*;

mod channel_packer;
mod height_map;
mod normal_map;
mod roughness_map;
mod texture_generator;

struct PhotonicRingExtension;

#[gdextension]
unsafe impl ExtensionLibrary for PhotonicRingExtension {}