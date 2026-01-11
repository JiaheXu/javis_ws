# Clone with submodules
git clone --recursive https://github.com/OpenNMT/CTranslate2.git
cd CTranslate2

# Build
mkdir build && cd build
cmake -DWITH_CUDA=ON -DWITH_CUDNN=ON -DWITH_MKL=OFF -DCMAKE_BUILD_TYPE=Release ..

make -j$(nproc)
sudo make install

##### ???????????????????????????
pip install pybind11

cd ~/CTranslate2/python
pip install . --no-build-isolation

pip3 install pybind11 openwakeword==0.5.0 sentence-transformers faiss-cpu av rapidfuzz pypinyin faster-whisper setuptools==67.2.0 wheel numpy==1.24.4 scipy==1.8.0 opencc -i https://pypi.tuna.tsinghua.edu.cn/simple

s

sudo apt install -y ffmpeg libavdevice-dev libavfilter-dev libavformat-dev libavcodec-dev libavutil-dev libswscale-dev libswresample-dev portaudio19-dev alsa-utils


pip3 install ctranslate2==4.4.0 faster-whisper -i https://pypi.tuna.tsinghua.edu.cn/simple

pip install transformers==4.45.2 sentence-transformers==5.1.1 -i https://pypi.tuna.tsinghua.edu.cn/simple
