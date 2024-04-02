from selenium import webdriver
import time
import os
import glob
import json
import requests
from PIL import Image, ImageDraw, ImageFont

def url_from_file(filename):
    target_url = 'https://ipinfo.io/tools/map?cli=1'
    headers = {
        'user-agent': 'curl/7.81.0',
        'accept': '*/*',
        'content-type': 'application/x-www-form-urlencoded'
    }

    with open(filename, 'rb') as file:
        files = {"file": file}

        # Make the POST request with files and headers
        response = requests.post(target_url, files=files, headers=headers)

        if response.status_code == 200:
            data = response.json()
            report_url = data.get('reportUrl')
            return report_url
        else:
            print("Failed to retrieve report URL.")
            print("Response:", response.text)  # Print the response if retrieval fails
            return None

def capture_screenshot(url, filename):
    options = webdriver.ChromeOptions()
    options.add_argument('--headless')  # Run in headless mode (without opening a browser window)
    options.add_argument('--window-size=1920,1080')  # Set viewport size to 1920x1080
    driver = webdriver.Chrome(options=options)

    driver.get(url)
    time.sleep(1)  # Wait for 5 seconds for the page to fully load (adjust as needed)
    driver.save_screenshot(filename + ".png")

    driver.quit()


def add_date_overlay(file, caption):
    output = os.path.splitext(file)[0] + "-captioned.png"
    
    if not os.path.isfile(output):
        image = Image.open(file)
        draw = ImageDraw.Draw(image)
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", 54)
        draw.text((10, 10), caption, fill="black", font=font)
        image.save(output)
    else:
        print(f"Skipping caption file (PNG already exists)")

# ip_list_filename = 'input.txt'
# report_url = url_from_file(ip_list_filename)
# capture_screenshot(report_url, ip_list_filename + '.png')

output_folder = "./output"
file_paths = sorted(glob.glob(os.path.join(output_folder, "*.txt")))
# for file_path in file_paths:
#     # if os.path.isfile(file_path):
#     #     # Capture screenshot for the URL with the same name as the file
#     #     capture_screenshot(url, file_name)
#     print("Processing file:", file_path)
#     url = url_from_file(file_path)
#     print("            url:", url)
#     capture_screenshot(url, file_path)
for file_path in file_paths:
    # Construct the corresponding PNG file path
    png_file_path = file_path + ".png"
    cap = png_file_path[9:19]
    
    # try outputting the captioned slide...
    add_date_overlay(png_file_path, cap)
    
    # Check if the PNG file exists
    if os.path.isfile(png_file_path):
        print("Skipping file (PNG already exists):", file_path)
        continue

    # Proceed with processing the file
    print("Processing file:", file_path)
    # Assuming you have a function to extract the URL from the file
    url = url_from_file(file_path)
    print("URL:", url)
    # Assuming you have a function to capture the screenshot
    capture_screenshot(url, file_path)