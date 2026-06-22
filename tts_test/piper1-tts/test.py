#!/usr/bin/env python3
import os
import io
import time
import wave
from packaging.version import Version
from pathlib import Path

import onnxruntime as ort
from piper.voice import PiperVoice
from piper.download_voices import download_voice

DEFAULT_PROMPT = '大家好，我是中文语音合成示例。'


def main(
    model='zh_CN-huayan-medium.onnx', config=None, cache=os.environ.get('PIPER_CACHE'),
    speaker=0, length_scale=1.0, noise_scale=0.667, noise_w_scale=0.8, sentence_silence=0.2,
    prompt=DEFAULT_PROMPT, output='./output.wav', backend='cuda', runs=1, dump=False, **kwargs
):
    # Build model path
    model_path = Path(cache) / f"{model}.onnx"
    if not model_path.exists():
        download_voice(model, Path(cache))

    # Choose providers
    if backend == 'cpu':
        providers = ['CPUExecutionProvider']
        use_cuda = False
    elif backend == 'cuda':
        providers = ['CUDAExecutionProvider', 'CPUExecutionProvider']
        use_cuda = True
    elif backend == 'tensorrt':
        providers = ['TensorrtExecutionProvider', 'CUDAExecutionProvider', 'CPUExecutionProvider']
        use_cuda = True
    else:
        raise ValueError(f"Unknown backend '{backend}'")

    print(f"Loading {model_path} with backend={backend} providers={providers}")

    if not model_path.exists():
        raise ValueError(
            f"Unable to find voice: {model_path} (use piper.download_voices)"
        )

    # Load Piper voice
    voice = PiperVoice.load(model_path, config_path=config, use_cuda=use_cuda)

    # Validate speaker
    speaker_id = speaker
    if (voice.config.num_speakers > 1) and (speaker_id is None):
        print("Multiple speakers available but no speaker_id specified, defaulting to 0")
        speaker_id = 0

    if (speaker_id is not None) and (speaker_id >= voice.config.num_speakers):
        print(f"Invalid speaker_id={speaker_id}, resetting to 0")
        speaker_id = 0

    # Benchmark runs
    for run in range(runs):
        # Save to output file
        with wave.open(output, "wb") as wav_file:
            wav_params_set = False

            start = time.perf_counter()
            for i, audio_chunk in enumerate(
                voice.synthesize(
                    prompt,
                    speaker=speaker_id,
                    length_scale=length_scale,
                    noise_scale=noise_scale,
                    noise_w=noise_w_scale,
                )
            ):
                if not wav_params_set:
                    wav_file.setframerate(audio_chunk.sample_rate)
                    wav_file.setsampwidth(audio_chunk.sample_width)
                    wav_file.setnchannels(audio_chunk.sample_channels)
                    wav_params_set = True

                # Insert silence between sentences
                if i > 0:
                    wav_file.writeframes(
                        bytes(int(voice.config.sample_rate * sentence_silence * 2))
                    )

                wav_file.writeframes(audio_chunk.audio_int16_bytes)

            end = time.perf_counter()
            inference_duration = end - start
            frames = wav_file.getnframes()
            rate = wav_file.getframerate()
            audio_duration = frames / float(rate)

        print(f"Piper TTS model:    {model}")
        print(f"Output saved to:    {output}")
        print(f"Inference duration: {inference_duration:.3f} sec")
        print(f"Audio duration:     {audio_duration:.3f} sec")
        print(f"Realtime factor:    {inference_duration/audio_duration:.3f}")
        print(f"Inverse RTF (RTFX): {audio_duration/inference_duration:.3f}\n")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('--model', type=str, default='en_US-lessac-high', help="model path or name to download")
    parser.add_argument('--config', type=str, default=None, help="path to the model's json config (if unspecified, will be inferred from --model)")
    parser.add_argument('--cache', type=str, default=os.environ.get('PIPER_CACHE'), help="the location to save downloaded models")

    parser.add_argument('--speaker', type=int, default=0, help="the speaker ID from the voice to use")
    parser.add_argument('--length-scale', type=float, default=1.0, help="speaking speed")
    parser.add_argument('--noise-scale', type=float, default=0.667, help="noise added to the generator")
    parser.add_argument('--noise-w-scale', type=float, default=0.8, help="phoneme width variation")
    parser.add_argument('--sentence-silence', type=float, default=0.2, help="seconds of silence after each sentence")

    parser.add_argument('--prompt', type=str, default=None, help="the test prompt to generate (will be set to a default prompt if left none)")
    parser.add_argument('--output', type=str, default=None, help="path to output audio wav file to save (will be /data/tts/piper-$MODEL.wav by default)")
    parser.add_argument('--runs', type=int, default=1, help="the number of benchmarking iterations to run")
    parser.add_argument('--dump', action='store_true', help="dump all speaker voices to the output directory")
    parser.add_argument('--disable-cuda', action='store_false', dest='use_cuda', help="disable CUDA and use CPU for inference instead")
    parser.add_argument('--verbose', action='store_true', help="enable onnxruntime debug logging")

    args = parser.parse_args()

    if args.verbose:
        ort.set_default_logger_severity(0)

    if not args.prompt:
        args.prompt = DEFAULT_PROMPT

    if not args.output:
        args.output = f"/data/audio/tts/piper-{os.path.splitext(os.path.basename(args.model))[0]}.wav"

    print(args)

    main(**vars(args))

