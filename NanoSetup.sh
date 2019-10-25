#!/bin/bash

#------------------------------------------------------------------------------
# Script to automatically setup a Jetson Nano for Deep Learning with Tensorflow.
#
# The script will:
#  - Update the System
#  - Install Visual Studio
#  - Create a Python3.6 virtual environment and install usefull packages
#  - Build Bazel
#  - Build Tensorflow 2.0
#
# MIT License
#
# Copyright acknowledgements:
#
# https://www.jetsonhacks.com/category/jetson-nano/
# https://devtalk.nvidia.com/default/topic/1055131/jetson-agx-xavier/building-tensorflow-1-13-on-jetson-xavier/
# https://devtalk.nvidia.com/default/topic/1049100/general/tensorflow-installation-on-drive-px2-/post/5324624/#5324624
# https://devtalk.nvidia.com/default/topic/1055378/building-tensorflow-lite-from-source-on-tx2-failed/
# https://devtalk.nvidia.com/default/topic/1052333/jetson-tx2/error-can-t-initialize-nvrm-channel/post/5350512/#5350512
# https://devtalk.nvidia.com/default/topic/1028179/jetson-tx2/gcc-options-for-tx2/post/5230415/#5230415
# https://gcc.gnu.org/onlinedocs/gcc-7.4.0/gcc/ARM-Options.html#ARM-Options
# https://www.jetsonhacks.com/2019/09/17/jetson-nano-run-from-usb-drive
# https://www.jetsonhacks.com/2019/09/08/jetson-nano-add-a-fan
# https://github.com/JetsonHacksNano/installSwapfile
# https://github.com/JetsonHacksNano/installVSCode
# https://code.headmelted.com/
# https://github.com/headmelted/codebuilds/blob/master/docs/installers/apt.sh
#
#------------------------------------------------------------------------------

# Abord script on any error
set -e

#-------------------------
#      Configuration
#-------------------------
TENSORFLOW_VERSION='2.0.0'
BAZEL_VERSION='0.24.1'
BAZEL_ARCHIVE='bazel-'$BAZEL_VERSION'-dist.zip'
BUILD_DIR=/opt/local/tmp
TPU_EDGE_RUNTIME='libedgetpu1-max'    # or libedgetpu1-std

printf "\n#--------------------------\n#    Setup Jetson Nano " 
printf "\n#      for Tensorflow    \n#--------------------------\n"
echo "Will Build and install Tensorflow $TENSORFLOW_VERSION"

#-------------------------
#    Update the System
#-------------------------
printf "\n#--------------------------\n#    Update the System   \n#--------------------------\n"
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install openjdk-8-jdk htop curl git python3-pip python3-dev pylint3 python-wheel python3-numpy python-setuptools gfortran swig libatlas-base-dev libhdf5-serial-dev hdf5-tools python3-widgetsnbextension python3-testresources python3-opengl xvfb libfreetype6-dev g++-5 gcc-5 rsync

#-------------------------
# Configure Edge TPU repo
#-------------------------
printf "\n#--------------------------\n# Configure Edge TPU repo   \n#--------------------------\n"
echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | sudo tee /etc/apt/sources.list.d/coral-edgetpu.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install $TPU_EDGE_RUNTIME python3-edgetpu edgetpu-examples edgetpu

#-------------------------
# Install Visual Studio
#-------------------------
printf "\n#--------------------------\n# Installing Visual Studio\n#--------------------------\n"
ARCH="$(uname -m)"
REPO_VENDOR="headmelted"

gpg_key=https://packagecloud.io/headmelted/codebuilds/gpgkey
repo_name="stretch"
repo_entry="deb https://packagecloud.io/headmelted/codebuilds/debian/ ${repo_name} main"
code_executable_name="code-oss"

echo "Retrieving GPG key [${REPO_VENDOR}] ($gpg_key)..."
curl -L $gpg_key | gpg --dearmor > /tmp/${REPO_VENDOR}_vscode.gpg
sudo mv /tmp/${REPO_VENDOR}_vscode.gpg /etc/apt/trusted.gpg.d/${REPO_VENDOR}_vscode.gpg
sudo chown root:root /etc/apt/trusted.gpg.d/${REPO_VENDOR}_vscode.gpg

echo "Removing any previous entry to headmelted repository"
sudo rm -rf /etc/apt/sources.list.d/headmelted_codebuilds.list
sudo rm -rf /etc/apt/sources.list.d/codebuilds.list
  
