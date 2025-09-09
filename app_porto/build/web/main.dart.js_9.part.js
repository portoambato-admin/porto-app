((a,b,c)=>{a[b]=a[b]||{}
a[b][c]=a[b][c]||[]
a[b][c].push({p:"main.dart.js_9",e:"beginPart"})})(self,"$__dart_deferred_initializers__","eventLog")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,E,G,F,H,I,K,B={
b1I(){return new B.nT(null)},
nT:function nT(d){this.a=d},
a1r:function a1r(d){this.d=d
this.c=this.a=null},
aAh:function aAh(d,e,f){this.a=d
this.b=e
this.c=f},
aAf:function aAf(d,e,f){this.a=d
this.b=e
this.c=f},
aAg:function aAg(d){this.a=d},
aAq:function aAq(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
aAp:function aAp(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
aAj:function aAj(d){this.a=d},
aAk:function aAk(d,e){this.a=d
this.b=e},
aAi:function aAi(d,e){this.a=d
this.b=e},
aAl:function aAl(d,e){this.a=d
this.b=e},
aAm:function aAm(d){this.a=d},
aAn:function aAn(d,e,f){this.a=d
this.b=e
this.c=f},
aAo:function aAo(d,e,f){this.a=d
this.b=e
this.c=f},
aAe:function aAe(d,e,f){this.a=d
this.b=e
this.c=f},
aAs:function aAs(d,e){this.a=d
this.b=e},
aAr:function aAr(d,e){this.a=d
this.b=e},
a1q:function a1q(d,e,f,g,h,i,j,k,l,m){var _=this
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
yc:function yc(d,e){this.c=d
this.a=e},
ayT:function ayT(){},
HS:function HS(d,e,f,g,h,i,j){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.a=j},
a0e:function a0e(d){this.a=d},
Vo:function Vo(d,e,f,g,h,i,j){var _=this
_.ct=d
_.cD=$
_.y1=e
_.y2=f
_.c3$=g
_.a0$=h
_.cv$=i
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
aik(d,e,f){var x,w,v=f.a,u=e.a,t=Math.pow(v[0]-u[0],2)+Math.pow(v[1]-u[1],2)
if(t===0)return e
x=d.a2(0,e)
w=f.a2(0,e)
return e.a1(0,w.kT(A.w(x.pn(w)/t,0,1)))},
b2u(d,e){var x,w,v,u,t,s,r,q=e.a,p=d.a2(0,q),o=e.b,n=o.a2(0,q),m=e.d,l=m.a2(0,q),k=p.pn(n),j=n.pn(n),i=p.pn(l),h=l.pn(l)
if(0<=k&&k<=j&&0<=i&&i<=h)return d
x=e.c
w=[B.aik(d,q,o),B.aik(d,o,x),B.aik(d,x,m),B.aik(d,m,q)]
v=A.be("closestOverall")
for(q=d.a,u=1/0,t=0;t<4;++t){s=w[t]
o=s.a
r=Math.sqrt(Math.pow(q[0]-o[0],2)+Math.pow(q[1]-o[1],2))
if(r<u){v.b=s
u=r}}return v.b5()},
b6n(){var x=new A.aO(new Float64Array(16))
x.cV()
return new B.XF(x,$.ay())},
aUM(d,e,f){return Math.log(f/d)/Math.log(e/100)},
aVj(d,e){var x,w,v,u,t,s,r=new A.aO(new Float64Array(16))
r.bs(d)
r.hA(r)
x=e.a
w=e.b
v=new A.bT(new Float64Array(3))
v.e2(x,w,0)
v=r.lG(v)
u=e.c
t=new A.bT(new Float64Array(3))
t.e2(u,w,0)
t=r.lG(t)
w=e.d
s=new A.bT(new Float64Array(3))
s.e2(u,w,0)
s=r.lG(s)
u=new A.bT(new Float64Array(3))
u.e2(x,w,0)
u=r.lG(u)
x=new A.bT(new Float64Array(3))
x.bs(v)
w=new A.bT(new Float64Array(3))
w.bs(t)
v=new A.bT(new Float64Array(3))
v.bs(s)
t=new A.bT(new Float64Array(3))
t.bs(u)
return new B.UP(x,w,v,t)},
aUH(d,e){var x,w,v,u,t,s,r=[e.a,e.b,e.c,e.d]
for(x=C.f,w=0;w<4;++w){v=r[w]
u=B.b2u(v,d).a
t=v.a
s=u[0]-t[0]
t=u[1]-t[1]
if(Math.abs(s)>Math.abs(x.a))x=new A.j(s,x.b)
if(Math.abs(t)>Math.abs(x.b))x=new A.j(x.a,t)}return B.aNu(x)},
aNu(d){return new A.j(A.q_(C.d.az(d.a,9)),A.q_(C.d.az(d.b,9)))},
b9z(d,e){if(d.j(0,e))return null
return Math.abs(e.a-d.a)>Math.abs(e.b-d.b)?C.br:C.aQ},
Cy:function Cy(d,e,f,g){var _=this
_.w=d
_.at=e
_.ax=f
_.a=g},
II:function II(d,e,f,g){var _=this
_.d=$
_.e=d
_.f=e
_.w=_.r=null
_.z=_.y=_.x=$
_.at=_.as=_.Q=null
_.ay=_.ax=0
_.ch=null
_.dD$=f
_.bk$=g
_.c=_.a=null},
aC9:function aC9(){},
a2k:function a2k(d,e,f,g,h,i,j){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.a=j},
XF:function XF(d,e){var _=this
_.a=d
_.a3$=0
_.ag$=e
_.ac$=_.b8$=0},
Ir:function Ir(d,e){this.a=d
this.b=e},
ank:function ank(d,e){this.a=d
this.b=e},
Ls:function Ls(){},
b3O(d){return new B.Ue(d,0,null,null,A.a([],y.F),$.ay())},
Ue:function Ue(d,e,f,g,h,i){var _=this
_.as=d
_.a=e
_.c=f
_.d=g
_.f=h
_.a3$=0
_.ag$=i
_.ac$=_.b8$=0},
wl:function wl(d,e,f,g,h,i,j){var _=this
_.r=d
_.a=e
_.b=f
_.c=g
_.d=h
_.e=i
_.f=j},
pF:function pF(d,e,f,g,h,i,j,k,l){var _=this
_.av=d
_.aN=null
_.c2=e
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
_.a3$=0
_.ag$=l
_.ac$=_.b8$=0},
Im:function Im(d,e){this.b=d
this.a=e},
DW:function DW(d){this.a=d},
DX:function DX(d,e,f,g){var _=this
_.r=d
_.y=e
_.z=f
_.a=g},
a3k:function a3k(){var _=this
_.d=0
_.e=$
_.c=_.a=null},
aDC:function aDC(d){this.a=d},
aDD:function aDD(d,e){this.a=d
this.b=e},
WL:function WL(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
a5Q:function a5Q(d,e,f){this.f=d
this.d=e
this.a=f},
a5R:function a5R(d,e,f){this.e=d
this.c=e
this.a=f},
a4N:function a4N(d,e,f){var _=this
_.dN=null
_.C=d
_.d5=null
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
UP:function UP(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g}},D
J=c[1]
A=c[0]
C=c[2]
E=c[8]
G=c[21]
F=c[11]
H=c[24]
I=c[12]
K=c[14]
B=a.updateHolder(c[4],B)
D=c[25]
B.nT.prototype={
ar(){var x="Campeonato Internacional",w=y.s,v=y.N,u=y.z
return new B.a1r(A.a([A.ac(["title","Brisas Cup 360","subtitle",x,"location","Panam\xe1","year",2025,"cover","assets/img/webp/main.webp","description","Experiencia internacional de alto nivel con clubes invitados de la regi\xf3n. Desarrollo competitivo y vitrina para talento joven.","images",A.a(["assets/img/eventos/panama2025/2025_1_thumb.webp","assets/img/eventos/panama2025/2025_2_thumb.webp","assets/img/eventos/panama2025/2025_3_thumb.webp","assets/img/eventos/panama2025/2025_4_thumb.webp","assets/img/eventos/panama2025/2025_5_thumb.webp","assets/img/eventos/panama2025/2025_6_thumb.webp","assets/img/eventos/panama2025/2025_7_thumb.webp"],w)],v,u),A.ac(["title","Caribe Champions","subtitle",x,"location","Barranquilla","year",2024,"cover","assets/img/eventosWebp/2024_1.webp","description","Torneo de referencia en el Caribe colombiano. Intensidad, disciplina y juego colectivo enfrentando a escuelas top del litoral.","images",A.a(["assets/img/eventos/barranquilla2024/2024_1_thumb.webp","assets/img/eventos/barranquilla2024/2024_2_thumb.webp","assets/img/eventos/barranquilla2024/2024_3_thumb.webp"],w)],v,u),A.ac(["title","Sporturs Soccer Cup","subtitle",x,"location","Medell\xedn","year",2023,"cover","assets/img/eventosWebp/2023_3.webp","description","Competencia con metodolog\xeda formativa y enfoque en el fair play. Gran oportunidad para medici\xf3n de rendimiento y convivencia.","images",A.a(["assets/img/eventos/medellin2023/2023_1_thumb.webp","assets/img/eventos/medellin2023/2023_2_thumb.webp","assets/img/eventos/medellin2023/2023_3_thumb.webp"],w)],v,u)],y.t))}}
B.a1r.prototype={
aid(d){var x,w=d.h(0,"images")
if(w==null)w=[]
x=A.iV(w,!0,y.N)
w=this.c
w.toString
A.ur(null,!0,new B.aAh(this,d,x),w,y.z)},
aie(d,e){var x,w={},v=B.b3O(e)
w.a=e
x=this.c
x.toString
A.ur(A.aD(217,C.p.E()>>>16&255,C.p.E()>>>8&255,C.p.E()&255),!0,new B.aAq(w,this,v,d),x,y.z)},
OG(d,e,f,g){return A.fH(d,new B.aAe(d,g,f),e,f,g)},
a8d(d,e){return this.OG(d,e,null,null)},
J(d){var x=null,w=A.br(d,x,y.w).w
return A.wU(I.ja,x,new F.CY(new A.xb(new B.aAs(this,w.a.a>=1000),4,!0,!0,!0,x),C.aT,C.aQ,!1,x,x,C.hM,x,!1,x,0,x,4,C.ak,x,x,C.V,C.aC,x))}}
B.a1q.prototype={
J(d){var x,w,v=this,u=null,t=y.p
if(v.y){x=A.a([],t)
w=v.z
if(!w)x.push(A.ce(new B.yc(v.r,u),5))
x.push(A.du(u,u,24))
x.push(A.ce(new B.HS(v.c,v.d,v.e,v.f,v.w,v.x,u),5))
if(w)C.b.I(x,A.a([C.pR,A.ce(new B.yc(v.r,u),5)],t))
t=A.c9(x,C.C,C.r,C.B)}else t=A.c0(A.a([new B.yc(v.r,u),C.bn,new B.HS(v.c,v.d,v.e,v.f,v.w,v.x,u)],t),C.bV,C.r,C.B)
return A.cq(u,A.cW(new A.cn(C.cf,new A.bl(K.k_,t,u),u),u,u),C.u,C.qZ,u,u,u,u,u,u,u,u,u)}}
B.yc.prototype={
J(d){var x=null
return new A.fZ(1.7777777777777777,A.hX(A.cV(16),A.fN(C.cc,A.a([A.fH(this.c,new B.ayT(),C.bN,x,x),A.aMi(0,A.qA(x,new A.cC(x,x,x,x,x,new A.l0(C.ds,C.eK,C.co,A.a([A.aD(64,C.p.E()>>>16&255,C.p.E()>>>8&255,C.p.E()&255),C.P],y.O),x,x),C.ao),C.dZ))],y.p),C.V,C.j5,x),C.aF),x)}}
B.HS.prototype={
J(d){var x,w=this,v=null,u=A.C(d).ok,t=A.cV(16),s=u.f
s=s==null?v:s.fd(C.bz)
x=y.p
return A.uO(new A.bl(C.i6,A.c0(A.a([A.aC(w.c,v,v,v,v,s,v,v),C.dM,A.aC(w.d,v,v,v,v,u.w,v,v),C.aw,A.c9(A.a([D.a18,H.hA,A.aC(w.e+" "+w.f,v,v,v,v,u.z,v,v)],x),C.C,C.r,C.B),C.aI,A.aC(w.r,v,v,v,v,u.y,v,v),C.bn,new A.d4(C.cq,v,v,A.or(D.a1d,D.amc,w.w),v)],x),C.bV,C.r,C.B),v),v,v,0.8,new A.cA(t,C.w))}}
B.a0e.prototype={
J(d){var x=null,w=A.C(d).ax,v=w.d
return A.cq(x,A.cW(new A.cn(C.cf,A.cq(x,D.alY,C.u,x,x,new A.cC((v==null?w.b:v).be(0.35),x,x,A.cV(12),x,x,C.ao),x,x,x,C.fD,x,x,x),x),x,x),C.u,C.n,x,x,x,x,x,C.ro,x,x,x)}}
B.Vo.prototype={
gwR(){return y.S.a(A.n.prototype.gV.call(this)).y*this.ct},
sxP(d){if(this.ct===d)return
this.ct=d
this.a4()}}
B.Cy.prototype={
ar(){var x=null,w=y.A
return new B.II(new A.bu(x,w),new A.bu(x,w),x,x)}}
B.II.prototype={
gcg(){var x=this.d
if(x===$){this.a.toString
x=B.b6n()
this.d=x}return x},
gyE(){var x,w=$.ad.aB$.x.h(0,this.e).ga5()
w.toString
x=y.x.a(w).gp()
this.a.toString
return C.aT.wK(new A.u(0,0,0+x.a,0+x.b))},
gAk(){var x=$.ad.aB$.x.h(0,this.f).ga5()
x.toString
x=y.x.a(x).gp()
return new A.u(0,0,0+x.a,0+x.b)},
r3(a0,a1){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this
if(a1.j(0,C.f)){x=new A.aO(new Float64Array(16))
x.bs(a0)
return x}if(d.Q!=null){d.a.toString
switch(3){case 3:break}}w=new A.aO(new Float64Array(16))
w.bs(a0)
w.cr(a1.a,a1.b)
v=B.aVj(w,d.gAk())
if(d.gyE().gZv(0))return w
x=d.gyE()
u=d.ay
t=new A.aO(new Float64Array(16))
t.cV()
s=x.c
r=x.a
q=s-r
p=x.d
x=x.b
o=p-x
t.cr(q/2,o/2)
t.o5(u)
t.cr(-q/2,-o/2)
u=new A.bT(new Float64Array(3))
u.e2(r,x,0)
u=t.lG(u)
q=new A.bT(new Float64Array(3))
q.e2(s,x,0)
q=t.lG(q)
x=new A.bT(new Float64Array(3))
x.e2(s,p,0)
x=t.lG(x)
s=new A.bT(new Float64Array(3))
s.e2(r,p,0)
s=t.lG(s)
r=new Float64Array(3)
new A.bT(r).bs(u)
u=new Float64Array(3)
new A.bT(u).bs(q)
q=new Float64Array(3)
new A.bT(q).bs(x)
x=new Float64Array(3)
new A.bT(x).bs(s)
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
x=new A.bT(new Float64Array(3))
x.e2(m,l,0)
u=new A.bT(new Float64Array(3))
u.e2(k,l,0)
s=new A.bT(new Float64Array(3))
s.e2(k,j,0)
r=new A.bT(new Float64Array(3))
r.e2(m,j,0)
q=new A.bT(new Float64Array(3))
q.bs(x)
x=new A.bT(new Float64Array(3))
x.bs(u)
u=new A.bT(new Float64Array(3))
u.bs(s)
s=new A.bT(new Float64Array(3))
s.bs(r)
i=new B.UP(q,x,u,s)
h=B.aUH(i,v)
if(h.j(0,C.f))return w
x=w.DF().a
u=x[0]
x=x[1]
g=a0.qb()
u-=h.a*g
x-=h.b*g
f=new A.aO(new Float64Array(16))
f.bs(a0)
s=new A.bT(new Float64Array(3))
s.e2(u,x,0)
f.N_(s)
e=B.aUH(i,B.aVj(f,d.gAk()))
if(e.j(0,C.f))return f
s=e.a===0
if(!s&&e.b!==0){x=new A.aO(new Float64Array(16))
x.bs(a0)
return x}u=s?u:0
x=e.b===0?x:0
s=new A.aO(new Float64Array(16))
s.bs(a0)
r=new A.bT(new Float64Array(3))
r.e2(u,x,0)
s.N_(r)
return s},
Gl(d,e){var x,w,v,u,t,s,r,q=this
if(e===1){x=new A.aO(new Float64Array(16))
x.bs(d)
return x}w=q.gcg().a.qb()
x=q.gAk()
v=q.gyE()
u=q.gAk()
t=q.gyE()
s=Math.max(w*e,Math.max((x.c-x.a)/(v.c-v.a),(u.d-u.b)/(t.d-t.b)))
t=q.a
r=A.w(s,t.ax,t.at)
x=new A.aO(new Float64Array(16))
x.bs(d)
x.by(r/w)
return x},
agB(d,e,f){var x,w,v,u
if(e===0){x=new A.aO(new Float64Array(16))
x.bs(d)
return x}w=this.gcg().iK(f)
x=new A.aO(new Float64Array(16))
x.bs(d)
v=w.a
u=w.b
x.cr(v,u)
x.o5(-e)
x.cr(-v,-u)
return x},
yY(d){var x
$label0$0:{x=!0
if(D.aqX===d){x=!1
break $label0$0}if(D.qe===d){this.a.toString
break $label0$0}if(D.ji===d||d==null){this.a.toString
break $label0$0}x=null}return x},
QH(d){this.a.toString
if(Math.abs(d.d-1)>Math.abs(0))return D.qe
else return D.ji},
ahJ(d){var x,w,v=this
v.a.toString
x=v.y
x===$&&A.b()
w=x.r
if(w!=null&&w.a!=null){x.f8()
x=v.y
x.sq(x.a)
x=v.r
if(x!=null)x.a.L(v.gz7())
v.r=null}x=v.z
x===$&&A.b()
w=x.r
if(w!=null&&w.a!=null){x.f8()
x=v.z
x.sq(x.a)
x=v.w
if(x!=null)x.a.L(v.gzb())
v.w=null}v.Q=v.ch=null
v.at=v.gcg().a.qb()
v.as=v.gcg().iK(d.b)
v.ax=v.ay},
ahL(d){var x,w,v,u,t,s,r=this,q=r.gcg().a.qb(),p=r.x=d.c,o=r.gcg().iK(p),n=r.ch
if(n===D.ji)n=r.ch=r.QH(d)
else if(n==null){n=r.QH(d)
r.ch=n}if(!r.yY(n)){r.a.toString
return}switch(r.ch.a){case 1:n=r.at
n.toString
r.gcg().sq(r.Gl(r.gcg().a,n*d.d/q))
x=r.gcg().iK(p)
n=r.gcg()
w=r.gcg().a
v=r.as
v.toString
n.sq(r.r3(w,x.a2(0,v)))
u=r.gcg().iK(p)
p=r.as
p.toString
if(!B.aNu(p).j(0,B.aNu(u)))r.as=u
break
case 2:n=d.r
if(n===0){r.a.toString
return}w=r.ax
w.toString
t=w+n
r.gcg().sq(r.agB(r.gcg().a,r.ay-t,p))
r.ay=t
break
case 0:if(d.d!==1){r.a.toString
return}if(r.Q==null){n=r.as
n.toString
r.Q=B.b9z(n,o)}n=r.as
n.toString
s=o.a2(0,n)
r.gcg().sq(r.r3(r.gcg().a,s))
r.as=r.gcg().iK(p)
break}r.a.toString},
ahH(d){var x,w,v,u,t,s,r,q,p,o,n,m,l=this
l.a.toString
l.as=l.ax=l.at=null
x=l.r
if(x!=null)x.a.L(l.gz7())
x=l.w
if(x!=null)x.a.L(l.gzb())
x=l.y
x===$&&A.b()
x.sq(x.a)
x=l.z
x===$&&A.b()
x.sq(x.a)
if(!l.yY(l.ch)){l.Q=null
return}$label0$0:{w=l.ch
if(D.ji===w){x=d.a.a
if(x.gd3()<50){l.Q=null
return}v=l.gcg().a.DF().a
u=v[0]
v=v[1]
l.a.toString
t=A.agh(0.0000135,u,x.a,0)
l.a.toString
s=A.agh(0.0000135,v,x.b,0)
x=x.gd3()
l.a.toString
r=B.aUM(x,0.0000135,10)
x=t.gte()
q=s.gte()
p=y.L
o=A.cs(C.dW,l.y,null)
l.r=new A.aW(o,new A.aH(new A.j(u,v),new A.j(x,q),p),p.i("aW<aI.T>"))
l.y.e=A.dz(0,0,C.d.aY(r*1000))
o.a6(l.gz7())
l.y.cE()
break $label0$0}if(D.qe===w){x=d.b
v=Math.abs(x)
if(v<0.1){l.Q=null
return}n=l.gcg().a.qb()
l.a.toString
m=A.agh(0.0026999999999999997,n,x/10,0)
l.a.toString
r=B.aUM(v,0.0000135,0.1)
x=m.f6(r)
v=y.Y
u=A.cs(C.dW,l.z,null)
l.w=new A.aW(u,new A.aH(n,x,v),v.i("aW<aI.T>"))
l.z.e=A.dz(0,0,C.d.aY(r*1000))
u.a6(l.gzb())
l.z.cE()
break $label0$0}break $label0$0}},
ag1(d){var x,w,v,u,t,s,r,q=this,p=d.gdu(),o=d.gb2()
if(y.C.b(d)){x=d.gcK()===C.bF
if(x)q.a.toString
if(x){q.a.toString
x=o.a1(0,d.glN())
w=d.glN()
v=A.rL(d.gcf(),null,w,x)
if(!q.yY(D.ji)){q.a.toString
return}u=q.gcg().iK(p)
t=q.gcg().iK(p.a2(0,v))
q.gcg().sq(q.r3(q.gcg().a,t.a2(0,u)))
q.a.toString
return}if(d.glN().b===0)return
x=d.glN()
q.a.toString
s=Math.exp(-x.b/200)}else if(y.X.b(d))s=d.ghL()
else return
q.a.toString
if(!q.yY(D.qe)){q.a.toString
return}u=q.gcg().iK(p)
q.gcg().sq(q.Gl(q.gcg().a,s))
r=q.gcg().iK(p)
q.gcg().sq(q.r3(q.gcg().a,r.a2(0,u)))
q.a.toString},
adB(){var x,w,v,u,t,s=this,r=s.y
r===$&&A.b()
r=r.r
if(!(r!=null&&r.a!=null)){s.Q=null
r=s.r
if(r!=null)r.a.L(s.gz7())
s.r=null
r=s.y
r.sq(r.a)
return}r=s.gcg().a.DF().a
x=r[0]
r=r[1]
w=s.gcg()
v=s.gcg().a
u=s.gcg()
t=s.r
w.sq(s.r3(v,u.iK(t.b.aq(t.a.gq())).a2(0,s.gcg().iK(new A.j(x,r)))))},
aew(){var x,w,v,u,t,s=this,r=s.z
r===$&&A.b()
r=r.r
if(!(r!=null&&r.a!=null)){s.Q=null
r=s.w
if(r!=null)r.a.L(s.gzb())
s.w=null
r=s.z
r.sq(r.a)
return}r=s.w
x=r.b.aq(r.a.gq())
r=s.gcg().a.qb()
w=s.gcg()
v=s.x
v===$&&A.b()
u=w.iK(v)
s.gcg().sq(s.Gl(s.gcg().a,x/r))
t=s.gcg().iK(s.x)
s.gcg().sq(s.r3(s.gcg().a,t.a2(0,u)))},
afu(){this.an(new B.aC9())},
aR(){var x=this,w=null
x.b9()
x.y=A.c5(w,w,w,w,x)
x.z=A.c5(w,w,w,w,x)
x.gcg().a6(x.gRK())},
b1(d){this.bg(d)
this.a.toString
return},
l(){var x=this,w=x.y
w===$&&A.b()
w.l()
w=x.z
w===$&&A.b()
w.l()
x.gcg().L(x.gRK())
x.a.toString
w=x.gcg()
w.ag$=$.ay()
w.a3$=0
x.a6H()},
J(d){var x,w,v,u=this,t=null
u.a.toString
x=u.gcg().a
w=u.a.w
v=new B.a2k(w,u.e,C.V,!0,x,t,t)
return A.w3(C.cL,A.kS(C.aC,v,C.ak,!1,t,t,t,t,t,t,t,t,t,u.gahG(),u.gahI(),u.gahK(),t,t,t,t,t,t,t,t,t,t,t,!1,new A.j(0,-0.005)),u.f,t,t,t,u.gag0(),t)}}
B.a2k.prototype={
J(d){var x=this,w=A.GH(x.w,new A.jN(x.c,x.d),null,x.r,!0)
return A.AQ(w,x.e,null)}}
B.XF.prototype={
iK(d){var x=this.a,w=new A.aO(new Float64Array(16))
if(w.hA(x)===0)A.a6(A.fg(x,"other","Matrix cannot be inverted"))
x=new A.bT(new Float64Array(3))
x.e2(d.a,d.b,0)
x=w.lG(x).a
return new A.j(x[0],x[1])}}
B.Ir.prototype={
K(){return"_GestureType."+this.b}}
B.ank.prototype={
K(){return"PanAxis."+this.b}}
B.Ls.prototype={
cc(){this.dh()
this.d8()
this.eY()},
l(){var x=this,w=x.bk$
if(w!=null)w.L(x.geI())
x.bk$=null
x.aW()}}
B.Ue.prototype={
We(d,e,f){var x=y.g.a(C.b.ghM(this.f))
if(x.aN!=null){x.aN=d
return A.cx(null,y.H)}if(x.ax==null){x.av=d
return A.cx(null,y.H)}return x.j1(x.u0(d),e,f)},
IR(d,e,f){var x=null,w=$.ay()
w=new B.pF(this.as,1,C.hy,d,e,!0,x,new A.ca(!1,w),w)
w.Et(e,x,!0,f,d)
w.Eu(e,x,x,!0,f,d)
return w},
aw(d){this.a4L(d)
y.g.a(d).sxP(1)}}
B.wl.prototype={}
B.pF.prototype={
wn(d,e,f,g,h,i){return this.a4X(d,e,f,g,h,null)},
sxP(d){var x,w=this
if(w.c2===d)return
x=w.gCF()
w.c2=d
if(x!=null)w.JI(w.u0(x))},
gzi(){var x=this.ax
x.toString
return Math.max(0,x*(this.c2-1)/2)},
xU(d,e){var x=Math.max(0,d-this.gzi())/(e*this.c2),w=C.d.a02(x)
if(Math.abs(x-w)<1e-10)return w
return x},
u0(d){var x=this.ax
x.toString
return d*x*this.c2+this.gzi()},
gCF(){var x,w,v=this,u=v.at
if(u==null)return null
x=v.z
if(x!=null&&v.Q!=null||v.ay){w=v.aN
if(w==null){x.toString
w=v.Q
w.toString
w=A.w(u,x,w)
x=v.ax
x.toString
x=v.xU(w,x)
u=x}else u=w}else u=null
return u},
ME(){var x,w,v=this,u=v.w,t=u.c
t.toString
t=A.ane(t)
if(t!=null){u=u.c
u.toString
x=v.aN
if(x==null){x=v.at
x.toString
w=v.ax
w.toString
w=v.xU(x,w)
x=w}t.a0V(u,x)}},
a_Y(){var x,w,v
if(this.at==null){x=this.w
w=x.c
w.toString
w=A.ane(w)
if(w==null)v=null
else{x=x.c
x.toString
v=w.a_w(x)}if(v!=null)this.av=v}},
MD(){var x,w=this,v=w.aN
if(v==null){v=w.at
v.toString
x=w.ax
x.toString
x=w.xU(v,x)
v=x}w.w.r.sq(v)
v=$.e4.dL$
v===$&&A.b()
v.Yo()},
a_X(d,e){if(e)this.av=d
else this.f4(this.u0(d))},
np(d){var x,w,v,u,t=this,s=t.ax
s=s!=null?s:null
if(d===s)return!0
t.a4T(d)
x=t.at
x=x!=null?x:null
if(x==null)w=t.av
else if(s===0){v=t.aN
v.toString
w=v}else{s.toString
w=t.xU(x,s)}u=t.u0(w)
t.aN=d===0?w:null
if(u!==x){t.at=u
return!1}return!0},
m8(d){var x
this.O2(d)
if(!(d instanceof B.pF))return
x=d.aN
if(x!=null)this.aN=x},
no(d,e){var x=d+this.gzi()
return this.a4R(x,Math.max(x,e-this.gzi()))},
kn(){var x,w,v,u,t,s,r=this,q=null,p=r.z
p=p!=null&&r.Q!=null?p:q
x=q
if(r.z!=null&&r.Q!=null){x=r.Q
x.toString}w=r.at
w=w!=null?w:q
v=r.ax
v=v!=null?v:q
u=r.w
t=u.a.c
s=r.c2
u=u.f
u===$&&A.b()
return new B.wl(s,p,x,w,v,t,u)},
$iwl:1}
B.Im.prototype={
l7(d){return new B.Im(!1,this.l9(d))},
gm9(){return this.b}}
B.DW.prototype={
l7(d){return new B.DW(this.l9(d))},
acg(d){var x,w
if(d instanceof B.pF){x=d.gCF()
x.toString
return x}x=d.at
x.toString
w=d.ax
w.toString
return x/w},
acj(d,e){var x
if(d instanceof B.pF)return d.u0(e)
x=d.ax
x.toString
return e*x},
rS(d,e){var x,w,v,u,t,s=this
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
if(x)return s.a4P(d,e)
v=s.o8(d)
u=s.acg(d)
x=v.c
if(e<-x)u-=0.5
else if(e>x)u+=0.5
t=s.acj(d,C.d.a02(u))
x=d.at
x.toString
if(t!==x){x=s.gqp()
w=d.at
w.toString
return new A.oT(t,A.ze(x,w-t,e),v)}return null},
gm9(){return!1}}
B.DX.prototype={
ar(){return new B.a3k()}}
B.a3k.prototype={
aR(){var x,w=this
w.b9()
w.RX()
x=w.e
x===$&&A.b()
w.d=x.as},
l(){this.a.toString
this.aW()},
RX(){var x=this.a.r
this.e=x},
b1(d){if(d.r!==this.a.r)this.RX()
this.bg(d)},
ac_(d){var x
this.a.toString
switch(0){case 0:x=A.aKu(d.aC(y.I).w)
this.a.toString
return x}},
J(d){var x,w,v,u=this,t=null,s=u.ac_(d)
u.a.toString
x=new B.DW(D.acC.l9(t))
x=new B.Im(!1,t).l9(x)
u.a.toString
w=u.e
w===$&&A.b()
v=A.lc(d).Xf(!1)
return new A.dl(new B.aDC(u),A.aqy(s,C.V,w,C.ak,!1,C.aC,t,new B.Im(!1,x),t,v,t,new B.aDD(u,s)),t,y.R)}}
B.WL.prototype={
J(d){var x=this.c,w=A.w(1-x,0,1)
return new B.a5R(w/2,new B.a5Q(x,this.e,null),null)}}
B.a5Q.prototype={
aQ(d){var x=new B.Vo(this.f,y.d.a(d),A.p(y.q,y.x),0,null,null,A.a8())
x.aO()
return x},
aT(d,e){e.sxP(this.f)}}
B.a5R.prototype={
aQ(d){var x=new B.a4N(this.e,null,A.a8())
x.aO()
return x},
aT(d,e){e.sxP(this.e)}}
B.a4N.prototype={
sxP(d){var x=this
if(x.C===d)return
x.C=d
x.d5=null
x.a4()},
gi2(){return this.d5},
alq(){var x,w,v=this
if(v.d5!=null&&J.d(v.dN,y.S.a(A.n.prototype.gV.call(v))))return
x=y.S
w=x.a(A.n.prototype.gV.call(v)).y*v.C
v.dN=x.a(A.n.prototype.gV.call(v))
switch(A.ba(x.a(A.n.prototype.gV.call(v)).a).a){case 0:x=new A.at(w,0,w,0)
break
case 1:x=new A.at(0,w,0,w)
break
default:x=null}v.d5=x
return},
bG(){this.alq()
this.O_()}}
B.UP.prototype={}
var z=a.updateTypes(["~()","~(F4)","~(F5)","~(wW)","~(f3)"])
B.aAh.prototype={
$1(d){var x,w,v,u,t,s=this,r=null,q=A.aC("Galer\xeda \u2014 "+A.k(s.b.h(0,"title")),r,r,r,r,r,r,r),p=s.c
if(p.length===0)p=D.acA
else{x=A.a([],y.p)
for(w=s.a,v=0;v<p.length;++v){u=p[v]
t=new A.b1(8,8)
x.push(A.kS(r,new E.mc(u,new A.qq(new A.cB(t,t,t,t),C.aF,w.OG(u,C.bN,120,160),r),!1,r),C.ak,!1,r,r,r,r,r,r,r,r,r,r,r,r,r,r,r,r,new B.aAf(w,p,v),r,r,r,r,r,r,!1,C.cR))}p=A.tn(A.ll(C.cp,x,12,12),r,r)}p=A.du(p,r,560)
return A.uy(A.a([A.hM(!1,C.eF,r,r,r,r,r,r,new B.aAg(s.a),r,r)],y.p),p,q)},
$S:53}
B.aAf.prototype={
$0(){var x=this.a,w=x.c
w.toString
A.c2(w,!1).ff(null)
x.aie(this.b,this.c)},
$S:0}
B.aAg.prototype={
$0(){var x=this.a.c
x.toString
A.c2(x,!1).ff(null)
return null},
$S:0}
B.aAq.prototype={
$1(d){var x=this
return new A.tq(new B.aAp(x.a,x.b,x.c,x.d),null)},
$S:644}
B.aAp.prototype={
$2(d,e){var x=this,w=null,v=x.c,u=x.a,t=x.d,s=A.a([A.kS(C.aC,w,C.ak,!1,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w,new B.aAj(d),w,w,w,w,w,w,!1,C.cR),new B.DX(v,new B.aAk(u,e),new A.xb(new B.aAl(x.b,t),t.length,!0,!0,!0,w),w),A.mF(w,A.kT(w,w,D.a0S,w,w,new B.aAm(d),w,A.me(w,C.cZ,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w),"Cerrar"),w,w,w,20,20,w)],y.p)
if(t.length>1)s.push(A.mF(w,A.kT(w,w,D.a1g,w,w,new B.aAn(u,t,v),w,A.me(w,C.cZ,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w),w),w,w,12,w,w,w))
if(t.length>1)s.push(A.mF(w,A.kT(w,w,D.a1k,w,w,new B.aAo(u,t,v),w,A.me(w,C.cZ,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w),w),w,w,w,12,w,w))
v=t.length
if(v>1){t=A.cV(12)
s.push(A.mF(20,A.cq(w,A.aC(""+(u.a+1)+" / "+v,w,w,w,w,D.aiQ,w,w),C.u,w,w,new A.cC(C.cZ,w,w,t,w,w,C.ao),w,w,w,D.a__,w,w,w),w,w,w,w,w,w))}return A.fN(C.X,s,C.V,C.cA,w)},
$S:645}
B.aAj.prototype={
$0(){A.c2(this.a,!1).ff(null)
return null},
$S:0}
B.aAk.prototype={
$1(d){return this.b.$1(new B.aAi(this.a,d))},
$S:16}
B.aAi.prototype={
$0(){return this.a.a=this.b},
$S:0}
B.aAl.prototype={
$2(d,e){var x=this.b[e]
return A.cW(E.aQm(new B.Cy(this.a.a8d(x,C.qI),5,1,null),x,!1),null,null)},
$S:646}
B.aAm.prototype={
$0(){A.c2(this.a,!1).ff(null)
return null},
$S:0}
B.aAn.prototype={
$0(){this.c.We(C.h.fp(this.a.a-1,0,this.b.length-1),C.eS,C.ab)},
$S:0}
B.aAo.prototype={
$0(){this.c.We(C.h.fp(this.a.a+1,0,this.b.length-1),C.eS,C.ab)},
$S:0}
B.aAe.prototype={
$3(d,e,f){var x=null
A.aKj().$1("NO se encontr\xf3 asset: "+this.a)
return A.cq(C.X,D.a0T,C.u,C.aq,x,x,x,this.c,x,x,x,x,this.b)},
$S:18}
B.aAs.prototype={
$2(d,e){var x,w
if(e===3)return new B.a0e(null)
x=this.a
w=x.d[e]
return new B.a1q(w.h(0,"title"),w.h(0,"subtitle"),w.h(0,"location"),w.h(0,"year"),w.h(0,"cover"),w.h(0,"description"),new B.aAr(x,w),this.b,(e&1)===1,null)},
$S:647}
B.aAr.prototype={
$0(){return this.a.aid(this.b)},
$S:0}
B.ayT.prototype={
$3(d,e,f){var x=null
return A.cq(C.X,C.t4,C.u,C.aq,x,x,x,x,x,x,x,x,x)},
$S:18}
B.aC9.prototype={
$0(){},
$S:0}
B.aDC.prototype={
$1(d){var x,w,v,u,t
if(d.ha$===0){this.a.a.toString
x=d instanceof A.j4}else x=!1
if(x){w=y.o.a(d.a)
x=w.c
x.toString
v=w.a
v.toString
u=w.b
u.toString
u=Math.max(0,A.w(x,v,u))
v=w.d
v.toString
t=C.d.aY(u/Math.max(1,v*w.r))
x=this.a
if(t!==x.d){x.d=t
x.a.y.$1(t)}}return!1},
$S:49}
B.aDD.prototype={
$2(d,e){var x=this.a,w=x.a
w.toString
x.e===$&&A.b()
return A.aTc(0,this.b,0,C.Va,null,C.V,e,A.a([new B.WL(1,!0,w.z,null)],y.p))},
$S:648};(function aliases(){var x=B.Ls.prototype
x.a6H=x.l})();(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u
var v
x(v=B.II.prototype,"gahI","ahJ",1)
x(v,"gahK","ahL",2)
x(v,"gahG","ahH",3)
x(v,"gag0","ag1",4)
w(v,"gz7","adB",0)
w(v,"gzb","aew",0)
w(v,"gRK","afu",0)})();(function inheritance(){var x=a.mixinHard,w=a.inheritMany,v=a.inherit
w(A.W,[B.nT,B.Cy,B.DX])
w(A.a1,[B.a1r,B.Ls,B.a3k])
w(A.h1,[B.aAh,B.aAq,B.aAk,B.aAe,B.ayT,B.aDC])
w(A.iI,[B.aAf,B.aAg,B.aAj,B.aAi,B.aAm,B.aAn,B.aAo,B.aAr,B.aC9])
w(A.kD,[B.aAp,B.aAl,B.aAs,B.aDD])
w(A.a9,[B.a1q,B.yc,B.HS,B.a0e,B.a2k,B.WL])
v(B.Vo,F.Vp)
v(B.II,B.Ls)
v(B.XF,A.ca)
w(A.yq,[B.Ir,B.ank])
v(B.Ue,A.hH)
v(B.wl,A.Qq)
v(B.pF,A.oS)
w(A.oR,[B.Im,B.DW])
v(B.a5Q,A.k2)
v(B.a5R,A.aP)
v(B.a4N,A.wJ)
v(B.UP,A.D)
x(B.Ls,A.dM)})()
A.no(b.typeUniverse,JSON.parse('{"nT":{"W":[],"e":[]},"a1r":{"a1":["nT"]},"a1q":{"a9":[],"e":[]},"yc":{"a9":[],"e":[]},"HS":{"a9":[],"e":[]},"a0e":{"a9":[],"e":[]},"Vo":{"la":[],"cz":[],"a3":["o","eT"],"n":[],"ak":[],"a3.1":"eT","a3.0":"o"},"Cy":{"W":[],"e":[]},"II":{"a1":["Cy"]},"a2k":{"a9":[],"e":[]},"XF":{"ca":["aO"],"ap":[]},"DX":{"W":[],"e":[]},"Ue":{"hH":[],"ap":[]},"pF":{"im":[],"wl":[],"fy":[],"ap":[]},"a3k":{"a1":["DX"]},"WL":{"a9":[],"e":[]},"a5Q":{"k2":[],"aq":[],"e":[]},"a5R":{"aP":[],"aq":[],"e":[]},"a4N":{"cz":[],"aG":["cz"],"n":[],"ak":[]}}'))
var y=(function rtii(){var x=A.Y
return{I:x("h2"),O:x("r<O>"),t:x("r<aS<f,@>>"),F:x("r<im>"),s:x("r<f>"),p:x("r<e>"),A:x("bu<a1<W>>"),w:x("fr"),R:x("dl<fM>"),o:x("wl"),X:x("rQ"),C:x("oA"),x:x("o"),S:x("j8"),d:x("p2"),N:x("f"),L:x("aH<j>"),Y:x("aH<Q>"),g:x("pF"),z:x("@"),q:x("l"),H:x("~")}})();(function constants(){D.a__=new A.at(10,6,10,6)
D.a0S=new A.bq(C.yg,null,C.n,null,null)
D.a0T=new A.bq(G.yf,48,C.cZ,null,null)
D.a18=new A.bq(C.t2,18,null,null,null)
D.a0u=new A.bC(58554,"MaterialIcons",!1)
D.a1d=new A.bq(D.a0u,null,null,null,null)
D.a0e=new A.bC(57694,"MaterialIcons",!0)
D.a1g=new A.bq(D.a0e,32,C.n,null,null)
D.a0f=new A.bC(57695,"MaterialIcons",!0)
D.a1k=new A.bq(D.a0f,32,C.n,null,null)
D.amz=new A.b_('Galer\xeda pr\xf3xima a publicarse.\nA\xf1ade im\xe1genes en img/eventos/ y reg\xedstralas en "images".',null,null,null,null,null,null,null,null,null)
D.acA=new A.bl(C.rq,D.amz,null)
D.acC=new B.DW(null)
D.asl=new B.ank(3,"free")
D.aiQ=new A.q(!0,C.n,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
D.alY=new A.b_("\xa1Pr\xf3ximamente m\xe1s eventos!",null,null,C.c9,null,null,null,null,null,null)
D.amc=new A.b_("Ver galer\xeda",null,null,null,null,null,null,null,null,null)
D.ji=new B.Ir(0,"pan")
D.qe=new B.Ir(1,"scale")
D.aqX=new B.Ir(2,"rotate")})()};
((a,b)=>{a[b]=a.current
a.eventLog.push({p:"main.dart.js_9",e:"endPart",h:b})})($__dart_deferred_initializers__,"WYgiHhuGgbZ7+3n5GmStwSYNHzs=");