import os
from PIL import Image

def cut_icons():
    sheet_path = r"C:\Users\aktuv\.gemini\antigravity\brain\64318609-86d4-4376-b3bb-cda2628e9d76\tumbahub_premium_icons_sheet_1775489374602.png"
    
    img = Image.open(sheet_path).convert("RGBA")
    w, h = img.size
    
    rows, cols = 3, 4
    icon_w, icon_h = w // cols, h // rows
    
    output_dir = r"c:\Users\aktuv\Downloads\TumbaHub-main (3)\TumbaHub-main\tumbaHub\icon"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    names = [
        "aim", "bot", "combat", "esp",
        "kit", "home", "player", "settings",
        "updates", "users", "utils", "visuals"
    ]
    
    idx = 0
    for r in range(rows):
        for c in range(cols):
            if idx < len(names):
                left = c * icon_w
                top = r * icon_h
                right = left + icon_w
                crop_bottom = top + int(icon_h * 0.78) 
                icon = img.crop((left, top, right, crop_bottom))
                
                # Convert to grayscale to evaluate brightness
                gray = icon.convert("L")
                
                # Map background (dark) to 0 alpha, and bright shapes to 255
                def contrast_mask(p):
                    if p < 50: return 0
                    elif p > 150: return 255
                    else: return int(((p - 50) / 100.0) * 255)
                    
                alpha = gray.point(contrast_mask)
                
                # Create a solid white image and apply our intelligent alpha mask
                new_icon = Image.new("RGBA", icon.size, (255, 255, 255, 255))
                new_icon.putalpha(alpha)
                
                # Trim empty transparent space around the icon so it aligns perfectly in UI
                bbox = new_icon.getbbox()
                if bbox:
                    new_icon = new_icon.crop(bbox)
                
                new_icon.save(os.path.join(output_dir, f"{names[idx]}.png"))
                print(f"Saved perfectly transparent {names[idx]}.png")
                idx += 1

if __name__ == "__main__":
    cut_icons()