echo "Installing [${REPO_VENDOR}] repository..."
echo "${repo_entry}" > /tmp/${REPO_VENDOR}_vscode.list
sudo mv /tmp/${REPO_VENDOR}_vscode.list /etc/apt/sources.list.d/${REPO_VENDOR}_vscode.list
sudo chown root:root /etc/apt/sources.list.d/${REPO_VENDOR}_vscode.list
  
echo "Updating APT cache..."
sudo apt-get update -yq;

echo "Installing Visual Studio Code from [${repo_name}]...";
sudo apt-get install --fix-broken -t ${repo_name} -y ${code_executable_name};

#-------------------------
#    Clean the System
#-------------------------
printf "\n#--------------------------\n#     Clean the System   \n#--------------------------\n"
sudo apt-get -y autoremove
sudo apt-get -y autoclean
sudo rm -rf /tmp/.[!.]* /tmp/*

#-------------------------
#    Create a tmp dir
# to build TF and that is
# not cleaned at boot time
#-------------------------
printf "\n#--------------------------\n# Configure Build directory  \n#--------------------------\n"
sudo mkdir -p $BUILD_DIR
sudo chmod 1777 $BUILD_DIR

#-------------------------
#    Hack to Speed up
#     builds via pip 
#-------------------------
printf "\n#--------------------------\n# Install a Hack for make  \n#--------------------------\n"
if [ ! -e /usr/bin/make.orig ]; then
    sudo mv /usr/bin/make /usr/bin/make.orig
    echo 'make.orig --jobs=3 $@' > /tmp/make
    chmod +x /tmp/make
    sudo mv /tmp/make /usr/bin/make
fi

#-------------------------
#      Create Swap
#-------------------------
printf "\n#--------------------------\n#     Create swap file  \n#--------------------------\n"
if [ ! -e /mnt/swapfile ]; then
    cd /mnt
    sudo fallocate -l 8G swapfile
    ls -lh swapfile
    sudo chmod 600 swapfile
    ls -lh swapfile
    sudo mkswap swapfile
    sudo swapon swapfile    
    swapon -s

    if grep -q "swap" /etc/fstab ; then
        echo "Swapfile is already configured in /etc/fstab"
    else
        echo "Configuring swapfile in /etc/fstab"
        sudo sh -c 'echo "/mnt/swapfile swap swap defaults 0 0" >> /etc/fstab' 
    fi
fi
# FYI, use "sudo swapoff /mnt/swapfile && sudo rm -v /mnt/swapfile" to desactivate the swapfile

#-------------------------
#    Python Setup
#-------------------------
printf "\n#--------------------------\n#    Python Env Setup  \n#--------------------------\n"
sudo pip3 install -U virtualenv
sudo mkdir -p /opt/local/virtual-env
sudo chmod 1777 /opt/local/virtual-env 
if [ ! -z "$VIRTUAL_ENV" ] ; then
    echo "Deactivate the virtual environment"
    deactivate
fi
virtualenv --system-site-packages -p python3 /opt/local/virtual-env
source /opt/local/virtual-env/bin/activate bash
pip install -U --user --no-use-pep517 pip setuptools wheel cython numpy scipy scikit-learn 
pip install -U --user mock enum34 six matplotlib bokeh ipython jupyterlab pandas h5py pyvirtualdisplay gym Pillow
pip install -U --user keras_applications keras_preprocessing --no-deps

#-------------------------
#   Check for Tensorflow 
#   Wheel availability
#   (Install or Build)
#-------------------------
printf "\n#--------------------------\n# Check for Tensorflow .whl \n#--------------------------\n"
if [ ! -f /opt/local/tmp/tensorflow_pkg/tensorflow-$TENSORFLOW_VERSION-cp36-cp36m-linux_aarch64.whl ]; then 
    echo "No Tensorflow wheel present: Will build Tensorflow from sources"

    #-------------------------
    #      Install Bazel
    #-------------------------
    printf "\n#--------------------------\n#    Build Bazel  \n#--------------------------\n"
    if [ ! -e /usr/local/bin/bazel ]; then
        echo "Installing bazel"
        cd $BUILD_DIR
        curl -L -o bazel-release.pub.gpg https://bazel.build/bazel-release.pub.gpg
        curl -L -o $BAZEL_ARCHIVE.sig https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/$BAZEL_ARCHIVE.sig
        curl -L -o $BAZEL_ARCHIVE https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/$BAZEL_ARCHIVE
        gpg --with-fingerprint bazel-release.pub.gpg 
        read -p "OK to continue? " -n 1
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
        gpg --import bazel-release.pub.gpg 
        gpg --verify $BAZEL_ARCHIVE.sig $BAZEL-ARCHIVE
        read -p "OK to continue? " -n 1
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
        unzip -d bazel $BAZEL_ARCHIVE
        cd bazel
        env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash ./compile.sh
        sudo cp output/bazel /usr/local/bin
    else
        echo "Bazel already available. Will use /usr/local/bin/bazel"
        bazel version
    fi

    #-------------------------
    #   Install Tensorflow
    #-------------------------
    printf "\n#--------------------------\n#   Get Tensorflow sources  \n#--------------------------\n"
    if [ ! -e $BUILD_DIR/tensorflow ]; then
        cd $BUILD_DIR
        git clone https://github.com/tensorflow/tensorflow.git --branch v$TENSORFLOW_VERSION --single-branch
    else
        echo "A Tensorflow directory already exists. Will use $BUILD_DIR/tensorflow " 
    fi
    cd $BUILD_DIR/tensorflow

    printf "\n#--------------------------\n#   Apply Nvidia patches   \n#--------------------------\n"
    # Apply Nvidia patches to some Tensorflow source files
    set +e
    cd $BUILD_DIR/tensorflow/tensorflow/lite/kernels/internal/
    cat > ./BUILD.patch <<- "EOF"
index 4be3226..960754a 100644
@@ -22,7 +22,6 @@ HARD_FP_FLAGS_IF_APPLICABLE = select({
 NEON_FLAGS_IF_APPLICABLE = select({
     ":arm": [
         "-O3",
-        "-mfpu=neon",
     ],
     ":armeabi-v7a": [
         "-O3",
EOF
    patch --forward --backup ./BUILD ./BUILD.patch
    diff ./BUILD ./BUILD.orig

    cd $BUILD_DIR/tensorflow/third_party/aws/
    cat > ./BUILD.bazel.patch <<- "EOF"
index 5426f79..e08f8fc 100644
@@ -24,7 +24,7 @@ cc_library(
         "@org_tensorflow//tensorflow:raspberry_pi_armeabi": glob([
             "aws-cpp-sdk-core/source/platform/linux-shared/*.cpp",
         ]),
-        "//conditions:default": [],
+        "//conditions:default": glob(["aws-cpp-sdk-core/source/platform/linux-shared/*.cpp",]),
     }) + glob([
         "aws-cpp-sdk-core/include/**/*.h",
         "aws-cpp-sdk-core/source/*.cpp",
