/* SWEKSHA image viewer: full-size photos open in a new tab with a return button. */
(()=>{"use strict";
const isImageURL=(value)=>{try{const u=new URL(value,location.href);return /\\.(?:avif|bmp|gif|jpe?g|png|svg|webp)$/i.test(u.pathname)&&!u.pathname.endsWith("/")}catch(_){return false}};
const viewerURL=(src)=>{const u=new URL("image-viewer.html",location.href);u.searchParams.set("src",src);u.searchParams.set("return",location.href);return u.href};
document.addEventListener("DOMContentLoaded",()=>{
 document.querySelectorAll("a[href]").forEach(a=>{
  if(isImageURL(a.href)){a.href=viewerURL(a.href);a.target="_blank";a.rel="noopener noreferrer"}
 });
 document.querySelectorAll("img").forEach(img=>{
  if(img.closest("a")||!isImageURL(img.currentSrc||img.src))return;
  img.style.cursor="zoom-in";
  img.setAttribute("title","Click to view full image");
  img.addEventListener("click",()=>window.open(viewerURL(img.currentSrc||img.src),"_blank","noopener"));
 });
});
})();

/* SWEKSHA Aura Field — lightweight, accessible pointer interaction */
(()=>{"use strict";
const root=document.documentElement;
const fine=window.matchMedia&&window.matchMedia("(hover:hover) and (pointer:fine)").matches;
const reduced=window.matchMedia&&window.matchMedia("(prefers-reduced-motion: reduce)").matches;
if(!fine||reduced)return;
let raf=0,lastX=innerWidth/2,lastY=innerHeight/3,hue=184,target=null;
const paint=(x,y)=>{root.style.setProperty("--sx-x",x+"px");root.style.setProperty("--sx-y",y+"px");root.style.setProperty("--sx-hue",String(Math.round(hue)))};
addEventListener("pointermove",e=>{lastX=e.clientX;lastY=e.clientY;const nx=e.clientX/Math.max(1,innerWidth),ny=e.clientY/Math.max(1,innerHeight);hue=178+nx*92+ny*28;if(!raf)raf=requestAnimationFrame(()=>{paint(lastX,lastY);raf=0});const next=e.target&&e.target.closest("a,button,[role='button'],.card,.panel,.expertise-card,article,summary");if(next!==target){if(target)target.classList.remove("sx-aura-active");target=next;if(target)target.classList.add("sx-aura-active")}},{passive:true});
addEventListener("pointerleave",()=>{if(target){target.classList.remove("sx-aura-active");target=null}root.style.setProperty("--sx-aura-opacity",".12")});
addEventListener("pointerenter",()=>root.style.setProperty("--sx-aura-opacity",".34"));
paint(lastX,lastY);
})();