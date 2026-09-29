import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), { status: 401 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

    // Scoped to the caller's own JWT — RLS applies exactly as it does in the app
    const supabase = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { cardId } = await req.json();
    if (!cardId) {
      return new Response(JSON.stringify({ error: "cardId is required" }), { status: 400 });
    }

    // This SELECT only succeeds if RLS allows it — proves the caller is the issuing merchant
    const { data: card, error: cardError } = await supabase
      .from("warranty_cards")
      .select("id")
      .eq("id", cardId)
      .single();

    if (cardError || !card) {
      return new Response(JSON.stringify({ error: "Not authorized to sign this card" }), { status: 403 });
    }

    const secret = Deno.env.get("QR_SIGNING_SECRET");
    if (!secret) {
      return new Response(JSON.stringify({ error: "Server misconfigured" }), { status: 500 });
    }

    const timestamp = Date.now().toString();
    const payload = `${cardId}:${timestamp}`;

    const key = await crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"],
    );
    const sigBuffer = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload));
    const signature = Array.from(new Uint8Array(sigBuffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    const qrHash = `${cardId}.${timestamp}.${signature}`;

    const { error: updateError } = await supabase
      .from("warranty_cards")
      .update({ qr_hash: qrHash })
      .eq("id", cardId);

    if (updateError) {
      return new Response(JSON.stringify({ error: updateError.message }), { status: 500 });
    }

    return new Response(JSON.stringify({ qrHash }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 });
  }
});