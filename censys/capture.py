from selenium import webdriver
import time
import os
import json
import requests

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


# ip_list_filename = 'input.txt'
# report_url = url_from_file(ip_list_filename)
# capture_screenshot(report_url, ip_list_filename + '.png')

output_folder = "./output"
for file_name in os.listdir(output_folder):
    file_path = os.path.join(output_folder, file_name)
    # if os.path.isfile(file_path):
    #     # Capture screenshot for the URL with the same name as the file
    #     capture_screenshot(url, file_name)
    print("Processing file:", file_path)
    url = url_from_file(file_path)
    print("            url:", url)
    capture_screenshot(url, file_path)