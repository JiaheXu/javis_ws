import torch
from TTS.api import TTS

# pick device
#device = "cuda" if torch.cuda.is_available() else "cpu"
device = "cpu"
# you can load directly from HuggingFace by name
# or point to your local folder if you cloned it
model_name = "/home/jiahe/tts_models--zh-CN--baker--tacotron2-DDC-GST"

print(f"Loading model: {model_name}")
tts = TTS(
    model_path="/home/jiahe/tacotron2-DDC-GST/model.pth",
    config_path="/home/jiahe/tacotron2-DDC-GST/config.json"
).to(device)
# synthesize and save to wav
tts.tts_to_file(
    text="您好，欢迎来到大唐芙蓉园。今天的天气非常好，适合游览。",
    file_path="baker_test1.wav"
)
tts.tts_to_file(
    text="您好，园区入口处设置共享婴儿车，可随时扫码租赁。园区日常客流较大，轮椅无法提供预留服务，请您理解。",
    file_path="baker_test2.wav"
)


print("✅ Audio saved as baker_test.wav")
