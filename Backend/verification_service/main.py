"""
Baratito — Servicio de verificación de identidad (DeepFace).

FastAPI que recibe el id de una verificación, descarga la cédula y el selfie
del bucket privado de Supabase, compara los rostros con DeepFace y actualiza
el resultado en la tabla `identity_verifications`.

Flujo híbrido (configuración interna, no visible para el usuario):
  similarity > APPROVE_THRESHOLD  -> approved   (automático)
  en cualquier otro caso          -> pending    (revisión manual del equipo)
El sistema NUNCA rechaza automáticamente.
APPROVE_THRESHOLD se expresa en 0..1 (0.70 = 70% de coincidencia).

Ejecutar:
  pip install -r requirements.txt
  cp .env.example .env   # y rellena tus credenciales
  uvicorn main:app --host 0.0.0.0 --port 8000
"""

import os
import tempfile
from datetime import datetime, timezone

from dotenv import load_dotenv
from fastapi import FastAPI
from pydantic import BaseModel
from supabase import create_client, Client

load_dotenv()

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_SERVICE_ROLE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
BUCKET = os.getenv("VERIFICATION_BUCKET", "verification-docs")

# Coincidencia (0..1) por encima de la cual se aprueba automáticamente.
# 0.80 = 80%. Por debajo, lo revisa una persona del equipo Baratito.
APPROVE_THRESHOLD = float(os.getenv("APPROVE_THRESHOLD", "0.70"))

MODEL_NAME = os.getenv("DEEPFACE_MODEL", "Facenet512")
DISTANCE_METRIC = os.getenv("DEEPFACE_METRIC", "cosine")

# Detectores de rostro, en orden de intento. RetinaFace es mucho más robusto
# que el haarcascade de OpenCV para rostros pequeños (ej. la foto de la cédula),
# con brillo o levemente rotados. Si uno no detecta, se prueba el siguiente.
DETECTOR_BACKENDS = [
    d.strip()
    for d in os.getenv("DEEPFACE_DETECTORS", "retinaface,opencv").split(",")
    if d.strip()
]

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

app = FastAPI(title="Baratito Verification Service")


class VerifyRequest(BaseModel):
    verification_id: str


@app.get("/health")
def health():
    return {"status": "ok", "model": MODEL_NAME}


def _download_to_temp(path: str, suffix: str = ".jpg") -> str:
    """Descarga un archivo del bucket privado a un archivo temporal local."""
    data = supabase.storage.from_(BUCKET).download(path)
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
    tmp.write(data)
    tmp.close()
    _normalize_orientation(tmp.name)
    return tmp.name


def _normalize_orientation(path: str) -> None:
    """Aplica la rotación EXIF y re-guarda la imagen.

    Las fotos de celular traen la rotación en metadatos EXIF; OpenCV (que usa
    DeepFace para cargar) los ignora, así que el rostro puede quedar "acostado"
    y el detector no lo encuentra. Esto lo corrige antes de procesar.
    """
    try:
        from PIL import Image, ImageOps

        img = Image.open(path)
        img = ImageOps.exif_transpose(img)
        img.convert("RGB").save(path, "JPEG", quality=95)
    except Exception:
        pass  # si no se puede normalizar, se procesa tal cual


def _update(verification_id: str, fields: dict):
    supabase.table("identity_verifications").update(fields).eq(
        "id", verification_id
    ).execute()


@app.post("/verify")
def verify(req: VerifyRequest):
    # DeepFace se importa aquí para que el arranque del server sea rápido
    # (la primera llamada descarga los pesos del modelo).
    from deepface import DeepFace

    vid = req.verification_id

    # 1. Traer la fila
    res = (
        supabase.table("identity_verifications")
        .select("*")
        .eq("id", vid)
        .single()
        .execute()
    )
    row = res.data
    if not row:
        return {"error": "verification not found", "id": vid}

    front_path = row.get("cedula_front_path")
    selfie_path = row.get("selfie_path")
    if not front_path or not selfie_path:
        _update(vid, {"status": "pending",
                      "rejection_reason": "Faltan imágenes para procesar"})
        return {"status": "pending", "reason": "missing images"}

    # 2. Descargar cédula frontal + selfie
    cedula_file = _download_to_temp(front_path)
    selfie_file = _download_to_temp(selfie_path)

    try:
        # 3. Comparar rostros, probando los detectores en orden hasta que
        #    uno encuentre rostro en AMBAS imágenes.
        result = None
        last_error: Exception | None = None
        for backend in DETECTOR_BACKENDS:
            try:
                result = DeepFace.verify(
                    img1_path=selfie_file,
                    img2_path=cedula_file,
                    model_name=MODEL_NAME,
                    distance_metric=DISTANCE_METRIC,
                    detector_backend=backend,
                    enforce_detection=True,
                )
                break
            except ValueError as e:
                last_error = e  # este detector no encontró rostro; probar el siguiente
        if result is None:
            raise last_error or ValueError("No se detectó rostro")

        distance = float(result["distance"])
        # Para métrica cosine: similitud = 1 - distancia, acotada a [0, 1].
        similarity = max(0.0, min(1.0, 1.0 - distance))

        if similarity > APPROVE_THRESHOLD:
            # Coincidencia alta → aprobación automática.
            status, reason = "approved", None
        else:
            # Todo lo demás pasa a revisión manual del equipo Baratito.
            status, reason = "pending", "Pendiente de revisión manual"

        fields = {
            "face_match_score": round(similarity, 4),
            "status": status,
            "reviewed_at": datetime.now(timezone.utc).isoformat(),
        }
        if reason:
            fields["rejection_reason"] = reason
        _update(vid, fields)

        return {
            "id": vid,
            "status": status,
            "similarity": round(similarity, 4),
            "distance": round(distance, 4),
        }

    except ValueError as e:
        # DeepFace lanza ValueError cuando no detecta un rostro.
        _update(vid, {
            "status": "pending",
            "rejection_reason": f"No se detectó un rostro claro: {e}",
        })
        return {"id": vid, "status": "pending", "reason": "no face detected"}

    finally:
        for f in (cedula_file, selfie_file):
            try:
                os.remove(f)
            except OSError:
                pass
