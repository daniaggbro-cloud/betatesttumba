import os
from PIL import Image

def cut_icons():
    sheet_path = r"C:\Users\aktuv\Downloads\TumbaHub-main (3)\TumbaHub-main\icon_sheet.png"
    # Ensure we use the correct absolute path from the bot's temporary storage if needed, 
    # but I'll assume the file is copied or accessible.
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
                bottom = top + icon_h
                
                # Adjust crop to exclude text at the bottom (approx top 75% of cell)
                crop_bottom = top + int(icon_h * 0.78) 
                icon = img.crop((left, top, right, crop_bottom))
                
                # Trim transparent/black edges to center the icon
                # (Optional but makes it look better)
                
                # Make black background transparent
                datas = icon.getdata()
                new_data = []
                for item in datas:
                    if item[0] < 5 and item[1] < 5 and item[2] < 5:
                        new_data.append((0, 0, 0, 0))
                    else:
                        new_data.append(item)
                icon.putdata(new_data)
                
                icon.save(os.path.join(output_dir, f"{names[idx]}.png"))
                print(f"Saved {names[idx]}.png")
                idx += 1

if __name__ == "__main__":
    cut_icons()