EOF
    #patch --forward --backup ./BUILD.bazel ./BUILD.bazel.patch
    #diff ./BUILD.bazel ./BUILD.bazel.orig

    cd $BUILD_DIR/tensorflow/third_party/gpus/crosstool/
    cat > ./BUILD.tpl.patch <<- "EOF"
index db76306..184cd35 100644
@@ -24,6 +24,7 @@ cc_toolchain_suite(
         "x64_windows|msvc-cl": ":cc-compiler-windows",
         "x64_windows": ":cc-compiler-windows",
         "arm": ":cc-compiler-local",
+        "aarch64": ":cc-compiler-local",
         "k8": ":cc-compiler-local",
         "piii": ":cc-compiler-local",
         "ppc": ":cc-compiler-local",
EOF
    #patch --forward --backup ./BUILD.tpl ./BUILD.tpl.patch
    #diff ./BUILD.tpl ./BUILD.tpl.orig
    set -e


    printf "\n#--------------------------\n#   Configure Tensorflow   \n#--------------------------\n"
    # The value of these variables allows to automate the Tensorflow
    # 'configure' process (if some of these variables are not defined, the
    # configure process will interractively prompt for the missing choices)
    # ( See https://github.com/tensorflow/tensorflow/blob/master/configure.py )
    # cat configure.py | grep \'TF_ | grep CUDA

    # Note: bazel makes an error if we try to use variables inside the path strings
    # Note: XLA relies on nccl which is not available on Jetson, so we disable XLA 
    export PYTHON_BIN_PATH="/opt/local/virtual-env/bin/python"
    export PYTHON_LIB_PATH="/opt/local/virtual-env/lib/python3.6/site-packages/"
    export TF_ENABLE_XLA=0
    export TF_NEED_OPENCL_SYCL=0
    export TF_NEED_ROCM=0
    export TF_NEED_CUDA=1
    export TF_NEED_TENSORRT=1
    export TF_CUDA_COMPUTE_CAPABILITIES="5.3"
    export TF_CUDA_CLANG=0
    export GCC_HOST_COMPILER_PATH=/usr/bin/gcc-5
    export TF_NEED_MPI=0
    export TF_SET_ANDROID_WORKSPACE=0

    # Note : "error SQLite will not work correctly with the -ffast-math option of GCC.", so we don't set this gcc flag
    export CC_OPT_FLAGS="-march=armv8-a+crypto -mcpu=cortex-a57+crypto -mtune=cortex-a57 -flto -funsafe-math-optimizations -ftree-vectorize -fomit-frame-pointer -Wno-sign-compare -O3"

    cd $BUILD_DIR/tensorflow
    ##./configure


    printf "\n#--------------------------\n#   Build Tensorflow   \n#--------------------------\n"
    # Note: Bazel option "--config=nogcp" seems to conflict with "--config=v2", so we skip it
    ##bazel build --config=opt --config=v2 --config=monolithic --config=cuda --config=nonccl --config=noaws --config=nohdfs --config=noignite --config=nokafka --verbose_failures --local_ram_resources=HOST_RAM*.60 --local_cpu_resources=2 //tensorflow/tools/pip_package:build_pip_package
    
    printf "\n#--------------------------\n#   Package Tensorflow   \n#--------------------------\n"
    ##bazel-bin/tensorflow/tools/pip_package/build_pip_package /opt/local/tmp/tensorflow_pkg

else
    echo "Found Tensorflow wheel : Will install Tensorflow from wheel /opt/local/tmp/tensorflow_pkg/tensorflow-$TENSORFLOW_VERSION-cp36-cp36m-linux_aarch64.whl"
fi 

printf "\n#--------------------------\n#   Install Tensorflow   \n#--------------------------\n"
pip install /opt/local/tmp/tensorflow_pkg/tensorflow-$TENSORFLOW_VERSION-cp36-cp36m-linux_aarch64.whl

printf "\n#--------------------------\n# Install Tensorflow-hub   \n#--------------------------\n"
pip install -U --user tensorflow-hub

#-------------------------
#  Copy NVIDIA TensorRT,
#   opencv2 and edgetpu 
#  python libs inside our 
#   python virtual env.
#
# Bypass solution to the 
# pip install opencv-python 
# issue in the virtual env
#
# Bypass solution for the 
# lack of wheel for edgetpu 
#-------------------------
printf "\n#--------------------------\n# Include NVIDIA py3 libs   \n#--------------------------\n"
cd /opt/local/virtual-env/lib/python3.6/
mkdir -p dist-packages
cp -R -u /usr/lib/python3.6/dist-packages/* ./ 

printf "\n#--------------------------\n# Include EdgeTPU py3 libs  \n#--------------------------\n"
cp -R -u /usr/lib/python3/dist-packages/edgetpu* ./


#-------------------------
#      Configuration
#------------------------- 
printf "\n#--------------------------\n#      Configuration  \n#--------------------------\n"
if grep -q "virtual-env" ~/.bashrc ; then
    echo "virtual-env is already configured in .bashrc"
else
    echo "Configuring virtual-env in .bashrc"
    printf "\nsource /opt/local/virtual-env/bin/activate bash\n" >> ~/.bashrc 
fi

if grep -q "chromium-browser" ~/.bashrc ; then
    echo "chromium-browser alias is already configured in .bashrc"
else
    echo "Configuring chromium-browser alias in .bashrc"
    printf "\nalias jl=\"(chromium-browser --no-sandbox &) ; jupyter-lab --log-level='ERROR'\"\n" >> ~/.bashrc 
fi

if [ -e /home/$USER/.local/share/jupyter/kernels/virtual-env/kernel.json ] ; then
    echo "A Jupyter Notebook kernel for virtual-env already exist."
else
    echo "Create a Jupyter Notebook kernel for the virtual-env"
    ipython kernel install --user --name=virtual-env
fi

#-------------------------
#      Clean & Exit
#-------------------------
printf "\n#--------------------------\n#   Cleaning  \n#--------------------------\n"
cd /tmp
sudo rm -rf /tmp/.[!.]* /tmp/*

# Comment these lines when debugging Tensorflow build process
rm -rf ~/.cache
#rm -rf $BUILD_DIR/bazel/
#rm -rf $BUILD_DIR/tensorflow/

 
printf "\n#--------------------------\n#          Done !  \n#--------------------------\n"
##################### End of Tensorflow Build Configuration ####################  

