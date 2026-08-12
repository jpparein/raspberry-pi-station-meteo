var A='api.php',curFx='';
var bg=document.getElementById('bg');
var part=document.getElementById('part');
var cldW=document.getElementById('cldW');
var rainW=document.getElementById('rainW');
var snowW=document.getElementById('snowW');
var litW=document.getElementById('litW');
var IC={};
IC[0]='sun';IC[1]='sun';IC[2]='part';IC[3]='cloud';
IC[45]='snow';IC[48]='snow';
IC[51]='rain';IC[53]='rain';IC[55]='rain';
IC[61]='rain';IC[63]='rain';IC[65]='rain';
IC[71]='snow';IC[73]='snow';IC[75]='snow';IC[77]='snow';
IC[80]='rain';IC[81]='rain';IC[82]='rain';
IC[85]='snow';IC[86]='snow';
IC[95]='storm';IC[96]='storm';IC[99]='storm';

var SAINTS={};
SAINTS['1']=['','Odilon','Basile','Genevieve, Genevra','Odilon, Odil','Edouard','Melchior','Raymond, Raymonde','Lucien, Lucienne','Alix, Alice','Guillaume, Guilhem','Paulin','Tatiana','Yvette','Nina','Remi','Marcel, Marcelle','Roseline','Prisca','Marius','Sebastien, Sebastienne','Agnes, Ines','Vincent','Barnard','Francois de Sales','Paul, Paula','Paule','Angele','Thomas','Gildas','Martine','Marcelle'];
SAINTS['2']=['','Ella','La Chandeleur','Blaise','Veronique','Agathe, Agate','Gaston','Eugenie','Jacqueline','Apolline','Arnaud','Notre-Dame de Lourdes','Felix, Felicie','Beatrice','Valentin, Valentine','Claude','Julienne','Alexis','Bernadette','Gabin','Aimee, Aime','Damien','Isabelle','Lazare','Modeste','Romeo','Nestor','Honorine','Romain','Auguste'];
SAINTS['3']=['','Aubin','Charles, Charlene','Guenole','Casimir','Olive','Colette, Nicolette','Felicite','Jean de Dieu','Francoise','Vivien','Rosine','Justine','Rodrigue','Mathilde','Louise','Benedicte','Patrice, Patricia','Cyrille','Joseph, Josiane','Herbert','Clemence','Lea','Victorien','Catherine de Suede','Annonciation','Larissa','Habib','Gontran','Gwladys','Amedee','Benjamin'];
SAINTS['4']=['','Hugues','Sandrine, Sandra','Richard','Isidore','Irene','Marcellin','Jean-Baptiste','Julie, Juliette','Gautier','Fulbert','Stanislas','Jules','Ida','Maxime','Paterne','Benoit-Joseph','Anicet','Parfait','Emma','Odette','Anselme','Alexandre','Georges, Georgia','Fidele','Marc','Alida','Zita','Valerie','Catherine','Robert'];
SAINTS['5']=['','Philippe, Philomene','Boris','Philippe','Sylvain, Sylvie','Judith, Judikael','Prudence','Gisele','Armelle','Pacome','Solange','Estelle','Achille','Rolande','Matthias, Matthiasse','Denise','Honore','Pascal, Pascale','Eric','Yves, Yvette','Bernardin','Constantin','Emile, Emilie','Didier','Donatien','Sophie','Beranger','Augustin','Germain','Aymar','Ferdinand','Visitation'];
SAINTS['6']=['','Justin, Justine','Blandine','Kevin','Clotilde','Igor','Norbert','Gilbert','Medard','Diane','Landry','Barnabe','Guy','Antoine de Padoue','Elisee','Germaine','Jean-Francois','Herve','Leonce','Romuald','Silvere','Rodolphe','Alban','Audrey','Jean-Baptiste','Prosper','Anthelme','Fernand','Irenee','Pierre','Martial'];
SAINTS['7']=['','Thierry','Martinien','Thomas, Thomasse','Florent, Florentine','Antoine','Mariette','Raoul','Thibaut','Amandine','Ulrich','Benoit','Olivier','Henri, Henriette','Camille','Donald','Mont-Carmel','Charlotte','Frederic','Arsene','Marina','Victor, Victoria','Marie-Madeleine','Brigitte','Christine','Jacques','Anne, Annick','Nathalie','Samson','Marthe','Juliette','Ignace'];
SAINTS['8']=['','Alphonse','Julien-Eymard','Lydie','Jean-Marie Vianney','Abel','Transfiguration','Gaetan','Dominique','Amour','Laurent, Laurence','Claire, Clara','Clarisse','Hippolyte','Evrard','Assomption','Armel','Hyacinthe','Helene, Lena','Jean-Eudes','Bernard, Bernadette','Christophe, Christelle','Fabrice','Rose, Rosalie','Barthelemy','Louis, Louise','Natacha','Monique','Augustin','Sabine','Fiacre','Aristide'];
SAINTS['9']=['','Gilles','Ingrid','Gregoire','Rosalie','Raissa','Bertrand','Reine','Nativite de Marie','Alain','Ines','Adelphe','Apollinaire','Aime','Sainte-Croix','Roland','Edith','Renaud','Nadege','Emilie','Davy','Matthieu','Maurice','Ecuyer','Thecle','Hermann','Come','Vincent de Paul','Venceslas','Michel, Michelle','Jerome'];
SAINTS['10']=['','Therese, Thea','Leger','Gerard, Geraldine','Francois d\'Assise','Fleur','Bruno','Serge','Pelagie','Denis, Denise','Ghislain','Firmin','Wilfried','Geraud','Juste','Therese d\'Avila','Edwige','Baudouin','Luc, Lucie','Rene, Renee','Adeline, Aline','Celine','Elodie','Jean de Capistran','Florentin','Enguerrand','Dimitri','Emeline','Simon','Narcisse','Bienvenue','Quentin'];
SAINTS['11']=['','Toussaint','Defunts','Hubert','Charles','Sylvie','Bertrand','Carine','Geoffroy','Theodore','Leon, Leonie','Martin, Martine','Christian, Christine','Brice','Sidoine','Albert, Albertine','Marguerite, Margot','Elisabeth, Isabelle','Aude','Tanguy','Edmond, Edmondine','Presentation de Marie','Cecile','Clement','Flora, Floriane','Catherine, Cathy','Delphine','Severin','Jacques','Saturnin','Andre, Andrea'];
SAINTS['12']=['','Florence','Viviane','Francois-Xavier','Barbara','Gerald','Nicolas, Nicole','Ambroise','Immaculee Conception','Pierre Fourier','Romaric','Daniel, Daniele','Corentin','Lucie','Odile','Ninon','Alice','Gael','Gatien','Urbain','Theophile','Pierre Canisius','Xaviere','Armand','Adele','Noel','Etienne, Stephanie','Jean','Innocents','David','Roger','Sylvestre'];

