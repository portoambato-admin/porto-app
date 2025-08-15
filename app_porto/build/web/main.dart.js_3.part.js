((a,b,c)=>{a[b]=a[b]||{}
a[b][c]=a[b][c]||[]
a[b][c].push({p:"main.dart.js_3",e:"beginPart"})})(self,"$__dart_deferred_initializers__","eventLog")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={nh:function nh(d,e){this.a=d
this.b=e},
aLx(d,e,f,g,h,i,j,k){return new A.zd(d,h,j,f,k,e,g,i,null,null)},
pO:function pO(d,e){this.a=d
this.b=e},
r0:function r0(d,e){this.a=d
this.b=e},
zd:function zd(d,e,f,g,h,i,j,k,l,m){var _=this
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
Zf:function Zf(d,e){var _=this
_.fx=_.fr=_.dy=_.dx=_.db=_.cy=_.cx=_.CW=null
_.e=_.d=$
_.fq$=d
_.cK$=e
_.c=_.a=null},
atI:function atI(){},
atJ:function atJ(){},
atK:function atK(){},
atL:function atL(){},
atM:function atM(){},
atN:function atN(){},
atO:function atO(){},
atP:function atP(){},
aOt(){var x=new Float64Array(4)
x[3]=1
return new A.oh(x)},
oh:function oh(d){this.a=d}},D
B=c[0]
C=c[2]
A=a.updateHolder(c[10],A)
D=c[19]
A.nh.prototype={
es(d){return B.pH(this.a,this.b,d)}}
A.pO.prototype={
es(d){var x=B.is(this.a,this.b,d)
x.toString
return x}}
A.r0.prototype={
es(a8){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2=new B.bM(new Float64Array(3)),a3=new B.bM(new Float64Array(3)),a4=A.aOt(),a5=A.aOt(),a6=new B.bM(new Float64Array(3)),a7=new B.bM(new Float64Array(3))
this.a.Wn(a2,a4,a6)
this.b.Wn(a3,a5,a7)
x=1-a8
w=a2.kx(x).Z(0,a3.kx(a8))
v=a4.kx(x).Z(0,a5.kx(a8))
u=new Float64Array(4)
t=new A.oh(u)
t.br(v)
t.asT()
s=a6.kx(x).Z(0,a7.kx(a8))
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
v.bw(s)
return v}}
A.zd.prototype={
aw(){return new A.Zf(null,null)}}
A.Zf.prototype={
m3(d){var x,w,v=this,u=null,t=v.CW
v.a.toString
x=y.b
v.CW=x.a(d.$3(t,u,new A.atI()))
t=v.cx
v.a.toString
w=y.f
v.cx=w.a(d.$3(t,u,new A.atJ()))
t=y.d
v.cy=t.a(d.$3(v.cy,v.a.y,new A.atK()))
v.db=t.a(d.$3(v.db,v.a.z,new A.atL()))
v.dx=y.e.a(d.$3(v.dx,v.a.Q,new A.atM()))
t=v.dy
v.a.toString
v.dy=w.a(d.$3(t,u,new A.atN()))
v.fr=y.w.a(d.$3(v.fr,v.a.at,new A.atO()))
t=v.fx
v.a.toString
v.fx=x.a(d.$3(t,u,new A.atP()))},
I(d){var x,w,v,u,t,s,r,q,p,o=this,n=null,m=o.geA(),l=o.CW
l=l==null?n:l.ao(m.gn())
x=o.cx
x=x==null?n:x.ao(m.gn())
w=o.cy
w=w==null?n:w.ao(m.gn())
v=o.db
v=v==null?n:v.ao(m.gn())
u=o.dx
u=u==null?n:u.ao(m.gn())
t=o.dy
t=t==null?n:t.ao(m.gn())
s=o.fr
s=s==null?n:s.ao(m.gn())
r=o.fx
r=r==null?n:r.ao(m.gn())
q=o.a
p=q.ay
return B.ci(l,q.r,p,n,u,w,v,n,t,x,s,r,n)}}
A.oh.prototype={
br(d){var x=d.a,w=this.a,v=x[0]
w.$flags&2&&B.aj(w)
w[0]=v
w[1]=x[1]
w[2]=x[2]
w[3]=x[3]},
a0J(d){var x,w,v,u,t,s=d.a,r=s[0],q=s[4],p=s[8],o=0+r+q+p
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
asT(){var x,w,v,u=Math.sqrt(this.gwb())
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
gwb(){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return w*w+v*v+u*u+t*t},
gK(d){var x=this.a,w=x[0],v=x[1],u=x[2],t=x[3]
return Math.sqrt(w*w+v*v+u*u+t*t)},
kx(d){var x=new Float64Array(4),w=new A.oh(x)
w.br(this)
x[3]=x[3]*d
x[2]=x[2]*d
x[1]=x[1]*d
x[0]=x[0]*d
return w},
am(a5,a6){var x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=h[3],f=h[2],e=h[1],d=h[0],a0=a6.gawm(),a1=a0.h(0,3),a2=a0.h(0,2),a3=a0.h(0,1),a4=a0.h(0,0)
h=C.d.am(g,a4)
x=C.d.am(d,a1)
w=C.d.am(e,a2)
v=C.d.am(f,a3)
u=C.d.am(g,a3)
t=C.d.am(e,a1)
s=C.d.am(f,a4)
r=C.d.am(d,a2)
q=C.d.am(g,a2)
p=C.d.am(f,a1)
o=C.d.am(d,a3)
n=C.d.am(e,a4)
m=C.d.am(g,a1)
l=C.d.am(d,a4)
k=C.d.am(e,a3)
j=C.d.am(f,a2)
i=new Float64Array(4)
i[0]=h+x+w-v
i[1]=u+t+s-r
i[2]=q+p+o-n
i[3]=m-l-k-j
return new A.oh(i)},
Z(d,e){var x,w=new Float64Array(4),v=new A.oh(w)
v.br(this)
x=e.a
w[0]=w[0]+x[0]
w[1]=w[1]+x[1]
w[2]=w[2]+x[2]
w[3]=w[3]+x[3]
return v},
a0(d,e){var x,w=new Float64Array(4),v=new A.oh(w)
v.br(this)
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
var z=a.updateTypes(["nh(@)","pO(@)","r0(@)"])
A.atI.prototype={
$1(d){return new A.nh(y.k.a(d),null)},
$S:z+0}
A.atJ.prototype={
$1(d){return new B.ku(y.m.a(d),null)},
$S:92}
A.atK.prototype={
$1(d){return new B.lJ(y.r.a(d),null)},
$S:161}
A.atL.prototype={
$1(d){return new B.lJ(y.r.a(d),null)},
$S:161}
A.atM.prototype={
$1(d){return new A.pO(y.a.a(d),null)},
$S:z+1}
A.atN.prototype={
$1(d){return new B.ku(y.m.a(d),null)},
$S:92}
A.atO.prototype={
$1(d){return new A.r0(y.E.a(d),null)},
$S:z+2}
A.atP.prototype={
$1(d){return new A.nh(y.k.a(d),null)},
$S:z+0};(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.aC,[A.nh,A.pO,A.r0])
w(A.zd,B.vg)
w(A.Zf,B.pI)
x(B.fR,[A.atI,A.atJ,A.atK,A.atL,A.atM,A.atN,A.atO,A.atP])
w(A.oh,B.I)})()
B.n6(b.typeUniverse,JSON.parse('{"nh":{"aC":["fP?"],"aD":["fP?"],"aD.T":"fP?","aC.T":"fP?"},"pO":{"aC":["a5"],"aD":["a5"],"aD.T":"a5","aC.T":"a5"},"r0":{"aC":["aP"],"aD":["aP"],"aD.T":"aP","aC.T":"aP"},"zd":{"Y":[],"e":[]},"Zf":{"a2":["zd"]}}'))
var y=(function rtii(){var x=B.Z
return{k:x("fP"),a:x("a5"),r:x("iA"),m:x("d4"),E:x("aP"),b:x("nh?"),e:x("pO?"),d:x("lJ?"),f:x("ku?"),w:x("r0?")}})();(function constants(){D.La=new B.i(0,7)})()};
((a,b)=>{a[b]=a.current
a.eventLog.push({p:"main.dart.js_3",e:"endPart",h:b})})($__dart_deferred_initializers__,"0NtsK/rlOy8KNpexkuWKIAwplNU=");