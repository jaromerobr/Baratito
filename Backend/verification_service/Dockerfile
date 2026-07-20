FROM python:3.11-slim

# Librerías de sistema que opencv-headless necesita en runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*

# HF Spaces corre como usuario no-root (uid 1000): creamos el user y un HOME escribible
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    DEEPFACE_HOME=/home/user

WORKDIR /home/user/app

# Dependencias Python
COPY --chown=user requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Pre-descarga los pesos de Facenet512 en el build → arranque mucho más rápido
RUN python -c "from deepface import DeepFace; DeepFace.build_model('Facenet512')"

# Código del servicio
COPY --chown=user . .

EXPOSE 7860
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]