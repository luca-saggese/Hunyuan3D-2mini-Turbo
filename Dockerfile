# Usa un'immagine di base con Python 3.10
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# Imposta il maintainer
LABEL maintainer="Andrea"

# Imposta la directory di lavoro
WORKDIR /app

# Installa i pacchetti di sistema necessari
RUN apt update && apt install -y \
    python3.10 python3.10-venv python3.10-dev python3-pip \
    git wget curl unzip ffmpeg libgl1-mesa-glx \
    && apt clean

# Copia solo il file requirements.txt per ottimizzare il caching
COPY requirements.txt /tmp/

# Crea un ambiente virtuale e attivalo
RUN python3 -m venv venv
ENV PATH="/app/venv/bin:$PATH"

# Installa pip e PyTorch prima per sfruttare la cache
RUN pip install --upgrade pip \
    && pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# Installa le dipendenze senza invalidare la cache quando il codice cambia
RUN pip install -r /tmp/requirements.txt

# Ora copia il resto del codice (non invalida il caching delle dipendenze)
COPY [^g]* /app

# Installa le dipendenze aggiuntive richieste
RUN pip install gradio==3.39.0 sentencepiece

# Imposta le variabili di ambiente per CUDA e Torch
ENV CUDA_HOME=/usr/local/cuda
ENV PATH="$CUDA_HOME/bin:$PATH"
ENV LD_LIBRARY_PATH="$CUDA_HOME/lib64:$LD_LIBRARY_PATH"

# Imposta TORCH_CUDA_ARCH_LIST per evitare errori di compilazione
ENV TORCH_CUDA_ARCH_LIST="7.5;8.0;8.6;9.0"

# Imposta la directory di cache Hugging Face
ENV HF_HOME=/huggingface

# Compila i moduli richiesti per la texture
RUN cd hy3dgen/texgen/custom_rasterizer && \
    python3 setup.py install && \
    cd ../../.. && \
    cd hy3dgen/texgen/differentiable_renderer && \
    bash compile_mesh_painter.sh

COPY gradio_app.py /app

# Espone la porta per Gradio
EXPOSE 7860 

# Comando di default per avviare il server Gradio
CMD ["python3", "gradio_app.py", "low_vram_mode"]

