# Diagrama de secuencia — Verificación de identidad / KYC (Baratito)

Muestra cómo Baratito verifica que la persona sea real: sube cédula + selfie a
un bucket **privado**, y un microservicio en Python compara los rostros con IA
(DeepFace). El flujo es **híbrido**: aprueba automático si hay alta coincidencia
y, ante la duda, manda a **revisión humana** (nunca rechaza solo).

**Evidencia real:**
- `Frontend/lib/features/verification/data/verification_repository.dart`
- Servicio `Backend/verification_service/main.py` (FastAPI + DeepFace / Facenet512)
- `Backend/04_verification_setup.sql` (bucket privado + RLS + trigger `sync_profile_verified`)

```mermaid
sequenceDiagram
    autonumber
    actor U as Usuario (App)
    participant ST as Storage privado (verification-docs)
    participant DB as Supabase Postgres
    participant DF as Servicio DeepFace (FastAPI)

    U->>ST: sube cédula (frente + reverso) + selfie
    Note over U,ST: Cámara guiada (rejilla para cédula, óvalo para rostro)
    U->>DB: INSERT identity_verifications (status='pending')
    U->>DF: POST /verify { verification_id }
    Note over U,DF: Best-effort: si el servicio no responde,<br/>queda 'pending' y la app sigue funcionando
    DF->>ST: descarga cédula frontal + selfie (service_role)
    ST-->>DF: imágenes
    DF->>DF: DeepFace.verify (Facenet512) → similitud
    alt similitud > umbral
        DF->>DB: UPDATE status='approved' + face_match_score
        DB->>DB: trigger sync_profile_verified → profiles.is_verified = true
    else similitud ≤ umbral o sin rostro
        DF->>DB: UPDATE status='pending' (revisión manual del admin)
    end
```

## Paso a paso
1. **Datos sensibles protegidos:** las fotos van a un bucket **privado**; solo el propio usuario y el servicio (con `service_role`) pueden leerlas.
2. **Comparación con IA:** el servicio compara el selfie con la foto de la cédula usando el modelo Facenet512.
3. **Decisión híbrida:** alta coincidencia → aprobado automático; cualquier duda → revisión humana. **Nunca hay rechazo automático.**
4. **Efecto en la cuenta:** al aprobarse, un *trigger* marca `profiles.is_verified = true`, lo que habilita publicar y comprar.
