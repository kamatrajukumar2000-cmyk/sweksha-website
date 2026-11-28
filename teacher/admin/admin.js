import { createClient } from "https://esm.sh/@supabase/supabase-js@2.58.0";

const SUPABASE_URL = "https://xotqafgkubodqpirfpfb.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_BDsby1luWPSrviDTYNT83g_Y6eMqLpf";
const ADMIN_EMAIL = "kamatrajukumar2000@gmail.com";
const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
});

const $ = (id) => document.getElementById(id);
const state = { rows: [], filter: "all", selected: null };
const escapeHtml = (value) => String(value ?? "").replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
const prettyStatus = (s) => ({new:"New",contacted:"Contacted","in_progress":"In progress",completed:"Completed",closed:"Closed",rejected:"Rejected"}[s] || s || "New");
const prettyType = (s) => s === "teacher_registration" ? "Teacher Registration" : "Student Request";
const dateText = (v) => v ? new Intl.DateTimeFormat("en-IN",{dateStyle:"medium",timeStyle:"short",timeZone:"Asia/Kolkata"}).format(new Date(v)) : "—";

function showApp(user) {
  $("loginView").classList.add("hidden");
  $("appView").classList.remove("hidden");
  $("adminEmail").textContent = user.email || ADMIN_EMAIL;
}
function showLogin() {
  $("appView").classList.add("hidden");
  $("loginView").classList.remove("hidden");
}
function message(text, good=false) {
  $("authMessage").textContent = text;
  $("authMessage").style.color = good ? "#16734e" : "#a13b35";
}
async function loadEnquiries() {
  $("loading").classList.remove("hidden");
  $("errorBox").classList.add("hidden");
  $("enquiryRows").innerHTML = "";
  const { data, error } = await supabase.from("enquiries")
    .select("id,name,email,whatsapp,subject,message,status,created_at,updated_at,department,service_category,source_page,enquiry_type,admin_notes")
    .in("enquiry_type", ["teacher_registration","teacher_request"])
    .order("created_at", { ascending: false }).limit(500);
  $("loading").classList.add("hidden");
  if (error) {
    $("errorBox").textContent = "Could not load enquiries: " + error.message;
    $("errorBox").classList.remove("hidden");
    return;
  }
  state.rows = data || [];
  updateStats();
  renderRows();
}
function updateStats() {
  const teachers = state.rows.filter(r=>r.enquiry_type==="teacher_registration").length;
  const students = state.rows.filter(r=>r.enquiry_type==="teacher_request").length;
  $("totalCount").textContent = state.rows.length;
  $("newCount").textContent = state.rows.filter(r=>(r.status||"new")==="new").length;
  $("teacherCount").textContent = teachers;
  $("studentCount").textContent = students;
}
function renderRows() {
  const query = $("searchInput").value.trim().toLowerCase();
  const status = $("statusFilter").value;
  const rows = state.rows.filter(r => {
    const matchesType = state.filter==="all" || r.enquiry_type===state.filter;
    const haystack = [r.name,r.whatsapp,r.email,r.subject,r.message,r.service_category].join(" ").toLowerCase();
    return matchesType && (!query || haystack.includes(query)) && (status==="all" || (r.status||"new")===status);
  });
  $("enquiryRows").innerHTML = rows.map(r => `<tr>
    <td><strong>${escapeHtml(r.name)}</strong><small>${escapeHtml(r.whatsapp || r.email || "No contact")}</small></td>
    <td><span class="type-pill">${prettyType(r.enquiry_type)}</span></td>
    <td><strong>${escapeHtml(r.subject || r.service_category || "Enquiry")}</strong><small>${escapeHtml((r.message||"").replace(/\s+/g," ").slice(0,75))}${(r.message||"").length>75?"…":""}</small></td>
    <td>${dateText(r.created_at)}</td>
    <td><span class="status-pill ${escapeHtml(r.status||"new")}">${prettyStatus(r.status||"new")}</span></td>
    <td><button class="view-btn" data-open="${r.id}">View / Edit</button></td>
  </tr>`).join("");
  $("resultCount").textContent = rows.length + " records";
  $("noResults").classList.toggle("hidden", rows.length>0);
  document.querySelectorAll("[data-open]").forEach(btn=>btn.addEventListener("click",()=>openRecord(Number(btn.dataset.open))));
}
function addDetail(label,value,wide=false) {
  return `<div class="detail-item ${wide?"wide":""}"><label>${escapeHtml(label)}</label><p>${escapeHtml(value || "—")}</p></div>`;
}
function openRecord(id) {
  const r=state.rows.find(x=>Number(x.id)===id);
  if(!r)return;
  state.selected=r;
  $("detailTitle").textContent = r.name || "Enquiry";
  $("detailContent").innerHTML =
    addDetail("Enquiry type",prettyType(r.enquiry_type))+
    addDetail("Phone / WhatsApp",r.whatsapp)+
    addDetail("Email",r.email)+
    addDetail("Received",dateText(r.created_at))+
    addDetail("Subject",r.subject)+
    addDetail("Department",r.department)+
    addDetail("Service category",r.service_category)+
    addDetail("Source page",r.source_page)+
    addDetail("Full message",r.message,true);
  $("recordStatus").value=r.status||"new";
  $("adminNotes").value=r.admin_notes||"";
  $("saveMessage").textContent="";
  $("detailModal").classList.remove("hidden");
}
async function saveRecord() {
  if(!state.selected)return;
  const btn=$("saveRecord");
  btn.disabled=true;btn.textContent="Saving…";
  const changes={status:$("recordStatus").value,admin_notes:$("adminNotes").value.trim(),updated_at:new Date().toISOString()};
  const {data,error}=await supabase.from("enquiries").update(changes).eq("id",state.selected.id).select("id,status,admin_notes,updated_at").single();
  btn.disabled=false;btn.textContent="Save changes";
  if(error){$("saveMessage").textContent="Save failed: "+error.message;return;}
  state.rows=state.rows.map(r=>r.id===state.selected.id?{...r,...data}:r);
  state.selected={...state.selected,...data};
  $("saveMessage").textContent="Changes saved successfully.";
  $("saveMessage").style.color="#16734e";
  updateStats();renderRows();
}
$("loginForm").addEventListener("submit",async e=>{
  e.preventDefault();message("Signing in…",true);
  const email=$("email").value.trim().toLowerCase();
  if(email!==ADMIN_EMAIL){message("This email is not authorised for the admin panel.");return;}
  const {data,error}=await supabase.auth.signInWithPassword({email,password:$("password").value});
  if(error){message(error.message);return;}
  if((data.user?.email||"").toLowerCase()!==ADMIN_EMAIL){await supabase.auth.signOut();message("This account is not authorised.");return;}
  showApp(data.user);await loadEnquiries();
});
$("forgotBtn").addEventListener("click",async()=>{
  const email=$("email").value.trim().toLowerCase();
  if(email!==ADMIN_EMAIL){message("Enter the authorised admin email first.");return;}
  const {error}=await supabase.auth.resetPasswordForEmail(email,{redirectTo:location.href});
  message(error?error.message:"Password reset link sent. Check the admin email inbox.",!error);
});
$("resetForm").addEventListener("submit",async e=>{
  e.preventDefault();
  const password=$("newPassword").value;
  if(password.length<10){message("Use at least 10 characters.");return;}
  const {error}=await supabase.auth.updateUser({password});
  message(error?error.message:"Password updated. You can continue to the admin panel.",!error);
  if(!error){$("resetForm").classList.add("hidden");const {data}=await supabase.auth.getUser();if(data.user?.email?.toLowerCase()===ADMIN_EMAIL){showApp(data.user);await loadEnquiries();}}
});
$("logoutBtn").addEventListener("click",async()=>{await supabase.auth.signOut();state.rows=[];showLogin();});
$("refreshBtn").addEventListener("click",loadEnquiries);
$("searchInput").addEventListener("input",renderRows);
$("statusFilter").addEventListener("change",renderRows);
document.querySelectorAll("[data-filter]").forEach(btn=>btn.addEventListener("click",()=>{
  state.filter=btn.dataset.filter;
  document.querySelectorAll("[data-filter]").forEach(b=>b.classList.toggle("active",b===btn));
  $("pageTitle").textContent=state.filter==="teacher_registration"?"Teacher Registrations":state.filter==="teacher_request"?"Student Requests":"Overview";
  $("listTitle").textContent=state.filter==="teacher_registration"?"Teacher Registrations":state.filter==="teacher_request"?"Student Requests":"Recent Teacher & Student Enquiries";
  renderRows();
}));
$("closeModal").addEventListener("click",()=>$("detailModal").classList.add("hidden"));
$("detailModal").addEventListener("click",e=>{if(e.target===$("detailModal"))$("detailModal").classList.add("hidden");});
$("saveRecord").addEventListener("click",saveRecord);

supabase.auth.onAuthStateChange(async(event,session)=>{
  if(event==="PASSWORD_RECOVERY"){$("resetForm").classList.remove("hidden");message("Choose a new password.",true);return;}
  if(session?.user && session.user.email?.toLowerCase()===ADMIN_EMAIL){
    showApp(session.user);
    if(event==="SIGNED_IN"||event==="INITIAL_SESSION")await loadEnquiries();
  } else if(!session) showLogin();
});
const {data:{session}}=await supabase.auth.getSession();
if(session?.user?.email?.toLowerCase()===ADMIN_EMAIL){showApp(session.user);await loadEnquiries();}
else showLogin();
