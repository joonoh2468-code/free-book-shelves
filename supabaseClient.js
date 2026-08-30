// ============================================================
// Free Book Shelf Network — shared Supabase connection
//
// Paste your project's real values below. Find them in the Supabase
// dashboard under Project Settings → API (click the "Connect" button
// on your project's main page for the fastest path to both values).
//
//   SUPABASE_URL   → looks like https://abcdefghij.supabase.co
//   SUPABASE_ANON_KEY → the "Publishable" key (or "anon" key on
//                        older projects) — NOT the Secret/service_role key
// ============================================================

const SUPABASE_URL = 'https://mzbtxmhekbfmgazfqxzb.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im16YnR4bWhla2JmbWdhemZxeHpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgwMzA5NzMsImV4cCI6MjEwMzYwNjk3M30.8ycSo-x-SBt7hmSmnCIQIjYmqx93DBGJ9k0PTFAjflE';

const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Call this at the top of every staff-only page. Redirects to the
// login page if nobody is signed in, otherwise returns the session.
async function requireLogin() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) {
    window.location.href = 'staff-login.html';
    return null;
  }
  return session;
}

// Signs the current staff member out and returns to the login page.
async function logout() {
  await supabase.auth.signOut();
  window.location.href = 'staff-login.html';
}
