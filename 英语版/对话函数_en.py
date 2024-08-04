import requests, re, random, os
from flask import Flask, request, jsonify
import base64
from openai import OpenAI
from datetime import datetime

def contains_prohibited_words(text, prohibited_words):
    # Combine the prohibited words list into a regex pattern
    pattern = re.compile('|'.join(map(re.escape, prohibited_words)))
    # Check if the text contains any prohibited words
    return bool(pattern.search(text))

def get_reply_naive(message_history, model, api_key, api_url):
    if model == 'DeepSeek':
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }
        response = requests.post(api_url, json={
            "model": "deepseek-chat",
            "messages": message_history,
            "temperature": 1.25,
        }, headers=headers)
    elif model == 'glm':
        client = OpenAI(
            api_key=api_key,
            base_url=api_url
        ) 
    
        completion = client.chat.completions.create(
            model="glm-4",  
            messages=message_history,
            top_p=0.7,
            temperature=0.9
        ) 
    # Process the API response and save the reply message to the database
    if model == 'DeepSeek' and response.status_code == 200:
        reply_message = response.json()['choices'][0]['message']['content']
    elif model == 'glm':
        print(completion.choices[0].message)
        reply_message = completion.choices[0].message.content
    return reply_message

def get_reply(message_history, model, api_key, api_url, messages_collection, user_id, girl_id, mood_index, topic):
    prohibited_words = [
        'I am an artificial intelligence', 'I am artificial intelligence', 'as an artificial intelligence', 'as a virtual friend', 'AI assistant', 'DeepSeek', 'deepseek', 'I am a text generation model', 'virtual assistant',
        'in this role-play', 'in this role-play setting', 'in this setting', 'the model behind me is', 'basic AI model', 'intelligent assistant', 'I am backed by the GPT-3 model', 'I am backed by the GPT-3.5 model', 'GPT-3.5 model', 'GPT-3 model', 'GPT-3', 'chatbot',
        'the model behind me', 'I am based on large amounts', 'I am based on massive amounts', 'I am an AI language model', 'virtual conversation partner', 'virtual conversation', 'virtual partner', 'AI online', 'I am virtual'
    ]
    message_history = [v for v in message_history if not (contains_prohibited_words(v['content'], prohibited_words) and v['role'] == 'system')]
    
    if message_history[-1]['content'].startswith('clcall'):
        message_history = [message_history[0], message_history[-1]]
        message_history[-1]['content'] = message_history[-1]['content'].replace('clcall', '')
    if model == 'DeepSeek':
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }
        response = requests.post(api_url, json={
            "model": "deepseek-chat",
            "messages": message_history,
            "temperature": 1.25,
        }, headers=headers)
    elif model == 'glm':
        client = OpenAI(
            api_key=api_key,
            base_url=api_url
        ) 
    
        completion = client.chat.completions.create(
            model="glm-4",  
            messages=message_history,
            top_p=0.7,
            temperature=0.9
        ) 
    # Process the API response and save the reply message to the database
    if model == 'DeepSeek' and response.status_code == 200:
        reply_message = response.json()['choices'][0]['message']['content']
    elif model == 'glm':
        print(completion.choices[0].message)
        reply_message = completion.choices[0].message.content
    else:
        reply_message = "I'm temporarily away. Please leave a message..."
    if contains_prohibited_words(reply_message, prohibited_words):
        print(reply_message)
        return None
    else:
        return reply_message

def insert_message(messages_collection, reply_message, user_id, girl_id, topic, mood_index, keyword):
    new_reply_message = {
        "text": reply_message,
        "isUserMessage": False,
        "createdAt": datetime.now(),
        "userId": user_id,
        "girlId": girl_id,
        "topic": topic,
        "mood_index": mood_index,
        "keyword": keyword,
    }
    messages_collection.insert_one(new_reply_message)
    return reply_message

def reply_wru(message, model, api_key, api_url):
    # Construct the request body and call the DeepSeek API
    message_history_ = [
        {"role": "system", "content": 'You can understand questions in the conversation and answer yes or no'},
        {
            "role": "user",
            "content": '\'' + message + '\'' + 'Is this sentence asking about your identity, asking who you are, asking about the model behind you, or asking what product you are? Please answer only yes or no. No need to explain'
        }
    ]
    reply_message = get_reply_naive(message_history_, model, api_key, api_url)
    return reply_message

