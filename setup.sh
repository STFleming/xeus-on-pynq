#!/bin/sh 

# Helps to setup xeus-cling on the KV260. Assumes that the other steps in the blog have been completed first.
# author: Shane T. Fleming

# Check that the user is root

cd /root/

mamba install -y -c conda-forge xeus-cling

# Some mamba packages for dpu_pynq
mamba install -y -c conda-forge opencv


# Wait for Ubuntu to finish unattended upgrades
while [[ $(lsof -w /var/lib/dpkg/lock-frontend) ]]
do
  echo -e "${YELLOW}Waiting for Ubuntu unattended upgrades to finish${NC}"
  sleep 20s
done

apt-get install -y python3-cffi libssl-dev libcurl4-openssl-dev \
  portaudio19-dev libcairo2-dev libdrm-dev libopencv-dev python3-opencv graphviz i2c-tools \
  fswebcam

# Install the pip packages
cat > requirements.txt <<EOT
alabaster==0.7.12
anyio==3.1.0
argon2-cffi==20.1.0
async-generator==1.10
Babel==2.9.1
backcall==0.2.0
bleach==3.3.0
Brotli==1.0.9
cffi==1.14.5
click==8.0.1
CppHeaderParser==2.7.4
Cython==0.29.24
dash==2.0.0
dash-bootstrap-components==0.13.1
dash-core-components==2.0.0
dash-html-components==2.0.0
dash-renderer==1.9.1
dash-table==5.0.0
defusedxml==0.7.1
deltasigma==0.2.2
docutils==0.17.1
Flask==2.0.1
Flask-Compress==1.10.1
gTTS==2.2.3
imagesize==1.2.0
imutils==0.5.4
ipykernel==5.5.5
ipython==7.24.0
ipywidgets==7.6.3
itsdangerous==2.0.1
jedi==0.17.2
Jinja2==3.0.1
json5==0.9.5
jsonschema==3.2.0
jupyter==1.0.0
jupyter-client==6.1.12
jupyter-console==6.4.0
jupyter-contrib-core==0.3.3
jupyter-contrib-nbextensions==0.5.1
jupyter-core==4.7.1
jupyter-highlight-selected-word==0.2.0
jupyter-latex-envs==1.4.6
jupyter-nbextensions-configurator==0.4.1
jupyter-server==1.8.0
jupyterlab==3.0.16
jupyterlab-pygments==0.1.2
jupyterlab-server==2.5.2
jupyterlab-widgets==1.0.0
jupyterplot==0.0.3
lrcurve==1.1.0
MarkupSafe==2.0.1
matplotlib-inline==0.1.2
mistune==0.8.4
nbclassic==0.3.1
nbclient==0.5.3
nbconvert==6.0.7
nbformat==5.1.3
nbsphinx==0.8.7
nbwavedrom==0.2.0
nest-asyncio==1.5.1
netifaces==0.11.0
notebook==6.4.0
numpy==1.20.3
pandas==1.3.3
pandocfilters==1.4.3
parsec==3.9
parso==0.7.1
patsy==0.5.1
pbr==5.6.0
pexpect==4.8.0
pip==21.2.1
plotly==5.1.0
prometheus-client==0.10.1
prompt-toolkit==3.0.18
psutil==5.8.0
ptyprocess==0.7.0
PyAudio==0.2.11
pybind11==2.8.0
pycairo==1.20.1
pycurl==7.43.0.2
pyeda==0.28.0
Pygments==2.9.0
pyrsistent==0.17.3
pyzmq==22.1.0
qtconsole==5.1.0
QtPy==1.9.0
rise==5.7.1
roman==3.3
Send2Trash==1.5.0
setproctitle==1.2.2
setuptools==44.0.0
simplegeneric==0.8.1
sniffio==1.2.0
snowballstemmer==2.1.0
SpeechRecognition==3.8.1
Sphinx==4.2.0
sphinx-rtd-theme==1.0.0
sphinxcontrib-applehelp==1.0.2
sphinxcontrib-devhelp==1.0.2
sphinxcontrib-htmlhelp==2.0.0
sphinxcontrib-jsmath==1.0.1
sphinxcontrib-qthelp==1.0.3
sphinxcontrib-serializinghtml==1.1.5
tenacity==8.0.0
terminado==0.10.0
testpath==0.5.0
testresources==2.0.1
tornado==6.1
tqdm==4.62.3
traitlets==5.0.5
voila==0.2.10
voila-gridstack==0.2.0
websocket-client==1.0.1
Werkzeug==2.0.1
widgetsnbextension==3.5.1
wurlitzer==3.0.2
EOT

/miniconda3/bin/python -m pip install pip==21.2.4
/miniconda3/bin/python -m pip install -r ./requirements.txt

# Setup Jupyter
export PYNQ_JUPYTER_NOTEBOOKS=/home/ubuntu/jupyter_notebooks
export NODE_OPTIONS=--max-old-space-size=4096

wget https://deb.nodesource.com/node_12.x/pool/main/n/nodejs/nodejs_12.22.6-deb-1nodesource1_arm64.deb
# Wait for Ubuntu to finish unattended upgrades
while [[ $(lsof -w /var/lib/dpkg/lock-frontend) ]]
do
  echo -e "${YELLOW}Waiting for Ubuntu unattended upgrades to finish${NC}"
  sleep 20s
done

dpkg -i *.deb
rm -rf *.deb


jupyter notebook --generate-config --allow-root

