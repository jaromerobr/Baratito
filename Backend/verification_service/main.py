"""
Baratito — Servicio de verificación de identidad (DeepFace).

FastAPI que recibe el id de una verificación, descarga la cédula y el selfie
del bucket privado de Supabase, compara los rostros con DeepFace y actualiza
el resultado en la tabla `identity_verifications`.

Flujo híbrido (configuración interna, no visible para el usuario):
  similarity > APPROVE_THRESHOLD  -> approved   (automático)
  en cualquier otro caso          -> pending    (revisión manual del equipo)
APPROVE_THRESHOLD se expresa en 0..1 (0.80 = 80% de coincidencia).

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
APPROVE_THRESHOLD = float(os.getenv("APPROVE_THRESHOLD", "0.80"))

MODEL_NAME = os.getenv("DEEPFACE_MODEL", "Facenet512")
DISTANCE_METRIC = os.getenv("DEEPFACE_METRIC", "cosine")

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
    return tmp.name


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
        # 3. Comparar rostros
        result = DeepFace.verify(
            img1_path=selfie_file,
            img2_path=cedula_file,
            model_name=MODEL_NAME,
            distance_metric=DISTANCE_METRIC,
            enforce_detection=True,
        )
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