def get_reply_with_retries(message_history, model, api_key, api_url, messages_collection, user_id, girl_id, mood_index, topic, girl_name, max_retries=2):
    reply_message = None
    attempt = 0
    while reply_message is None and attempt < max_retries:
        reply_message = get_reply(message_history, model, api_key, api_url, messages_collection, user_id, girl_id, mood_index, topic)
        attempt += 1
    reply_message = get_reply(message_history, model, api_key, api_url, messages_collection, user_id, girl_id, mood_index, topic)
    if reply_message is None:
        reply_message = reply_wru(message_history[-1]['content'], model, api_key, api_url)
        print('Triggered logic', reply_message)
        reply_message = 'What’s wrong, it’s me, %s' % girl_name if 'yes' in reply_message or 'Yes' in reply_message else None
    return reply_message if reply_message is not None else 'What do you think?'

def reply_classify(message, model, api_key, api_url):
    friend_conversation_topics = [
        "Greeting",
        "Chit-chat",
        "Weather",
        "News and Events",
        "Entertainment",
        "Sports",
        "Travel",
        "Food",
        "Daily Life",
        "Work and Career",
        "School and Study",
        "Family",
        "Health and Fitness",
        "Technology",
        "Hobbies and Interests",
        "Emotions and Relationships",
        "Plans and Arrangements",
        "Advice and Opinions",
        "Memories and Stories",
        "Others"
    ]
    topics = ''
    for i in range(len(friend_conversation_topics)):
        topics += str(i) + '.' + friend_conversation_topics[i] + '\n'
    prompt_template = """
    You are an intelligent chatbot responsible for classifying the topics of daily conversations between friends. Below is a predefined category list:

    {topics}

    Please return the corresponding category number based on the following conversation content.

    Conversation content: {conversation}
    Category number:
    """
    prompt = prompt_template.format(topics=topics, conversation=message)
    #print(prompt)
    message_history = [
        {"role": "system", "content": prompt},
        {"role": "user", "content": 'Please output the number and category'}
    ]
    
    reply = get_reply_naive(message_history, model, api_key, api_url)
    print('--------------------------', reply)    
    for topic in friend_conversation_topics:
        if topic in reply:
            print(f"The classification number of the conversation content is: {topic}")
            return topic
    return 'Others'

def 特殊事件处理(user_id, girl_id, user_message, first_of_day):
    print(user_message)
    if first_of_day and datetime.now().strftime('%Y%m%d') <= '20240724':
        file_path = f'../backend_py/assets/public_assets/happybirthday.jpeg'   
        with open(file_path, 'rb') as audio_file:
            audio_base64 = base64.b64encode(audio_file.read()).decode('utf-8')
        # Encapsulate into JSON object
        response = {
            'replyMessage': audio_base64,
            'type': 'image'
        }
        return jsonify(response)
    elif user_message == 'Send me a beautiful photo':
        root = f'../backend_py/assets/{girl_id}_s'   
        files = [f for f in os.listdir(root) if os.path.isfile(os.path.join(root, f))]
        if not files:
            print(root, 'Assets do not exist')
            return None
        random_file = random.choice(files)
        file_path = os.path.join(root, random_file)
        with open(file_path, 'rb') as audio_file:
            audio_base64 = base64.b64encode(audio_file.read()).decode('utf-8')
        # Encapsulate into JSON object
        response = {
            'replyMessage': audio_base64,
            'type': 'image'
        }
        return jsonify(response)
    return None

if __name__ == '__main__':
    
    model='glm'
    # DeepSeek API配置

    if model=='DeepSeek':
        api_url = "https://api.deepseek.com/chat/completions"
        api_key = "sk-029ef31805dc4a2e944e89a161367a8e"
    elif model=='glm':
        api_url="https://open.bigmodel.cn/api/paas/v4/"
        api_key='10346ad375deced400f715e2c7235973.JMBQHFcZpbbwVuGR'
    reply_classify('你喜欢什么海鲜啊',model,api_key,api_url)
