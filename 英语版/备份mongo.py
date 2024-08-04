from pymongo import MongoClient
import subprocess
from datetime import datetime

# MongoDB连接信息
mongo_uri = 'mongodb://localhost:27017/'
database_name = 'chat-app'
backup_dir = '/myapp/mongobak'

def backup_mongodb():
    # 获取当前日期时间作为备份文件夹名
    current_date = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_path = f"{backup_dir}/{current_date}"

    # 使用mongodump命令备份数据库
    command = f"mongodump --uri {mongo_uri} --db {database_name} --out {backup_path}"
    process = subprocess.Popen(command, shell=True)
    process.wait()

if __name__ == "__main__":
    backup_mongodb()
