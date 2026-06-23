const { createClient } = require('@supabase/supabase-js');
const supabase = createClient('https://ddygpqkuxgfrjdipdvek.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkeWdwcWt1eGdmcmpkaXBkdmVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMjUwNjEsImV4cCI6MjA5NDkwMTA2MX0.63PViWP91iqrC2r4r6WX-SMcVehwRE-2IbZvwkNOVzY');
async function test() {
  const { data, error } = await supabase.auth.resetPasswordForEmail('eduardo.baratito.test@gmail.com');
  console.log('Data:', data);
  console.log('Error:', error);
}
test();
