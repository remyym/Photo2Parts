## 📦 Output

- **Model name**: Name used for the generated `Model` when model container creation is enabled.
- **Part prefix**: Prefix used for generated part names.
- **Parent**: Destination for the generated model or parts. Use Workspace, or select an instance in Studio and press **Use Selection**.
- **Pixel size**: World-space size of one sampled image pixel.
- **Y offset**: World-space offset applied to generated parts.
- **Plane**: Orientation for the image: flat XZ, wall XY, or wall YZ.
- **Center at origin**: Centers the generated image around the origin of its output plane.
- **Create model container**: Parents generated parts into a new `Model`; otherwise parts go directly into the selected parent.

## 📐 Scaling

- **Mode**: Original size, exact output width/height, or maximum dimension.
- **Output width / height**: Target dimensions used by exact-size scaling.
- **Max dimension**: Largest target side used by max-dimension scaling.
- **Color mode**: Original color, grayscale, or black and white.
- **B/W threshold**: Brightness cutoff for black-and-white output.

## ⚡ Optimization

- **Merge mode**: No merging, exact-color rectangle merging, or similar-color rectangle merging.
- **Color tolerance**: Larger values group nearby colors together for similar-color merging.
- **Alpha tolerance**: Larger values group nearby alpha values together for similar-color merging.
- **Alpha cutoff**: Transparent pixels below this alpha are skipped when skipping is enabled.
- **Minimum area**: Drops planned rectangles smaller than this area to remove tiny noisy regions.
- **Batch size**: Number of parts created before yielding when batched generation is enabled.
- **Skip transparent pixels**: Avoids creating parts for transparent pixels.
- **Quantize colors**: Snaps colors into coarser buckets before planning, usually reducing part count.
- **Average merged colors**: Uses the average color of similar merged rectangles instead of the first pixel's color.
- **Ignore alpha for merging**: Allows pixels with different transparency to merge together.
- **Yield during generation**: Pauses between batches so Studio stays responsive on large outputs.

## 🧱 Part Properties

- **Material**: Roblox material assigned to every generated part.
- **Thickness**: Thin, cube, or custom part thickness.
- **Custom thickness**: Thickness value used when the custom preset is selected.
- **Preserve transparency**: Converts PNG alpha into part transparency.
- **Anchored**: Sets generated parts to anchored.
- **Can collide**: Enables collisions on generated parts.
- **Cast shadows**: Enables shadow casting on generated parts.

## 🎛️ Presets

Presets are quick starting points. You can apply one, then adjust any setting afterward.

- **Default**: Restores the normal balanced settings.
- **Pixel Art**: Keeps exact colors and hard edges. Good for sprites, pixel logos, and low-resolution art.
- **Low Part Count**: Uses stronger similar-color merging, quantization, and tiny-region cleanup. Good when performance matters more than perfect color detail.
- **Detailed Photo**: Keeps more color detail while still using similar-color rectangle merging.
- **Sign / Logo**: Preserves transparency and uses thin smooth parts for clean graphics.
- **Black & White Silhouette**: Converts the image into bold black-and-white blocks with fewer color groups.
- **Neon Display**: Uses Neon material and thin, non-shadow-casting parts for bright signs and display-style images.
