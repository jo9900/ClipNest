#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
icon_source=Artwork/AppIcon.png
icon_target=ClipNest/Resources/Assets.xcassets/AppIcon.appiconset
mkdir -p "$icon_target"
for icon_size in 16 32 128 256 512; do
  for icon_scale in 1 2; do
    icon_pixels=$((icon_size * icon_scale))
    sips -z "$icon_pixels" "$icon_pixels" "$icon_source" --out "$icon_target/icon_${icon_size}x${icon_size}@${icon_scale}x.png" >/dev/null
  done
done
echo "Generated all 10 macOS icon representations."
