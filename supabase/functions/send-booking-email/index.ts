import { serve } from 'https://deno.land/std/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

serve(async (req) => {
  try {
    if (req.method === 'OPTIONS') {
      return new Response('ok', { headers: corsHeaders })
    }

    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: corsHeaders }
      )
    }

    let body: any = {}
    try {
      body = await req.json()
    } catch {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON body' }),
        { status: 400, headers: corsHeaders }
      )
    }

    const { appointment_id } = body

    if (!appointment_id) {
      return new Response(
        JSON.stringify({ error: 'Missing appointment_id' }),
        { status: 400, headers: corsHeaders }
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const { data: appointment, error } = await supabase
      .from('appointments')
      .select(`
        id,
        start_time,
        end_time,
        customers (
          name,
          email
        ),
        services (
          name
        )
      `)
      .eq('id', appointment_id)
      .single()

    if (error || !appointment) {
      return new Response(
        JSON.stringify({ error: 'Appointment not found' }),
        { status: 404, headers: corsHeaders }
      )
    }

    const email = appointment.customers?.email
    const customerName = appointment.customers?.name
    const serviceName = appointment.services?.name

    if (!email) {
      return new Response(
        JSON.stringify({ error: 'Customer email missing in DB' }),
        { status: 400, headers: corsHeaders }
      )
    }

    const rawDate = new Date(appointment.start_time)

    const appointmentDate = new Intl.DateTimeFormat('it-IT', {
      timeZone: 'Europe/Rome',
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    }).format(rawDate)

    const appointmentTime = new Intl.DateTimeFormat('it-IT', {
      timeZone: 'Europe/Rome',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    }).format(rawDate)

    // ✅ BASE_URL aggiornato a mvenzo.it
    const BASE_URL = Deno.env.get('BASE_URL') ?? 'https://mvenzo.it'
    const cancelLink = `${BASE_URL}/cancel/${appointment_id}`

    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

    const emailResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        // ✅ mittente aggiornato a mvenzo.it
        from: 'mvenzo <noreply@mvenzo.it>',
        to: [email],
        subject: 'Conferma prenotazione',
        html: `
        <div style="font-family: Arial, sans-serif; background:#f8fafc; padding:30px;">
          <div style="max-width:600px; margin:0 auto; background:#ffffff; border-radius:12px; overflow:hidden; box-shadow:0 4px 20px rgba(0,0,0,0.08);">

            <div style="background:#111827; padding:20px; text-align:center;">
              <h1 style="color:#ffffff; margin:0; font-size:20px;">mvenzo</h1>
            </div>

            <div style="padding:24px; color:#111827;">
              <h2 style="margin-top:0; font-size:18px;">Prenotazione confermata ✅</h2>
              <p style="font-size:14px; color:#374151;">
                Ciao <b>${customerName}</b>,<br/>
                la tua prenotazione è stata confermata con successo.
              </p>

              <div style="margin-top:20px; padding:16px; background:#f3f4f6; border-radius:10px;">
                <p style="margin:0; font-size:14px;"><b>Servizio:</b> ${serviceName}</p>
                <p style="margin:6px 0 0 0; font-size:14px;"><b>Data:</b> ${appointmentDate}</p>
                <p style="margin:6px 0 0 0; font-size:14px;"><b>Ora:</b> ${appointmentTime}</p>
              </div>

              <p style="margin-top:20px; font-size:13px; color:#6b7280;">
                Ti aspettiamo puntuale 💆‍♀️<br/>
                In caso di necessità puoi contattarci direttamente.
              </p>

              <div style="text-align:center; margin-top:25px;">
                <a href="${cancelLink}"
                   style="background:#dc2626; color:#ffffff; padding:12px 24px; text-decoration:none; border-radius:8px; font-size:14px; display:inline-block;">
                  Annulla prenotazione
                </a>
                <p style="margin-top:12px; font-size:12px; color:#6b7280;">
                  Clicca il pulsante per annullare la tua prenotazione in autonomia.
                </p>
              </div>
            </div>

            <div style="background:#f9fafb; padding:14px; text-align:center; font-size:12px; color:#6b7280;">
              © ${new Date().getFullYear()} mvenzo - Tutti i diritti riservati
            </div>

          </div>
        </div>
        `,
      }),
    })

    const rawRes = await emailResponse.text()
    let emailData
    try {
      emailData = JSON.parse(rawRes)
    } catch {
      emailData = rawRes
    }

    return new Response(
      JSON.stringify({ success: true, email: emailData }),
      { status: 200, headers: corsHeaders }
    )

  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500, headers: corsHeaders }
    )
  }
})