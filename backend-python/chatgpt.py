import os
from openai import OpenAI

os.environ["OPENAI_API_KEY"] = "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"

client = OpenAI(
    # Defaults to os.environ.get("OPENAI_API_KEY")
    api_key=os.environ.get("OPENAI_API_KEY") 
)

chat_completion = client.chat.completions.create(
    model="gpt-3.5-turbo",
    messages=[{"role": "user", "content": "Hello world"}]
)

print(chat_completion.choices[0].message.content)