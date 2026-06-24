/// The no-account web ballot page, served by the relay at `GET /v/<id>`.
///
/// It is the top-of-funnel surface: a recipient opens a shared link in any
/// browser, votes without an account, and sees the conversion CTA. The page is
/// **zero-knowledge to the relay** exactly like the app — the decryption key
/// lives only in the URL fragment (`#<key>`), which browsers never send to the
/// server. All crypto runs client-side via WebCrypto and mirrors `PartyCrypto`:
/// AES-GCM-256 over a blob laid out as nonce(12) ‖ ciphertext ‖ mac(16).
///
/// The party/ballot JSON shapes match `PartyCodec`. Tallying still happens in
/// the app; the web voter just submits an encrypted ballot.
const String ballotPageHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>ReckonParty — cast your vote</title>
<style>
  :root { --terracotta:#C25B3F; --linen:#FBF6EF; --ink:#2B2622; --sage:#6B7F6E; }
  * { box-sizing: border-box; }
  body { margin:0; background:var(--linen); color:var(--ink);
    font-family: -apple-system, system-ui, "Nunito", sans-serif;
    display:flex; justify-content:center; padding:24px; }
  main { width:100%; max-width:480px; }
  h1 { font-family: Georgia, "Lora", serif; font-weight:600; font-size:1.6rem; line-height:1.25; }
  .sub { color:#6b635a; font-size:.9rem; margin-top:-6px; }
  .opt { display:flex; align-items:center; gap:12px; padding:14px 16px; margin:10px 0;
    background:#fff; border:1px solid #e7ddcf; border-radius:12px; cursor:pointer; }
  .opt.sel { border-color:var(--terracotta); box-shadow:0 0 0 2px rgba(194,91,63,.15); }
  .opt .rank { min-width:26px; height:26px; border-radius:50%; background:var(--terracotta);
    color:#fff; display:none; align-items:center; justify-content:center; font-size:.85rem; }
  .opt.sel .rank { display:flex; }
  button { width:100%; padding:14px; border:0; border-radius:12px; background:var(--terracotta);
    color:#fff; font-size:1rem; font-weight:700; cursor:pointer; margin-top:12px; }
  button:disabled { opacity:.5; cursor:default; }
  .hint { font-size:.8rem; color:#8a8278; margin-top:8px; }
  .cta { margin-top:28px; padding:18px; background:#fff; border:1px solid #e7ddcf;
    border-radius:12px; text-align:center; }
  .cta a { color:var(--terracotta); font-weight:700; text-decoration:none; }
  .err { color:#9b2c2c; }
</style>
</head>
<body>
<main id="app"><p>Loading…</p></main>
<script>
const app = document.getElementById('app');
const show = (html) => { app.innerHTML = html; };

function b64urlToBytes(s){ s=s.replace(/-/g,'+').replace(/_/g,'/'); while(s.length%4)s+='='; return b64ToBytes(s); }
function b64ToBytes(s){ const bin=atob(s); const b=new Uint8Array(bin.length); for(let i=0;i<bin.length;i++) b[i]=bin.charCodeAt(i); return b; }

async function importKey(keyB64url){
  return crypto.subtle.importKey('raw', b64urlToBytes(keyB64url), {name:'AES-GCM'}, false, ['encrypt','decrypt']);
}
async function decryptJson(key, blob){
  const iv = blob.slice(0,12), ctMac = blob.slice(12);
  const pt = await crypto.subtle.decrypt({name:'AES-GCM', iv}, key, ctMac);
  return JSON.parse(new TextDecoder().decode(pt));
}
async function encryptJson(key, obj){
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const ct = new Uint8Array(await crypto.subtle.encrypt({name:'AES-GCM', iv}, key,
    new TextEncoder().encode(JSON.stringify(obj))));
  const out = new Uint8Array(12 + ct.length); out.set(iv,0); out.set(ct,12); return out;
}

const cta = `<div class="cta">This was decided with <strong>Reckon</strong>.<br/>
  <a href="https://reckon.app">Make better decisions yourself →</a></div>`;

async function main(){
  const id = location.pathname.split('/').filter(Boolean).pop();
  const keyStr = location.hash.slice(1);
  if (!id || !keyStr){ show('<p class="err">This link is missing its party id or key.</p>'); return; }

  let key, party, data;
  try {
    key = await importKey(keyStr);
    const res = await fetch('/parties/' + encodeURIComponent(id));
    if (!res.ok) throw new Error('Party not found');
    data = await res.json();
    party = await decryptJson(key, b64ToBytes(data.party));
  } catch(e){
    show('<p class="err">Could not open this party. The link may be wrong or expired.</p>'); return;
  }

  if (data.closed){ show('<h1>'+esc(party.title)+'</h1><p class="sub">Voting has closed.</p>'+cta); return; }

  const ranked = party.votingMethod === 'ranked';
  const selected = []; // option ids, in click order (ranked) or membership (approval)

  function render(){
    const opts = party.options.map(o => {
      const idx = selected.indexOf(o.id);
      const sel = idx >= 0;
      const badge = ranked ? (sel ? (idx+1) : '') : (sel ? '✓' : '');
      return `<div class="opt ${sel?'sel':''}" data-id="${esc(o.id)}">
        <span class="rank" style="display:${sel?'flex':'none'}">${badge}</span>
        <span>${esc(o.label)}</span></div>`;
    }).join('');
    show(`<h1>${esc(party.title)}</h1>
      <p class="sub">${ranked ? 'Tap options in your order of preference.' : 'Tap every option you would be happy with.'}</p>
      ${opts}
      <button id="submit" ${selected.length?'':'disabled'}>Submit vote</button>
      <p class="hint">Your vote is encrypted in your browser. The server only sees scrambled bytes.</p>`);
    document.querySelectorAll('.opt').forEach(el => el.onclick = () => toggle(el.dataset.id));
    document.getElementById('submit').onclick = submit;
  }
  function toggle(oid){
    const i = selected.indexOf(oid);
    if (i >= 0) selected.splice(i,1); else selected.push(oid);
    render();
  }
  async function submit(){
    const btn = document.getElementById('submit'); btn.disabled = true; btn.textContent = 'Submitting…';
    const ballot = {
      id: crypto.randomUUID(),
      method: ranked ? 'ranked' : 'approval',
      approvals: ranked ? [] : selected.slice(),
      ranking: ranked ? selected.slice() : [],
    };
    try {
      const body = await encryptJson(key, ballot);
      const res = await fetch('/parties/'+encodeURIComponent(id)+'/ballots/'+ballot.id,
        { method:'PUT', body });
      if (!res.ok) throw new Error('rejected');
      show('<h1>'+esc(party.title)+'</h1><p class="sub">Thanks — your vote is in.</p>'+cta);
    } catch(e){
      btn.disabled = false; btn.textContent = 'Submit vote';
      const p = document.createElement('p'); p.className='err'; p.textContent='Could not submit — try again.';
      app.appendChild(p);
    }
  }
  function esc(s){ return String(s).replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c])); }
  render();
}
main();
</script>
</body>
</html>''';
