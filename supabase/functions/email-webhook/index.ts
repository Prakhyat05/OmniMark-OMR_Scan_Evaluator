// supabase/functions/email-webhook/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { persistSession: false },
    });

    const payload = await req.json();
    const eventType = payload.type; // e.g. 'email.delivered', 'email.bounced'
    const emailId = payload.data?.email_id;

    if (!emailId) {
      return new Response(JSON.stringify({ message: "No email_id in webhook" }), { status: 200 });
    }

    let status = "sent";
    if (eventType === "email.delivered") {
      status = "delivered";
    } else if (eventType === "email.bounced" || eventType === "email.complained") {
      status = "bounced";
    }

    await supabaseClient
      .from("email_deliveries")
      .update({
        status: status,
        delivered_at: status === "delivered" ? new Date().toISOString() : null,
        last_error: status === "bounced" ? payload.data?.bounce?.message || "Email bounced" : null,
        updated_at: new Date().toISOString(),
      })
      .eq("provider_message_id", emailId);

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