function $(i){return document.getElementById(i)}

function J(u,cb,eb){
  var x=new XMLHttpRequest();
  x.open('GET',A+'?action='+u,true);
  x.onload=function(){try{cb(JSON.parse(x.responseText))}catch(e){if(eb)eb()}};
  x.onerror=function(){if(eb)eb()};
  x.send();
}

function tick(){
  var n=new Date();
  var D=['dimanche','lundi','mardi','mercredi','jeudi','vendredi','samedi'];
  var M=['janvier','fevrier','mars','avril','mai','juin','juillet','aout','septembre','octobre','novembre','decembre'];
  var hh=('0'+n.getHours()).slice(-2);
  var mm=('0'+n.getMinutes()).slice(-2);
  $('tDay').textContent=D[n.getDay()];
  $('tTime').textContent=hh+':'+mm;
  $('tDate').textContent=n.getDate()+' '+M[n.getMonth()]+' '+n.getFullYear();
  var st=SAINTS[String(n.getMonth()+1)][n.getDate()];
  $('tSaint').textContent=st?'Fete : '+st:'';

}

function mkRain(){
  rainW.innerHTML='';
  var i,d;
  for(i=0;i<50;i++){
    d=document.createElement('div');
    d.className='drop';
    d.style.left=Math.random()*100+'%';
    d.style.height=(12+Math.random()*20)+'px';
    d.style.animationDuration=(.35+Math.random()*.35)+'s';
    d.style.animationDelay=Math.random()*2+'s';
    d.style.opacity=.3+Math.random()*.5;
    rainW.appendChild(d);
  }
}

