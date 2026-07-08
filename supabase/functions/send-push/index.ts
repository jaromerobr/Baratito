// Baratito — Edge Function `send-push`
//
// La llama un trigger de Postgres (pg_net) cada vez que se inserta una fila
// en public.notifications. Busca los push_tokens ACTIVOS del usuario y envía
// la notificación por FCM HTTP v1 a todos sus dispositivos.
//
// Secretos requeridos (supabase secrets set):
//   FIREBASE_SERVICE_ACCOUNT  → contenido del JSON de la cuenta de servicio
// (SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY los inyecta Supabase solo.)

import { createClient } from "npm:@supabase/supabase-js@2";

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

const sa: ServiceAccount = JSON.parse(
  Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "{}",
);

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// ── OAuth2 de Google con la cuenta de servicio (RS256) ──
let cachedToken: { token: string; exp: number } | null = null;

function b64url(data: string | Uint8Array): string {
  const bytes = typeof data === "string"
    ? new TextEncoder().encode(data)
    : data;
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.exp > now + 60) return cachedToken.token;

  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${claims}`;

  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s/g, "");
  const keyBytes = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      key,
      new TextEncoder().encode(unsigned),
    ),
  );
  const jwt = `${unsigned}.${b64url(sig)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:
      `grant_type=${encodeURIComponent("urn:ietf:params:oauth:grant-type:jwt-bearer")}&assertion=${jwt}`,
  });
  const json = await res.json();
  if (!json.access_token) {
    throw new Error(`OAuth falló: ${JSON.stringify(json)}`);
  }
  cachedToken = { token: json.access_token, exp: now + 3500 };
  return json.access_token;
}

// ── Envío FCM v1 a un token ─────────────────────────────
async function sendToToken(
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<"ok" | "dead" | "error"> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          data,
          android: {
            notification: {
              channel_id: channelFor(data.tipo),
              // silueta del logo + color de marca (los recursos viven en la app)
              icon: "ic_stat_baratito",
              color: "#2D6A4F",
            },
          },
        },
      }),
    },
  );

  if (res.ok) return "ok";
  const err = await res.json().catch(() => ({}));
  const status = err?.error?.details?.[0]?.errorCode ?? err?.error?.status;
  // Token de una app desinstalada / rotado → marcarlo inactivo.
  if (status === "UNREGISTERED" || res.status === 404) return "dead";
  console.error("FCM error:", res.status, JSON.stringify(err));
  return "error";
}

function channelFor(tipo?: string): string {
  switch (tipo) {
    case "nuevo_mensaje":
      return "baratito_chat";
    case "venta_realizada":
    case "pago_confirmado":
    case "pedido_enviado":
      return "baratito_pedidos";
    case "verificacion_aprobada":
    case "verificacion_rechazada":
    case "nueva_verificacion":
      return "baratito_cuenta";
    default:
      return "baratito_general";
  }
}

// ── Handler ─────────────────────────────────────────────
Deno.serve(async (req) => {
  try {
    const { user_id, title, body, metadata } = await req.json();
    if (!user_id || !title) {
      return new Response(JSON.stringify({ error: "user_id y title requeridos" }), { status: 400 });
    }

    const { data: tokens, error } = await supabase
      .from("push_tokens")
      .select("token")
      .eq("user_id", user_id)
      .eq("is_active", true);
    if (error) throw error;
    if (!tokens?.length) {
      return new Response(JSON.stringify({ sent: 0, reason: "sin tokens activos" }), { status: 200 });
    }

    // FCM data: todos los valores deben ser string.
    const data: Record<string, string> = {};
    for (const [k, v] of Object.entries(metadata ?? {})) {
      if (v !== null && v !== undefined) data[k] = String(v);
    }

    const accessToken = await getAccessToken();
    let sent = 0;
    for (const { token } of tokens) {
      const result = await sendToToken(accessToken, token, title, body ?? "", data);
      if (result === "ok") sent++;
      if (result === "dead") {
        await supabase.from("push_tokens").update({ is_active: false }).eq("token", token);
      }
    }

    return new Response(JSON.stringify({ sent, of: tokens.length }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("send-push:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
