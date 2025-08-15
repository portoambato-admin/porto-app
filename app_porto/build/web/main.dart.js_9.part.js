((a,b,c)=>{a[b]=a[b]||{}
a[b][c]=a[b][c]||[]
a[b][c].push({p:"main.dart.js_9",e:"beginPart"})})(self,"$__dart_deferred_initializers__","eventLog")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,A,C,E,G,F,H,I,K,B={
aYW(){return new B.Bb(null)},
Bb:function Bb(d){this.a=d},
a0m:function a0m(d){this.d=d
this.c=this.a=null},
axt:function axt(d,e,f){this.a=d
this.b=e
this.c=f},
axr:function axr(d,e,f){this.a=d
this.b=e
this.c=f},
axs:function axs(d){this.a=d},
axC:function axC(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
axB:function axB(d,e,f,g){var _=this
_.a=d
_.b=e
_.c=f
_.d=g},
axv:function axv(d){this.a=d},
axw:function axw(d,e){this.a=d
this.b=e},
axu:function axu(d,e){this.a=d
this.b=e},
axx:function axx(d,e){this.a=d
this.b=e},
axy:function axy(d){this.a=d},
axz:function axz(d,e,f){this.a=d
this.b=e
this.c=f},
axA:function axA(d,e,f){this.a=d
this.b=e
this.c=f},
axq:function axq(d,e,f){this.a=d
this.b=e
this.c=f},
axE:function axE(d,e){this.a=d
this.b=e},
axD:function axD(d,e){this.a=d
this.b=e},
a0l:function a0l(d,e,f,g,h,i,j,k,l,m){var _=this
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
xw:function xw(d,e){this.c=d
this.a=e},
aw5:function aw5(){},
H8:function H8(d,e,f,g,h,i,j){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.a=j},
a_9:function a_9(d){this.a=d},
Uq:function Uq(d,e,f,g,h,i,j){var _=this
_.co=d
_.cu=$
_.y1=e
_.y2=f
_.cr$=g
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
agg(d,e,f){var x,w,v=f.a,u=e.a,t=Math.pow(v[0]-u[0],2)+Math.pow(v[1]-u[1],2)
if(t===0)return e
x=d.a0(0,e)
w=f.a0(0,e)
return e.Z(0,w.kx(A.v(x.oQ(w)/t,0,1)))},
aZE(d,e){var x,w,v,u,t,s,r,q=e.a,p=d.a0(0,q),o=e.b,n=o.a0(0,q),m=e.d,l=m.a0(0,q),k=p.oQ(n),j=n.oQ(n),i=p.oQ(l),h=l.oQ(l)
if(0<=k&&k<=j&&0<=i&&i<=h)return d
x=e.c
w=[B.agg(d,q,o),B.agg(d,o,x),B.agg(d,x,m),B.agg(d,m,q)]
v=A.bi("closestOverall")
for(q=d.a,u=1/0,t=0;t<4;++t){s=w[t]
o=s.a
r=Math.sqrt(Math.pow(q[0]-o[0],2)+Math.pow(q[1]-o[1],2))
if(r<u){v.b=s
u=r}}return v.b8()},
b2o(){var x=new A.aP(new Float64Array(16))
x.cQ()
return new B.Wy(x,$.aA())},
aRs(d,e,f){return Math.log(f/d)/Math.log(e/100)},
aRY(d,e){var x,w,v,u,t,s,r=new A.aP(new Float64Array(16))
r.br(d)
r.hg(r)
x=e.a
w=e.b
v=new A.bM(new Float64Array(3))
v.dP(x,w,0)
v=r.lg(v)
u=e.c
t=new A.bM(new Float64Array(3))
t.dP(u,w,0)
t=r.lg(t)
w=e.d
s=new A.bM(new Float64Array(3))
s.dP(u,w,0)
s=r.lg(s)
u=new A.bM(new Float64Array(3))
u.dP(x,w,0)
u=r.lg(u)
x=new A.bM(new Float64Array(3))
x.br(v)
w=new A.bM(new Float64Array(3))
w.br(t)
v=new A.bM(new Float64Array(3))
v.br(s)
t=new A.bM(new Float64Array(3))
t.br(u)
return new B.TT(x,w,v,t)},
aRn(d,e){var x,w,v,u,t,s,r=[e.a,e.b,e.c,e.d]
for(x=C.f,w=0;w<4;++w){v=r[w]
u=B.aZE(v,d).a
t=v.a
s=u[0]-t[0]
t=u[1]-t[1]
if(Math.abs(s)>Math.abs(x.a))x=new A.i(s,x.b)
if(Math.abs(t)>Math.abs(x.b))x=new A.i(x.a,t)}return B.aKa(x)},
aKa(d){return new A.i(A.pz(C.d.ar(d.a,9)),A.pz(C.d.ar(d.b,9)))},
b5t(d,e){if(d.j(0,e))return null
return Math.abs(e.a-d.a)>Math.abs(e.b-d.b)?C.bR:C.b4},
BR:function BR(d,e,f,g){var _=this
_.w=d
_.at=e
_.ax=f
_.a=g},
HY:function HY(d,e,f,g){var _=this
_.d=$
_.e=d
_.f=e
_.w=_.r=null
_.z=_.y=_.x=$
_.at=_.as=_.Q=null
_.ay=_.ax=0
_.ch=null
_.dm$=f
_.bi$=g
_.c=_.a=null},
azm:function azm(){},
a1d:function a1d(d,e,f,g,h,i,j){var _=this
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h
_.w=i
_.a=j},
Wy:function Wy(d,e){var _=this
_.a=d
_.a3$=0
_.ai$=e
_.ab$=_.ba$=0},
HH:function HH(d,e){this.a=d
this.b=e},
al9:function al9(d,e){this.a=d
this.b=e},
KE:function KE(){},
b_X(d){return new B.Tk(d,0,null,null,A.a([],y.F),$.aA())},
Tk:function Tk(d,e,f,g,h,i){var _=this
_.as=d
_.a=e
_.c=f
_.d=g
_.f=h
_.a3$=0
_.ai$=i
_.ab$=_.ba$=0},
vN:function vN(d,e,f,g,h,i,j){var _=this
_.r=d
_.a=e
_.b=f
_.c=g
_.d=h
_.e=i
_.f=j},
pf:function pf(d,e,f,g,h,i,j,k,l){var _=this
_.aA=d
_.aN=null
_.ca=e
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
_.ai$=l
_.ab$=_.ba$=0},
HD:function HD(d,e){this.b=d
this.a=e},
Dd:function Dd(d){this.a=d},
De:function De(d,e,f,g){var _=this
_.r=d
_.y=e
_.z=f
_.a=g},
a2c:function a2c(){var _=this
_.d=0
_.e=$
_.c=_.a=null},
aAB:function aAB(d){this.a=d},
aAC:function aAC(d,e){this.a=d
this.b=e},
VM:function VM(d,e,f,g){var _=this
_.c=d
_.d=e
_.e=f
_.a=g},
a4J:function a4J(d,e,f){this.f=d
this.d=e
this.a=f},
a4K:function a4K(d,e,f){this.e=d
this.c=e
this.a=f},
a3F:function a3F(d,e,f){var _=this
_.ee=null
_.C=d
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
TT:function TT(d,e,f,g){var _=this
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
B.Bb.prototype={
aw(){var x="Campeonato Internacional",w=y.s,v=y.N,u=y.z
return new B.a0m(A.a([A.ag(["title","Brisas Cup 360","subtitle",x,"location","Panam\xe1","year",2025,"cover","assets/img/webp/main.webp","description","Experiencia internacional de alto nivel con clubes invitados de la regi\xf3n. Desarrollo competitivo y vitrina para talento joven.","images",A.a(["assets/img/eventos/panama2025/2025_1_thumb.webp","assets/img/eventos/panama2025/2025_2_thumb.webp","assets/img/eventos/panama2025/2025_3_thumb.webp","assets/img/eventos/panama2025/2025_4_thumb.webp","assets/img/eventos/panama2025/2025_5_thumb.webp","assets/img/eventos/panama2025/2025_6_thumb.webp","assets/img/eventos/panama2025/2025_7_thumb.webp"],w)],v,u),A.ag(["title","Caribe Champions","subtitle",x,"location","Barranquilla","year",2024,"cover","assets/img/eventosWebp/2024_1.webp","description","Torneo de referencia en el Caribe colombiano. Intensidad, disciplina y juego colectivo enfrentando a escuelas top del litoral.","images",A.a(["assets/img/eventos/barranquilla2024/2024_1_thumb.webp","assets/img/eventos/barranquilla2024/2024_2_thumb.webp","assets/img/eventos/barranquilla2024/2024_3_thumb.webp"],w)],v,u),A.ag(["title","Sporturs Soccer Cup","subtitle",x,"location","Medell\xedn","year",2023,"cover","assets/img/eventosWebp/2023_3.webp","description","Competencia con metodolog\xeda formativa y enfoque en el fair play. Gran oportunidad para medici\xf3n de rendimiento y convivencia.","images",A.a(["assets/img/eventos/medellin2023/2023_1_thumb.webp","assets/img/eventos/medellin2023/2023_2_thumb.webp","assets/img/eventos/medellin2023/2023_3_thumb.webp"],w)],v,u)],y.t))}}
B.a0m.prototype={
agC(d){var x,w=d.h(0,"images")
if(w==null)w=[]
x=A.iL(w,!0,y.N)
w=this.c
w.toString
A.tZ(null,!0,new B.axt(this,d,x),w,y.z)},
agD(d,e){var x,w={},v=B.b_X(e)
w.a=e
x=this.c
x.toString
A.tZ(A.aK(217,C.p.E()>>>16&255,C.p.E()>>>8&255,C.p.E()&255),!0,new B.axC(w,this,v,d),x,y.z)},
ND(d,e,f,g){return A.fW(d,new B.axq(d,g,f),e,f,g)},
a6N(d,e){return this.ND(d,e,null,null)},
I(d){var x=null,w=A.bo(d,x,y.w).w
return A.Ej(I.iX,new F.Cg(new A.wx(new B.axE(this,w.a.a>=1000),4,!0,!0,!0,x),C.aZ,C.b4,!1,x,x,C.hz,x,!1,x,0,x,4,C.aq,x,x,C.Z,C.aB,x))}}
B.a0l.prototype={
I(d){var x,w,v=this,u=null,t=y.p
if(v.y){x=A.a([],t)
w=v.z
if(!w)x.push(A.c6(new B.xw(v.r,u),5))
x.push(A.dx(u,u,24))
x.push(A.c6(new B.H8(v.c,v.d,v.e,v.f,v.w,v.x,u),5))
if(w)C.b.H(x,A.a([C.pC,A.c6(new B.xw(v.r,u),5)],t))
t=A.c8(x,C.E,C.t,C.C)}else t=A.c5(A.a([new B.xw(v.r,u),C.bj,new B.H8(v.c,v.d,v.e,v.f,v.w,v.x,u)],t),C.bU,C.t,C.C)
return A.ci(u,A.d1(new A.ct(C.ce,new A.br(K.jL,t,u),u),u,u),C.u,C.qF,u,u,u,u,u,u,u,u,u)}}
B.xw.prototype={
I(d){var x=null
return new A.hc(1.7777777777777777,A.iv(A.d0(16),A.fH(C.cb,A.a([A.fW(this.c,new B.aw5(),C.bS,x,x),A.aJ1(0,A.q5(x,new A.cs(x,x,x,x,x,new A.kK(C.dl,C.eB,C.cl,A.a([A.aK(64,C.p.E()>>>16&255,C.p.E()>>>8&255,C.p.E()&255),C.L],y.O),x,x),C.an),C.dT))],y.p),C.Z,C.iT,x),C.aI),x)}}
B.H8.prototype={
I(d){var x,w=this,v=null,u=A.E(d).ok,t=A.d0(16),s=u.f
s=s==null?v:s.fn(C.bw)
x=y.p
return A.zP(new A.br(C.r7,A.c5(A.a([A.aH(w.c,v,v,v,s,v,v),C.ex,A.aH(w.d,v,v,v,u.w,v,v),C.aC,A.c8(A.a([D.a0u,H.hn,A.aH(w.e+" "+w.f,v,v,v,u.z,v,v)],x),C.E,C.t,C.C),C.aW,A.aH(w.r,v,v,v,u.y,v,v),C.bj,new A.dA(C.dO,v,v,A.rb(D.a0y,D.alj,w.w),v)],x),C.bU,C.t,C.C),v),v,0.8,new A.cy(t,C.y))}}
B.a_9.prototype={
I(d){var x=null,w=A.E(d).ax,v=w.d
return A.ci(x,A.d1(new A.ct(C.ce,A.ci(x,D.al9,C.u,x,x,new A.cs((v==null?w.b:v).bg(0.35),x,x,A.d0(12),x,x,C.an),x,x,x,C.fs,x,x,x),x),x,x),C.u,C.n,x,x,x,x,x,C.r5,x,x,x)}}
B.Uq.prototype={
gw7(){return y.S.a(A.n.prototype.gY.call(this)).y*this.co},
sx0(d){if(this.co===d)return
this.co=d
this.a2()}}
B.BR.prototype={
aw(){var x=null,w=y.A
return new B.HY(new A.bp(x,w),new A.bp(x,w),x,x)}}
B.HY.prototype={
gcd(){var x=this.d
if(x===$){this.a.toString
x=B.b2o()
this.d=x}return x},
gxQ(){var x,w=$.ae.az$.x.h(0,this.e).ga1()
w.toString
x=y.x.a(w).gp()
this.a.toString
return C.aZ.w_(new A.u(0,0,0+x.a,0+x.b))},
gzx(){var x=$.ae.az$.x.h(0,this.f).ga1()
x.toString
x=y.x.a(x).gp()
return new A.u(0,0,0+x.a,0+x.b)},
qt(a0,a1){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this
if(a1.j(0,C.f)){x=new A.aP(new Float64Array(16))
x.br(a0)
return x}if(d.Q!=null){d.a.toString
switch(3){case 3:break}}w=new A.aP(new Float64Array(16))
w.br(a0)
w.cm(a1.a,a1.b)
v=B.aRY(w,d.gzx())
if(d.gxQ().gYh(0))return w
x=d.gxQ()
u=d.ay
t=new A.aP(new Float64Array(16))
t.cQ()
s=x.c
r=x.a
q=s-r
p=x.d
x=x.b
o=p-x
t.cm(q/2,o/2)
t.nE(u)
t.cm(-q/2,-o/2)
u=new A.bM(new Float64Array(3))
u.dP(r,x,0)
u=t.lg(u)
q=new A.bM(new Float64Array(3))
q.dP(s,x,0)
q=t.lg(q)
x=new A.bM(new Float64Array(3))
x.dP(s,p,0)
x=t.lg(x)
s=new A.bM(new Float64Array(3))
s.dP(r,p,0)
s=t.lg(s)
r=new Float64Array(3)
new A.bM(r).br(u)
u=new Float64Array(3)
new A.bM(u).br(q)
q=new Float64Array(3)
new A.bM(q).br(x)
x=new Float64Array(3)
new A.bM(x).br(s)
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
x=new A.bM(new Float64Array(3))
x.dP(m,l,0)
u=new A.bM(new Float64Array(3))
u.dP(k,l,0)
s=new A.bM(new Float64Array(3))
s.dP(k,j,0)
r=new A.bM(new Float64Array(3))
r.dP(m,j,0)
q=new A.bM(new Float64Array(3))
q.br(x)
x=new A.bM(new Float64Array(3))
x.br(u)
u=new A.bM(new Float64Array(3))
u.br(s)
s=new A.bM(new Float64Array(3))
s.br(r)
i=new B.TT(q,x,u,s)
h=B.aRn(i,v)
if(h.j(0,C.f))return w
x=w.CN().a
u=x[0]
x=x[1]
g=a0.pF()
u-=h.a*g
x-=h.b*g
f=new A.aP(new Float64Array(16))
f.br(a0)
s=new A.bM(new Float64Array(3))
s.dP(u,x,0)
f.LZ(s)
e=B.aRn(i,B.aRY(f,d.gzx()))
if(e.j(0,C.f))return f
s=e.a===0
if(!s&&e.b!==0){x=new A.aP(new Float64Array(16))
x.br(a0)
return x}u=s?u:0
x=e.b===0?x:0
s=new A.aP(new Float64Array(16))
s.br(a0)
r=new A.bM(new Float64Array(3))
r.dP(u,x,0)
s.LZ(r)
return s},
Fr(d,e){var x,w,v,u,t,s,r,q=this
if(e===1){x=new A.aP(new Float64Array(16))
x.br(d)
return x}w=q.gcd().a.pF()
x=q.gzx()
v=q.gxQ()
u=q.gzx()
t=q.gxQ()
s=Math.max(w*e,Math.max((x.c-x.a)/(v.c-v.a),(u.d-u.b)/(t.d-t.b)))
t=q.a
r=A.v(s,t.ax,t.at)
x=new A.aP(new Float64Array(16))
x.br(d)
x.bw(r/w)
return x},
af0(d,e,f){var x,w,v,u
if(e===0){x=new A.aP(new Float64Array(16))
x.br(d)
return x}w=this.gcd().ik(f)
x=new A.aP(new Float64Array(16))
x.br(d)
v=w.a
u=w.b
x.cm(v,u)
x.nE(-e)
x.cm(-v,-u)
return x},
ya(d){var x
$label0$0:{x=!0
if(D.aq7===d){x=!1
break $label0$0}if(D.pX===d){this.a.toString
break $label0$0}if(D.j3===d||d==null){this.a.toString
break $label0$0}x=null}return x},
Px(d){this.a.toString
if(Math.abs(d.d-1)>Math.abs(0))return D.pX
else return D.j3},
ag6(d){var x,w,v=this
v.a.toString
x=v.y
x===$&&A.b()
w=x.r
if(w!=null&&w.a!=null){x.eQ()
x=v.y
x.sn(x.a)
x=v.r
if(x!=null)x.a.L(v.gyk())
v.r=null}x=v.z
x===$&&A.b()
w=x.r
if(w!=null&&w.a!=null){x.eQ()
x=v.z
x.sn(x.a)
x=v.w
if(x!=null)x.a.L(v.gyo())
v.w=null}v.Q=v.ch=null
v.at=v.gcd().a.pF()
v.as=v.gcd().ik(d.b)
v.ax=v.ay},
ag8(d){var x,w,v,u,t,s,r=this,q=r.gcd().a.pF(),p=r.x=d.c,o=r.gcd().ik(p),n=r.ch
if(n===D.j3)n=r.ch=r.Px(d)
else if(n==null){n=r.Px(d)
r.ch=n}if(!r.ya(n)){r.a.toString
return}switch(r.ch.a){case 1:n=r.at
n.toString
r.gcd().sn(r.Fr(r.gcd().a,n*d.d/q))
x=r.gcd().ik(p)
n=r.gcd()
w=r.gcd().a
v=r.as
v.toString
n.sn(r.qt(w,x.a0(0,v)))
u=r.gcd().ik(p)
p=r.as
p.toString
if(!B.aKa(p).j(0,B.aKa(u)))r.as=u
break
case 2:n=d.r
if(n===0){r.a.toString
return}w=r.ax
w.toString
t=w+n
r.gcd().sn(r.af0(r.gcd().a,r.ay-t,p))
r.ay=t
break
case 0:if(d.d!==1){r.a.toString
return}if(r.Q==null){n=r.as
n.toString
r.Q=B.b5t(n,o)}n=r.as
n.toString
s=o.a0(0,n)
r.gcd().sn(r.qt(r.gcd().a,s))
r.as=r.gcd().ik(p)
break}r.a.toString},
ag4(d){var x,w,v,u,t,s,r,q,p,o,n,m,l=this
l.a.toString
l.as=l.ax=l.at=null
x=l.r
if(x!=null)x.a.L(l.gyk())
x=l.w
if(x!=null)x.a.L(l.gyo())
x=l.y
x===$&&A.b()
x.sn(x.a)
x=l.z
x===$&&A.b()
x.sn(x.a)
if(!l.ya(l.ch)){l.Q=null
return}$label0$0:{w=l.ch
if(D.j3===w){x=d.a.a
if(x.gcU()<50){l.Q=null
return}v=l.gcd().a.CN().a
u=v[0]
v=v[1]
l.a.toString
t=A.aeA(0.0000135,u,x.a,0)
l.a.toString
s=A.aeA(0.0000135,v,x.b,0)
x=x.gcU()
l.a.toString
r=B.aRs(x,0.0000135,10)
x=t.grB()
q=s.grB()
p=y.L
o=A.cj(C.dQ,l.y,null)
l.r=new A.aV(o,new A.aC(new A.i(u,v),new A.i(x,q),p),p.i("aV<aD.T>"))
l.y.e=A.du(0,0,C.d.aY(r*1000))
o.a4(l.gyk())
l.y.cv()
break $label0$0}if(D.pX===w){x=d.b
v=Math.abs(x)
if(v<0.1){l.Q=null
return}n=l.gcd().a.pF()
l.a.toString
m=A.aeA(0.0026999999999999997,n,x/10,0)
l.a.toString
r=B.aRs(v,0.0000135,0.1)
x=m.eN(r)
v=y.Y
u=A.cj(C.dQ,l.z,null)
l.w=new A.aV(u,new A.aC(n,x,v),v.i("aV<aD.T>"))
l.z.e=A.du(0,0,C.d.aY(r*1000))
u.a4(l.gyo())
l.z.cv()
break $label0$0}break $label0$0}},
aet(d){var x,w,v,u,t,s,r,q=this,p=d.gdg(),o=d.gb1()
if(y.C.b(d)){x=d.gcF()===C.bC
if(x)q.a.toString
if(x){q.a.toString
x=o.Z(0,d.gln())
w=d.gln()
v=A.ri(d.gcc(),null,w,x)
if(!q.ya(D.j3)){q.a.toString
return}u=q.gcd().ik(p)
t=q.gcd().ik(p.a0(0,v))
q.gcd().sn(q.qt(q.gcd().a,t.a0(0,u)))
q.a.toString
return}if(d.gln().b===0)return
x=d.gln()
q.a.toString
s=Math.exp(-x.b/200)}else if(y.X.b(d))s=d.ghs()
else return
q.a.toString
if(!q.ya(D.pX)){q.a.toString
return}u=q.gcd().ik(p)
q.gcd().sn(q.Fr(q.gcd().a,s))
r=q.gcd().ik(p)
q.gcd().sn(q.qt(q.gcd().a,r.a0(0,u)))
q.a.toString},
ac0(){var x,w,v,u,t,s=this,r=s.y
r===$&&A.b()
r=r.r
if(!(r!=null&&r.a!=null)){s.Q=null
r=s.r
if(r!=null)r.a.L(s.gyk())
s.r=null
r=s.y
r.sn(r.a)
return}r=s.gcd().a.CN().a
x=r[0]
r=r[1]
w=s.gcd()
v=s.gcd().a
u=s.gcd()
t=s.r
w.sn(s.qt(v,u.ik(t.b.ao(t.a.gn())).a0(0,s.gcd().ik(new A.i(x,r)))))},
acV(){var x,w,v,u,t,s=this,r=s.z
r===$&&A.b()
r=r.r
if(!(r!=null&&r.a!=null)){s.Q=null
r=s.w
if(r!=null)r.a.L(s.gyo())
s.w=null
r=s.z
r.sn(r.a)
return}r=s.w
x=r.b.ao(r.a.gn())
r=s.gcd().a.pF()
w=s.gcd()
v=s.x
v===$&&A.b()
u=w.ik(v)
s.gcd().sn(s.Fr(s.gcd().a,x/r))
t=s.gcd().ik(s.x)
s.gcd().sn(s.qt(s.gcd().a,t.a0(0,u)))},
adW(){this.aq(new B.azm())},
aR(){var x=this,w=null
x.b9()
x.y=A.bY(w,w,w,w,x)
x.z=A.bY(w,w,w,w,x)
x.gcd().a4(x.gQu())},
b3(d){this.bl(d)
this.a.toString
return},
l(){var x=this,w=x.y
w===$&&A.b()
w.l()
w=x.z
w===$&&A.b()
w.l()
x.gcd().L(x.gQu())
x.a.toString
w=x.gcd()
w.ai$=$.aA()
w.a3$=0
x.a5j()},
I(d){var x,w,v,u=this,t=null
u.a.toString
x=u.gcd().a
w=u.a.w
v=new B.a1d(w,u.e,C.Z,!0,x,t,t)
return A.vu(C.cH,A.kD(C.aB,v,C.aq,!1,t,t,t,t,t,t,t,t,t,u.gag3(),u.gag5(),u.gag7(),t,t,t,t,t,t,t,t,t,t,t,!1,new A.i(0,-0.005)),u.f,t,t,t,u.gaes(),t)}}
B.a1d.prototype={
I(d){var x=this,w=A.G0(x.w,new A.jB(x.c,x.d),null,x.r,!0)
return A.A7(w,x.e,null)}}
B.Wy.prototype={
ik(d){var x=this.a,w=new A.aP(new Float64Array(16))
if(w.hg(x)===0)A.an(A.fx(x,"other","Matrix cannot be inverted"))
x=new A.bM(new Float64Array(3))
x.dP(d.a,d.b,0)
x=w.lg(x).a
return new A.i(x[0],x[1])}}
B.HH.prototype={
J(){return"_GestureType."+this.b}}
B.al9.prototype={
J(){return"PanAxis."+this.b}}
B.KE.prototype={
c8(){this.d7()
this.d0()
this.eB()},
l(){var x=this,w=x.bi$
if(w!=null)w.L(x.geo())
x.bi$=null
x.aZ()}}
B.Tk.prototype={
V1(d,e,f){var x=y.g.a(C.b.ght(this.f))
if(x.aN!=null){x.aN=d
return A.cp(null,y.H)}if(x.ax==null){x.aA=d
return A.cp(null,y.H)}return x.iC(x.tl(d),e,f)},
HY(d,e,f){var x=null,w=$.aA()
w=new B.pf(this.as,1,C.hl,d,e,!0,x,new A.c1(!1,w),w)
w.DA(e,x,!0,f,d)
w.DB(e,x,x,!0,f,d)
return w},
av(d){this.a3q(d)
y.g.a(d).sx0(1)}}
B.vN.prototype={}
B.pf.prototype={
vD(d,e,f,g,h,i){return this.a3C(d,e,f,g,h,null)},
sx0(d){var x,w=this
if(w.ca===d)return
x=w.gBO()
w.ca=d
if(x!=null)w.IN(w.tl(x))},
gyv(){var x=this.ax
x.toString
return Math.max(0,x*(this.ca-1)/2)},
x6(d,e){var x=Math.max(0,d-this.gyv())/(e*this.ca),w=C.d.ZN(x)
if(Math.abs(x-w)<1e-10)return w
return x},
tl(d){var x=this.ax
x.toString
return d*x*this.ca+this.gyv()},
gBO(){var x,w,v=this,u=v.at
if(u==null)return null
x=v.z
if(x!=null&&v.Q!=null||v.ay){w=v.aN
if(w==null){x.toString
w=v.Q
w.toString
w=A.v(u,x,w)
x=v.ax
x.toString
x=v.x6(w,x)
u=x}else u=w}else u=null
return u},
LD(){var x,w,v=this,u=v.w,t=u.c
t.toString
t=A.al3(t)
if(t!=null){u=u.c
u.toString
x=v.aN
if(x==null){x=v.at
x.toString
w=v.ax
w.toString
w=v.x6(x,w)
x=w}t.a_F(u,x)}},
ZI(){var x,w,v
if(this.at==null){x=this.w
w=x.c
w.toString
w=A.al3(w)
if(w==null)v=null
else{x=x.c
x.toString
v=w.Zi(x)}if(v!=null)this.aA=v}},
LC(){var x,w=this,v=w.aN
if(v==null){v=w.at
v.toString
x=w.ax
x.toString
x=w.x6(v,x)
v=x}w.w.r.sn(v)
v=$.e0.dw$
v===$&&A.b()
v.Xb()},
ZH(d,e){if(e)this.aA=d
else this.eJ(this.tl(d))},
n2(d){var x,w,v,u,t=this,s=t.ax
s=s!=null?s:null
if(d===s)return!0
t.a3y(d)
x=t.at
x=x!=null?x:null
if(x==null)w=t.aA
else if(s===0){v=t.aN
v.toString
w=v}else{s.toString
w=t.x6(x,s)}u=t.tl(w)
t.aN=d===0?w:null
if(u!==x){t.at=u
return!1}return!0},
lJ(d){var x
this.N_(d)
if(!(d instanceof B.pf))return
x=d.aN
if(x!=null)this.aN=x},
n1(d,e){var x=d+this.gyv()
return this.a3w(x,Math.max(x,e-this.gyv()))},
jZ(){var x,w,v,u,t,s,r=this,q=null,p=r.z
p=p!=null&&r.Q!=null?p:q
x=q
if(r.z!=null&&r.Q!=null){x=r.Q
x.toString}w=r.at
w=w!=null?w:q
v=r.ax
v=v!=null?v:q
u=r.w
t=u.a.c
s=r.ca
u=u.f
u===$&&A.b()
return new B.vN(s,p,x,w,v,t,u)},
$ivN:1}
B.HD.prototype={
kM(d){return new B.HD(!1,this.kO(d))},
glK(){return this.b}}
B.Dd.prototype={
kM(d){return new B.Dd(this.kO(d))},
aaI(d){var x,w
if(d instanceof B.pf){x=d.gBO()
x.toString
return x}x=d.at
x.toString
w=d.ax
w.toString
return x/w},
aaL(d,e){var x
if(d instanceof B.pf)return d.tl(e)
x=d.ax
x.toString
return e*x},
re(d,e){var x,w,v,u,t,s=this
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
if(x)return s.a3u(d,e)
v=s.nH(d)
u=s.aaI(d)
x=v.c
if(e<-x)u-=0.5
else if(e>x)u+=0.5
t=s.aaL(d,C.d.ZN(u))
x=d.at
x.toString
if(t!==x){x=s.gpR()
w=d.at
w.toString
return new A.ow(t,A.yv(x,w-t,e),v)}return null},
glK(){return!1}}
B.De.prototype={
aw(){return new B.a2c()}}
B.a2c.prototype={
aR(){var x,w=this
w.b9()
w.QH()
x=w.e
x===$&&A.b()
w.d=x.as},
l(){this.a.toString
this.aZ()},
QH(){var x=this.a.r
this.e=x},
b3(d){if(d.r!==this.a.r)this.QH()
this.bl(d)},
aar(d){var x
this.a.toString
switch(0){case 0:x=A.aHe(d.aD(y.I).w)
this.a.toString
return x}},
I(d){var x,w,v,u=this,t=null,s=u.aar(d)
u.a.toString
x=new B.Dd(D.abO.kO(t))
x=new B.HD(!1,t).kO(x)
u.a.toString
w=u.e
w===$&&A.b()
v=A.kU(d).W3(!1)
return new A.df(new B.aAB(u),A.aol(s,C.Z,w,C.aq,!1,C.aB,t,new B.HD(!1,x),t,v,t,new B.aAC(u,s)),t,y.R)}}
B.VM.prototype={
I(d){var x=this.c,w=A.v(1-x,0,1)
return new B.a4K(w/2,new B.a4J(x,this.e,null),null)}}
B.a4J.prototype={
aQ(d){var x=new B.Uq(this.f,y.d.a(d),A.t(y.q,y.x),0,null,null,A.a7())
x.aP()
return x},
aT(d,e){e.sx0(this.f)}}
B.a4K.prototype={
aQ(d){var x=new B.a3F(this.e,null,A.a7())
x.aP()
return x},
aT(d,e){e.sx0(this.e)}}
B.a3F.prototype={
sx0(d){var x=this
if(x.C===d)return
x.C=d
x.cV=null
x.a2()},
ghI(){return this.cV},
ajK(){var x,w,v=this
if(v.cV!=null&&J.d(v.ee,y.S.a(A.n.prototype.gY.call(v))))return
x=y.S
w=x.a(A.n.prototype.gY.call(v)).y*v.C
v.ee=x.a(A.n.prototype.gY.call(v))
switch(A.b6(x.a(A.n.prototype.gY.call(v)).a).a){case 0:x=new A.au(w,0,w,0)
break
case 1:x=new A.au(0,w,0,w)
break
default:x=null}v.cV=x
return},
bJ(){this.ajK()
this.MX()}}
B.TT.prototype={}
var z=a.updateTypes(["~()","~(Eo)","~(Ep)","~(wk)","~(eZ)"])
B.axt.prototype={
$1(d){var x,w,v,u,t,s=this,r=null,q=A.aH("Galer\xeda \u2014 "+A.k(s.b.h(0,"title")),r,r,r,r,r,r),p=s.c
if(p.length===0)p=D.abN
else{x=A.a([],y.p)
for(w=s.a,v=0;v<p.length;++v){u=p[v]
t=new A.aZ(8,8)
x.push(A.kD(r,new E.lX(u,new A.pV(new A.cr(t,t,t,t),C.aI,w.ND(u,C.bS,120,160),r),!1,r),C.aq,!1,r,r,r,r,r,r,r,r,r,r,r,r,r,r,r,r,new B.axr(w,p,v),r,r,r,r,r,r,!1,C.cN))}p=A.EV(A.k0(C.c9,x,12,12),r,r)}p=A.dx(p,r,560)
return A.u5(A.a([A.ib(C.fe,new B.axs(s.a),r)],y.p),p,q)},
$S:44}
B.axr.prototype={
$0(){var x=this.a,w=x.c
w.toString
A.cx(w,!1).f8(null)
x.agD(this.b,this.c)},
$S:0}
B.axs.prototype={
$0(){var x=this.a.c
x.toString
A.cx(x,!1).f8(null)
return null},
$S:0}
B.axC.prototype={
$1(d){var x=this
return new A.rY(new B.axB(x.a,x.b,x.c,x.d),null)},
$S:613}
B.axB.prototype={
$2(d,e){var x=this,w=null,v=x.c,u=x.a,t=x.d,s=A.a([A.kD(C.aB,w,C.aq,!1,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w,new B.axv(d),w,w,w,w,w,w,!1,C.cN),new B.De(v,new B.axw(u,e),new A.wx(new B.axx(x.b,t),t.length,!0,!0,!0,w),w),A.mr(w,A.lZ(w,w,D.a0e,w,w,new B.axy(d),w,A.m0(w,C.cV,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w),"Cerrar"),w,w,w,20,20,w)],y.p)
if(t.length>1)s.push(A.mr(w,A.lZ(w,w,D.a0B,w,w,new B.axz(u,t,v),w,A.m0(w,C.cV,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w),w),w,w,12,w,w,w))
if(t.length>1)s.push(A.mr(w,A.lZ(w,w,D.a0D,w,w,new B.axA(u,t,v),w,A.m0(w,C.cV,w,w,w,w,w,w,w,w,w,w,w,w,w,w,w),w),w,w,w,12,w,w))
v=t.length
if(v>1){t=A.d0(12)
s.push(A.mr(20,A.ci(w,A.aH(""+(u.a+1)+" / "+v,w,w,w,D.ai6,w,w),C.u,w,w,new A.cs(C.cV,w,w,t,w,w,C.an),w,w,w,D.Zt,w,w,w),w,w,w,w,w,w))}return A.fH(C.X,s,C.Z,C.cv,w)},
$S:614}
B.axv.prototype={
$0(){A.cx(this.a,!1).f8(null)
return null},
$S:0}
B.axw.prototype={
$1(d){return this.b.$1(new B.axu(this.a,d))},
$S:16}
B.axu.prototype={
$0(){return this.a.a=this.b},
$S:0}
B.axx.prototype={
$2(d,e){var x=this.b[e]
return A.d1(E.aN1(new B.BR(this.a.a6N(x,C.qo),5,1,null),x,!1),null,null)},
$S:615}
B.axy.prototype={
$0(){A.cx(this.a,!1).f8(null)
return null},
$S:0}
B.axz.prototype={
$0(){this.c.V1(C.h.f2(this.a.a-1,0,this.b.length-1),C.eK,C.aa)},
$S:0}
B.axA.prototype={
$0(){this.c.V1(C.h.f2(this.a.a+1,0,this.b.length-1),C.eK,C.aa)},
$S:0}
B.axq.prototype={
$3(d,e,f){var x=null
A.aH2().$1("NO se encontr\xf3 asset: "+this.a)
return A.ci(C.X,D.a0f,C.u,C.at,x,x,x,this.c,x,x,x,x,this.b)},
$S:21}
B.axE.prototype={
$2(d,e){var x,w
if(e===3)return new B.a_9(null)
x=this.a
w=x.d[e]
return new B.a0l(w.h(0,"title"),w.h(0,"subtitle"),w.h(0,"location"),w.h(0,"year"),w.h(0,"cover"),w.h(0,"description"),new B.axD(x,w),this.b,(e&1)===1,null)},
$S:616}
B.axD.prototype={
$0(){return this.a.agC(this.b)},
$S:0}
B.aw5.prototype={
$3(d,e,f){var x=null
return A.ci(C.X,C.rR,C.u,C.at,x,x,x,x,x,x,x,x,x)},
$S:21}
B.azm.prototype={
$0(){},
$S:0}
B.aAB.prototype={
$1(d){var x,w,v,u,t
if(d.cf$===0){this.a.a.toString
x=d instanceof A.iV}else x=!1
if(x){w=y.o.a(d.a)
x=w.c
x.toString
v=w.a
v.toString
u=w.b
u.toString
u=Math.max(0,A.v(x,v,u))
v=w.d
v.toString
t=C.d.aY(u/Math.max(1,v*w.r))
x=this.a
if(t!==x.d){x.d=t
x.a.y.$1(t)}}return!1},
$S:45}
B.aAC.prototype={
$2(d,e){var x=this.a,w=x.a
w.toString
x.e===$&&A.b()
return A.aPQ(0,this.b,0,C.UJ,null,C.Z,e,A.a([new B.VM(1,!0,w.z,null)],y.p))},
$S:617};(function aliases(){var x=B.KE.prototype
x.a5j=x.l})();(function installTearOffs(){var x=a._instance_1u,w=a._instance_0u
var v
x(v=B.HY.prototype,"gag5","ag6",1)
x(v,"gag7","ag8",2)
x(v,"gag3","ag4",3)
x(v,"gaes","aet",4)
w(v,"gyk","ac0",0)
w(v,"gyo","acV",0)
w(v,"gQu","adW",0)})();(function inheritance(){var x=a.mixinHard,w=a.inheritMany,v=a.inherit
w(A.Y,[B.Bb,B.BR,B.De])
w(A.a2,[B.a0m,B.KE,B.a2c])
w(A.fR,[B.axt,B.axC,B.axw,B.axq,B.aw5,B.aAB])
w(A.iw,[B.axr,B.axs,B.axv,B.axu,B.axy,B.axz,B.axA,B.axD,B.azm])
w(A.kp,[B.axB,B.axx,B.axE,B.aAC])
w(A.aa,[B.a0l,B.xw,B.H8,B.a_9,B.a1d,B.VM])
v(B.Uq,F.Ur)
v(B.HY,B.KE)
v(B.Wy,A.c1)
w(A.tt,[B.HH,B.al9])
v(B.Tk,A.hv)
v(B.vN,A.Py)
v(B.pf,A.ov)
w(A.ou,[B.HD,B.Dd])
v(B.a4J,A.jS)
v(B.a4K,A.aR)
v(B.a3F,A.w9)
v(B.TT,A.I)
x(B.KE,A.dG)})()
A.n6(b.typeUniverse,JSON.parse('{"Bb":{"Y":[],"e":[]},"a0m":{"a2":["Bb"]},"a0l":{"aa":[],"e":[]},"xw":{"aa":[],"e":[]},"H8":{"aa":[],"e":[]},"a_9":{"aa":[],"e":[]},"Uq":{"kS":[],"cq":[],"a9":["r","eQ"],"n":[],"ak":[],"a9.1":"eQ","a9.0":"r"},"BR":{"Y":[],"e":[]},"HY":{"a2":["BR"]},"a1d":{"aa":[],"e":[]},"Wy":{"c1":["aP"],"al":[]},"De":{"Y":[],"e":[]},"Tk":{"hv":[],"al":[]},"pf":{"i6":[],"vN":[],"fr":[],"al":[]},"a2c":{"a2":["De"]},"VM":{"aa":[],"e":[]},"a4J":{"jS":[],"aq":[],"e":[]},"a4K":{"aR":[],"aq":[],"e":[]},"a3F":{"cq":[],"aE":["cq"],"n":[],"ak":[]}}'))
var y=(function rtii(){var x=A.Z
return{I:x("fS"),O:x("o<H>"),t:x("o<aU<f,@>>"),F:x("o<i6>"),s:x("o<f>"),p:x("o<e>"),A:x("bp<a2<Y>>"),w:x("fj"),R:x("df<fG>"),o:x("vN"),X:x("rn"),C:x("oe"),x:x("r"),S:x("iY"),d:x("oG"),N:x("f"),L:x("aC<i>"),Y:x("aC<F>"),g:x("pf"),z:x("@"),q:x("m"),H:x("~")}})();(function constants(){D.Zt=new A.au(10,6,10,6)
D.a0e=new A.bz(C.xR,null,C.n,null,null)
D.a0f=new A.bz(G.xQ,48,C.cV,null,null)
D.a0u=new A.bz(C.rO,18,null,null,null)
D.a_S=new A.bG(58554,"MaterialIcons",!1)
D.a0y=new A.bz(D.a_S,null,null,null,null)
D.a_F=new A.bG(57694,"MaterialIcons",!0)
D.a0B=new A.bz(D.a_F,32,C.n,null,null)
D.a_G=new A.bG(57695,"MaterialIcons",!0)
D.a0D=new A.bz(D.a_G,32,C.n,null,null)
D.ald=new A.b0('Galer\xeda pr\xf3xima a publicarse.\nA\xf1ade im\xe1genes en img/eventos/ y reg\xedstralas en "images".',null,null,null,null,null,null,null,null)
D.abN=new A.br(C.r9,D.ald,null)
D.abO=new B.Dd(null)
D.arx=new B.al9(3,"free")
D.ai6=new A.p(!0,C.n,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
D.al9=new A.b0("\xa1Pr\xf3ximamente m\xe1s eventos!",null,null,C.c8,null,null,null,null,null)
D.alj=new A.b0("Ver galer\xeda",null,null,null,null,null,null,null,null)
D.j3=new B.HH(0,"pan")
D.pX=new B.HH(1,"scale")
D.aq7=new B.HH(2,"rotate")})()};
((a,b)=>{a[b]=a.current
a.eventLog.push({p:"main.dart.js_9",e:"endPart",h:b})})($__dart_deferred_initializers__,"JSQnaRidr+Y5qorjHlzf1/2XTH4=");