import pymongo
from pymongo import MongoClient, ReplaceOne
from datetime import datetime, timedelta
import random



# 定义复合唯一键和要插入的文档


def 初始化设定(userId,girlId,current_date,messages_collection,collection):
    # 查询最近的消息记录
    historical_messages = messages_collection.find(
        {"userId": userId, "girlId": girlId}
    ).sort("createdAt", pymongo.DESCENDING)

    # 获取第一个消息和消息总数
    first_message = next(historical_messages, None)
    message_count = messages_collection.count_documents({"userId": userId, "girlId": girlId})

    # 如果存在最早的对话记录，计算日期差
    if first_message:
        first_message_date = first_message["createdAt"].date()
        # 计算距离今天的天数
        days_since_first_message = (current_date - first_message_date).days
    else:
        days_since_first_message = 0

    # 设置好感度
    if girlId == 'xiaoxia':
        overall_affinity = 50
    elif girlId == 'shihan':
        overall_affinity = 70
    else:
        overall_affinity = 0  # 默认值

    # 查找最近一个记录
    latest_record = collection.find_one(
        {"userId": userId, "girlId": girlId},
        sort=[("current_date", pymongo.DESCENDING)]
    )

    if latest_record and latest_record.get("current_date") == current_date.isoformat():
        print("已经初始化")
        print(latest_record)
        return False
    
    # 查找最近一天的消息数
    if latest_record:
        last_date_str = latest_record['current_date']
        last_date = datetime.fromisoformat(last_date_str).date() 
        last_datetime = datetime.combine(last_date, datetime.min.time())
        current_datetime = datetime.combine(current_date, datetime.min.time())
        previous_day_messages_count = messages_collection.count_documents(
            {"userId": userId, "girlId": girlId, "createdAt": {"$gte": last_datetime, "$lt": current_datetime}}
        )
        other_girls_messages_count = messages_collection.count_documents(
            {"userId": userId, "createdAt": {"$gte": last_datetime, "$lt": current_datetime}, "girlId": {"$ne": girlId}}
        )
        previous_affinity = latest_record['overall_affinity']
        overall_affinity = previous_affinity + 0.01 * min(previous_day_messages_count, 100) - 0.005 * min(other_girls_messages_count, 500)
    else:
        previous_affinity = overall_affinity
        previous_day_messages_count = 0

    # 随机生成 mood_index
    mood_index = random.randint(1, 6)

    # 准备新文档
    new_document = {
        "userId": userId,
        "girlId": girlId,
        "current_date": current_date.isoformat(),  # 将日期转换为字符串
        "days_since_first_message": days_since_first_message,
        "mood_index": mood_index,
        "overall_affinity": overall_affinity,
        "message_count": message_count
    }

    # 创建复合唯一索引
    index_keys = [("userId", pymongo.ASCENDING), ("girlId", pymongo.ASCENDING), ("current_date", pymongo.ASCENDING)]
    collection.create_index(index_keys, unique=True)

    # 使用 replace_one 执行 upsert 操作
    collection.replace_one(
        {"userId": userId, "girlId": girlId, "current_date": current_date.isoformat()},  # 将日期转换为字符串
        new_document,
        upsert=True
    )
    print(new_document)
    return True

def 初始化所有设定():
    # 连接到MongoDB
   
    
    
    # 获取所有 userId 和 girlId 的组合
    combinations = messages_collection.aggregate([
        {
            "$group": {
                "_id": {
                    "userId": "$userId",
                    "girlId": "$girlId"
                }
            }
        }
    ])

    current_date = datetime.now().date()  # 获取当前日期
    for combo in combinations:
        print(combo,'---------------------当日初始化')
        if 'userId' in combo['_id']:
            userId = combo['_id']['userId']
            girlId = combo['_id']['girlId']
            初始化设定(userId,girlId,current_date,messages_collection,collection)

if __name__ == '__main__':
    初始化所有设定()
