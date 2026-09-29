import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

async function computeSignature(payload: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sigBuffer = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload));
  return Array.from(new Uint8Array(sigBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

serve(async (req) => {
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ valid: false, reason: "unauthenticated" }), { status: 401 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { qrHash } = await req.json();
    if (!qrHash || typeof qrHash !== "string") {
      return new Response(JSON.stringify({ valid: false, reason: "missing_qr_hash" }), { status: 400 });
    }

    const parts = qrHash.split(".");
    if (parts.length !== 3) {
      return new Response(JSON.stringify({ valid: false, reason: "malformed_token" }), { status: 200 });
    }
    const [cardId, timestamp, signature] = parts;

    const secret = Deno.env.get("QR_SIGNING_SECRET");
    if (!secret) {
      return new Response(JSON.stringify({ valid: false, reason: "server_misconfigured" }), { status: 500 });
    }

    const expectedSignature = await computeSignature(`${cardId}:${timestamp}`, secret);
    if (expectedSignature !== signature) {
      return new Response(JSON.stringify({ valid: false, reason: "invalid_signature" }), { status: 200 });
    }

    const { data: card, error } = await supabase
      .from("warranty_cards")
      .select("id, title, category, serial_number, issue_date, expiry_date, status, qr_hash, customer_email")
      .eq("id", cardId)
      .single();

    if (error || !card) {
      return new Response(JSON.stringify({ valid: false, reason: "not_found_or_not_authorized" }), { status: 200 });
    }

    if (card.qr_hash !== qrHash) {
      return new Response(JSON.stringify({ valid: false, reason: "token_superseded" }), { status: 200 });
    }

    const isExpired = new Date(card.expiry_date) < new Date();
    const liveStatus = isExpired ? "expired" : card.status;

    return new Response(
      JSON.stringify({
        valid: true,
        card: { ...card, status: liveStatus },
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ valid: false, reason: "server_error", detail: e.message }), { status: 500 });
  }
});