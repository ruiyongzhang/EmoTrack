import os, json
from openai import OpenAI

os.environ["OPENAI_API_KEY"] = "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"

client = OpenAI(
    # Defaults to os.environ.get("OPENAI_API_KEY")
    api_key=os.environ.get("OPENAI_API_KEY") 
)

with open("scraped_data.json", "r") as file:
    data = json.load(file)
    
for item in data:
    title = item["title"]
    description = item["description"]

    content = "Categorise the YouTube video in one word accoding to its title and description, the title is: " + title + " and the description is: " + description



    chat_completion = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": content}]
    )

    print(chat_completion.choices[0].message.content)