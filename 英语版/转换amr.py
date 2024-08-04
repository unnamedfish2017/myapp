import ffmpeg
import os

input_file = 'wav/test.wav'
output_file = 'wav/test.amr'

# 检查输入文件是否存在
if not os.path.isfile(input_file):
    raise FileNotFoundError(f"Input file {input_file} does not exist")

try:
    # 转换 WAV 到 AMR 并捕获 stdout 和 stderr
    out, err = (
        ffmpeg
        .input(input_file)
        .output(output_file)
        .run(capture_stdout=True, capture_stderr=True)
    )
    print(f"Successfully converted {input_file} to {output_file}")
except ffmpeg.Error as e:
    print(f"Error occurred: {e.stderr.decode('utf-8')}")
