import torch
from TTS.api import TTS

def synthesize_with_xtts(text: str, output_path: str, model_file: str, config_file: str, speaker_wav: str):
    """
    Generate speech using a local XTTS model (voice cloning required).
    """
    device = "cuda" if torch.cuda.is_available() else "cpu"

    # Load XTTS model
    tts = TTS(model_path=model_file, config_path=config_file, progress_bar=False).to(device)

    # XTTS requires either a reference wav or a valid speaker ID
    tts.tts_to_file(
        text=text,
        speaker_wav=speaker_wav,
        language="zh-cn",
        file_path=output_path
    )

    print(f"✅ Saved XTTS output to {output_path}")


if __name__ == "__main__":
    synthesize_with_xtts(
        text="您好，园区入口处设置共享婴儿车，可随时扫码租赁。",
        output_path="xtts_test.wav",
        model_file="/home/jiahe/model_data/xtts_v2/",
        config_file="/home/jiahe/model_data/xtts_v2/config.json",
        speaker_wav="/home/jiahe/javis_ws/tts_test/xtts/reference.wav"  # <-- add your sample voice here
    )


if __name__ == "__main__":
    synthesize_with_xtts(
        text="您好，园区入口处设置共享婴儿车，可随时扫码租赁。",
        output_path="xtts_test.wav",
        model_file="/home/jiahe/model_data/xtts_v2/",
        config_file="/home/jiahe/model_data/xtts_v2/config.json",
        speaker_wav=None
    )

