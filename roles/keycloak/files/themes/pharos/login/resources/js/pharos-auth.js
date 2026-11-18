'use strict';
(() => {
 const source=document.currentScript;
 const issuer=new URL(new URL(source.src).searchParams.get('issuer'));
 const mount='/proof_spa/identity';
 if(!location.pathname.startsWith(mount+'/realms/'))return;
 const realm=location.pathname.slice(mount.length).match(/^\/realms\/[^/]+\//)?.[0];
 const secure=issuer.protocol==='https:'||(issuer.protocol==='http:'&&issuer.hostname==='localhost'&&issuer.port);
 if(!realm||!secure||issuer.username||issuer.password)return;
 const local=value=>{
  const url=new URL(value,location.href);
  if(url.origin!==issuer.origin||!url.pathname.startsWith(realm))return null;
  return mount+url.pathname+url.search+url.hash;
 };
 const update=()=>{
  for(const form of document.forms){const target=local(form.action);if(target)form.action=target;}
  for(const link of document.querySelectorAll('a[href]')){const target=local(link.href);if(target)link.href=target;}
 };
 const ready=()=>{
  update();document.documentElement.dataset.proofSignin='true';
  document.title='Proof · Sign in';
  const brand=document.getElementById('kc-header-wrapper');if(brand){brand.textContent='PHAROS';const label=document.createElement('span');label.textContent='PROOF';brand.append(label);}
  const heading=document.getElementById('kc-page-title');if(heading&&document.getElementById('kc-form-login'))heading.hidden=true;
  const username=document.getElementById('username');
  if(username&&(document.getElementById('kc-form-login')||document.getElementById('kc-reset-password-form'))){username.type='email';username.autocomplete='username';username.inputMode='email';username.placeholder='you@example.com';const label=document.querySelector('label[for="username"]');if(label)label.textContent='Email';}
  const submit=document.getElementById('kc-login');if(submit){submit.title='Sign in';submit.setAttribute('aria-label','Sign in');}
  document.addEventListener('submit',update,true);
  document.addEventListener('click',event=>{if(event.target.closest('a[href]'))update();},true);
  // Keep provider action codes out of the visible page URL; native form actions retain their full CSRF context.
  history.replaceState(null,'','/proof_spa/sign-in');
 };
 if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',ready,{once:true});else ready();
})();
