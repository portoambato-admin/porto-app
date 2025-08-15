((a,b,c)=>{a[b]=a[b]||{}
a[b][c]=a[b][c]||[]
a[b][c].push({p:"main.dart.js_3",e:"beginPart"})})(self,"$__dart_deferred_initializers__","eventLog")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={nk:function nk(d,e){this.a=d
this.b=e},
aLp(d,e,f,g,h,i,j,k){return new A.zf(d,h,j,f,k,e,g,i,null,null)},
pT:function pT(d,e){this.a=d
this.b=e},
r9:function r9(d,e){this.a=d
this.b=e},
zf:function zf(d,e,f,g,h,i,j,k,l,m){var _=this
_.r=d
_.y=e
_.z=f
_.Q=g
_.at=h
_.ay=i
_.c=j
_.d=k
_.e=l
_.a=m},
Zb:function Zb(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.fn$=d
_.cI$=e
_.c=_.a=null},
atG:function atG(){},
atH:function atH(){},
atI:function atI(){},
atJ:function atJ(){},
atK:function atK(){},
atL:function atL(){},
atM:function atM(){},
atN:function atN(){},
aOi(){var x=new Float64Array(4)
x[3]=1
return new A.oi(x)},
oi:function oi(d){this.a=d},
aHG(d){var x=new B.bd(d,1,C.P,-1)
return new B.dJ(x,x,x,x)}},E,D
B=c[0]
C=c[2]
A=a.updateHolder(c[10],A)
E=c[21]
D=c[13]
A.nk.prototype={
er(d){return B.pN(this.a,this.b,d)}}
A.pT.prototype={
er(d){var x=B.ir(this.a,this.b,d)
x.toString
return x}}
A.r9.prototype={
er(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.bL(new Float64Array(3)),a3=new B.bL(new Float64Array(3)),a4=A.aOi(),a5=A.aOi(),a6=new B.bL(new Float64Array(3)),a7=new B.bL(new Float64Array(3))
this.a.Wl(a2,a4,a6)
this.b.Wl(a3,a5,a7)
x=1-a8
w=a2.kv(x).a_(0,a3.kv(a8))
v=a4.kv(x).a_(0,a5.kv(a8))
u=new Float64Array(4)
t=new A.oi(u)
t.bu(v)
t.asL()
s=a6.kv(x).a_(0,a7.kv(a8))
x=new Float64Array(16)
v=new B.aP(x)
r=u[0]
q=u[1]
p=u[2]
o=u[3]
n=r+r
m=q+q
l=p+p
k=r*n
j=r*m
i=r*l
h=q*m
g=q*l
f=p*l
e=o*n
d=o*m
a0=o*l
a1=w.a
x[0]=1-(h+f)
x[1]=j+a0
x[2]=i-d
x[3]=0
x[4]=j-a0
x[5]=1-(k+f)
x[6]=g+e
x[7]=0
x[8]=i+d
x[9]=g-e
x[10]=1-(k+h)
x[11]=0
x[12]=a1[0]
x[13]=a1[1]
x[14]=a1[2]
x[15]=1
v.by(s)
return v}}
A.zf.prototype={
av(){return new A.Zb(null,null)}}
A.Zb.prototype={
lX(d){var x,w,v=this,u=null,t=v.CW
v.a.toString
x=y.b
v.CW=x.a(d.$3(t,u,new A.atG()))
t=v.cx
v.a.toString
w=y.f
v.cx=w.a(d.$3(t,u,new A.atH()))
t=y.d
v.cy=t.a(d.$3(v.cy,v.a.y,new A.atI()))
v.db=t.a(d.$3(v.db,v.a.z,new A.atJ()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.atK()))
t=v.dy
v.a.toString
v.dy=w.a(d.$3(t,u,new A.atL()))
v.fr=y.w.a(d.$3(v.fr,v.a.at,new A.atM()))
t=v.fx
v.a.toString
v.fx=x.a(d.$3(t,u,new A.atN()))},
J(d){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=o.gez(),l=o.CW
l=l==null?n:l.an(m.gp())
x=o.cx
x=x==null?n:x.an(m.gp())
w=o.cy
w=w==null?n:w.an(m.gp())
v=o.db
v=v==null?n:v.an(m.gp())
u=o.dx
u=u==null?n:u.an(m.gp())
t=o.dy
t=t==null?n:t.an(m.gp())
s=o.fr
s=s==null?n:s.an(m.gp())
r=o.fx
r=r==null?n:r.an(m.gp())
q=o.a
p=q.ay
return B.cg(l,q.r,p,n,u,w,v,n,t,x,s,r,n)}}
A.oi.prototype={
bu(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.aj(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
a0H(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
if(o>0){x=Math.sqrt(o+1)
r=this.a
r.$flags&2&&B.aj(r)
r[3]=x*0.5
x=0.5/x
r[0]=(s[5]-s[7])*x
r[1]=(s[6]-s[2])*x
r[2]=(s[1]-s[3])*x}else{if(r<q)w=q<p?2:1
else w=r<p?2:0
v=(w+1)%3
u=(w+2)%3
r=w*3
q=v*3
p=u*3
x=Math.sqrt(s[r+w]-s[q+v]-s[p+u]+1)
t=this.a
t.$flags&2&&B.aj(t)
t[w]=x*0.5
x=0.5/x
t[3]=(s[q+u]-s[p+v])*x
t[v]=(s[r+v]+s[q+w])*x
t[u]=(s[r+u]+s[p+w])*x}},
asL(){var x,w,v,u=Math.sqrt(this.gwe())
if(u===0)return 0
x=1/u
w=this.a
v=w[0]
w.$flags&2&&B.aj(w)
w[0]=v*x
w[1]=w[1]*x
w[2]=w[2]*x
w[3]=w[3]*x
return u},
gwe(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
gK(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
kv(d){var x=new Float64Array(4),w=new A.oi(x)
w.bu(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
al(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gawk(),a1=a0.h(0,3),a2=a0.h(0,2),a3=a0.h(0,1),a4=a0.h(0,0)
h=C.d.al(g,a4)
x=C.d.al(d,a1)
w=C.d.al(e,a2)
v=C.d.al(f,a3)
u=C.d.al(g,a3)
t=C.d.al(e,a1)
s=C.d.al(f,a4)
r=C.d.al(d,a2)
q=C.d.al(g,a2)
p=C.d.al(f,a1)
o=C.d.al(d,a3)
n=C.d.al(e,a4)
m=C.d.al(g,a1)
l=C.d.al(d,a4)
k=C.d.al(e,a3)
j=C.d.al(f,a2)
i=new Float64Array(4)
i[0]=h+x+w-v
i[1]=u+t+s-r
i[2]=q+p+o-n
i[3]=m-l-k-j
return new A.oi(i)},
a_(d,e){var x,w=new Float64Array(4),v=new A.oi(w)
v.bu(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
Z(d,e){var x,w=new Float64Array(4),v=new A.oi(w)
v.bu(this)
x=e.a
w[0]=w[0]-x[0]
w[1]=w[1]-x[1]
w[2]=w[2]-x[2]
w[3]=w[3]-x[3]
return v},
h(d,e){return this.a[e]},
m(d,e,f){var x=this.a
x.$flags&2&&B.aj(x)
x[e]=f},
k(d){var x=this.a
return B.k(x[0])+", "+B.k(x[1])+", "+B.k(x[2])+" @ "+B.k(x[3])}}
var z=a.updateTypes(["nk(@)","iA(@)","pT(@)","r9(@)"])
A.atG.prototype={
$1(d){return new A.nk(y.k.a(d),null)},
$S:z+0}
A.atH.prototype={
$1(d){return new D.iA(y.m.a(d),null)},
$S:z+1}
A.atI.prototype={
$1(d){return new B.lP(y.r.a(d),null)},
$S:134}
A.atJ.prototype={
$1(d){return new B.lP(y.r.a(d),null)},
$S:134}
A.atK.prototype={
$1(d){return new A.pT(y.a.a(d),null)},
$S:z+2}
A.atL.prototype={
$1(d){return new D.iA(y.m.a(d),null)},
$S:z+1}
A.atM.prototype={
$1(d){return new A.r9(y.E.a(d),null)},
$S:z+3}
A.atN.prototype={
$1(d){return new A.nk(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.aC,[A.nk,A.pT,A.r9])
w(A.zf,B.qN)
w(A.Zb,B.lE)
x(B.fB,[A.atG,A.atH,A.atI,A.atJ,A.atK,A.atL,A.atM,A.atN])
w(A.oi,B.F)})()
B.k8(b.typeUniverse,JSON.parse('{"nk":{"aC":["fR?"],"aG":["fR?"],"aG.T":"fR?","aC.T":"fR?"},"pT":{"aC":["a2"],"aG":["a2"],"aG.T":"a2","aC.T":"a2"},"r9":{"aC":["aP"],"aG":["aP"],"aG.T":"aP","aC.T":"aP"},"zf":{"Z":[],"e":[]},"Zb":{"a3":["zf"]}}'))
var y=(function rtii(){var x=B.Y
return{k:x("fR"),a:x("a2"),r:x("iy"),m:x("cX"),E:x("aP"),b:x("nk?"),e:x("pT?"),d:x("lP?"),f:x("iA?"),w:x("r9?")}})();(function constants(){E.L6=new B.i(0,7)})()};
((a,b)=>{a[b]=a.current
a.eventLog.push({p:"main.dart.js_3",e:"endPart",h:b})})($__dart_deferred_initializers__,"+HJtLzyYoBbBDRtFunjQ5u4lG0M=");