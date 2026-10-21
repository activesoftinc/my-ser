import pyautogui as pag
import time
import requests
import os

# Define actions with coordinates and duration
actions = [
    (516, 405, 4),  # install (wait 15sec)
    (50, 100, 1),   # tic launch avica
    (249, 203, 4),  # allow rdp (attempt to activate the Allow button)
    (249, 203, 4),  # allow rdp (attempt to activate the Allow button again)
    (249, 203, 4),  # allow rdp (attempt to activate the Allow button again)
    (249, 203, 4),  # allow rdp (attempt to activate the Allow button again)
    (447, 286, 4),  # ss id & upload (launch avica and take screenshot and send to gofile)
]

# Give time to focus on the target application
time.sleep(10)

# Credentials and upload information
img_filename = 'AvicaRemoteIDFixed.png'

# Upload to Gofile.io
def upload_image_to_gofile(img_filename):
    url = 'https://store1.gofile.io/uploadFile'
    try:
        with open(img_filename, 'rb') as img_file:
            files = {'file': img_file}
            response = requests.post(url, files=files)
            response.raise_for_status()
            result = response.json()

            if result['status'] == 'ok':
                download_page = result['data']['downloadPage']
                with open('show.bat', 'a') as bat_file:
                    bat_file.write(f'\necho Avica Remote ID : {download_page}')
                return download_page
            else:
                print("Upload error:", result.get('status'))
                return None
    except Exception as e:
        print(f"Failed to upload image: {e}")
        return None

# Check if the mouse is near the corner
def is_mouse_in_corner():
    x, y = pag.position()  # Get the current mouse position
    screen_width, screen_height = pag.size()  # Get screen size
    # Define the corner threshold (e.g., within 5 pixels of the corners)
    threshold = 5

    return (x < threshold and y < threshold) or \
           (x > screen_width - threshold and y < threshold) or \
           (x < threshold and y > screen_height - threshold) or \
           (x > screen_width - threshold and y > screen_height - threshold)

# Iterate through actions
for x, y, duration in actions:
    # Check if the mouse is near a corner before clicking
    if is_mouse_in_corner():
        print("Mouse is near the corner. Skipping action to avoid fail-safe.")
        continue  # Skip the current action if the mouse is in the corner
    
    pag.click(x, y, duration=duration)
    if (x, y) == (249, 203):  # Attempt to activate "Allow remote access"
        time.sleep(1)
        pag.click(x, y, duration=duration)  # Try activating the button again
    
    if (x, y) == (447, 286):  # Launch avica and upload screenshot
        os.system('"C:\\Program Files x86\\Avica\\Avica.exe"')
        time.sleep(5)
        pag.click(249, 203, duration=4)  # Re-click on the Allow button coordinates
        time.sleep(10)
        pag.screenshot().save(img_filename)
        gofile_link = upload_image_to_gofile(img_filename)
        if gofile_link:
            print(f"Image uploaded successfully. Link: {gofile_link}")
        else:
            print("Failed to upload the image.")
    time.sleep(10)

print('Done!')