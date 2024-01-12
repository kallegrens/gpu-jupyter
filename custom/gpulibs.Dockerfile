LABEL maintainer="Christoph Schranz <christoph.schranz@salzburgresearch.at>, Mathematical Michael <consistentbayes@gmail.com>"

# Install Tensorflow, check compatibility here:
# https://www.tensorflow.org/install/source#gpu
# installation via conda leads to errors in version 4.8.2
# Install CUDA-specific nvidia libraries and update libcudnn8 before that
USER ${NB_UID}
RUN pip install --upgrade pip && \
    pip install --no-cache-dir tensorflow==2.15.0 keras==2.15.0 && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install PyTorch with dependencies
RUN mamba install --quiet --yes \
    pyyaml setuptools cmake cffi typing && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Check compatibility here:
# https://pytorch.org/get-started/locally/
# Installation via conda leads to errors installing cudatoolkit=11.1
# RUN pip install --no-cache-dir torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0  && \
#     torchviz==0.0.2 --extra-index-url https://download.pytorch.org/whl/cu118
RUN set -ex \
    && buildDeps=' \
    torch==2.1.2 \
    torchvision==0.16.2 \
    torchaudio==2.1.2 \
    lightning==2.1.3 \
    ' \
    && pip install --no-cache-dir $buildDeps \
    && fix-permissions "${CONDA_DIR}" \
    && fix-permissions "/home/${NB_USER}"

USER root
ENV CUDA_PATH=/opt/conda/

# Install nvtop to monitor the gpu tasks
RUN apt-get update && \
    apt-get install -y --no-install-recommends cmake libncurses5-dev libncursesw5-dev git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# reinstall nvcc with cuda-nvcc to install ptax
USER $NB_UID
RUN mamba install -c nvidia cuda-nvcc -y && \
    mamba clean --all -f -y && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

USER root
RUN ln -s $CONDA_DIR/bin/ptxas /usr/bin/ptxas

USER $NB_UID