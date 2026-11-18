// supabase/functions/create-report-link/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { persistSession: false },
    });

    const { resultId, expiresIn = 86400 } = await req.json();
    if (!resultId) {
      return new Response(JSON.stringify({ error: "resultId is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: report, error: reportError } = await supabaseClient
      .from("reports")
      .select("*, result:results(*)")
      .eq("result_id", resultId)
      .single();

    if (reportError || !report) {
      return new Response(JSON.stringify({ error: "Report not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Create signed storage URL (valid for specified seconds, default 24h)
    const { data: signedUrlData, error: signError } = await supabaseClient
      .storage
      .from("reports")
      .createSignedUrl(report.storage_path, expiresIn);

    if (signError || !signedUrlData) {
      throw signError || new Error("Failed to sign report URL");
    }

    return new Response(JSON.stringify({
      success: true,
      signedUrl: signedUrlData.signedUrl,
      expiresIn,
    }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
