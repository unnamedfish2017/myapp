from flask import Flask, request, jsonify
import pymongo,json
from pymongo import MongoClient, errors
import requests
from datetime import datetime
from 对话设定_en import *
import time,re
from 随机事件_en import *
from zhipuai import ZhipuAI
from openai import OpenAI
from 对话函数_en import *
import base64
from PIL import Image
app = Flask(__name__)

# MongoDB 连接配置
# MongoDB connection configuration
mongo_client = MongoClient("mongodb://localhost:27017/")
db = mongo_client["chat-app"]
messages_collection = db["messages"]
collection = db['messages_settings']
accounts_collection = db['accounts']
try:
    accounts_collection.create_index("username", unique=True)
except errors.CollectionInvalid:
    print("Accounts Index already exists.")

model='DeepSeek'
# DeepSeek API configuration

if model=='DeepSeek':
    api_url = "https://api.deepseek.com/chat/completions"
    api_key = "sk-029ef31805dc4a2e944e89a161367a8e"
elif model=='glm':
    api_url="https://open.bigmodel.cn/api/paas/v4/"
    api_key='10346ad375deced400f715e2c7235973.JMBQHFcZpbbwVuGR'

def get_time_period():
    now = datetime.now()
    hour = now.hour

    if 5 <= hour < 7:
        return "early morning"
    elif 7 <= hour < 11:
        return "morning"
    elif 11 <= hour < 13:
        return "noon"
    elif 13 <= hour < 17:
        return "afternoon"
    elif 17 <= hour < 19:
        return "evening"
    elif 19 <= hour < 23:
        return "night"
    else:
        return "late night"

def generate_additional_config(user_id, girl_id, collection, recent_messages, keyword):
    latest_record = collection.find_one(
        {"userId": user_id, "girlId": girl_id},
        sort=[("current_date", pymongo.DESCENDING)]
    )
    print(latest_record)

    weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][datetime.now().weekday()]
    overall_affinity = int(latest_record['overall_affinity'])
    mood_index = int(latest_record['mood_index'])

    affinity_level = 10

    affection_levels = {
        10: "You have a deep affection for me, our emotional connection is very close, we are in love, you think of me every moment."
    }

    additional_setting = f'Now it is {weekday} {get_time_period()}, {affection_levels[int(affinity_level)]}'
    print(weekday, 'Affection Level', affinity_level)

    recent_system_messages = [
        msg for msg in recent_messages if msg.get("isUserMessage") == False
    ]

    if len(recent_system_messages) > 0:
        latest_message_date = recent_system_messages[-1]['createdAt']
        now = datetime.now()
        time_delta = now - latest_message_date
        hours_diff = time_delta.total_seconds() / 3600
        print(f"Hours since the last record: {hours_diff:.2f}")
        topic = recent_system_messages[-1]['topic'] if 'topic' in recent_system_messages[-1] else None
        mood_index = recent_system_messages[-1]['mood_index'] if 'mood_index' in recent_system_messages[-1] else mood_index
        mood_index += random.random() - 0.5
    else:
        hours_diff = 10000
        topic = None

    mood_levels = {
        1: "Mood is heavy, like a sky full of dark clouds, even breathing feels oppressive.",
        2: "Mood is low, like a drizzle, bringing a sense of coolness and melancholy.",
        3: "Mood is calm, like a tranquil lake, without much fluctuation, but also lacks brilliance.",
        4: "Mood is light, like a warm spring breeze, bringing comfort and a hint of joy.",
        5: "Mood is excellent, like a sunny summer day, full of energy and infinite joy.",
    }
    mood_index_ = max(1, min(5, round(mood_index)))
    additional_setting += mood_levels[mood_index_]
    if int(affinity_level) >= 7 and mood_index_ <= 2:
        additional_setting += 'You are very eager for my comfort.'
    elif int(affinity_level) <= 3 and mood_index_ <= 2:
        additional_setting += 'You do not really want to talk to me.'

    if int(affinity_level) >= 7 and hours_diff >= 1 and (datetime.now().hour >= 22 or datetime.now().hour <= 8) or random.random() > .95 and topic is None or random.random() > .95:
        topic = get_topic(True)
    elif int(affinity_level) >= 7 and hours_diff >= 1 or random.random() > .95 and topic is None or random.random() > .95:
        topic = get_topic()
    if random.random() > .8 or 'do not really want to talk to me' in additional_setting or keyword is not None:
        topic = None
    if topic is not None:
        print('Triggered topic', topic)
        additional_setting += f'You will proactively discuss the topic of {topic} with me.'
    return affinity_level, additional_setting, topic, mood_index

# Define routes and view functions
@app.route('/register', methods=['POST'])
def handle_register():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    print('=========================================================', username, password)
    account = accounts_collection.find_one({"username": username})

    invalid_chars_pattern = r'[^a-zA-Z0-9_]'
    if re.search(invalid_chars_pattern, username):
        reply_message = 'The username contains special characters, please choose another one~~'
        statusCode = 401
    elif account and account.get('password') != password:
        reply_message = 'The username is already registered, please choose another one~~'
        statusCode = 401
    elif len(password) < 4:
        reply_message = 'The password is too simple, please use a password of at least 4 characters~~'
        statusCode = 401
    else:
        accounts_ = {
            "username": username,
            "password": password,
        }
        accounts_collection.insert_one(accounts_)
        reply_message = 'OK'
        statusCode = 200
    return jsonify({"message": reply_message}), statusCode