function mkSnow(){
  snowW.innerHTML='';
  var i,s,z;
  for(i=0;i<35;i++){
    s=document.createElement('div');
    s.className='fl';
    s.style.left=Math.random()*100+'%';
    z=3+Math.random()*4;
    s.style.width=z+'px';
    s.style.height=z+'px';
    s.style.animationDuration=(3+Math.random()*4)+'s';
    s.style.animationDelay=Math.random()*3+'s';
    s.style.opacity=.4+Math.random()*.6;
    snowW.appendChild(s);
  }
}

var PAL=[];
PAL[0]=['rgba(255,200,120,.8)','rgba(255,235,150,.8)','rgba(255,160,80,.75)'];
PAL[1]=['rgba(255,230,160,.8)','rgba(255,190,100,.75)','rgba(255,170,120,.7)'];
PAL[2]=['rgba(255,255,220,.8)','rgba(200,255,180,.75)','rgba(255,240,180,.75)'];
PAL[3]=['rgba(220,240,255,.8)','rgba(255,255,255,.8)','rgba(200,225,255,.75)'];
PAL[4]=['rgba(200,230,255,.8)','rgba(255,255,255,.85)','rgba(180,215,255,.75)'];

var PAL_NIGHT=[];
PAL_NIGHT[0]=['rgba(100,150,200,.2)','rgba(150,180,220,.15)','rgba(120,160,210,.18)'];
PAL_NIGHT[1]=['rgba(90,140,190,.18)','rgba(130,170,210,.14)','rgba(110,150,200,.16)'];
PAL_NIGHT[2]=['rgba(80,130,180,.16)','rgba(120,160,200,.13)','rgba(100,140,190,.14)'];
PAL_NIGHT[3]=['rgba(70,120,170,.14)','rgba(110,150,190,.12)','rgba(90,130,180,.13)'];
PAL_NIGHT[4]=['rgba(60,110,160,.12)','rgba(100,140,180,.11)','rgba(80,120,170,.12)'];

var nightMode=false;

function isNight(){
  var h=new Date().getHours();
  return h>=21||h<7;
}

function setNight(on){
  nightMode=on;
  document.body.className=on?'night':'';
  var btn=$('nightBtn');
  if(btn)btn.textContent=on?'☀':'☾';
  upd();
}

function toggleNight(){
  setNight(!nightMode);
}
var sunSched={t:0,on:false},sunTimer=null,lastFc=null;
function parseSun(s){
  var a=s.split('T');
  var d=a[0].split('-');
  var t=a[1].split(':');
  return new Date(+d[0],+d[1]-1,+d[2],+t[0],+t[1],0,0);
}
function fmtHM(x){
  var h=x.getHours(),m=x.getMinutes();
  return (h<10?'0':'')+h+':'+(m<10?'0':'')+m;
}
function captionSun(t){var e=$('nsched');if(e)e.textContent=t;}
function doSwitch(){setNight(sunSched.on);if(lastFc)applySun(lastFc);}
function scheduleSwitch(target,on){
  sunSched.t=target.getTime();sunSched.on=on;
  if(sunTimer)clearTimeout(sunTimer);
  var ms=target.getTime()-new Date().getTime();
  if(ms<0)ms=0;
  sunTimer=setTimeout(doSwitch,ms);
}
function applySun(d){
  lastFc=d;
  if(!d.daily||!d.daily.length)return;
  var t=d.daily[0];
  if(!t.sunrise||!t.sunset)return;
  var sr=parseSun(t.sunrise),ss=parseSun(t.sunset);
  var now=new Date();
  var night=now<sr||now>=ss;
  var nextSr=(d.daily[1]&&d.daily[1].sunrise)?parseSun(d.daily[1].sunrise):sr;
  if(nightMode!==night)setNight(night);
  if(night){
    scheduleSwitch(nextSr,false);
    captionSun('Passage en mode jour au lever du soleil à '+fmtHM(nextSr));
  }else{
    scheduleSwitch(ss,true);
    captionSun('Passage en mode nuit au coucher du soleil à '+fmtHM(ss));
  }
}

