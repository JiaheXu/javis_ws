import requests


#def synthesize_speech(text: str, output_path: str, server_url: str = "http://192.168.1.100:5000") -> bool:
def synthesize_speech(text: str, output_path: str, server_url: str = "http://0.0.0.0:5000") -> bool:
    """
    Send a text-to-speech request to the Piper TTS server and save the result as a WAV file.

    Parameters
    ----------
    text : str
        The text to be synthesized into speech.
    output_path : str
        Path to the output WAV file where the synthesized audio will be stored.
    server_url : str, optional
        The URL of the TTS server (default is "http://192.168.1.100:5000").

    Returns
    -------
    bool
        True if the request was successful and the file was saved, False otherwise.
    """
    headers = {"Content-Type": "application/json"}
    payload = {"text": text}

    try:
        response = requests.post(server_url, json=payload, headers=headers, timeout=30)

        if response.status_code == 200:
            with open(output_path, "wb") as f:
                f.write(response.content)
            print(f"✅ Speech successfully synthesized and saved to: {output_path}")
            return True
        else:
            print(f"❌ Request failed with status {response.status_code}: {response.text}")
            return False

    except requests.exceptions.RequestException as e:
        print(f"⚠️ Error during request: {e}")
        return False


if __name__ == "__main__":
    # Example usage
    text_input = "您好，园区入口处设置共享婴儿车，可随时扫码租赁。园区日常客流较大，轮椅无法提供预留服务，请您理解。"
    synthesize_speech(text_input, "test1.wav")
    text_input = "园区日常客流较大，轮椅无法提供预留服务，请您理解。"
    synthesize_speech(text_input, "test2.wav")