cat - >> /root/.jupyter/jupyter_notebook_config.py <<EOT
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.notebook_dir = '$PYNQ_JUPYTER_NOTEBOOKS'
c.NotebookApp.password = 'sha1:46c5ef4fa52f:ee46dad5008c6270a52f6272828a51b16336b492'
c.NotebookApp.port = 9090
c.NotebookApp.iopub_data_rate_limit = 100000000
import datetime
expire_time = datetime.datetime.now() + datetime.timedelta(days=3650)
c.NotebookApp.cookie_options = {"expires": expire_time}
EOT

mkdir -p $PYNQ_JUPYTER_NOTEBOOKS

# Get PYNQ
git clone https://github.com/Xilinx/PYNQ.git -b image_v2.7 --depth 1 pynq

# Get the KV260 repo
git clone https://github.com/Xilinx/Kria-PYNQ.git 

# Get the libcma
cd /root/pynq/sdbuild/packages/libsds/libcma
make -t
make install 
cp ./libcma.so.64 /miniconda3/lib 
cp ./libxlnk_cma.h /miniconda3/include


# Setting up the flags and runtime env
echo "export LDFLAGS=\"$LDFLAGS -L/usr/lib/aarch64-linux-gnu\"" > /root/.conda_env.sh
echo "export BOARD=KV260" >> /root/.conda_env.sh
echo "export XILINX_XRT=/usr" >> /root/.conda_env.sh
export XILINX_XRT=/usr
export BOARD=KV260
export PYNQ_JUPYTER_NOTEBOOKS=/home/ubuntu/jupyter_notebooks

# define the name of the platform
echo "KV260" > /etc/xocl.txt

echo "source /root/.conda_env.sh" >> /root/.bashrc
source /root/.conda_env.sh

cp -r /usr/include/xf86drm* /miniconda3/include/
cp -r /lib/xfsprogs /miniconda3/lib
cp -r /lib/xrt/ /miniconda3/lib

mamba install -y -c conda-forge boost-cpp

# install pynq
/miniconda3/bin/python -m pip install pynq

# Install the base overlay
cd /root/Kria-PYNQ
/miniconda3/bin/python3 -m pip install .

# compile the pynq device tree overlay and insert it by default
cd /root/Kria-PYNQ
pushd dts/
make
mkdir -p /usr/local/share/pynq-dts/
cp insert_dtbo.py pynq.dtbo /usr/local/share/pynq-dts
echo "/miniconda3/bin/python3 /usr/local/share/pynq-dts/insert_dtbo.py" >> /root/.conda_env.sh
source /root/.conda_env.sh
popd

# Get the PYNQ Binaries
pushd /tmp
wget https://bit.ly/pynq_binaries_2_7 -O pynq_binaries.tar.gz
if [ $(file --mime-type -b pynq_binaries.tar.gz) != "application/gzip" ]; then
  echo -e "${RED}Could not download pynq binaries, server may be down${NC}\n"
  exit
fi

tar -xf pynq_binaries.tar.gz

cp -r  /tmp/pynq-v2.7-binaries/gcc-mb/microblazeel-xilinx-elf /miniconda3/bin/

cp pynq-v2.7-binaries/xrt/xclbinutil /miniconda3/bin/
chmod +x /miniconda3/bin/xclbinutil
popd

#Install PYNQ-HelloWorld
/miniconda3/bin/python3 -m pip install pynq-helloworld

#Install DPU-PYNQ
yes Y | apt remove --purge vitis-ai-runtime
/miniconda3/bin/python3 -m pip install pynq-dpu --no-use-pep517
cp -r /usr/lib/python3/site-packages/vaitrace_py /miniconda3/lib/python3.8/site-packages/ 
cp /usr/lib/python3/site-packages/vart.so /miniconda3/lib/python3.8/site-packages/
cp -r /usr/include/vart/ /miniconda3/include
cp -r /usr/include/xir/ /miniconda3/include
cp -r /usr/include/UniLog /miniconda3/include
# Hack to fix the glog issue (TODO: improve this)
cp -r /usr/include/glog /miniconda3/include/
cp -r /usr/include/gflags /miniconda3/include/
cp /usr/lib/python3/dist-packages/xir.cpython-38-aarch64-linux-gnu.so /miniconda3/lib/python3.8/site-packages/

# Get the notebooks
yes Y | pynq-get-notebooks -p /home/ubuntu/jupyter_notebooks -f

# Add the C++ stuff to the notebooks
mkdir -p /home/ubuntu/jupyter_notebooks/pynq-dpu/cpp_demo
wget https://raw.githubusercontent.com/STFleming/xeus-on-pynq/main/dpu_cling.h -P /home/ubuntu/jupyter_notebooks/pynq-dpu/cpp_demo/
wget https://raw.githubusercontent.com/STFleming/xeus-on-pynq/main/common.h -P /home/ubuntu/jupyter_notebooks/pynq-dpu/cpp_demo/
wget https://raw.githubusercontent.com/STFleming/xeus-on-pynq/main/overlay_setup.ipynb -P /home/ubuntu/jupyter_notebooks/pynq-dpu/cpp_demo/
wget https://raw.githubusercontent.com/STFleming/xeus-on-pynq/main/xeus_cling_dpu_example.ipynb -P /home/ubuntu/jupyter_notebooks/pynq-dpu/cpp_demo/
cp -r /home/ubuntu/jupyter_notebooks/pynq-dpu/img /home/ubuntu/jupyter_notebooks/pynq-dpu/cpp_demo/img


