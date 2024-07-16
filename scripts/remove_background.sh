#!/bin/bash

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null
then
    echo "ImageMagick is not installed. Please install it first."
    exit 1
fi

# Check if input file is provided
if [ $# -eq 0 ]; then
    echo "Please provide an input image file."
    echo "Usage: $0 <input_image> [fuzz_value]"
    exit 1
fi

input_file="$1"
fuzz_value="${2:-10}"  # Default fuzz value is 10%
base_name="${input_file%.*}"

# Step 1: Analyze the image
echo "Step 1: Analyzing the image"
convert "$input_file" -format "%[pixel:p{0,0}]" info:- > color.txt
bg_color=$(cat color.txt)
echo "Background color detected: $bg_color"

# Step 2: Create a mask
echo "Step 2: Creating a mask"
convert "$input_file" -fuzz ${fuzz_value}% -fill white +opaque "$bg_color" -fill black -opaque "$bg_color" "${base_name}_mask.png"

# Step 3: Apply the mask to the original image
echo "Step 3: Applying the mask"
convert "$input_file" "${base_name}_mask.png" -alpha Off -compose CopyOpacity -composite "${base_name}_transparent.png"

# Step 4: Clean up edges
echo "Step 4: Cleaning up edges"
convert "${base_name}_transparent.png" -channel alpha -blur 0x1 -level 50x100% "${base_name}_final.png"

echo "Process completed. Check these files:"
echo "1. ${base_name}_mask.png (black and white mask)"
echo "2. ${base_name}_transparent.png (initial transparency)"
echo "3. ${base_name}_final.png (final result with cleaned edges)"
echo ""
echo "If the result isn't satisfactory, try adjusting the fuzz value:"
echo "Current fuzz value: ${fuzz_value}%"
echo "Usage: $0 <input_image> <fuzz_value>"
echo "Example: $0 $input_file 15"