import sys, json
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import NoSuchElementException, TimeoutException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By

scraped_data = []

def scrape_title_and_description(url, driver):
    try:
        driver.get(url)
        try:
            # wait up to 15 seconds for the consent dialog to show up
            consent_overlay = WebDriverWait(driver, 15).until(
                EC.presence_of_element_located((By.ID, 'dialog'))
            )
            # select the consent option buttons
            consent_buttons = consent_overlay.find_elements(By.CSS_SELECTOR, '.eom-buttons button.yt-spec-button-shape-next')
            if len(consent_buttons) > 1:
                # retrieve and click the 'Accept all' button
                accept_all_button = consent_buttons[1]
                accept_all_button.click()
        except TimeoutException:
            print('Cookie modal missing')
            
        # Wait for the title to be visible
        WebDriverWait(driver, 15).until(EC.visibility_of_element_located((By.CSS_SELECTOR, 'h1.ytd-watch-metadata')))
        # initialize the dictionary that will contain
        # the data scraped from the YouTube page
        video = {}

        # scraping logic
        title = driver \
            .find_element(By.CSS_SELECTOR, 'h1.ytd-watch-metadata') \
            .text
            
        # click the description section to expand it
        driver.find_element(By.ID, 'description-inline-expander').click()
        
        try:
            description = driver \
              .find_element(By.CSS_SELECTOR, '#description-inline-expander .ytd-text-inline-expander span') \
              .text
        except NoSuchElementException:
            description = "No description found"
        return title, description
    except TimeoutException:
        return "Timeout waiting for page to load", "Timeout waiting for page to load"

def main(urls_file):
    options = Options()
    # Uncomment the next line if you want the browser to run headlessly
    # options.add_argument('--headless')
    driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()),  options=options)

    try:
        with open(urls_file, 'r') as file:
            urls = file.readlines()
        
        for url in urls:
            url = url.strip()  # Remove any leading/trailing whitespace
            title, description = scrape_title_and_description(url, driver)
            # print(f"URL: {url}\nTitle: {title}\nDescription: {description}\n")
            # Append a dictionary for each URL's data to the list
            scraped_data.append({
                'url': url,
                'title': title,
                'description': description
            })
    finally:
        driver.quit()
    
    with open('scraped_data.json', 'w', encoding='utf-8') as file:
      json.dump(scraped_data, file, indent=4)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python scraper.py <urls_file>")
        sys.exit(1)
    
    urls_file = sys.argv[1]
    main(urls_file)
