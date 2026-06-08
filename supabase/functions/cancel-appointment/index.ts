import { serve } from 'https://deno.land/std/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: corsHeaders }
    )
  }

  try {
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

    const { data: existing, error: fetchError } = await supabase
      .from('appointments')
      .select('id, status')
      .eq('id', appointment_id)
      .single()

    if (fetchError || !existing) {
      return new Response(
        JSON.stringify({ error: 'Appointment not found' }),
        { status: 404, headers: corsHeaders }
      )
    }

    if (existing.status === 'cancelled') {
      return new Response(
        JSON.stringify({ error: 'already_cancelled' }),
        { status: 200, headers: corsHeaders }
      )
    }

    const { error: updateError } = await supabase
      .from('appointments')
      .update({ status: 'cancelled' })
      .eq('id', appointment_id)

    if (updateError) {
      return new Response(
        JSON.stringify({ error: updateError.message }),
        { status: 500, headers: corsHeaders }
      )
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: corsHeaders }
    )

  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500, headers: corsHeaders }
    )
  }
})