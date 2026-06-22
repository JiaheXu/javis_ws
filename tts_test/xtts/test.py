#!/usr/bin/env python3
import os
import torch
import pprint

from TTS.api import TTS

#device = "cuda" if torch.cuda.is_available() else "cpu"
device = "cpu"
#print(TTS().list_models())

model="xtts_v2"  # "tts_models/multilingual/multi-dataset/xtts_v1.1"
model_file="/home/jiahe/model_data/tacotron2-DDC-GST/"
config_file="/home/jiahe/model_data/tacotron2-DDC-GST/config.json"
#model="/home/developer/model_data/xtts_v2"

speaker='Sofia Hellen'
language='zh-cn'

print(f"Loading TTS model {model}")

tts = TTS(model_path=model_file, config_path=config_file, progress_bar=False).to(device)

print(dir(tts.synthesizer.tts_model.speaker_manager))
print(tts.synthesizer.tts_model.speaker_manager)

print(f"\nMulti-speaker:  {tts.is_multi_speaker}")

if tts.is_multi_speaker:
    print(f"\nSpeakers:  {tts.synthesizer.tts_model.speaker_manager.name_to_id}")
print(f"\nLanguages:  {tts.synthesizer.tts_model.language_manager.name_to_id}")

# Text to speech to a file
prompts = [
    "大家好，我是中文语音合成示例。", 
    "你好，今天天气真不错，希望你有一个愉快的周末。", 
    "您好，园区入口处设置共享婴儿车，可随时扫码租赁。",
    "园区日常客流较大，轮椅无法提供预留服务，请您理解",
]
    
if tts.is_multi_speaker:
    prompts = [' '.join(prompts)] #+ prompts

for prompt_idx, prompt in enumerate(prompts):
    wav = f"./{os.path.basename(model)}_offline_{speaker.lower().replace(' ', '_')}.wav" #_{prompt_idx}.wav"
    print(f'\ngenerating "{prompt}"  speaker="{speaker}"  lang="{language}"  wav="{wav}"\n')
    if tts.is_multi_speaker:
        tts.tts_to_file(text=prompt, speaker=speaker, language=language, file_path=wav)
    else:
        tts.tts_to_file(text=prompt, speaker_wav=speaker_wav, language=language, file_path=wav)
