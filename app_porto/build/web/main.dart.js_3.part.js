((a,b,c)=>{a[b]=a[b]||{}
a[b][c]=a[b][c]||[]
a[b][c].push({p:"main.dart.js_3",e:"beginPart"})})(self,"$__dart_deferred_initializers__","eventLog")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={ny:function ny(d,e){this.a=d
this.b=e},
aOQ(d,e,f,g,h,i,j,k){return new A.zY(d,h,j,f,k,e,g,i,null,null)},
qj:function qj(d,e){this.a=d
this.b=e},
rt:function rt(d,e){this.a=d
this.b=e},
zY:function zY(d,e,f,g,h,i,j,k,l,m){var _=this
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
a_j:function a_j(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.fP$=d
_.cO$=e
_.c=_.a=null},
awo:function awo(){},
awp:function awp(){},
awq:function awq(){},
awr:function awr(){},
aws:function aws(){},
awt:function awt(){},
awu:function awu(){},
awv:function awv(){},
aRQ(){var x=new Float64Array(4)
x[3]=1
return new A.oD(x)},
oD:function oD(d){this.a=d}},D
B=c[0]
C=c[2]
A=a.updateHolder(c[10],A)
D=c[18]
A.ny.prototype={
eN(d){return B.q9(this.a,this.b,d)}}
A.qj.prototype={
eN(d){var x=B.iF(this.a,this.b,d)
x.toString
return x}}
A.rt.prototype={
eN(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.bT(new Float64Array(3)),a3=new B.bT(new Float64Array(3)),a4=A.aRQ(),a5=A.aRQ(),a6=new B.bT(new Float64Array(3)),a7=new B.bT(new Float64Array(3))
this.a.XA(a2,a4,a6)
this.b.XA(a3,a5,a7)
x=1-a8
w=a2.kT(x).a1(0,a3.kT(a8))
v=a4.kT(x).a1(0,a5.kT(a8))
u=new Float64Array(4)
t=new A.oD(u)
t.bs(v)
t.x7()
s=a6.kT(x).a1(0,a7.kT(a8))
x=new Float64Array(16)
v=new B.aO(x)
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
A.zY.prototype={
ar(){return new A.a_j(null,null)}}
A.a_j.prototype={
mr(d){var x,w,v=this,u=null,t=v.CW
v.a.toString
x=y.b
v.CW=x.a(d.$3(t,u,new A.awo()))
t=v.cx
v.a.toString
w=y.f
v.cx=w.a(d.$3(t,u,new A.awp()))
t=y.d
v.cy=t.a(d.$3(v.cy,v.a.y,new A.awq()))
v.db=t.a(d.$3(v.db,v.a.z,new A.awr()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.aws()))
t=v.dy
v.a.toString
v.dy=w.a(d.$3(t,u,new A.awt()))
v.fr=y.w.a(d.$3(v.fr,v.a.at,new A.awu()))
t=v.fx
v.a.toString
v.fx=x.a(d.$3(t,u,new A.awv()))},
J(d){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=o.geX(),l=o.CW
l=l==null?n:l.aq(m.gq())
x=o.cx
x=x==null?n:x.aq(m.gq())
w=o.cy
w=w==null?n:w.aq(m.gq())
v=o.db
v=v==null?n:v.aq(m.gq())
u=o.dx
u=u==null?n:u.aq(m.gq())
t=o.dy
t=t==null?n:t.aq(m.gq())
s=o.fr
s=s==null?n:s.aq(m.gq())
r=o.fx
r=r==null?n:r.aq(m.gq())
q=o.a
p=q.ay
return B.cq(l,q.r,p,n,u,w,v,n,t,x,s,r,n)}}
A.oD.prototype={
bs(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.al(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
a20(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
if(o>0){x=Math.sqrt(o+1)
r=this.a
r.$flags&2&&B.al(r)
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
t.$flags&2&&B.al(t)
t[w]=x*0.5
x=0.5/x
t[3]=(s[q+u]-s[p+v])*x
t[v]=(s[r+v]+s[q+w])*x
t[u]=(s[r+u]+s[p+w])*x}},
x7(){var x,w,v,u=Math.sqrt(this.gwV())
if(u===0)return 0
x=1/u
w=this.a
v=w[0]
w.$flags&2&&B.al(w)
w[0]=v*x
w[1]=w[1]*x
w[2]=w[2]*x
w[3]=w[3]*x
return u},
gwV(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
gH(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
kT(d){var x=new Float64Array(4),w=new A.oD(x)
w.bs(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
aj(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gayk(),a1=a0.h(0,3),a2=a0.h(0,2),a3=a0.h(0,1),a4=a0.h(0,0)
h=C.d.aj(g,a4)
x=C.d.aj(d,a1)
w=C.d.aj(e,a2)
v=C.d.aj(f,a3)
u=C.d.aj(g,a3)
t=C.d.aj(e,a1)
s=C.d.aj(f,a4)
r=C.d.aj(d,a2)
q=C.d.aj(g,a2)
p=C.d.aj(f,a1)
o=C.d.aj(d,a3)
n=C.d.aj(e,a4)
m=C.d.aj(g,a1)
l=C.d.aj(d,a4)
k=C.d.aj(e,a3)
j=C.d.aj(f,a2)
i=new Float64Array(4)
i[0]=h+x+w-v
i[1]=u+t+s-r
i[2]=q+p+o-n
i[3]=m-l-k-j
return new A.oD(i)},
a1(d,e){var x,w=new Float64Array(4),v=new A.oD(w)
v.bs(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
a2(d,e){var x,w=new Float64Array(4),v=new A.oD(w)
v.bs(this)
x=e.a
w[0]=w[0]-x[0]
w[1]=w[1]-x[1]
w[2]=w[2]-x[2]
w[3]=w[3]-x[3]
return v},
h(d,e){return this.a[e]},
m(d,e,f){var x=this.a
x.$flags&2&&B.al(x)
x[e]=f},
k(d){var x=this.a
return B.k(x[0])+", "+B.k(x[1])+", "+B.k(x[2])+" @ "+B.k(x[3])}}
var z=a.updateTypes(["ny(@)","qj(@)","rt(@)"])
A.awo.prototype={
$1(d){return new A.ny(y.k.a(d),null)},
$S:z+0}
A.awp.prototype={
$1(d){return new B.kI(y.m.a(d),null)},
$S:111}
A.awq.prototype={
$1(d){return new B.m0(y.r.a(d),null)},
$S:229}
A.awr.prototype={
$1(d){return new B.m0(y.r.a(d),null)},
$S:229}
A.aws.prototype={
$1(d){return new A.qj(y.a.a(d),null)},
$S:z+1}
A.awt.prototype={
$1(d){return new B.kI(y.m.a(d),null)},
$S:111}
A.awu.prototype={
$1(d){return new A.rt(y.E.a(d),null)},
$S:z+2}
A.awv.prototype={
$1(d){return new A.ny(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.aH,[A.ny,A.qj,A.rt])
w(A.zY,B.Cm)
w(A.a_j,B.qa)
x(B.h1,[A.awo,A.awp,A.awq,A.awr,A.aws,A.awt,A.awu,A.awv])
w(A.oD,B.D)})()
B.no(b.typeUniverse,JSON.parse('{"ny":{"aH":["fY?"],"aI":["fY?"],"aH.T":"fY?","aI.T":"fY?"},"qj":{"aH":["a7"],"aI":["a7"],"aH.T":"a7","aI.T":"a7"},"rt":{"aH":["aO"],"aI":["aO"],"aH.T":"aO","aI.T":"aO"},"zY":{"W":[],"e":[]},"a_j":{"a1":["zY"]}}'))
var y=(function rtii(){var x=B.Y
return{k:x("fY"),a:x("a7"),r:x("iM"),m:x("db"),E:x("aO"),b:x("ny?"),e:x("qj?"),d:x("m0?"),f:x("kI?"),w:x("rt?")}})();(function constants(){D.LB=new B.j(0,7)})()};
((a,b)=>{a[b]=a.current
a.eventLog.push({p:"main.dart.js_3",e:"endPart",h:b})})($__dart_deferred_initializers__,"VC7M7OSsscJDkKe3yPC1CZ1/JsE=");