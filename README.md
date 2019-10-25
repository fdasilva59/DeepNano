# DeepNano

This project aims to provide a couple of script to automate the setup of a Jetson Nano for Deep Learning at Edge with Tensorflow.

The scripts will :
- Update the system
- Create a Python3.6 virtual environment and install usefull packages
- Install Visual Studio
- Install the Coral TPU Edge
- Build and Install Bazel (in order to build Tensorflow)
- Build and Install Tensorflow 2.0 for Jetson Nano (aarch64 with CUDA support)


**Be aware that the setup can takes 1-2 days if compiling bazel and Tensorflow** (a bit more than 1 day just to compile Tensorflow natively on the Jetson Nano. Cross-compiling might be considered to speed up the compilation from sources)

## Prerequisites

- Install a Fan on the Jetson Nano in order operate at max power
- Download and install the [Jetson Nano Developer Kit SD Card Image  with JetPack 4.2.2](https://developer.nvidia.com/embedded/downloads#?tx=$product,jetson_nano) on a 64GB SD Card
- Boot on the Jeston Nano with this SD card (**Make sure** to power the Nano with a 4A power supply in order to operate in power mode0 MAXN)



## How to use

1. Clone this github project
2. If you have already built a binary for Bazel and a Python wheel for Tensorflow, restore them at the following locations :
  - `/usr/local/bin/bazel`
  - `/opt/local/tmp/tensorflow_pkg/tensorflow-2.0.0-cp36-cp36m-linux_aarch64.whl`
3. Review the script and eventually customize the installation
4. During the script execution, make sure to close all applications (except  the Terminal to run the script). During the tensorflow compilation almost all the RAM + Swap memory will be used. Using other applications might cause a crash
5. Execute the script `NanoSetup.sh` to configure the system on the SD card
6. Make sure that that **only one single USB drive is connected** to the Jetson Nano. Then, execute the script `Move2USB.sh` to copy the system on the USB SSD drive and update the system to boot from it (Note: You might want to reuse this script in the future, in order to refresh your USB SSD drive with a fresh copy of the system located on the SD Card)

When using the Nano, make sure:
- To execute your Tensorflow code inside the Python Virtual Environment
- If you want to launch Jupyter Lab notebooks, first start the Chromium browser with the `--no-sandbox` or `--disable-gpu` option

```
# Manually using Jupyter Labd on the Jetson Nano
/opt/local/virtual-env/bin/activate bash 
chromium-browser --no-sandbox &
jupyter-lab --log-level='ERROR'
```  

For convenience an alias `jl` has been define in the .bashrc  (`alias jl='(chromium-browser --no-sandbox &) ; jupyter-lab --log-level='\''ERROR'\'''`)

## Jupyter Notebook experiments - **Work In progress**

A Jupyter Notebook is provided to experiment with Tensorflow 2.0 on the Jetson Nano and Coral Edge TPU.

This notebook does not aim to serve as a benchmark. It is intended at exploring the possibilities/capabilities with this setup. It can also serves as a quick reference guide for using the tf.lite API. (Also remember that these devices are intended for inference. They are not designed for training. That being said, the hetsion Nano is not bad at training a rather basic Neural network!)

## Copyright acknowledgements and usefull links

MIT License

- [Nvidia forum discussion on buildling Tensorflow from sources (1)](https://devtalk.nvidia.com/default/topic/1055131/jetson-agx-xavier/building-tensorflow-1-13-on-jetson-xavier/)
- [Nvidia forum discussion on buildling Tensorflow from sources (2)](https://devtalk.nvidia.com/default/topic/1049100/general/tensorflow-installation-on-drive-px2-/post/5324624/#5324624)
- [Nvidia forum discussion on buildling Tensorflow from sources (3)](https://devtalk.nvidia.com/default/topic/1055378/building-tensorflow-lite-from-source-on-tx2-failed/)
- [Nvidia forum discussion on Jupyter-lab error](https://devtalk.nvidia.com/default/topic/1052333/jetson-tx2/error-can-t-initialize-nvrm-channel/post/5350512/#5350512)
- [Nvidia forum discussion on compiling options](https://devtalk.nvidia.com/default/topic/1028179/jetson-tx2/gcc-options-for-tx2/post/5230415/#5230415)
- [GCC options for ARM](https://gcc.gnu.org/onlinedocs/gcc-7.4.0/gcc/ARM-Options.html#ARM-Options)
- [Jetsonhacks tutorials & ressources](https://www.jetsonhacks.com/category/jetson-nano/)
- [Jetsonhacks tutorial to install a Fan](https://www.jetsonhacks.com/2019/09/08/jetson-nano-add-a-fan/)
- [Jetsonhacks tutorial to run from a USB drive](https://www.jetsonhacks.com/2019/09/17/jetson-nano-run-from-usb-drive/)
- [Jetsonhacks tutorial to install a Swap File](https://github.com/JetsonHacksNano/installSwapfile)
- [Jetsonhacks tutorial to install Visual Studio editor](https://github.com/JetsonHacksNano/installVSCode)
- [Headmelted Visual Studio Code for ARM platform](https://code.headmelted.com/)
- [Headmelted github code](https://github.com/headmelted/codebuilds/blob/master/docs/installers/apt.sh)
- [Tensorflow Lite Python Quickstart](https://www.tensorflow.org/lite/guide/python)
- [tensorflow Post training Quantization](https://www.tensorflow.org/lite/performance/post_training_quantization)
- [Inference on Coral TPU Edge with TensorFlow Lite in Python](https://coral.withgoogle.com/docs/edgetpu/tflite-python/)





## My Hardware setup

**TODO add screenshots**

- [Nvidia Jetson Nano](https://developer.nvidia.com/embedded/jetson-nano-developer-kit)
- [Samsung 64GB Micro SD](https://www.amazon.com/Samsung-MicroSDXC-Memory-Adapter-MB-MC64GA/dp/B06XFWPXYD/ref=sr_1_3)
- [5v 4A power supply - Adjust to your region](https://www.amazon.fr/TOP-CHARGEUR-Adaptateur-Alimentation-Certification/dp/B07PM41CNR/ref=sr_1_1)
- [Google Coral TPU Edge](https://coral.withgoogle.com/)
- [Noctua NF-A4x20 5V PWM Fan](https://www.amazon.com/Noctua-NF-A4x20-5V-PWM-Premium-Quality/dp/B071FNHVXN/ref=sr_1_1_sspa)
- [Intel Dual Band Wireless AC8265](https://www.amazon.com/Wireless-Intel-8265NGW-Bluetooth-Wireless/dp/B0721MLM8B/ref=sr_1_2)
- [Wifi Antenna](https://www.amazon.com/WayinTop-Wireless-Network-Antenna-Pigtail/dp/B07PHFL663/ref=sr_1_4)
- [Samsung 250GB SSD T5](https://www.amazon.com/Samsung-Portable-MU-PA250B-AM-Alluring/dp/B073H552FK/ref=sr_1_3)
- [Raspberry Pi v2 8MP camera](https://www.amazon.com/Raspberry-Pi-Camera-Module-Megapixel/dp/B01ER2SKFS/ref=sr_1_1)
- [Waveshare Jetson Nano case](https://www.amazon.com/Case-Jetson-Nano-Compatible-Peripherals/dp/B07VTNSS4S/ref=sr_1_1)
- [2 x USB 3.0 to type C angle cable](https://www.amazon.com/BSHTU-Extension-Transfer-Charger-90%C2%B0Type/dp/B077M8DHDT/ref=sr_1_13)

(and of course a Monitor, a Keyboard and a Mouse)
