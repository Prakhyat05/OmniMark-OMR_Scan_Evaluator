// supabase/functions/finalize-result/index.ts
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

    // Authenticate user
    const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });

    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized user token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { resultId, teacherRemark } = await req.json();
    if (!resultId) {
      return new Response(JSON.stringify({ error: "resultId is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fetch result record
    const { data: result, error: resultError } = await supabaseClient
      .from("results")
      .select("*, exam:exams(*)")
      .eq("id", resultId)
      .single();

    if (resultError || !result) {
      return new Response(JSON.stringify({ error: "Result not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify user membership in the organization
    const { data: member, error: memberError } = await supabaseClient
      .from("organization_members")
      .select("role, status")
      .eq("organization_id", result.organization_id)
      .eq("user_id", user.id)
      .eq("status", "active")
      .single();

    if (memberError || !member || !["owner", "admin", "teacher"].includes(member.role)) {
      return new Response(JSON.stringify({ error: "Insufficient permissions to finalize result" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Transition result to finalized
    const now = new Date().toISOString();
    const { data: updatedResult, error: updateError } = await supabaseClient
      .from("results")
      .update({
        status: "finalized",
        finalized_at: now,
        finalized_by: user.id,
        teacher_remark: teacherRemark || result.teacher_remark,
        updated_at: now,
      })
      .eq("id", resultId)
      .select()
      .single();

    if (updateError) {
      throw updateError;
    }

    // Insert result event audit log
    await supabaseClient.from("result_events").insert({
      organization_id: result.organization_id,
      result_id: resultId,
      actor_user_id: user.id,
      event_type: "finalized",
      before_state: { status: result.status, teacher_remark: result.teacher_remark },
      after_state: { status: "finalized", teacher_remark: teacherRemark || result.teacher_remark },
      reason: "Staff finalized evaluation result",
    });

    // Enqueue or auto-create Report record
    const reportPath = `organizations/${result.organization_id}/reports/${resultId}.pdf`;
    await supabaseClient.from("reports").upsert({
      organization_id: result.organization_id,
      result_id: resultId,
      template_version: "1.0.0",
      storage_path: reportPath,
      report_version: 1,
      status: "ready",
      generated_at: now,
    }, { onConflict: "result_id" });

    return new Response(JSON.stringify({
      success: true,
      message: "Result finalized successfully",
      result: updatedResult,
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
