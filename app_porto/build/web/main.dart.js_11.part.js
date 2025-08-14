((a,b,c)=>{a[b]=a[b]||{}
a[b][c]=a[b][c]||[]
a[b][c].push({p:"main.dart.js_11",e:"beginPart"})})(self,"$__dart_deferred_initializers__","eventLog")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,B={
aYu(){return new B.B9(null)},
B9:function B9(d){this.a=d},
Hn:function Hn(d){this.d=d
this.c=this.a=null},
ax8:function ax8(d,e,f){this.a=d
this.b=e
this.c=f},
ax6:function ax6(d,e,f){this.a=d
this.b=e
this.c=f},
ax7:function ax7(d){this.a=d},
axh:function axh(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
axg:function axg(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
axa:function axa(d){this.a=d},
axb:function axb(d,e){this.a=d
this.b=e},
ax9:function ax9(d,e){this.a=d
this.b=e},
axc:function axc(d,e){this.a=d
this.b=e},
axd:function axd(d){this.a=d},
axe:function axe(d,e,f){this.a=d
this.b=e
this.c=f},
axf:function axf(d,e,f){this.a=d
this.b=e
this.c=f},
ax5:function ax5(d,e,f){this.a=d
this.b=e
this.c=f},
axj:function axj(d){this.a=d},
axi:function axi(d){this.a=d},
axl:function axl(d,e){this.a=d
this.b=e},
axk:function axk(d,e){this.a=d
this.b=e},
a0f:function a0f(d,e,f,g,h,i,j,k,l,m){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.x=j
_.y=k
_.z=l
_.a=m},
xC:function xC(d,e){this.c=d
this.a=e},
avQ:function avQ(){},
H0:function H0(d,e,f,g,h,i,j){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.a=j},
a_3:function a_3(d){this.a=d},
Ui:function Ui(d,e,f,g,h,i,j){var _=this
_.bC=d
_.dI=$
_.y1=e
_.y2=f
_.cv$=g
_.a7$=h
_.cJ$=i
_.b=_.dy=null
_.c=0
_.y=_.d=null
_.z=!0
_.Q=null
_.as=!1
_.at=null
_.ay=$
_.ch=j
_.CW=!1
_.cx=$
_.cy=!0
_.db=!1
_.dx=$},
ag4(d,e,f){var x,w,v=f.a,u=e.a,t=Math.pow(v[0]-u[0],2)+Math.pow(v[1]-u[1],2)
if(t===0)return e
x=d.a_(0,e)
w=f.a_(0,e)
return e.a0(0,w.kw(A.u(x.oN(w)/t,0,1)))},
aZc(d,e){var x,w,v,u,t,s,r,q=e.a,p=d.a_(0,q),o=e.b,n=o.a_(0,q),m=e.d,l=m.a_(0,q),k=p.oN(n),j=n.oN(n),i=p.oN(l),h=l.oN(l)
if(0<=k&&k<=j&&0<=i&&i<=h)return d
x=e.c
w=[B.ag4(d,q,o),B.ag4(d,o,x),B.ag4(d,x,m),B.ag4(d,m,q)]
v=A.bh("closestOverall")
for(q=d.a,u=1/0,t=0;t<4;++t){s=w[t]
o=s.a
r=Math.sqrt(Math.pow(q[0]-o[0],2)+Math.pow(q[1]-o[1],2))
if(r<u){v.b=s
u=r}}return v.ba()},
b1V(){var x=new A.aR(new Float64Array(16))
x.cZ()
return new B.Wt(x,$.az())},
aR1(d,e,f){return Math.log(f/d)/Math.log(e/100)},
aRw(d,e){var x,w,v,u,t,s,r=new A.aR(new Float64Array(16))
r.bw(d)
r.hb(r)
x=e.a
w=e.b
v=new A.bN(new Float64Array(3))
v.dR(x,w,0)
v=r.ld(v)
u=e.c
t=new A.bN(new Float64Array(3))
t.dR(u,w,0)
t=r.ld(t)
w=e.d
s=new A.bN(new Float64Array(3))
s.dR(u,w,0)
s=r.ld(s)
u=new A.bN(new Float64Array(3))
u.dR(x,w,0)
u=r.ld(u)
x=new A.bN(new Float64Array(3))
x.bw(v)
w=new A.bN(new Float64Array(3))
w.bw(t)
v=new A.bN(new Float64Array(3))
v.bw(s)
t=new A.bN(new Float64Array(3))
t.bw(u)
return new B.TK(x,w,v,t)},
aQX(d,e){var x,w,v,u,t,s,r=[e.a,e.b,e.c,e.d]
for(x=C.f,w=0;w<4;++w){v=r[w]
u=B.aZc(v,d).a
t=v.a
s=u[0]-t[0]
t=u[1]-t[1]
if(Math.abs(s)>Math.abs(x.a))x=new A.i(s,x.b)
if(Math.abs(t)>Math.abs(x.b))x=new A.i(x.a,t)}return B.aJV(x)},
aJV(d){return new A.i(A.ng(C.d.av(d.a,9)),A.ng(C.d.av(d.b,9)))},
b50(d,e){if(d.j(0,e))return null
return Math.abs(e.a-d.a)>Math.abs(e.b-d.b)?C.bP:C.b3},
BO:function BO(d,e,f,g){var _=this
_.w=d
_.at=e
_.ax=f
_.a=g},
HN:function HN(d,e,f,g){var _=this
_.d=$
_.e=d
_.f=e
_.w=_.r=null
_.z=_.y=_.x=$
_.at=_.as=_.Q=null
_.ay=_.ax=0
_.ch=null
_.dq$=f
_.bk$=g
_.c=_.a=null},
az_:function az_(){},
a17:function a17(d,e,f,g,h,i,j){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.a=j},
Wt:function Wt(d,e){var _=this
_.a=d
_.aa$=0
_.a3$=e
_.b9$=_.b4$=0},
Hy:function Hy(d,e){this.a=d
this.b=e},
akZ:function akZ(d,e){this.a=d
this.b=e},
Kv:function Kv(){},
b_u(d){return new B.Tc(d,0,null,null,A.a([],y.F),$.az())},
Tc:function Tc(d,e,f,g,h,i){var _=this
_.as=d
_.a=e
_.c=f
_.d=g
_.f=h
_.aa$=0
_.a3$=i
_.b9$=_.b4$=0},
w1:function w1(d,e,f,g,h,i,j){var _=this
_.r=d
_.a=e
_.b=f
_.c=g
_.d=h
_.e=i
_.f=j},
pq:function pq(d,e,f,g,h,i,j,k,l){var _=this
_.au=d
_.aM=null
_.c4=e
_.k3=0
_.k4=f
_.ok=null
_.r=g
_.w=h
_.x=i
_.y=j
_.Q=_.z=null
_.as=0
_.ax=_.at=null
_.ay=!1
_.ch=!0
_.CW=!1
_.cx=null
_.cy=!1
_.dx=_.db=null
_.dy=k
_.fr=null
_.aa$=0
_.a3$=l
_.b9$=_.b4$=0},
Hu:function Hu(d,e){this.b=d
this.a=e},
D8:function D8(d){this.a=d},
D9:function D9(d,e,f,g){var _=this
_.r=d
_.y=e
_.z=f
_.a=g},
a25:function a25(){var _=this
_.d=0
_.e=$
_.c=_.a=null},
aAd:function aAd(d){this.a=d},
aAe:function aAe(d,e){this.a=d
this.b=e},
VG:function VG(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
a4B:function a4B(d,e,f){this.f=d
this.d=e
this.a=f},
a4C:function a4C(d,e,f){this.e=d
this.c=e
this.a=f},
a3z:function a3z(d,e,f){var _=this
_.C=null
_.dA=d
_.cV=null
_.C$=e
_.b=_.dy=null
_.c=0
_.y=_.d=null
_.z=!0
_.Q=null
_.as=!1
_.at=null
_.ay=$
_.ch=f
_.CW=!1
_.cx=$
_.cy=!0
_.db=!1
_.dx=$},
TK:function TK(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g}},D,H,E,F,G,I,K,L
J=c[1]
A=c[0]
C=c[2]
B=a.updateHolder(c[4],B)
D=c[26]
H=c[21]
E=c[11]
F=c[16]
G=c[12]
I=c[25]
K=c[14]
L=c[9]
B.B9.prototype={
aq(){var x="Campeonato Internacional",w=y.s,v=y.N,u=y.z
return new B.Hn(A.a([A.ak(["title","Brisas Cup 360","subtitle",x,"location","Panam\xe1","year",2025,"cover","assets/img/webp/main.webp","description","Experiencia internacional de alto nivel con clubes invitados de la regi\xf3n. Desarrollo competitivo y vitrina para talento joven.","images",A.a(["assets/img/eventos/panama2025/2025_1_thumb.webp","assets/img/eventos/panama2025/2025_2_thumb.webp","assets/img/eventos/panama2025/2025_3_thumb.webp","assets/img/eventos/panama2025/2025_4_thumb.webp","assets/img/eventos/panama2025/2025_5_thumb.webp","assets/img/eventos/panama2025/2025_6_thumb.webp","assets/img/eventos/panama2025/2025_7_thumb.webp"],w)],v,u),A.ak(["title","Caribe Champions","subtitle",x,"location","Barranquilla","year",2024,"cover","assets/img/eventosWebp/2024_1.webp","description","Torneo de referencia en el Caribe colombiano. Intensidad, disciplina y juego colectivo enfrentando a escuelas top del litoral.","images",A.a(["assets/img/eventos/barranquilla2024/2024_1_thumb.webp","assets/img/eventos/barranquilla2024/2024_2_thumb.webp","assets/img/eventos/barranquilla2024/2024_3_thumb.webp"],w)],v,u),A.ak(["title","Sporturs Soccer Cup","subtitle",x,"location","Medell\xedn","year",2023,"cover","assets/img/eventosWebp/2023_3.webp","description","Competencia con metodolog\xeda formativa y enfoque en el fair play. Gran oportunidad para medici\xf3n de rendimiento y convivencia.","images",A.a(["assets/img/eventos/medellin2023/2023_1_thumb.webp","assets/img/eventos/medellin2023/2023_2_thumb.webp","assets/img/eventos/medellin2023/2023_3_thumb.webp"],w)],v,u)],y.t))}}
B.Hn.prototype={
agG(d){var x,w=d.h(0,"images")
if(w==null)w=[]
x=A.iM(w,!0,y.N)
w=this.c
w.toString
E.z4(null,!0,new B.ax8(this,d,x),w,y.z)},
agH(d,e){var x,w={},v=B.b_u(e)
w.a=e
x=this.c
x.toString
E.z4(A.aP(217,C.p.F()>>>16&255,C.p.F()>>>8&255,C.p.F()&255),!0,new B.axh(w,this,v,d),x,y.z)},
NE(d,e,f,g){return A.hl(d,new B.ax5(d,g,f),e,f,g)},
a6S(d,e){return this.NE(d,e,null,null)},
ajH(){var x=this.c
x.toString
E.z4(null,!0,new B.axj(this),x,y.z)},
J(d){var x=null,w=A.bo(d,x,y.w).w,v=L.aMA(D.a0d,D.akP,this.gajG())
return A.Eb(K.iZ,new G.Cc(new A.ER(new B.axl(this,w.a.a>=1000),4,!0,!0,!0,x),C.aN,C.b3,!1,x,x,C.j7,!1,x,4,C.am,x,x,C.U,C.aD,x),v)}}
B.a0f.prototype={
J(d){var x,w,v=this,u=null,t=y.p
if(v.y){x=A.a([],t)
w=v.z
if(!w)x.push(A.cj(new B.xC(v.r,u),5))
x.push(A.du(u,u,24))
x.push(A.cj(new B.H0(v.c,v.d,v.e,v.f,v.w,v.x,u),5))
if(w)C.b.H(x,A.a([C.pC,A.cj(new B.xC(v.r,u),5)],t))
t=A.cz(x,C.F,C.u,C.I)}else t=A.cb(A.a([new B.xC(v.r,u),C.bj,new B.H0(v.c,v.d,v.e,v.f,v.w,v.x,u)],t),C.bR,C.u,C.I)
return A.cF(u,A.da(new A.co(C.ca,new A.bv(F.jN,t,u),u),u,u),C.t,C.wR,u,u,u,u,u,u,u,u,u)}}
B.xC.prototype={
J(d){var x=null
return new A.hb(1.7777777777777777,A.hN(A.d2(16),A.hA(C.cz,A.a([A.hl(this.c,new B.avQ(),C.ch,x,x),A.aII(0,A.qg(x,new A.cN(x,x,x,x,x,new A.o1(C.fn,C.hD,C.dc,A.a([A.aP(64,C.p.F()>>>16&255,C.p.F()>>>8&255,C.p.F()&255),C.M],y.O),x,x),C.ay),C.dR))],y.p),C.U,C.uH,x),C.aU),x)}}
B.H0.prototype={
J(d){var x,w=this,v=null,u=A.L(d).ok,t=A.d2(16),s=u.f
s=s==null?v:s.hz(C.bm)
x=y.p
return A.zQ(new A.bv(I.i0,A.cb(A.a([A.aX(w.c,v,v,v,s,v,v),F.f9,A.aX(w.d,v,v,v,u.w,v,v),C.b8,A.cz(A.a([D.a03,I.hr,A.aX(w.e+" "+w.f,v,v,v,u.z,v,v)],x),C.F,C.u,C.I),K.aW,A.aX(w.r,v,v,v,u.y,v,v),C.bj,new A.e1(C.ey,v,v,A.rk(D.a06,D.akS,w.w),v)],x),C.bR,C.u,C.I),v),0.8,new A.ct(t,C.y))}}
B.a_3.prototype={
J(d){var x=null,w=A.L(d).ax,v=w.d
return A.cF(x,A.da(new A.co(C.ca,A.cF(x,D.akC,C.t,x,x,new A.cN((v==null?w.b:v).bs(0.35),x,x,A.d2(12),x,x,C.ay),x,x,x,C.fw,x,x,x),x),x,x),C.t,C.o,x,x,x,x,x,C.r5,x,x,x)}}
B.Ui.prototype={
gwf(){return y.S.a(A.n.prototype.gX.call(this)).y*this.bC},
sxa(d){if(this.bC===d)return
this.bC=d
this.a2()}}
B.BO.prototype={
aq(){var x=null,w=y.A
return new B.HN(new A.bj(x,w),new A.bj(x,w),x,x)}}
B.HN.prototype={
gcj(){var x=this.d
if(x===$){this.a.toString
x=B.b1V()
this.d=x}return x},
gxX(){var x,w=$.ad.aG$.x.h(0,this.e).ga1()
w.toString
x=y.x.a(w).gp()
this.a.toString
return C.aN.w7(new A.v(0,0,0+x.a,0+x.b))},
gzD(){var x=$.ad.aG$.x.h(0,this.f).ga1()
x.toString
x=y.x.a(x).gp()
return new A.v(0,0,0+x.a,0+x.b)},
qq(a0,a1){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this
if(a1.j(0,C.f)){x=new A.aR(new Float64Array(16))
x.bw(a0)
return x}if(d.Q!=null){d.a.toString
switch(3){case 3:break}}w=new A.aR(new Float64Array(16))
w.bw(a0)
w.cu(a1.a,a1.b)
v=B.aRw(w,d.gzD())
if(d.gxX().gYi(0))return w
x=d.gxX()
u=d.ay
t=new A.aR(new Float64Array(16))
t.cZ()
s=x.c
r=x.a
q=s-r
p=x.d
x=x.b
o=p-x
t.cu(q/2,o/2)
t.nC(u)
t.cu(-q/2,-o/2)
u=new A.bN(new Float64Array(3))
u.dR(r,x,0)
u=t.ld(u)
q=new A.bN(new Float64Array(3))
q.dR(s,x,0)
q=t.ld(q)
x=new A.bN(new Float64Array(3))
x.dR(s,p,0)
x=t.ld(x)
s=new A.bN(new Float64Array(3))
s.dR(r,p,0)
s=t.ld(s)
r=new Float64Array(3)
new A.bN(r).bw(u)
u=new Float64Array(3)
new A.bN(u).bw(q)
q=new Float64Array(3)
new A.bN(q).bw(x)
x=new Float64Array(3)
new A.bN(x).bw(s)
s=r[0]
p=u[0]
o=q[0]
n=x[0]
m=Math.min(s,Math.min(p,Math.min(o,n)))
r=r[1]
u=u[1]
q=q[1]
x=x[1]
l=Math.min(r,Math.min(u,Math.min(q,x)))
k=Math.max(s,Math.max(p,Math.max(o,n)))
j=Math.max(r,Math.max(u,Math.max(q,x)))
x=new A.bN(new Float64Array(3))
x.dR(m,l,0)
u=new A.bN(new Float64Array(3))
u.dR(k,l,0)
s=new A.bN(new Float64Array(3))
s.dR(k,j,0)
r=new A.bN(new Float64Array(3))
r.dR(m,j,0)
q=new A.bN(new Float64Array(3))
q.bw(x)
x=new A.bN(new Float64Array(3))
x.bw(u)
u=new A.bN(new Float64Array(3))
u.bw(s)
s=new A.bN(new Float64Array(3))
s.bw(r)
i=new B.TK(q,x,u,s)
h=B.aQX(i,v)
if(h.j(0,C.f))return w
x=w.CS().a
u=x[0]
x=x[1]
g=a0.pA()
u-=h.a*g
x-=h.b*g
f=new A.aR(new Float64Array(16))
f.bw(a0)
s=new A.bN(new Float64Array(3))
s.dR(u,x,0)
f.LZ(s)
e=B.aQX(i,B.aRw(f,d.gzD()))
if(e.j(0,C.f))return f
s=e.a===0
if(!s&&e.b!==0){x=new A.aR(new Float64Array(16))
x.bw(a0)
return x}u=s?u:0
x=e.b===0?x:0
s=new A.aR(new Float64Array(16))
s.bw(a0)
r=new A.bN(new Float64Array(3))
r.dR(u,x,0)
s.LZ(r)
return s},
Fw(d,e){var x,w,v,u,t,s,r,q=this
if(e===1){x=new A.aR(new Float64Array(16))
x.bw(d)
return x}w=q.gcj().a.pA()
x=q.gzD()
v=q.gxX()
u=q.gzD()
t=q.gxX()
s=Math.max(w*e,Math.max((x.c-x.a)/(v.c-v.a),(u.d-u.b)/(t.d-t.b)))
t=q.a
r=A.u(s,t.ax,t.at)
x=new A.aR(new Float64Array(16))
x.bw(d)
x.bB(r/w)
return x},
af6(d,e,f){var x,w,v,u
if(e===0){x=new A.aR(new Float64Array(16))
x.bw(d)
return x}w=this.gcj().ij(f)
x=new A.aR(new Float64Array(16))
x.bw(d)
v=w.a
u=w.b
x.cu(v,u)
x.nC(-e)
x.cu(-v,-u)
return x},
yg(d){var x
$label0$0:{x=!0
if(D.apz===d){x=!1
break $label0$0}if(D.q0===d){this.a.toString
break $label0$0}if(D.j1===d||d==null){this.a.toString
break $label0$0}x=null}return x},
PB(d){this.a.toString
if(Math.abs(d.d-1)>Math.abs(0))return D.q0
else return D.j1},
ag8(d){var x,w,v=this
v.a.toString
x=v.y
x===$&&A.b()
w=x.r
if(w!=null&&w.a!=null){x.eO()
x=v.y
x.sn(x.a)
x=v.r
if(x!=null)x.a.L(v.gyq())
v.r=null}x=v.z
x===$&&A.b()
w=x.r
if(w!=null&&w.a!=null){x.eO()
x=v.z
x.sn(x.a)
x=v.w
if(x!=null)x.a.L(v.gyu())
v.w=null}v.Q=v.ch=null
v.at=v.gcj().a.pA()
v.as=v.gcj().ij(d.b)
v.ax=v.ay},
aga(d){var x,w,v,u,t,s,r=this,q=r.gcj().a.pA(),p=r.x=d.c,o=r.gcj().ij(p),n=r.ch
if(n===D.j1)n=r.ch=r.PB(d)
else if(n==null){n=r.PB(d)
r.ch=n}if(!r.yg(n)){r.a.toString
return}switch(r.ch.a){case 1:n=r.at
n.toString
r.gcj().sn(r.Fw(r.gcj().a,n*d.d/q))
x=r.gcj().ij(p)
n=r.gcj()
w=r.gcj().a
v=r.as
v.toString
n.sn(r.qq(w,x.a_(0,v)))
u=r.gcj().ij(p)
p=r.as
p.toString
if(!B.aJV(p).j(0,B.aJV(u)))r.as=u
break
case 2:n=d.r
if(n===0){r.a.toString
return}w=r.ax
w.toString
t=w+n
r.gcj().sn(r.af6(r.gcj().a,r.ay-t,p))
r.ay=t
break
case 0:if(d.d!==1){r.a.toString
return}if(r.Q==null){n=r.as
n.toString
r.Q=B.b50(n,o)}n=r.as
n.toString
s=o.a_(0,n)
r.gcj().sn(r.qq(r.gcj().a,s))
r.as=r.gcj().ij(p)
break}r.a.toString},
ag6(d){var x,w,v,u,t,s,r,q,p,o,n,m,l=this
l.a.toString
l.as=l.ax=l.at=null
x=l.r
if(x!=null)x.a.L(l.gyq())
x=l.w
if(x!=null)x.a.L(l.gyu())
x=l.y
x===$&&A.b()
x.sn(x.a)
x=l.z
x===$&&A.b()
x.sn(x.a)
if(!l.yg(l.ch)){l.Q=null
return}$label0$0:{w=l.ch
if(D.j1===w){x=d.a.a
if(x.gcU()<50){l.Q=null
return}v=l.gcj().a.CS().a
u=v[0]
v=v[1]
l.a.toString
t=A.aem(0.0000135,u,x.a,0)
l.a.toString
s=A.aem(0.0000135,v,x.b,0)
x=x.gcU()
l.a.toString
r=B.aR1(x,0.0000135,10)
x=t.grB()
q=s.grB()
p=y.L
o=A.ch(C.dO,l.y,null)
l.r=new A.aV(o,new A.aD(new A.i(u,v),new A.i(x,q),p),p.i("aV<aF.T>"))
l.y.e=A.dA(0,C.d.b2(r*1000))
o.a4(l.gyq())
l.y.cw()
break $label0$0}if(D.q0===w){x=d.b
v=Math.abs(x)
if(v<0.1){l.Q=null
return}n=l.gcj().a.pA()
l.a.toString
m=A.aem(0.0026999999999999997,n,x/10,0)
l.a.toString
r=B.aR1(v,0.0000135,0.1)
x=m.eM(r)
v=y.Y
u=A.ch(C.dO,l.z,null)
l.w=new A.aV(u,new A.aD(n,x,v),v.i("aV<aF.T>"))
l.z.e=A.dA(0,C.d.b2(r*1000))
u.a4(l.gyu())
l.z.cw()
break $label0$0}break $label0$0}},
aez(d){var x,w,v,u,t,s,r,q=this,p=d.gdj(),o=d.gb1()
if(y.C.b(d)){x=d.gcF()===C.bA
if(x)q.a.toString
if(x){q.a.toString
x=o.a0(0,d.gll())
w=d.gll()
v=A.rr(d.gcg(),null,w,x)
if(!q.yg(D.j1)){q.a.toString
return}u=q.gcj().ij(p)
t=q.gcj().ij(p.a_(0,v))
q.gcj().sn(q.qq(q.gcj().a,t.a_(0,u)))
q.a.toString
return}if(d.gll().b===0)return
x=d.gll()
q.a.toString
s=Math.exp(-x.b/200)}else if(y.X.b(d))s=d.ghq()
else return
q.a.toString
if(!q.yg(D.q0)){q.a.toString
return}u=q.gcj().ij(p)
q.gcj().sn(q.Fw(q.gcj().a,s))
r=q.gcj().ij(p)
q.gcj().sn(q.qq(q.gcj().a,r.a_(0,u)))
q.a.toString},
ac6(){var x,w,v,u,t,s=this,r=s.y
r===$&&A.b()
r=r.r
if(!(r!=null&&r.a!=null)){s.Q=null
r=s.r
if(r!=null)r.a.L(s.gyq())
s.r=null
r=s.y
r.sn(r.a)
return}r=s.gcj().a.CS().a
x=r[0]
r=r[1]
w=s.gcj()
v=s.gcj().a
u=s.gcj()
t=s.r
w.sn(s.qq(v,u.ij(t.b.an(t.a.gn())).a_(0,s.gcj().ij(new A.i(x,r)))))},
ad0(){var x,w,v,u,t,s=this,r=s.z
r===$&&A.b()
r=r.r
if(!(r!=null&&r.a!=null)){s.Q=null
r=s.w
if(r!=null)r.a.L(s.gyu())
s.w=null
r=s.z
r.sn(r.a)
return}r=s.w
x=r.b.an(r.a.gn())
r=s.gcj().a.pA()
w=s.gcj()
v=s.x
v===$&&A.b()
u=w.ij(v)
s.gcj().sn(s.Fw(s.gcj().a,x/r))
t=s.gcj().ij(s.x)
s.gcj().sn(s.qq(s.gcj().a,t.a_(0,u)))},
ae2(){this.ao(new B.az_())},
aO(){var x=this,w=null
x.bb()
x.y=A.c0(w,w,w,w,x)
x.z=A.c0(w,w,w,w,x)
x.gcj().a4(x.gQw())},
aZ(d){this.bi(d)
this.a.toString
return},
l(){var x=this,w=x.y
w===$&&A.b()
w.l()
w=x.z
w===$&&A.b()
w.l()
x.gcj().L(x.gQw())
x.a.toString
w=x.gcj()
w.a3$=$.az()
w.aa$=0
x.a5n()},
J(d){var x,w,v,u=this,t=null
u.a.toString
x=u.gcj().a
w=u.a.w
v=new B.a17(w,u.e,C.U,!0,x,t,t)
return A.vI(C.cD,A.kG(C.aD,v,C.am,!1,t,t,t,t,t,t,t,t,t,u.gag5(),u.gag7(),u.gag9(),t,t,t,t,t,t,t,t,t,t,t,!1,new A.i(0,-0.005)),u.f,t,t,t,u.gaey(),t)}}
B.a17.prototype={
J(d){var x=this,w=A.FR(x.w,new A.jD(x.c,x.d),null,x.r,!0)
return A.A8(w,x.e,null)}}
B.Wt.prototype={
ij(d){var x=this.a,w=new A.aR(new Float64Array(16))
if(w.hb(x)===0)A.an(A.fy(x,"other","Matrix cannot be inverted"))
x=new A.bN(new Float64Array(3))
x.dR(d.a,d.b,0)
x=w.ld(x).a
return new A.i(x[0],x[1])}}
B.Hy.prototype={
I(){return"_GestureType."+this.b}}
B.akZ.prototype={
I(){return"PanAxis."+this.b}}
B.Kv.prototype={
cd(){this.d7()
this.d0()
this.eC()},
l(){var x=this,w=x.bk$
if(w!=null)w.L(x.gel())
x.bk$=null
x.aY()}}
B.Tc.prototype={
V4(d,e,f){var x=y.g.a(C.b.ghr(this.f))
if(x.aM!=null){x.aM=d
return A.cn(null,y.H)}if(x.ax==null){x.au=d
return A.cn(null,y.H)}return x.iz(x.tk(d),e,f)},
I0(d,e,f){var x=null,w=$.az()
w=new B.pq(this.as,1,C.hq,d,e,!0,x,new A.bZ(!1,w),w)
w.DF(e,x,!0,f,d)
w.DG(e,x,x,!0,f,d)
return w},
aA(d){this.a3u(d)
y.g.a(d).sxa(1)}}
B.w1.prototype={}
B.pq.prototype={
vI(d,e,f,g,h,i){return this.a3G(d,e,f,g,h,null)},
sxa(d){var x,w=this
if(w.c4===d)return
x=w.gBQ()
w.c4=d
if(x!=null)w.IQ(w.tk(x))},
gyB(){var x=this.ax
x.toString
return Math.max(0,x*(this.c4-1)/2)},
xf(d,e){var x=Math.max(0,d-this.gyB())/(e*this.c4),w=C.d.ZQ(x)
if(Math.abs(x-w)<1e-10)return w
return x},
tk(d){var x=this.ax
x.toString
return d*x*this.c4+this.gyB()},
gBQ(){var x,w,v=this,u=v.at
if(u==null)return null
x=v.z
if(x!=null&&v.Q!=null||v.ay){w=v.aM
if(w==null){x.toString
w=v.Q
w.toString
w=A.u(u,x,w)
x=v.ax
x.toString
x=v.xf(w,x)
u=x}else u=w}else u=null
return u},
LD(){var x,w,v=this,u=v.w,t=u.c
t.toString
t=A.akT(t)
if(t!=null){u=u.c
u.toString
x=v.aM
if(x==null){x=v.at
x.toString
w=v.ax
w.toString
w=v.xf(x,w)
x=w}t.a_K(u,x)}},
ZL(){var x,w,v
if(this.at==null){x=this.w
w=x.c
w.toString
w=A.akT(w)
if(w==null)v=null
else{x=x.c
x.toString
v=w.Zl(x)}if(v!=null)this.au=v}},
LC(){var x,w=this,v=w.aM
if(v==null){v=w.at
v.toString
x=w.ax
x.toString
x=w.xf(v,x)
v=x}w.w.r.sn(v)
v=$.dZ.fN$
v===$&&A.b()
v.Xb()},
ZK(d,e){if(e)this.au=d
else this.eI(this.tk(d))},
mX(d){var x,w,v,u,t=this,s=t.ax
s=s!=null?s:null
if(d===s)return!0
t.a3C(d)
x=t.at
x=x!=null?x:null
if(x==null)w=t.au
else if(s===0){v=t.aM
v.toString
w=v}else{s.toString
w=t.xf(x,s)}u=t.tk(w)
t.aM=d===0?w:null
if(u!==x){t.at=u
return!1}return!0},
lE(d){var x
this.N1(d)
if(!(d instanceof B.pq))return
x=d.aM
if(x!=null)this.aM=x},
mW(d,e){var x=d+this.gyB()
return this.a3A(x,Math.max(x,e-this.gyB()))},
jY(){var x,w,v,u,t,s,r=this,q=null,p=r.z
p=p!=null&&r.Q!=null?p:q
x=q
if(r.z!=null&&r.Q!=null){x=r.Q
x.toString}w=r.at
w=w!=null?w:q
v=r.ax
v=v!=null?v:q
u=r.w
t=u.a.c
s=r.c4
u=u.f
u===$&&A.b()
return new B.w1(s,p,x,w,v,t,u)},
$iw1:1}
B.Hu.prototype={
kL(d){return new B.Hu(!1,this.kN(d))},
glF(){return this.b}}
B.D8.prototype={
kL(d){return new B.D8(this.kN(d))},
aaN(d){var x,w
if(d instanceof B.pq){x=d.gBQ()
x.toString
return x}x=d.at
x.toString
w=d.ax
w.toString
return x/w},
aaQ(d,e){var x
if(d instanceof B.pq)return d.tk(e)
x=d.ax
x.toString
return e*x},
rb(d,e){var x,w,v,u,t,s=this
if(e<=0){x=d.at
x.toString
w=d.z
w.toString
w=x<=w
x=w}else x=!1
if(!x)if(e>=0){x=d.at
x.toString
w=d.Q
w.toString
w=x>=w
x=w}else x=!1
else x=!0
if(x)return s.a3y(d,e)
v=s.nF(d)
u=s.aaN(d)
x=v.c
if(e<-x)u-=0.5
else if(e>x)u+=0.5
t=s.aaQ(d,C.d.ZQ(u))
x=d.at
x.toString
if(t!==x){x=s.gpN()
w=d.at
w.toString
return new A.oE(t,A.yA(x,w-t,e),v)}return null},
glF(){return!1}}
B.D9.prototype={
aq(){return new B.a25()}}
B.a25.prototype={
aO(){var x,w=this
w.bb()
w.QJ()
x=w.e
x===$&&A.b()
w.d=x.as},
l(){this.a.toString
this.aY()},
QJ(){var x=this.a.r
this.e=x},
aZ(d){if(d.r!==this.a.r)this.QJ()
this.bi(d)},
aaw(d){var x
this.a.toString
switch(0){case 0:x=A.aGY(d.ar(y.I).w)
this.a.toString
return x}},
J(d){var x,w,v,u=this,t=null,s=u.aaw(d)
u.a.toString
x=new B.D8(D.abo.kN(t))
x=new B.Hu(!1,t).kN(x)
u.a.toString
w=u.e
w===$&&A.b()
v=A.l_(d).W4(!1)
return new A.d6(new B.aAd(u),A.aoa(s,C.U,w,C.am,!1,C.aD,t,new B.Hu(!1,x),t,v,t,new B.aAe(u,s)),t,y.R)}}
B.VG.prototype={
J(d){var x=this.c,w=A.u(1-x,0,1)
return new B.a4C(w/2,new B.a4B(x,this.e,null),null)}}
B.a4B.prototype={
aQ(d){var x=new B.Ui(this.f,y.d.a(d),A.t(y.q,y.x),0,null,null,A.a7())
x.aP()
return x},
aS(d,e){e.sxa(this.f)}}
B.a4C.prototype={
aQ(d){var x=new B.a3z(this.e,null,A.a7())
x.aP()
return x},
aS(d,e){e.sxa(this.e)}}
B.a3z.prototype={
sxa(d){var x=this
if(x.dA===d)return
x.dA=d
x.cV=null
x.a2()},
ghH(){return this.cV},
ajQ(){var x,w,v=this
if(v.cV!=null&&J.d(v.C,y.S.a(A.n.prototype.gX.call(v))))return
x=y.S
w=x.a(A.n.prototype.gX.call(v)).y*v.dA
v.C=x.a(A.n.prototype.gX.call(v))
switch(A.b8(x.a(A.n.prototype.gX.call(v)).a).a){case 0:x=new A.aA(w,0,w,0)
break
case 1:x=new A.aA(0,w,0,w)
break
default:x=null}v.cV=x
return},
bJ(){this.ajQ()
this.MZ()}}
B.TK.prototype={}
var z=a.updateTypes(["~()","kk(R)","~(Eg)","~(Eh)","~(wz)","~(f2)"])
B.ax8.prototype={
$1(d){var x,w,v,u,t,s=this,r=null,q=A.aX("Galer\xeda \u2014 "+A.k(s.b.h(0,"title")),r,r,r,r,r,r),p=s.c
if(p.length===0)p=D.abn
else{x=A.a([],y.p)
for(w=s.a,v=0;v<p.length;++v){u=p[v]
t=new A.b2(8,8)
x.push(A.kG(r,new G.m2(u,new A.q3(new A.cm(t,t,t,t),C.aU,w.NE(u,C.ch,120,160),r),!1,r),C.am,!1,r,r,r,r,r,r,r,r,r,r,r,r,r,r,r,r,new B.ax6(w,p,v),r,r,r,r,r,r,!1,C.cJ))}p=A.Vv(A.p4(C.cw,x,12,12),r,r)}p=A.du(p,r,560)
return E.zh(A.a([A.jX(F.pM,new B.ax7(s.a),r)],y.p),p,q)},
$S:z+1}
B.ax6.prototype={
$0(){var x=this.a,w=x.c
w.toString
A.cy(w,!1).ee(null)
x.agH(this.b,this.c)},
$S:0}
B.ax7.prototype={
$0(){var x=this.a.c
x.toString
A.cy(x,!1).ee(null)
return null},
$S:0}
B.axh.prototype={
$1(d){var x=this
return new A.t5(new B.axg(x.a,x.b,x.c,x.d),null)},
$S:550}
B.axg.prototype={
$2(d,e){var x=this,w=null,v=x.c,u=x.a,t=x.d,s=A.a([A.kG(C.aD,w,C.am,!1,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w,new B.axa(d),w,w,w,w,w,w,!1,C.cJ),new B.D9(v,new B.axb(u,e),new A.ER(new B.axc(x.b,t),t.length,!0,!0,!0,w),w),A.mt(w,A.m4(w,w,D.a_T,w,w,new B.axd(d),w,A.m6(w,C.cS,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w),"Cerrar"),w,w,w,20,20,w)],y.p)
if(t.length>1)s.push(A.mt(w,A.m4(w,w,D.a0a,w,w,new B.axe(u,t,v),w,A.m6(w,C.cS,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w),w),w,w,12,w,w,w))
if(t.length>1)s.push(A.mt(w,A.m4(w,w,D.a0c,w,w,new B.axf(u,t,v),w,A.m6(w,C.cS,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w),w),w,w,w,12,w,w))
v=t.length
if(v>1){t=A.d2(12)
s.push(A.mt(20,A.cF(w,A.aX(""+(u.a+1)+" / "+v,w,w,w,D.ahC,w,w),C.t,w,w,new A.cN(C.cS,w,w,t,w,w,C.ay),w,w,w,D.Zg,w,w,w),w,w,w,w,w,w))}return A.hA(C.Z,s,C.U,C.cs,w)},
$S:551}
B.axa.prototype={
$0(){A.cy(this.a,!1).ee(null)
return null},
$S:0}
B.axb.prototype={
$1(d){return this.b.$1(new B.ax9(this.a,d))},
$S:15}
B.ax9.prototype={
$0(){return this.a.a=this.b},
$S:0}
B.axc.prototype={
$2(d,e){var x=this.b[e]
return A.da(G.aIe(new B.BO(this.a.a6S(x,C.je),5,1,null),x,!1),null,null)},
$S:552}
B.axd.prototype={
$0(){A.cy(this.a,!1).ee(null)
return null},
$S:0}
B.axe.prototype={
$0(){this.c.V4(C.h.eT(this.a.a-1,0,this.b.length-1),F.ft,C.ac)},
$S:0}
B.axf.prototype={
$0(){this.c.V4(C.h.eT(this.a.a+1,0,this.b.length-1),F.ft,C.ac)},
$S:0}
B.ax5.prototype={
$3(d,e,f){var x=null
A.aGJ().$1("NO se encontr\xf3 asset: "+this.a)
return A.cF(C.Z,D.a_U,C.t,C.aA,x,x,x,this.c,x,x,x,x,this.b)},
$S:23}
B.axj.prototype={
$1(d){return E.zh(A.a([A.jX(H.QP,new B.axi(this.a),null)],y.p),D.aeY,D.alb)},
$S:z+1}
B.axi.prototype={
$0(){var x=this.a.c
x.toString
A.cy(x,!1).ee(null)
return null},
$S:0}
B.axl.prototype={
$2(d,e){var x,w
if(e===3)return new B.a_3(null)
x=this.a
w=x.d[e]
return new B.a0f(w.h(0,"title"),w.h(0,"subtitle"),w.h(0,"location"),w.h(0,"year"),w.h(0,"cover"),w.h(0,"description"),new B.axk(x,w),this.b,(e&1)===1,null)},
$S:553}
B.axk.prototype={
$0(){return this.a.agG(this.b)},
$S:0}
B.avQ.prototype={
$3(d,e,f){var x=null
return A.cF(C.Z,C.rP,C.t,C.aA,x,x,x,x,x,x,x,x,x)},
$S:23}
B.az_.prototype={
$0(){},
$S:0}
B.aAd.prototype={
$1(d){var x,w,v,u,t
if(d.bC$===0){this.a.a.toString
x=d instanceof A.iY}else x=!1
if(x){w=y.o.a(d.a)
x=w.c
x.toString
v=w.a
v.toString
u=w.b
u.toString
u=Math.max(0,A.u(x,v,u))
v=w.d
v.toString
t=C.d.b2(u/Math.max(1,v*w.r))
x=this.a
if(t!==x.d){x.d=t
x.a.y.$1(t)}}return!1},
$S:43}
B.aAe.prototype={
$2(d,e){var x=this.a,w=x.a
w.toString
x.e===$&&A.b()
return A.aPt(0,this.b,0,C.UD,null,C.U,e,A.a([new B.VG(1,!0,w.z,null)],y.p))},
$S:554};(function aliases(){var x=B.Kv.prototype
x.a5n=x.l})();(function installTearOffs(){var x=a._instance_0u,w=a._instance_1u
x(B.Hn.prototype,"gajG","ajH",0)
var v
w(v=B.HN.prototype,"gag7","ag8",2)
w(v,"gag9","aga",3)
w(v,"gag5","ag6",4)
w(v,"gaey","aez",5)
x(v,"gyq","ac6",0)
x(v,"gyu","ad0",0)
x(v,"gQw","ae2",0)})();(function inheritance(){var x=a.mixinHard,w=a.inheritMany,v=a.inherit
w(A.X,[B.B9,B.BO,B.D9])
w(A.a1,[B.Hn,B.Kv,B.a25])
w(A.fB,[B.ax8,B.axh,B.axb,B.ax5,B.axj,B.avQ,B.aAd])
w(A.iy,[B.ax6,B.ax7,B.axa,B.ax9,B.axd,B.axe,B.axf,B.axi,B.axk,B.az_])
w(A.jq,[B.axg,B.axc,B.axl,B.aAe])
w(A.ab,[B.a0f,B.xC,B.H0,B.a_3,B.a17,B.VG])
v(B.Ui,G.Uj)
v(B.HN,B.Kv)
v(B.Wt,A.bZ)
w(A.pf,[B.Hy,B.akZ])
v(B.Tc,A.hx)
v(B.w1,A.Pq)
v(B.pq,A.oD)
w(A.oC,[B.Hu,B.D8])
v(B.a4B,A.jT)
v(B.a4C,A.aM)
v(B.a3z,A.wo)
v(B.TK,A.F)
x(B.Kv,A.dG)})()
A.lt(b.typeUniverse,JSON.parse('{"B9":{"X":[],"e":[]},"Hn":{"a1":["B9"]},"a0f":{"ab":[],"e":[]},"xC":{"ab":[],"e":[]},"H0":{"ab":[],"e":[]},"a_3":{"ab":[],"e":[]},"Ui":{"kY":[],"cK":[],"a9":["p","eR"],"n":[],"af":[],"a9.1":"eR","a9.0":"p"},"BO":{"X":[],"e":[]},"HN":{"a1":["BO"]},"a17":{"ab":[],"e":[]},"Wt":{"bZ":["aR"],"al":[]},"D9":{"X":[],"e":[]},"Tc":{"hx":[],"al":[]},"pq":{"ia":[],"w1":[],"fr":[],"al":[]},"a25":{"a1":["D9"]},"VG":{"ab":[],"e":[]},"a4B":{"jT":[],"ap":[],"e":[]},"a4C":{"aM":[],"ap":[],"e":[]},"a3z":{"cK":[],"aG":["cK"],"n":[],"af":[]}}'))
var y=(function rtii(){var x=A.Y
return{I:x("fD"),O:x("o<I>"),t:x("o<aQ<f,@>>"),F:x("o<ia>"),s:x("o<f>"),p:x("o<e>"),A:x("bj<a1<X>>"),w:x("f1"),R:x("d6<eO>"),o:x("w1"),X:x("rv"),C:x("ok"),x:x("p"),S:x("jS"),d:x("oN"),N:x("f"),L:x("aD<i>"),Y:x("aD<C>"),g:x("pq"),z:x("@"),q:x("m"),H:x("~")}})();(function constants(){var x=a.makeConstList
D.Zg=new A.aA(10,6,10,6)
D.a_T=new A.bK(C.xV,null,C.o,null,null)
D.a_U=new A.bK(H.rK,48,C.cS,null,null)
D.a03=new A.bK(C.xW,18,null,null,null)
D.a_z=new A.bY(58554,"MaterialIcons",!1)
D.a06=new A.bK(D.a_z,null,null,null,null)
D.a_q=new A.bY(57694,"MaterialIcons",!0)
D.a0a=new A.bK(D.a_q,32,C.o,null,null)
D.a_r=new A.bY(57695,"MaterialIcons",!0)
D.a0c=new A.bK(D.a_r,32,C.o,null,null)
D.a_l=new A.bY(57431,"MaterialIcons",!1)
D.a0d=new A.bK(D.a_l,null,null,null,null)
D.akH=new A.b3('Galer\xeda pr\xf3xima a publicarse.\nA\xf1ade im\xe1genes en img/eventos/ y reg\xedstralas en "images".',null,null,null,null,null,null,null,null)
D.abn=new A.bv(C.r9,D.akH,null)
D.abo=new B.D8(null)
D.aqN=new B.akZ(3,"free")
D.ala=new A.b3('1) Coloca tus archivos en: img/eventos/\n2) Decl\xe1ralos en pubspec.yaml (tu carpeta base actual)\n3) Agrega rutas en "images" o cambia "cover" por tu portada.\n\nEj: "images": ["img/eventos/brisas1.jpg", "img/eventos/brisas2.jpg"]',null,null,null,null,null,null,null,null)
D.a4I=A.a(x([D.ala]),y.p)
D.XF=new A.q8(C.b3,C.u,C.aV,C.F,null,C.dH,null,0,D.a4I,null)
D.aeY=new A.ee(520,null,D.XF,null)
D.ahC=new A.q(!0,C.o,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
D.akC=new A.b3("\xa1Pr\xf3ximamente m\xe1s eventos!",null,null,C.cu,null,null,null,null,null)
D.akP=new A.b3("Agregar im\xe1genes",null,null,null,null,null,null,null,null)
D.akS=new A.b3("Ver galer\xeda",null,null,null,null,null,null,null,null)
D.alb=new A.b3("Agregar im\xe1genes (est\xe1tico)",null,null,null,null,null,null,null,null)
D.j1=new B.Hy(0,"pan")
D.q0=new B.Hy(1,"scale")
D.apz=new B.Hy(2,"rotate")})()};
((a,b)=>{a[b]=a.current
a.eventLog.push({p:"main.dart.js_11",e:"endPart",h:b})})($__dart_deferred_initializers__,"LS347v4sOUMm1FtEmhSm+wq4gEU=");