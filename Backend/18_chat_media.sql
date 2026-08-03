-- ============================================================
-- Baratito — Multimedia en el chat (imágenes, videos, audios)
--
-- Los mensajes pueden ser de texto o llevar un archivo (imagen/video/audio)
-- guardado en MinIO (bucket `baratito`, carpeta `chat/`). `media_path` es la
-- key del objeto; `content` queda como texto/caption opcional.
--
-- Depende de: 06_profile_chat_setup.sql (tabla messages + RLS).
-- Correr TODO en Supabase → SQL Editor. Es idempotente.
-- ============================================================

alter table public.messages
  add column if not exists message_type text not null default 'text';

alter table public.messages drop constraint if exists messages_type_check;
alter table public.messages add constraint messages_type_check
  check (message_type in ('text', 'image', 'video', 'audio'));

alter table public.messages
  add column if not exists media_path text;

-- El contenido de texto ya no es obligatorio (los mensajes multimedia pueden
-- no llevar texto).
alter table public.messages alter column content drop not null;
