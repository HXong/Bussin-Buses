/**
 * Supabase client configuration
 * This file is responsible for creating a Supabase client instance using the provided URL and API key.
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '../../.env' });

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    console.error("Supabase URL or API Key is missing! Check your .env file.");
}

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
module.exports = { supabase };