function setTmpBg(t){
  var lvl;
  if(t>=28){bg.className='bg-hot';lvl=0}
  else if(t>=24){bg.className='bg-warm';lvl=1}
  else if(t>=20){bg.className='bg-mild';lvl=2}
  else if(t>=15){bg.className='bg-cool';lvl=3}
  else{bg.className='bg-cold';lvl=4}
  if(nightMode)bg.className='night';
  mkParts(t,lvl);
}

function mkParts(t,lvl){
  var n;
  if(t>=28)n=42;
  else if(t>=24)n=34;
  else if(t>=20)n=26;
  else if(t>=15)n=18;
  else if(t>=10)n=12;
  else n=8;
  part.innerHTML='';
  var p,i,j,x,s,dur2,dl;
  var pal=nightMode?PAL_NIGHT[lvl]:PAL[lvl];
  var dur=t>=28?9:(t>=24?11:(t>=20?13:(t>=15?16:20)));
  if(nightMode)dur=dur*2;
  var sz=nightMode?3:4;
  var opMin=nightMode?.15:.55;
  var opMax=nightMode?.35:.95;
  for(i=0;i<n;i++){
    p=document.createElement('div');
    p.className='pt';
    x=Math.random()*100;
    s=(sz+Math.random()*sz).toFixed(1);
    dur2=(dur+Math.random()*6).toFixed(1);
    dl=('-'+(Math.random()*dur2).toFixed(1))+'s';
    p.style.left=x+'%';
    p.style.width=s+'px';
    p.style.height=s+'px';
    p.style.background=pal[i%pal.length];
    p.style.boxShadow='0 0 '+(nightMode?3:6+Math.random()*8).toFixed(0)+'px '+(nightMode?1:2+Math.random()*3).toFixed(0)+'px '+pal[i%pal.length];
    p.style.opacity=(opMin+Math.random()*(opMax-opMin)).toFixed(2);
    p.style.webkitAnimation=(nightMode?'twinkle':'rise')+' linear infinite';
    p.style.animation=(nightMode?'twinkle':'rise')+' linear infinite';
    p.style.webkitAnimationDuration=dur2+'s';
    p.style.animationDuration=dur2+'s';
    p.style.webkitAnimationDelay=dl;
    p.style.animationDelay=dl;
    part.appendChild(p);
  }
}

function setFx(code){
  var fx='sunny';
  if(code<=1)fx='sunny';
  else if(code<=3)fx='cloudy';
  else if(code<=48)fx='cloudy';
  else if(code<=65)fx='rain';
  else if(code<=77)fx='snow';
  else if(code<=82)fx='rain';
  else if(code<=86)fx='snow';
  else fx='storm';
  if(fx===curFx)return;
  curFx=fx;
  cldW.className=(fx==='cloudy'||fx==='rain'||fx==='storm')?'on':'';
  rainW.className=(fx==='rain'||fx==='storm')?'on':'';
  snowW.className=fx==='snow'?'on':'';
  if(fx==='rain'||fx==='storm')mkRain();
  if(fx==='snow')mkSnow();
}