@app.route('/login', methods=['POST'])
def handle_login():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    print('=========================================================', username, password)
    account = accounts_collection.find_one({"username": username})

    invalid_chars_pattern = r'[^a-zA-Z0-9_]'
    if not account:
        reply_message = 'The username does not exist, please register first~~'
        statusCode = 401
    elif account and account.get('password') != password:
        reply_message = 'Incorrect password~~'
        statusCode = 401
    else:
        reply_message = 'OK'
        statusCode = 200
    return jsonify({"message": reply_message}), statusCode

@app.route('/messages', methods=['POST'])
def handle_message():
    data = request.json
    user_message = data.get('content')
    user_id = data.get('userId')
    girl_id = data.get('girlId')
    current_date = datetime.now().date()  # Get the current date
    
    print(user_id, girl_id, user_message)
    first_of_the_day = 初始化设定(user_id, girl_id, current_date, messages_collection, collection)
    
    special_return = 特殊事件处理(user_id, girl_id, user_message, first_of_the_day)
    if special_return is not None:
        return special_return
    
    keyword = reply_classify(user_message, model, api_key, api_url)
    # Save user message to the database
    new_user_message = {
        "text": user_message,
        "isUserMessage": True,
        "createdAt": datetime.now(),
        "userId": user_id,
        "girlId": girl_id,
        "topic": None,
        "keyword": keyword,
    }
    messages_collection.insert_one(new_user_message)

    # Query the most recent N messages
    # N=10
    # recent_messages = list(messages_collection.find(
    #     {"userId": user_id, "girlId": girl_id}
    # ).sort("createdAt", pymongo.DESCENDING).limit(N))[::-1]

    # Find the most recent N records with the same userId and girlId, and keyword equal to the specified value
    N1 = 10
    query_with_keyword = {
        "userId": user_id,
        "girlId": girl_id,
        "keyword": keyword
    }

    # Find the most recent N records with the same userId and girlId
    N2 = 4
    query_without_keyword = {
        "userId": user_id,
        "girlId": girl_id
    }

    # Execute the query, sort by createdAt in descending order, and take the most recent N records
    messages_with_keyword = list(messages_collection.find(query_with_keyword).sort("createdAt", pymongo.DESCENDING).limit(N1))
    messages_without_keyword = list(messages_collection.find(query_without_keyword).sort("createdAt", pymongo.DESCENDING).limit(N2))

    # Merge the two query results and remove duplicates
    combined_messages = {message['_id']: message for message in messages_with_keyword + messages_without_keyword}
    recent_messages = list(combined_messages.values())
    # Sort the final result by createdAt in ascending order
    recent_messages.sort(key=lambda x: x['createdAt'])

    # Generate additional configuration
    affinity_level, additional_setting, topic, mood_index = generate_additional_config(user_id, girl_id, collection, recent_messages, keyword)
    print({"userId": user_id, "girlId": girl_id})
    # Set initialSystemMessage based on girlId
    if girl_id == 'Chloe':
        initial_system_message = 'You are my girl friend, the person I love most in the world. You usually speak very briefly, keeping within 10 words. Only when you are in a very good mood will you occasionally give long replies,'\
            # .replace('you', 'you').replace('me', 'you').replace('you', 'me');
        girl_name = 'Chloe'
    else:
        return jsonify({"replyMessage": 'I have walked away~','type':'text'})
    initial_system_message += additional_setting
    # print(initial_system_message)
    # Construct the request body and call the DeepSeek API
    message_history = [
        {"role": "system", "content": initial_system_message},
        *[
            {
                "role": "user" if msg["isUserMessage"] else "assistant",
                "content": msg["text"]
            }
            for msg in recent_messages
            if msg["text"].strip()
        ]
    ]
    print(message_history)
    
    reply_message = get_reply_with_retries(message_history, model, api_key, api_url, messages_collection, user_id, girl_id, mood_index, topic, girl_name, max_retries = 2)
    insert_message(messages_collection, reply_message, user_id, girl_id, topic, mood_index, keyword)
    
    if len(reply_message) < 10 and random.random() > .9 and reply_message != 'I have walked away for a while...':  #####################################When replying briefly, there is a probability of triggering two replies
    # if True:
        message_history.append({"role": "system", "content": reply_message})
        message_history.append({"role": "user", "content": 'Continue'})
        reply_message_add = get_reply(message_history, model, api_key, api_url, messages_collection, user_id, girl_id, mood_index, topic)
        insert_message(messages_collection, reply_message, user_id, girl_id, topic, mood_index, keyword)
        reply_message = [reply_message, reply_message_add]
    
    response = {"replyMessage": reply_message, 'type': 'text'}
    return jsonify(response)
    # return jsonify({"replyMessage": "I have temporarily walked away, please leave a message if you have anything..."}), 500

if __name__ == '__main__':
    # app.run(host='0.0.0.0', port=3000, debug=True)
    app.run(host='127.0.0.1', port=5002)
