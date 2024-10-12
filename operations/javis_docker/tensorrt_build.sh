# please run this inside docker javis_estimation

# clone Torch-TensorRT tag v1.0.0 for orin NX and build inside docker, must be performed outside of dockerfile since it uses nvidia runtime
cd ~/thirdparty-software

git clone --recursive https://github.com/pytorch/TensorRT.git Torch-TensorRT -b v1.2.0
cp ~/javis_ws/operations/javis_docker/WORKSPACE ~/thirdparty-software/Torch-TensorRT/WORKSPACE

# build python3 package
cd ~/thirdparty-software/Torch-TensorRT/py 

echo passme24 | sudo python3 setup.py install --jetpack-version 5.0.2 --use-cxx11-abi