function dewPoint(t,h){
  var b=17.62,c=243.12;
  var g=Math.log(h/100)+((b*t)/(c+t));
  return c*g/(b-g);
}
function humInfo(h,t){
  var cat;
  if(h<25)cat='Air très sec';
  else if(h<40)cat='Air sec';
  else if(h<=60)cat='Humidité modérée';
  else if(h<=75)cat='Air humide';
  else cat='Air très humide';
  var e=$('vH');if(e)e.textContent=h.toFixed(0)+'%';
  var c=$('hCat');if(c)c.textContent=' · '+cat;
  var dw=$('hDew');if(dw)dw.textContent='Point de rosée '+dewPoint(t,h).toFixed(1).replace('.',',')+' °C';
  var lm=$('hLim');if(lm)lm.style.display=(h<=21)?'block':'none';
}
function cpuInfo(){
  J('cpu_temp',function(d){
    var e=$('cpu');
    if(!e)return;
    if(d.error||typeof d.temperature!=='number'){e.textContent='';e.className='cpu';return;}
    var t=d.temperature;
    if(t>=70){e.textContent=' • CPU chaud '+t+'°';e.className='cpu hot';}
    else if(t>=60){e.textContent=' • CPU '+t+'°';e.className='cpu warn';}
    else{e.textContent=' • CPU '+t+'°';e.className='cpu';}
  });
}
function upd(){
  J('current',function(d){
    if(d.error)return;
    $('vT').innerHTML=d.temperature.toFixed(1)+'<span class="u">\u00B0</span>';
    $('vTm').textContent='Mis a jour '+d.last_update.split(' ')[1];
    humInfo(d.humidity,d.temperature);
    setTmpBg(d.temperature);
  });
  J('sensor_status',function(d){
    $('dot').className='dot'+(d.ok?' ok':'');
    $('smsg').textContent=d.ok?'En ligne':'Hors ligne';
  });
}

var fcTry=0;
function fc(){
  if(!$('fcS').children.length){
    $('fcS').innerHTML='<div style="padding:8px;opacity:.5">Chargement des previsions...</div>';
  }
  J('forecast',function(d){
    fcTry=0;
    if(d.error||!d.hourly||!d.hourly.length){
      fcFail();
      return;
    }
    var h='';
    var i;
    for(i=0;i<d.hourly.length;i++){
      var x=d.hourly[i];
      var ico=IC[x.code]||'cloud';
      h+='<div class="fi'+(i===0?' now':'')+'"><div class="fh">'+x.time+'</div><div class="ico ico-'+ico+'"></div><div class="ft2">'+x.temp.toFixed(0)+'\u00B0</div></div>';
    }
    $('fcS').innerHTML=h;
    applySun(d);
    if(d.hourly.length>0)setFx(d.hourly[0].code);
  },fcFail);
}
function fcFail(){
  fcTry++;
  if(fcTry<=3){
    $('fcS').innerHTML='<div style="padding:8px;opacity:.5">Previsions indisponibles - nouvelle tentative...</div>';
    setTimeout(fc,3000*fcTry);
  }else{
    fcTry=0;
    $('fcS').innerHTML='<div style="padding:8px;opacity:.6">Previsions indisponibles <a href="#" onclick="fc();return false" style="color:#fff;text-decoration:underline">Reessayer</a></div>';
  }
}

$('btnL').onclick=function(){
  var b=this;
  b.className='btn ld';
  J('live',function(d){
    b.className='btn';
    if(!d.error){
      $('vT').innerHTML=d.temperature.toFixed(1)+'<span class="u">\u00B0</span>';
      humInfo(d.humidity,d.temperature);
      $('vTm').textContent='Mesure instantanee';
      setTmpBg(d.temperature);
    }
  });
  setTimeout(function(){b.className='btn'},25000);
};

