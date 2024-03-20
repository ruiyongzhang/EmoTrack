import json, sys, os
from openai import OpenAI
from datetime import datetime, timezone
from dateutil import parser
from google.cloud import firestore
from google.oauth2 import service_account
from google.api_core.exceptions import DeadlineExceeded
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common import TimeoutException
from selenium.common.exceptions import StaleElementReferenceException, NoSuchElementException, ElementClickInterceptedException

os.environ["OPENAI_API_KEY"] = "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"

client = OpenAI(
    # Defaults to os.environ.get("OPENAI_API_KEY")
    api_key=os.environ.get("OPENAI_API_KEY") 
)

try:
  gcs_credentials = service_account.Credentials.from_service_account_file("sms-app-project-415923-5cd00cff4d32.json")
  db = firestore.Client(credentials=gcs_credentials)
except Exception as e:
  print(f"An unexpected error occurred: {e}")

# Define your time range
start_time = datetime.strptime('2024-02-14 00:00:00', '%Y-%m-%d %H:%M:%S').replace(tzinfo=timezone.utc)
end_time = datetime.strptime('2024-02-18 00:00:00', '%Y-%m-%d %H:%M:%S').replace(tzinfo=timezone.utc)

# Function to parse ISO 8601 formatted string to a datetime object
def convert_time(iso_time_str):
    return parser.isoparse(iso_time_str)

def filter_scrape_categorise(uid):
  print('1111111')
  # sub_collection_path = 
  history_ref = db.collection('Users').document(uid).collection('YouTube Watch History')
  history_docs = history_ref.stream()
  # print(len(history_docs))
  try:
    # enable the headless mode
    options = Options()
    options.add_argument('--headless')

    # initialize a web driver instance to control a Chrome window
    driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()), options=options)
  
  
    for history_doc in history_docs:
      if start_time <= convert_time(history_doc.id) <= end_time:
        print('22222')
        video_data = history_doc.to_dict()
        video_title = video_data.get('title', 'null')
        watch_time = video_data.get('time', 'null')
        video_url = video_data.get('titleUrl', 'null')
        video_url = video_url.strip()
        print(video_title)
        
        if 'description' in video_data and 'category' in video_data:
          print('Already has description and category')
          continue
        
        try:
          video_description = scrape_info(video_url, driver)
          try:
            content = "Categorise the YouTube video in one word accoding to its title and description, the title is: " + video_title + " and the description is: " + video_description
            chat_completion = client.chat.completions.create(
                model="gpt-4",
                messages=[{"role": "user", "content": content}]
            )
            video_category = chat_completion.choices[0].message.content
          except AttributeError as e:
            print(f"An error occurred: {e}")
          
          history_ref.document(history_doc.id).update({'description': video_description, 'category': video_category})
        except TimeoutException:
          print(f"Timeout while scraping info from {video_url}")
          continue
   
  except DeadlineExceeded:
    print("Query took too long to complete. Please try again with a smaller dataset or a faster network connection.")
  except Exception as e:
    print(f"An unexpected error occurred: {e}")
  finally:
    driver.quit()
  
           
    
def scrape_info(url, driver):
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

    try:
      WebDriverWait(driver, 15).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'h1.ytd-watch-metadata'))
      )
      title = driver \
          .find_element(By.CSS_SELECTOR, 'h1.ytd-watch-metadata') \
          .text
      WebDriverWait(driver, 15).until(
        EC.visibility_of_element_located((By.ID, 'description-inline-expander'))
      )
      driver.find_element(By.ID, 'description-inline-expander').click()

      description = driver \
        .find_element(By.CSS_SELECTOR, '#description-inline-expander .ytd-text-inline-expander span') \
        .text
    except StaleElementReferenceException:
      description = "No description found"
    except NoSuchElementException:
      description = "No description found"
    except ElementClickInterceptedException:
      description = "No description found"

    return description
  
  except TimeoutException:
    return "Timeout waiting for page to load"

    
    

uid = 'qKtXmGL42mZAfwSYEnsLdDmA1lF2'
filter_scrape_categorise(uid)
