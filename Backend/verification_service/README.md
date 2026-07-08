# Baratito — Servicio de verificación (DeepFace)

Microservicio en Python (FastAPI) que compara el selfie con la foto de la
cédula usando **DeepFace** y actualiza el resultado en Supabase.

## Requisitos
- Python 3.10 – 3.11 (recomendado; DeepFace/TensorFlow aún no soporta 3.13 bien).
- ~2 GB libres (TensorFlow + pesos del modelo).

## Instalación (una sola vez)

```bash
cd Backend/verification_service

# 1. Entorno virtual
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# 2. Dependencias
pip install -r requirements.txt

# 3. Configuración
cp .env.example .env
#   Edita .env y pega tu SUPABASE_SERVICE_ROLE_KEY
#   (Supabase → Project Settings → API → service_role secret)
```

## Ejecutar

```bash
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000
```

- La **primera** llamada a `/verify` descarga los pesos del modelo (~100 MB),
  puede tardar 1–2 min. Las siguientes son rápidas.
- Prueba: `curl http://localhost:8000/health` → `{"status":"ok",...}`

## Cómo lo llama la app

La app Flutter, al enviar una verificación, hace:
`POST http://<IP_DE_TU_PC>:8000/verify  { "verification_id": "<uuid>" }`

- **Emulador Android:** la app usa `10.0.2.2:8000` (ya configurado por defecto).
- **Dispositivo físico:** corre la app con la IP LAN de tu PC:
  ```bash
  flutter run --dart-define=VERIFY_SERVICE_URL=http://192.168.1.XX:8000
  ```
  (averigua tu IP con `ip addr` / `ifconfig`; PC y teléfono en la misma red).

## Decisión (flujo híbrido — configuración interna, no visible al usuario)
- `similarity > 0.70` (más de 70%) → **approved** automático
  (el trigger marca `profiles.is_verified = true`).
- Cualquier otro caso → **pending**: lo revisa manualmente una persona del
  equipo Baratito (no hay rechazo automático).

Ajusta el umbral con `APPROVE_THRESHOLD` en `.env`.

## Seguridad
- La `service_role key` vive SOLO aquí, nunca en la app.
- El bucket `verification-docs` es privado; solo este servicio (service_role)
  y el propio usuario pueden leer sus imágenes.
