import os
import subprocess
from PIL import Image

# Get the script's directory and construct absolute paths
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
input_dir = os.path.join(project_root, "assets", "icons", "imports")
output_dir = os.path.join(project_root, "assets", "icons", "svgs")

print(f"Script directory: {script_dir}")
print(f"Project root: {project_root}")
print(f"Input directory: {input_dir}")
print(f"Output directory: {output_dir}")

# Check if input directory exists
if not os.path.exists(input_dir):
    print(f"Error: Input directory does not exist: {input_dir}")
    exit(1)

os.makedirs(output_dir, exist_ok=True)

for filename in os.listdir(input_dir):
    if filename.lower().endswith(".png"):
        input_path = os.path.join(input_dir, filename)
        pbm_path = os.path.join(output_dir, os.path.splitext(filename)[0] + ".pbm")
        svg_path = os.path.join(output_dir, os.path.splitext(filename)[0] + ".svg")
        
        # Check if SVG already exists
        if os.path.exists(svg_path):
            print(f"Skipped: {filename} → {os.path.basename(svg_path)} (already exists)")
            continue

        # Convert PNG to monochrome PBM
        img = Image.open(input_path).convert("L")
        img = img.point(lambda p: 0 if p < 128 else 255, '1')
        img.save(pbm_path)

        # Call potrace with white background
        subprocess.run(["potrace", pbm_path, "-s", "-o", svg_path])
        
        # Read the generated SVG and add white background
        with open(svg_path, 'r') as f:
            svg_content = f.read()
        
        # Add white background by inserting fill="white" in the SVG
        # Find the first <path> tag and add a white background rectangle before it
        if '<path' in svg_content:
            # Insert a white background rectangle at the beginning of the SVG content
            white_bg = '<rect width="100%" height="100%" fill="white"/>'
            # Find the position after the opening <svg> tag
            svg_start = svg_content.find('<svg')
            if svg_start != -1:
                # Find the end of the opening svg tag
                svg_tag_end = svg_content.find('>', svg_start) + 1
                # Insert white background after the opening svg tag
                svg_content = svg_content[:svg_tag_end] + '\n  ' + white_bg + svg_content[svg_tag_end:]
        
        # Write the modified SVG back
        with open(svg_path, 'w') as f:
            f.write(svg_content)
        
        # Resize SVG to 1024x1024 pixels
        # Read the SVG content again to modify dimensions
        with open(svg_path, 'r') as f:
            svg_content = f.read()
        
        # Update SVG dimensions to 1024x1024
        # Find and replace width and height attributes
        import re
        
        # Replace width and height attributes
        svg_content = re.sub(r'width="[^"]*"', 'width="1024"', svg_content)
        svg_content = re.sub(r'height="[^"]*"', 'height="1024"', svg_content)
        
        # Update viewBox if it exists
        svg_content = re.sub(r'viewBox="[^"]*"', 'viewBox="0 0 1024 1024"', svg_content)
        
        # Write the resized SVG back
        with open(svg_path, 'w') as f:
            f.write(svg_content)
        
        # Clean up the temporary PBM file
        if os.path.exists(pbm_path):
            os.remove(pbm_path)

        print(f"Converted: {filename} → {os.path.basename(svg_path)} (1024x1024 with white background)")
