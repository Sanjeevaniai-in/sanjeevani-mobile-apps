from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
import math

def create_logo():
    size = 1024
    center = size // 2
    bg_color = (10, 10, 20) # Very dark blue/black
    primary_color = (0, 255, 255) # Cyan/Electric Blue
    secondary_color = (255, 60, 60) # Alert Red
    lens_color = (20, 20, 40) # Dark gray/blue for lens

    # Create image
    img = Image.new('RGB', (size, size), bg_color)
    draw = ImageDraw.Draw(img)

    # 1. Outer Tech Ring (dashed/segmented)
    outer_radius = 420
    segments = 4
    gap = 20  # degrees
    active_segment_angle = (360 / segments) - gap
    
    for i in range(segments):
        start_angle = i * (360 / segments) + gap/2
        end_angle = start_angle + active_segment_angle
        draw.arc(
            [(center - outer_radius, center - outer_radius), 
             (center + outer_radius, center + outer_radius)], 
            start=start_angle, end=end_angle, fill=primary_color, width=30
        )

    # 2. Middle Lens Housing
    middle_radius = 320
    draw.ellipse(
        [(center - middle_radius, center - middle_radius), 
         (center + middle_radius, center + middle_radius)], 
        outline=(100, 200, 255), width=15
    )

    # 3. Inner Lens (The "Eye")
    inner_radius = 180
    draw.ellipse(
        [(center - inner_radius, center - inner_radius), 
         (center + inner_radius, center + inner_radius)], 
        fill=lens_color, outline=primary_color, width=10
    )

    # 4. Pupil / Camera sensor (Glowing center)
    pupil_radius = 80
    draw.ellipse(
        [(center - pupil_radius, center - pupil_radius), 
         (center + pupil_radius, center + pupil_radius)], 
        fill=(0, 200, 255)
    )
    
    # 5. Red "Recording" or "Alert" dot (small accent)
    dot_radius = 30
    dot_offset = 260
    # Top Right Quadrant
    dot_x = center + dot_offset * math.cos(math.radians(-45))
    dot_y = center + dot_offset * math.sin(math.radians(-45))
    
    draw.ellipse(
        [(dot_x - dot_radius, dot_y - dot_radius), 
         (dot_x + dot_radius, dot_y + dot_radius)], 
        fill=secondary_color
    )

    # Save
    try:
        img.save('assets/icons/app_icon.png')
        print("Logo generated at assets/icons/app_icon.png")
    except Exception as e:
        print(f"Error saving logo: {e}")

if __name__ == "__main__":
    create_logo()