/* === LOCALISATION / PREVISIONS COMMUNE === */
var LOC=null,pendingLoc=null,started=false;
function showLocOverlay(){var o=$('locOverlay');if(o)o.style.display='flex';}
function hideLocOverlay(){var o=$('locOverlay');if(o)o.style.display='none';}
function loadLocation(cb){
  J('location',function(d){
    if(d&&d.configured){LOC=d;cb(true);}else{cb(false);}
  },function(){cb(false);});
}
function updateLocUI(){
  var n=LOC?LOC.name:'';
  var s=$('src'); if(s)s.textContent='Previsions pour '+(n||'…')+' · Open-Meteo.com';
  var b=$('locBtn');
  if(b)b.textContent='Lieu : '+(n||'…');
}
function locSearch(q){
  J('location_search&q='+encodeURIComponent(q),function(d){
    var box=$('locResults'); if(!box)return; box.innerHTML='';
    if(!d||!d.length){box.innerHTML='<div style="opacity:.6;padding:8px">Aucun resultat</div>';return;}
    d.forEach(function(r){
      var b=document.createElement('button');
      b.className='loc-res';
      b.textContent=r.name+(r.admin2?(' — '+r.admin2):'')+(r.admin1?(', '+r.admin1):'');
      b.onclick=function(){
        var all=box.querySelectorAll('.loc-res'); for(var i=0;i<all.length;i++)all[i].className='loc-res';
        b.className='loc-res sel'; pendingLoc=r;
        var c=$('locConfirm'); if(c)c.style.display='';
      };
      box.appendChild(b);
    });
  });
}
function locSave(){
  if(!pendingLoc)return;
  var x=new XMLHttpRequest();
  x.open('POST',A+'?action=location_save',true);
  x.setRequestHeader('Content-Type','application/json');
  x.onload=function(){
    try{var d=JSON.parse(x.responseText);}catch(e){return;}
    if(d.ok){LOC=pendingLoc;hideLocOverlay();updateLocUI();startLive();}
    else{var box=$('locResults');if(box)box.innerHTML='<div style="opacity:.6;padding:8px">'+(d.error||'Echec enregistrement')+'</div>';}
  };
  x.send(JSON.stringify(pendingLoc));
}
function locReset(){
  if(!confirm('Reinitialiser la commune ? Les previsions reafficheront l.ecran de configuration.'))return;
  var x=new XMLHttpRequest();
  x.open('POST',A+'?action=location_reset',true);
  x.onload=function(){
    try{var d=JSON.parse(x.responseText);}catch(e){return;}
    if(d.ok){
      LOC=null; pendingLoc=null;
      var rb=$('locResults'); if(rb)rb.innerHTML='';
      var cf=$('locConfirm'); if(cf)cf.style.display='none';
      var inp=$('locInput'); if(inp)inp.value='';
      showLocOverlay();
    }
  };
  x.send();
}
function startLive(){
  if(started)return; started=true;
  upd(); setInterval(upd,60000);
  fc(); setInterval(fc,900000);
}

tick();
setInterval(tick,10000);
if(isNight())setNight(true);
cpuInfo();
setInterval(cpuInfo,60000);
setInterval(function(){if(sunSched.t&&new Date().getTime()>=sunSched.t){doSwitch();}},60000);
document.addEventListener('visibilitychange',function(){
  if(!document.hidden && LOC){upd();fc();cpuInfo();}
});
$('nightBtn').onclick=toggleNight;
var lbSearch=$('locSearch'); if(lbSearch)lbSearch.onclick=function(){var q=$('locInput').value.trim(); if(q)locSearch(q);};
var lbConfirm=$('locConfirm'); if(lbConfirm)lbConfirm.onclick=locSave;
var locBtn=$('locBtn'); if(locBtn)locBtn.onclick=function(){pendingLoc=null;var rb=$('locResults');if(rb)rb.innerHTML='';var cf=$('locConfirm');if(cf)cf.style.display='none';showLocOverlay();};
var lbReset=$('locReset'); if(lbReset)lbReset.onclick=locReset;
loadLocation(function(ok){
  if(ok){hideLocOverlay();updateLocUI();startLive();}
  else{showLocOverlay();}
});
