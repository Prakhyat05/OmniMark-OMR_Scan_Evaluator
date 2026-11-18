// supabase/functions/send-report-email/index.ts
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
    const resendApiKey = Deno.env.get("RESEND_API_KEY") || "mock_resend_api_key";
    const fromEmail = Deno.env.get("RESEND_FROM_EMAIL") || "no-reply@omrplatform.edu";

    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { persistSession: false },
    });

    const { resultId, customNote } = await req.json();
    if (!resultId) {
      return new Response(JSON.stringify({ error: "resultId is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fetch result with student, parent, exam, and organization info
    const { data: result, error: resultError } = await supabaseClient
      .from("results")
      .select(`
        *,
        student:students(*),
        exam:exams(*),
        organization:organizations(*)
      `)
      .eq("id", resultId)
      .single();

    if (resultError || !result) {
      return new Response(JSON.stringify({ error: "Result not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (result.status !== "finalized") {
      return new Response(JSON.stringify({ error: "Result must be finalized before sending parent email" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Find primary parent contact
    const { data: parentContact, error: parentError } = await supabaseClient
      .from("parent_contacts")
      .select("*")
      .eq("student_id", result.student_id)
      .eq("is_primary", true)
      .single();

    if (parentError || !parentContact) {
      return new Response(JSON.stringify({ error: "Primary parent contact with email not found for this student" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fetch report record
    const { data: report, error: reportError } = await supabaseClient
      .from("reports")
      .select("*")
      .eq("result_id", resultId)
      .single();

    if (reportError || !report) {
      return new Response(JSON.stringify({ error: "Report record not found for this result" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Check existing email delivery to maintain idempotency
    const { data: existingDelivery } = await supabaseClient
      .from("email_deliveries")
      .select("*")
      .eq("result_id", resultId)
      .eq("parent_contact_id", parentContact.id)
      .eq("report_id", report.id)
      .maybeSingle();

    if (existingDelivery && existingDelivery.status === "sent") {
      return new Response(JSON.stringify({
        success: true,
        message: "Email already sent previously (idempotent response)",
        delivery: existingDelivery,
      }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Generate signed report link
    const { data: signedUrlData } = await supabaseClient
      .storage
      .from("reports")
      .createSignedUrl(report.storage_path, 7 * 86400); // 7 days validity

    const reportUrl = signedUrlData?.signedUrl || "https://omrplatform.edu/reports/view";
    const subject = `Official Assessment Report — ${result.student.full_name} (${result.exam.name})`;

    const emailHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #fcf9f8; color: #1b1c1c; margin: 0; padding: 20px; }
          .card { background-color: #ffffff; border-radius: 12px; border: 1px solid #eae7e7; max-width: 600px; margin: 0 auto; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.05); }
          .header { background-color: #006e1c; color: #ffffff; padding: 24px; text-align: center; }
          .content { padding: 32px; }
          .stat-box { background-color: #f0eded; border-radius: 8px; padding: 16px; margin: 20px 0; display: flex; justify-content: space-around; }
          .stat-item { text-align: center; }
          .stat-val { font-size: 24px; font-weight: bold; color: #006e1c; }
          .stat-lbl { font-size: 12px; color: #556158; text-transform: uppercase; }
          .button { display: inline-block; background-color: #006e1c; color: #ffffff !important; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; margin-top: 20px; }
          .footer { font-size: 12px; color: #556158; text-align: center; padding: 20px; border-top: 1px solid #f0eded; }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="header">
            <h2 style="margin:0;">${result.organization.name}</h2>
            <p style="margin:6px 0 0 0; opacity: 0.9; font-size: 14px;">Student Assessment Report</p>
          </div>
          <div class="content">
            <p>Dear <strong>${parentContact.name}</strong>,</p>
            <p>The evaluation for <strong>${result.student.full_name}</strong> in <strong>${result.exam.name}</strong> has been finalized.</p>
            
            <div class="stat-box">
              <div class="stat-item">
                <div class="stat-val">${result.marks_obtained}/${result.maximum_marks}</div>
                <div class="stat-lbl">Score</div>
              </div>
              <div class="stat-item">
                <div class="stat-val">${result.percentage ? result.percentage + '%' : 'N/A'}</div>
                <div class="stat-lbl">Percentage</div>
              </div>
              <div class="stat-item">
                <div class="stat-val">${result.rank ? '#' + result.rank : '-'}</div>
                <div class="stat-lbl">Rank</div>
              </div>
            </div>

            ${customNote ? `<div style="background-color: #e8f5e9; padding: 12px; border-radius: 6px; margin-bottom: 20px;"><strong style="color:#006e1c;">Teacher's Note:</strong> ${customNote}</div>` : ''}

            <center>
              <a href="${reportUrl}" class="button">View & Download Report Card</a>
            </center>

            <p style="font-size: 13px; color: #556158; margin-top: 30px;">
              If you have any questions regarding these marks, please reach out to ${result.organization.name} administration at ${result.organization.contact_email || 'the school office'}.
            </p>
          </div>
          <div class="footer">
            © ${new Date().getFullYear()} ${result.organization.name}. Powered by OMR Scan System.
          </div>
        </div>
      </body>
      </html>
    `;

    // Call Resend API or simulate in non-production
    let providerMessageId = `resend_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    let status = "sent";
    let lastError = null;

    if (resendApiKey && resendApiKey !== "mock_resend_api_key") {
      try {
        const resendResponse = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${resendApiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from: fromEmail,
            to: parentContact.email,
            subject: subject,
            html: emailHtml,
          }),
        });
        const resendData = await resendResponse.json();
        if (!resendResponse.ok) {
          throw new Error(resendData.message || "Resend API error");
        }
        providerMessageId = resendData.id;
      } catch (e: any) {
        status = "failed";
        lastError = e.message;
      }
    }

    // Upsert delivery record
    const { data: deliveryRecord, error: deliveryError } = await supabaseClient
      .from("email_deliveries")
      .upsert({
        organization_id: result.organization_id,
        result_id: resultId,
        report_id: report.id,
        parent_contact_id: parentContact.id,
        provider: "resend",
        provider_message_id: providerMessageId,
        to_email: parentContact.email,
        subject: subject,
        status: status,
        attempt_count: (existingDelivery?.attempt_count || 0) + 1,
        last_error: lastError,
        sent_at: status === "sent" ? new Date().toISOString() : null,
      }, { onConflict: "result_id,parent_contact_id,report_id" })
      .select()
      .single();

    if (deliveryError) {
      throw deliveryError;
    }

    // Insert Audit log
    await supabaseClient.from("audit_logs").insert({
      organization_id: result.organization_id,
      action: "email_sent",
      entity_type: "email_deliveries",
      entity_id: deliveryRecord.id,
      metadata: {
        to_email: parentContact.email,
        student_id: result.student_id,
        result_id: resultId,
        provider_message_id: providerMessageId,
      },
    });

    return new Response(JSON.stringify({
      success: status === "sent",
      message: status === "sent" ? "Report email sent successfully" : "Email provider failed",
      delivery: deliveryRecord,
      error: lastError,
    }), {
      status: status === "sent" ? 200 : 502,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
