from apscheduler.schedulers.blocking import BlockingScheduler
import subprocess
import os
os.environ['TZ'] = 'Asia/Shanghai'
import time
time.tzset()

import sys
import os
import time

from apscheduler.schedulers.blocking import BlockingScheduler
from datetime import timezone
from datetime import timedelta

scheduler = BlockingScheduler(timezone=timezone(timedelta(hours=8))) 

def run_(path, file, timeout=2400*10):
    try:
        os.chdir(path)  # 切换到指定目录
        result = subprocess.run(['python3', file], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True, text=True, timeout=timeout)
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Command '{e.cmd}' failed with return code {e.returncode}: {e.stderr}")
    except subprocess.TimeoutExpired as e:
        print(f"Command '{e.cmd}' timed out after {timeout} seconds")
    except Exception as e:
        print(str(e))


# 创建调度器实例
scheduler = BlockingScheduler()

root='./'

scheduler.add_job(run_, 'cron', hour=3, minute=0,args=(root,'备份mongo.py',1200), misfire_grace_time=10*60*24)

# 启动调度器
scheduler.start()


