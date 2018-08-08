(function(){var supportsDirectProtoAccess=function(){var z=function(){}
z.prototype={p:{}}
var y=new z()
if(!(y.__proto__&&y.__proto__.p===z.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var x=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(x))return true}}catch(w){}return false}()
function map(a){a=Object.create(null)
a.x=0
delete a.x
return a}var A=map()
var B=map()
var C=map()
var D=map()
var E=map()
var F=map()
var G=map()
var H=map()
var J=map()
var K=map()
var L=map()
var M=map()
var N=map()
var O=map()
var P=map()
var Q=map()
var R=map()
var S=map()
var T=map()
var U=map()
var V=map()
var W=map()
var X=map()
var Y=map()
var Z=map()
function I(){}init()
function setupProgram(a,b,c){"use strict"
function generateAccessor(b0,b1,b2){var g=b0.split("-")
var f=g[0]
var e=f.length
var d=f.charCodeAt(e-1)
var a0
if(g.length>1)a0=true
else a0=false
d=d>=60&&d<=64?d-59:d>=123&&d<=126?d-117:d>=37&&d<=43?d-27:0
if(d){var a1=d&3
var a2=d>>2
var a3=f=f.substring(0,e-1)
var a4=f.indexOf(":")
if(a4>0){a3=f.substring(0,a4)
f=f.substring(a4+1)}if(a1){var a5=a1&2?"r":""
var a6=a1&1?"this":"r"
var a7="return "+a6+"."+f
var a8=b2+".prototype.g"+a3+"="
var a9="function("+a5+"){"+a7+"}"
if(a0)b1.push(a8+"$reflectable("+a9+");\n")
else b1.push(a8+a9+";\n")}if(a2){var a5=a2&2?"r,v":"v"
var a6=a2&1?"this":"r"
var a7=a6+"."+f+"=v"
var a8=b2+".prototype.s"+a3+"="
var a9="function("+a5+"){"+a7+"}"
if(a0)b1.push(a8+"$reflectable("+a9+");\n")
else b1.push(a8+a9+";\n")}}return f}function defineClass(a4,a5){var g=[]
var f="function "+a4+"("
var e="",d=""
for(var a0=0;a0<a5.length;a0++){var a1=a5[a0]
if(a1.charCodeAt(0)==48){a1=a1.substring(1)
var a2=generateAccessor(a1,g,a4)
d+="this."+a2+" = null;\n"}else{var a2=generateAccessor(a1,g,a4)
var a3="p_"+a2
f+=e
e=", "
f+=a3
d+="this."+a2+" = "+a3+";\n"}}if(supportsDirectProtoAccess)d+="this."+"$deferredAction"+"();"
f+=") {\n"+d+"}\n"
f+=a4+".builtin$cls=\""+a4+"\";\n"
f+="$desc=$collectedClasses."+a4+"[1];\n"
f+=a4+".prototype = $desc;\n"
if(typeof defineClass.name!="string")f+=a4+".name=\""+a4+"\";\n"
f+=g.join("")
return f}var z=supportsDirectProtoAccess?function(d,e){var g=d.prototype
g.__proto__=e.prototype
g.constructor=d
g["$is"+d.name]=d
return convertToFastObject(g)}:function(){function tmp(){}return function(a1,a2){tmp.prototype=a2.prototype
var g=new tmp()
convertToSlowObject(g)
var f=a1.prototype
var e=Object.keys(f)
for(var d=0;d<e.length;d++){var a0=e[d]
g[a0]=f[a0]}g["$is"+a1.name]=a1
g.constructor=a1
a1.prototype=g
return g}}()
function finishClasses(a5){var g=init.allClasses
a5.combinedConstructorFunction+="return [\n"+a5.constructorsList.join(",\n  ")+"\n]"
var f=new Function("$collectedClasses",a5.combinedConstructorFunction)(a5.collected)
a5.combinedConstructorFunction=null
for(var e=0;e<f.length;e++){var d=f[e]
var a0=d.name
var a1=a5.collected[a0]
var a2=a1[0]
a1=a1[1]
g[a0]=d
a2[a0]=d}f=null
var a3=init.finishedClasses
function finishClass(c2){if(a3[c2])return
a3[c2]=true
var a6=a5.pending[c2]
if(a6&&a6.indexOf("+")>0){var a7=a6.split("+")
a6=a7[0]
var a8=a7[1]
finishClass(a8)
var a9=g[a8]
var b0=a9.prototype
var b1=g[c2].prototype
var b2=Object.keys(b0)
for(var b3=0;b3<b2.length;b3++){var b4=b2[b3]
if(!u.call(b1,b4))b1[b4]=b0[b4]}}if(!a6||typeof a6!="string"){var b5=g[c2]
var b6=b5.prototype
b6.constructor=b5
b6.$isb=b5
b6.$deferredAction=function(){}
return}finishClass(a6)
var b7=g[a6]
if(!b7)b7=existingIsolateProperties[a6]
var b5=g[c2]
var b6=z(b5,b7)
if(b0)b6.$deferredAction=mixinDeferredActionHelper(b0,b6)
if(Object.prototype.hasOwnProperty.call(b6,"%")){var b8=b6["%"].split(";")
if(b8[0]){var b9=b8[0].split("|")
for(var b3=0;b3<b9.length;b3++){init.interceptorsByTag[b9[b3]]=b5
init.leafTags[b9[b3]]=true}}if(b8[1]){b9=b8[1].split("|")
if(b8[2]){var c0=b8[2].split("|")
for(var b3=0;b3<c0.length;b3++){var c1=g[c0[b3]]
c1.$nativeSuperclassTag=b9[0]}}for(b3=0;b3<b9.length;b3++){init.interceptorsByTag[b9[b3]]=b5
init.leafTags[b9[b3]]=false}}b6.$deferredAction()}if(b6.$ise)b6.$deferredAction()}var a4=Object.keys(a5.pending)
for(var e=0;e<a4.length;e++)finishClass(a4[e])}function finishAddStubsHelper(){var g=this
while(!g.hasOwnProperty("$deferredAction"))g=g.__proto__
delete g.$deferredAction
var f=Object.keys(g)
for(var e=0;e<f.length;e++){var d=f[e]
var a0=d.charCodeAt(0)
var a1
if(d!=="^"&&d!=="$reflectable"&&a0!==43&&a0!==42&&(a1=g[d])!=null&&a1.constructor===Array&&d!=="<>")addStubs(g,a1,d,false,[])}convertToFastObject(g)
g=g.__proto__
g.$deferredAction()}function mixinDeferredActionHelper(d,e){var g
if(e.hasOwnProperty("$deferredAction"))g=e.$deferredAction
return function foo(){if(!supportsDirectProtoAccess)return
var f=this
while(!f.hasOwnProperty("$deferredAction"))f=f.__proto__
if(g)f.$deferredAction=g
else{delete f.$deferredAction
convertToFastObject(f)}d.$deferredAction()
f.$deferredAction()}}function processClassData(b2,b3,b4){b3=convertToSlowObject(b3)
var g
var f=Object.keys(b3)
var e=false
var d=supportsDirectProtoAccess&&b2!="b"
for(var a0=0;a0<f.length;a0++){var a1=f[a0]
var a2=a1.charCodeAt(0)
if(a1==="i"){processStatics(init.statics[b2]=b3.i,b4)
delete b3.i}else if(a2===43){w[g]=a1.substring(1)
var a3=b3[a1]
if(a3>0)b3[g].$reflectable=a3}else if(a2===42){b3[g].$D=b3[a1]
var a4=b3.$methodsWithOptionalArguments
if(!a4)b3.$methodsWithOptionalArguments=a4={}
a4[a1]=g}else{var a5=b3[a1]
if(a1!=="^"&&a5!=null&&a5.constructor===Array&&a1!=="<>")if(d)e=true
else addStubs(b3,a5,a1,false,[])
else g=a1}}if(e)b3.$deferredAction=finishAddStubsHelper
var a6=b3["^"],a7,a8,a9=a6
var b0=a9.split(";")
a9=b0[1]?b0[1].split(","):[]
a8=b0[0]
a7=a8.split(":")
if(a7.length==2){a8=a7[0]
var b1=a7[1]
if(b1)b3.$S=function(b5){return function(){return init.types[b5]}}(b1)}if(a8)b4.pending[b2]=a8
b4.combinedConstructorFunction+=defineClass(b2,a9)
b4.constructorsList.push(b2)
b4.collected[b2]=[m,b3]
i.push(b2)}function processStatics(a4,a5){var g=Object.keys(a4)
for(var f=0;f<g.length;f++){var e=g[f]
if(e==="^")continue
var d=a4[e]
var a0=e.charCodeAt(0)
var a1
if(a0===43){v[a1]=e.substring(1)
var a2=a4[e]
if(a2>0)a4[a1].$reflectable=a2
if(d&&d.length)init.typeInformation[a1]=d}else if(a0===42){m[a1].$D=d
var a3=a4.$methodsWithOptionalArguments
if(!a3)a4.$methodsWithOptionalArguments=a3={}
a3[e]=a1}else if(typeof d==="function"){m[a1=e]=d
h.push(e)}else if(d.constructor===Array)addStubs(m,d,e,true,h)
else{a1=e
processClassData(e,d,a5)}}}function addStubs(b6,b7,b8,b9,c0){var g=0,f=g,e=b7[g],d
if(typeof e=="string")d=b7[++g]
else{d=e
e=b8}if(typeof d=="number"){f=d
d=b7[++g]}b6[b8]=b6[e]=d
var a0=[d]
d.$stubName=b8
c0.push(b8)
for(g++;g<b7.length;g++){d=b7[g]
if(typeof d!="function")break
if(!b9)d.$stubName=b7[++g]
a0.push(d)
if(d.$stubName){b6[d.$stubName]=d
c0.push(d.$stubName)}}for(var a1=0;a1<a0.length;g++,a1++)a0[a1].$callName=b7[g]
var a2=b7[g]
b7=b7.slice(++g)
var a3=b7[0]
var a4=(a3&1)===1
a3=a3>>1
var a5=a3>>1
var a6=(a3&1)===1
var a7=a3===3
var a8=a3===1
var a9=b7[1]
var b0=a9>>1
var b1=(a9&1)===1
var b2=a5+b0
var b3=b7[2]
if(typeof b3=="number")b7[2]=b3+c
if(b>0){var b4=3
for(var a1=0;a1<b0;a1++){if(typeof b7[b4]=="number")b7[b4]=b7[b4]+b
b4++}for(var a1=0;a1<b2;a1++){b7[b4]=b7[b4]+b
b4++}}var b5=2*b0+a5+3
if(a2){d=tearOff(a0,f,b7,b9,b8,a4)
b6[b8].$getter=d
d.$getterStub=true
if(b9)c0.push(a2)
b6[a2]=d
a0.push(d)
d.$stubName=a2
d.$callName=null}}function tearOffGetter(d,e,f,g,a0){return a0?new Function("funcs","applyTrampolineIndex","reflectionInfo","name","H","c","return function tearOff_"+g+y+++"(x) {"+"if (c === null) c = "+"H.a0"+"("+"this, funcs, applyTrampolineIndex, reflectionInfo, false, [x], name);"+"return new c(this, funcs[0], x, name);"+"}")(d,e,f,g,H,null):new Function("funcs","applyTrampolineIndex","reflectionInfo","name","H","c","return function tearOff_"+g+y+++"() {"+"if (c === null) c = "+"H.a0"+"("+"this, funcs, applyTrampolineIndex, reflectionInfo, false, [], name);"+"return new c(this, funcs[0], null, name);"+"}")(d,e,f,g,H,null)}function tearOff(d,e,f,a0,a1,a2){var g
return a0?function(){if(g===void 0)g=H.a0(this,d,e,f,true,[],a1).prototype
return g}:tearOffGetter(d,e,f,a1,a2)}var y=0
if(!init.libraries)init.libraries=[]
if(!init.mangledNames)init.mangledNames=map()
if(!init.mangledGlobalNames)init.mangledGlobalNames=map()
if(!init.statics)init.statics=map()
if(!init.typeInformation)init.typeInformation=map()
var x=init.libraries
var w=init.mangledNames
var v=init.mangledGlobalNames
var u=Object.prototype.hasOwnProperty
var t=a.length
var s=map()
s.collected=map()
s.pending=map()
s.constructorsList=[]
s.combinedConstructorFunction="function $reflectable(fn){fn.$reflectable=1;return fn};\n"+"var $desc;\n"
for(var r=0;r<t;r++){var q=a[r]
var p=q[0]
var o=q[1]
var n=q[2]
var m=q[3]
var l=q[4]
var k=!!q[5]
var j=l&&l["^"]
if(j instanceof Array)j=j[0]
var i=[]
var h=[]
processStatics(l,s)
x.push([p,o,i,h,n,j,k,m])}finishClasses(s)}I.a2=function(){}
var dart=[["","",,H,{"^":"",cj:{"^":"b;a"}}],["","",,J,{"^":"",
j:function(a){return void 0},
a7:function(a,b,c,d){return{i:a,p:b,e:c,x:d}},
H:function(a){var z,y,x,w,v
z=a[init.dispatchPropertyName]
if(z==null)if($.a4==null){H.c6()
z=a[init.dispatchPropertyName]}if(z!=null){y=z.p
if(!1===y)return z.i
if(!0===y)return a
x=Object.getPrototypeOf(a)
if(y===x)return z.i
if(z.e===x)throw H.c(P.az("Return interceptor for "+H.a(y(a,z))))}w=a.constructor
v=w==null?null:w[$.$get$Q()]
if(v!=null)return v
v=H.c9(a)
if(v!=null)return v
if(typeof a=="function")return C.p
y=Object.getPrototypeOf(a)
if(y==null)return C.f
if(y===Object.prototype)return C.f
if(typeof w=="function"){Object.defineProperty(w,$.$get$Q(),{value:C.c,enumerable:false,writable:true,configurable:true})
return C.c}return C.c},
e:{"^":"b;",
h:function(a){return"Instance of '"+H.y(a)+"'"},
"%":"ArrayBuffer|Blob|DOMError|File|MediaError|Navigator|NavigatorConcurrentHardware|NavigatorUserMediaError|OverconstrainedError|PositionError|SQLError"},
b7:{"^":"e;",
h:function(a){return String(a)},
$isbW:1},
b9:{"^":"e;",
h:function(a){return"null"},
$isV:1},
S:{"^":"e;",
h:["D",function(a){return String(a)}]},
bg:{"^":"S;"},
X:{"^":"S;"},
x:{"^":"S;",
h:function(a){var z=a[$.$get$ae()]
if(z==null)return this.D(a)
return"JavaScript function for "+H.a(J.B(z))},
$S:function(){return{func:1,opt:[,,,,,,,,,,,,,,,,]}}},
D:{"^":"e;$ti",
h:function(a){return P.ah(a,"[","]")},
gv:function(a){return new J.aX(a,a.length,0)},
gk:function(a){return a.length},
$ism:1,
i:{
b6:function(a,b){return J.w(H.K(a,[b]))},
w:function(a){a.fixed$length=Array
return a}}},
ci:{"^":"D;$ti"},
aX:{"^":"b;a,b,c,0d",
gn:function(){return this.d},
p:function(){var z,y,x
z=this.a
y=z.length
if(this.b!==y)throw H.c(H.cc(z))
x=this.c
if(x>=y){this.d=null
return!1}this.d=z[x]
this.c=x+1
return!0}},
O:{"^":"e;",
h:function(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
I:function(a,b){var z
if(a>0)z=this.H(a,b)
else{z=b>31?31:b
z=a>>z>>>0}return z},
H:function(a,b){return b>31?0:a>>>b},
A:function(a,b){if(typeof b!=="number")throw H.c(H.aH(b))
return a<b},
$isa8:1},
ai:{"^":"O;",$isa5:1},
b8:{"^":"O;"},
P:{"^":"e;",
G:function(a,b){if(b>=a.length)throw H.c(H.a1(a,b))
return a.charCodeAt(b)},
m:function(a,b){if(typeof b!=="string")throw H.c(P.aW(b,null,null))
return a+b},
C:function(a,b,c){if(c==null)c=a.length
if(b>c)throw H.c(P.W(b,null,null))
if(c>a.length)throw H.c(P.W(c,null,null))
return a.substring(b,c)},
B:function(a,b){return this.C(a,b,null)},
h:function(a){return a},
gk:function(a){return a.length},
$ist:1}}],["","",,H,{"^":"",bb:{"^":"b;a,b,c,0d",
gn:function(){return this.d},
p:function(){var z,y,x,w
z=this.a
y=J.aK(z)
x=y.gk(z)
if(this.b!==x)throw H.c(P.ad(z))
w=this.c
if(w>=x){this.d=null
return!1}this.d=y.L(z,w);++this.c
return!0}},ag:{"^":"b;"}}],["","",,H,{"^":"",
c1:function(a){return init.types[a]},
cy:function(a,b){var z
if(b!=null){z=b.x
if(z!=null)return z}return!!J.j(a).$isR},
a:function(a){var z
if(typeof a==="string")return a
if(typeof a==="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
z=J.B(a)
if(typeof z!=="string")throw H.c(H.aH(a))
return z},
y:function(a){var z,y,x,w,v,u,t,s,r
z=J.j(a)
y=z.constructor
if(typeof y=="function"){x=y.name
w=typeof x==="string"?x:null}else w=null
if(w==null||z===C.h||!!J.j(a).$isX){v=C.e(a)
if(v==="Object"){u=a.constructor
if(typeof u=="function"){t=String(u).match(/^\s*function\s*([\w$]*)\s*\(/)
s=t==null?null:t[1]
if(typeof s==="string"&&/^\w+$/.test(s))w=s}if(w==null)w=v}else w=v}w=w
if(w.length>1&&C.a.G(w,0)===36)w=C.a.B(w,1)
r=H.aN(H.a3(a),0,null)
return function(b,c){return b.replace(/[^<,> ]+/g,function(d){return c[d]||d})}(w+r,init.mangledGlobalNames)},
a6:function(a,b){if(a==null)J.L(a)
throw H.c(H.a1(a,b))},
a1:function(a,b){var z
if(typeof b!=="number"||Math.floor(b)!==b)return new P.q(!0,b,"index",null)
z=J.L(a)
if(b<0||b>=z)return P.b5(b,a,"index",null,z)
return P.W(b,"index",null)},
aH:function(a){return new P.q(!0,a,null,null)},
c:function(a){var z
if(a==null)a=new P.ak()
z=new Error()
z.dartException=a
if("defineProperty" in Object){Object.defineProperty(z,"message",{get:H.aS})
z.name=""}else z.toString=H.aS
return z},
aS:function(){return J.B(this.dartException)},
cc:function(a){throw H.c(P.ad(a))},
ce:function(a){var z,y,x,w,v,u,t,s,r,q,p,o,n,m,l
z=new H.cf(a)
if(a==null)return
if(typeof a!=="object")return a
if("dartException" in a)return z.$1(a.dartException)
else if(!("message" in a))return a
y=a.message
if("number" in a&&typeof a.number=="number"){x=a.number
w=x&65535
if((C.i.I(x,16)&8191)===10)switch(w){case 438:return z.$1(H.T(H.a(y)+" (Error "+w+")",null))
case 445:case 5007:return z.$1(H.aj(H.a(y)+" (Error "+w+")",null))}}if(a instanceof TypeError){v=$.$get$ao()
u=$.$get$ap()
t=$.$get$aq()
s=$.$get$ar()
r=$.$get$av()
q=$.$get$aw()
p=$.$get$at()
$.$get$as()
o=$.$get$ay()
n=$.$get$ax()
m=v.j(y)
if(m!=null)return z.$1(H.T(y,m))
else{m=u.j(y)
if(m!=null){m.method="call"
return z.$1(H.T(y,m))}else{m=t.j(y)
if(m==null){m=s.j(y)
if(m==null){m=r.j(y)
if(m==null){m=q.j(y)
if(m==null){m=p.j(y)
if(m==null){m=s.j(y)
if(m==null){m=o.j(y)
if(m==null){m=n.j(y)
l=m!=null}else l=!0}else l=!0}else l=!0}else l=!0}else l=!0}else l=!0}else l=!0
if(l)return z.$1(H.aj(y,m))}}return z.$1(new H.br(typeof y==="string"?y:""))}if(a instanceof RangeError){if(typeof y==="string"&&y.indexOf("call stack")!==-1)return new P.al()
y=function(b){try{return String(b)}catch(k){}return null}(a)
return z.$1(new P.q(!1,null,null,typeof y==="string"?y.replace(/^RangeError:\s*/,""):y))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof y==="string"&&y==="too much recursion")return new P.al()
return a},
c0:function(a){var z
if(a==null)return new H.aF(a)
z=a.$cachedTrace
if(z!=null)return z
return a.$cachedTrace=new H.aF(a)},
c8:function(a,b,c,d,e,f){switch(b){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw H.c(new P.bD("Unsupported number of arguments for wrapped closure"))},
A:function(a,b){var z
if(a==null)return
z=a.$identity
if(!!z)return z
z=function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,H.c8)
a.$identity=z
return z},
b0:function(a,b,c,d,e,f,g){var z,y,x,w,v,u,t,s,r,q,p,o,n,m
z=b[0]
y=z.$callName
if(!!J.j(d).$ism){z.$reflectionInfo=d
x=H.bj(z).r}else x=d
w=e?Object.create(new H.bm().constructor.prototype):Object.create(new H.a9(null,null,null,null).constructor.prototype)
w.$initialize=w.constructor
if(e)v=function(){this.$initialize()}
else{u=$.h
if(typeof u!=="number")return u.m()
$.h=u+1
u=new Function("a,b,c,d"+u,"this.$initialize(a,b,c,d"+u+")")
v=u}w.constructor=v
v.prototype=w
if(!e){t=f.length==1&&!0
s=H.ac(a,z,t)
s.$reflectionInfo=d}else{w.$static_name=g
s=z
t=!1}if(typeof x=="number")r=function(h,i){return function(){return h(i)}}(H.c1,x)
else if(typeof x=="function")if(e)r=x
else{q=t?H.ab:H.M
r=function(h,i){return function(){return h.apply({$receiver:i(this)},arguments)}}(x,q)}else throw H.c("Error in reflectionInfo.")
w.$S=r
w[y]=s
for(u=b.length,p=s,o=1;o<u;++o){n=b[o]
m=n.$callName
if(m!=null){n=e?n:H.ac(a,n,t)
w[m]=n}if(o===c){n.$reflectionInfo=d
p=n}}w["call*"]=p
w.$R=z.$R
w.$D=z.$D
return v},
aY:function(a,b,c,d){var z=H.M
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,z)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,z)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,z)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,z)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,z)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,z)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,z)}},
ac:function(a,b,c){var z,y,x,w,v,u,t
if(c)return H.b_(a,b)
z=b.$stubName
y=b.length
x=a[z]
w=b==null?x==null:b===x
v=!w||y>=27
if(v)return H.aY(y,!w,z,b)
if(y===0){w=$.h
if(typeof w!=="number")return w.m()
$.h=w+1
u="self"+w
w="return function(){var "+u+" = this."
v=$.r
if(v==null){v=H.C("self")
$.r=v}return new Function(w+H.a(v)+";return "+u+"."+H.a(z)+"();}")()}t="abcdefghijklmnopqrstuvwxyz".split("").splice(0,y).join(",")
w=$.h
if(typeof w!=="number")return w.m()
$.h=w+1
t+=w
w="return function("+t+"){return this."
v=$.r
if(v==null){v=H.C("self")
$.r=v}return new Function(w+H.a(v)+"."+H.a(z)+"("+t+");}")()},
aZ:function(a,b,c,d){var z,y
z=H.M
y=H.ab
switch(b?-1:a){case 0:throw H.c(H.bl("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,z,y)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,z,y)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,z,y)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,z,y)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,z,y)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,z,y)
default:return function(e,f,g,h){return function(){h=[g(this)]
Array.prototype.push.apply(h,arguments)
return e.apply(f(this),h)}}(d,z,y)}},
b_:function(a,b){var z,y,x,w,v,u,t,s
z=$.r
if(z==null){z=H.C("self")
$.r=z}y=$.aa
if(y==null){y=H.C("receiver")
$.aa=y}x=b.$stubName
w=b.length
v=a[x]
u=b==null?v==null:b===v
t=!u||w>=28
if(t)return H.aZ(w,!u,x,b)
if(w===1){z="return function(){return this."+H.a(z)+"."+H.a(x)+"(this."+H.a(y)+");"
y=$.h
if(typeof y!=="number")return y.m()
$.h=y+1
return new Function(z+y+"}")()}s="abcdefghijklmnopqrstuvwxyz".split("").splice(0,w-1).join(",")
z="return function("+s+"){return this."+H.a(z)+"."+H.a(x)+"(this."+H.a(y)+", "+s+");"
y=$.h
if(typeof y!=="number")return y.m()
$.h=y+1
return new Function(z+y+"}")()},
a0:function(a,b,c,d,e,f,g){var z,y
z=J.w(b)
y=!!J.j(d).$ism?J.w(d):d
return H.b0(a,z,c,y,!!e,f,g)},
cd:function(a){throw H.c(new P.b2(a))},
aL:function(a){return init.getIsolateTag(a)},
K:function(a,b){a.$ti=b
return a},
a3:function(a){if(a==null)return
return a.$ti},
cx:function(a,b,c){return H.aR(a["$as"+H.a(c)],H.a3(b))},
p:function(a,b){var z,y
if(a==null)return"dynamic"
if(a===-1)return"void"
if(typeof a==="object"&&a!==null&&a.constructor===Array)return a[0].builtin$cls+H.aN(a,1,b)
if(typeof a=="function")return a.builtin$cls
if(a===-2)return"dynamic"
if(typeof a==="number"){if(b==null||a<0||a>=b.length)return"unexpected-generic-index:"+H.a(a)
z=b.length
y=z-a-1
if(y<0||y>=z)return H.a6(b,y)
return H.a(b[y])}if('func' in a)return H.bK(a,b)
if('futureOr' in a)return"FutureOr<"+H.p("type" in a?a.type:null,b)+">"
return"unknown-reified-type"},
bK:function(a,b){var z,y,x,w,v,u,t,s,r,q,p,o,n,m,l,k,j,i,h
if("bounds" in a){z=a.bounds
if(b==null){b=H.K([],[P.t])
y=null}else y=b.length
x=b.length
for(w=z.length,v=w;v>0;--v)b.push("T"+(x+v))
for(u="<",t="",v=0;v<w;++v,t=", "){u+=t
s=b.length
r=s-v-1
if(r<0)return H.a6(b,r)
u=C.a.m(u,b[r])
q=z[v]
if(q!=null&&q!==P.b)u+=" extends "+H.p(q,b)}u+=">"}else{u=""
y=null}p=!!a.v?"void":H.p(a.ret,b)
if("args" in a){o=a.args
for(s=o.length,n="",m="",l=0;l<s;++l,m=", "){k=o[l]
n=n+m+H.p(k,b)}}else{n=""
m=""}if("opt" in a){j=a.opt
n+=m+"["
for(s=j.length,m="",l=0;l<s;++l,m=", "){k=j[l]
n=n+m+H.p(k,b)}n+="]"}if("named" in a){i=a.named
n+=m+"{"
for(s=H.bX(i),r=s.length,m="",l=0;l<r;++l,m=", "){h=s[l]
n=n+m+H.p(i[h],b)+(" "+H.a(h))}n+="}"}if(y!=null)b.length=y
return u+"("+n+") => "+p},
aN:function(a,b,c){var z,y,x,w,v,u
if(a==null)return""
z=new P.am("")
for(y=b,x="",w=!0,v="";y<a.length;++y,x=", "){z.a=v+x
u=a[y]
if(u!=null)w=!1
v=z.a+=H.p(u,c)}v="<"+z.h(0)+">"
return v},
aR:function(a,b){if(a==null)return b
a=a.apply(null,b)
if(a==null)return
if(typeof a==="object"&&a!==null&&a.constructor===Array)return a
if(typeof a=="function")return a.apply(null,b)
return b},
cw:function(a,b,c){return a.apply(b,H.aR(J.j(b)["$as"+H.a(c)],H.a3(b)))},
c9:function(a){var z,y,x,w,v,u
z=$.aM.$1(a)
y=$.G[z]
if(y!=null){Object.defineProperty(a,init.dispatchPropertyName,{value:y,enumerable:false,writable:true,configurable:true})
return y.i}x=$.I[z]
if(x!=null)return x
w=init.interceptorsByTag[z]
if(w==null){z=$.aG.$2(a,z)
if(z!=null){y=$.G[z]
if(y!=null){Object.defineProperty(a,init.dispatchPropertyName,{value:y,enumerable:false,writable:true,configurable:true})
return y.i}x=$.I[z]
if(x!=null)return x
w=init.interceptorsByTag[z]}}if(w==null)return
x=w.prototype
v=z[0]
if(v==="!"){y=H.J(x)
$.G[z]=y
Object.defineProperty(a,init.dispatchPropertyName,{value:y,enumerable:false,writable:true,configurable:true})
return y.i}if(v==="~"){$.I[z]=x
return x}if(v==="-"){u=H.J(x)
Object.defineProperty(Object.getPrototypeOf(a),init.dispatchPropertyName,{value:u,enumerable:false,writable:true,configurable:true})
return u.i}if(v==="+")return H.aP(a,x)
if(v==="*")throw H.c(P.az(z))
if(init.leafTags[z]===true){u=H.J(x)
Object.defineProperty(Object.getPrototypeOf(a),init.dispatchPropertyName,{value:u,enumerable:false,writable:true,configurable:true})
return u.i}else return H.aP(a,x)},
aP:function(a,b){var z=Object.getPrototypeOf(a)
Object.defineProperty(z,init.dispatchPropertyName,{value:J.a7(b,z,null,null),enumerable:false,writable:true,configurable:true})
return b},
J:function(a){return J.a7(a,!1,null,!!a.$isR)},
cb:function(a,b,c){var z=b.prototype
if(init.leafTags[a]===true)return H.J(z)
else return J.a7(z,c,null,null)},
c6:function(){if(!0===$.a4)return
$.a4=!0
H.c7()},
c7:function(){var z,y,x,w,v,u,t,s
$.G=Object.create(null)
$.I=Object.create(null)
H.c2()
z=init.interceptorsByTag
y=Object.getOwnPropertyNames(z)
if(typeof window!="undefined"){window
x=function(){}
for(w=0;w<y.length;++w){v=y[w]
u=$.aQ.$1(v)
if(u!=null){t=H.cb(v,z[v],u)
if(t!=null){Object.defineProperty(u,init.dispatchPropertyName,{value:t,enumerable:false,writable:true,configurable:true})
x.prototype=u}}}}for(w=0;w<y.length;++w){v=y[w]
if(/^[A-Za-z_]/.test(v)){s=z[v]
z["!"+v]=s
z["~"+v]=s
z["-"+v]=s
z["+"+v]=s
z["*"+v]=s}}},
c2:function(){var z,y,x,w,v,u,t
z=C.m()
z=H.o(C.j,H.o(C.o,H.o(C.d,H.o(C.d,H.o(C.n,H.o(C.k,H.o(C.l(C.e),z)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){y=dartNativeDispatchHooksTransformer
if(typeof y=="function")y=[y]
if(y.constructor==Array)for(x=0;x<y.length;++x){w=y[x]
if(typeof w=="function")z=w(z)||z}}v=z.getTag
u=z.getUnknownTag
t=z.prototypeForTag
$.aM=new H.c3(v)
$.aG=new H.c4(u)
$.aQ=new H.c5(t)},
o:function(a,b){return a(b)||b},
bi:{"^":"b;a,b,c,d,e,f,r,0x",i:{
bj:function(a){var z,y,x
z=a.$reflectionInfo
if(z==null)return
z=J.w(z)
y=z[0]
x=z[1]
return new H.bi(a,z,(y&2)===2,y>>2,x>>1,(x&1)===1,z[2])}}},
bp:{"^":"b;a,b,c,d,e,f",
j:function(a){var z,y,x
z=new RegExp(this.a).exec(a)
if(z==null)return
y=Object.create(null)
x=this.b
if(x!==-1)y.arguments=z[x+1]
x=this.c
if(x!==-1)y.argumentsExpr=z[x+1]
x=this.d
if(x!==-1)y.expr=z[x+1]
x=this.e
if(x!==-1)y.method=z[x+1]
x=this.f
if(x!==-1)y.receiver=z[x+1]
return y},
i:{
i:function(a){var z,y,x,w,v,u
a=a.replace(String({}),'$receiver$').replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
z=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(z==null)z=H.K([],[P.t])
y=z.indexOf("\\$arguments\\$")
x=z.indexOf("\\$argumentsExpr\\$")
w=z.indexOf("\\$expr\\$")
v=z.indexOf("\\$method\\$")
u=z.indexOf("\\$receiver\\$")
return new H.bp(a.replace(new RegExp('\\\\\\$arguments\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$argumentsExpr\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$expr\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$method\\\\\\$','g'),'((?:x|[^x])*)').replace(new RegExp('\\\\\\$receiver\\\\\\$','g'),'((?:x|[^x])*)'),y,x,w,v,u)},
F:function(a){return function($expr$){var $argumentsExpr$='$arguments$'
try{$expr$.$method$($argumentsExpr$)}catch(z){return z.message}}(a)},
au:function(a){return function($expr$){try{$expr$.$method$}catch(z){return z.message}}(a)}}},
bf:{"^":"f;a,b",
h:function(a){var z=this.b
if(z==null)return"NullError: "+H.a(this.a)
return"NullError: method not found: '"+z+"' on null"},
i:{
aj:function(a,b){return new H.bf(a,b==null?null:b.method)}}},
ba:{"^":"f;a,b,c",
h:function(a){var z,y
z=this.b
if(z==null)return"NoSuchMethodError: "+H.a(this.a)
y=this.c
if(y==null)return"NoSuchMethodError: method not found: '"+z+"' ("+H.a(this.a)+")"
return"NoSuchMethodError: method not found: '"+z+"' on '"+y+"' ("+H.a(this.a)+")"},
i:{
T:function(a,b){var z,y
z=b==null
y=z?null:b.method
return new H.ba(a,y,z?null:b.receiver)}}},
br:{"^":"f;a",
h:function(a){var z=this.a
return z.length===0?"Error":"Error: "+z}},
cf:{"^":"d:1;a",
$1:function(a){if(!!J.j(a).$isf)if(a.$thrownJsError==null)a.$thrownJsError=this.a
return a}},
aF:{"^":"b;a,0b",
h:function(a){var z,y
z=this.b
if(z!=null)return z
z=this.a
y=z!==null&&typeof z==="object"?z.stack:null
z=y==null?"":y
this.b=z
return z}},
d:{"^":"b;",
h:function(a){return"Closure '"+H.y(this).trim()+"'"},
gw:function(){return this},
gw:function(){return this}},
an:{"^":"d;"},
bm:{"^":"an;",
h:function(a){var z=this.$static_name
if(z==null)return"Closure of unknown static method"
return"Closure '"+z+"'"}},
a9:{"^":"an;a,b,c,d",
h:function(a){var z=this.c
if(z==null)z=this.a
return"Closure '"+H.a(this.d)+"' of "+("Instance of '"+H.y(z)+"'")},
i:{
M:function(a){return a.a},
ab:function(a){return a.c},
C:function(a){var z,y,x,w,v
z=new H.a9("self","target","receiver","name")
y=J.w(Object.getOwnPropertyNames(z))
for(x=y.length,w=0;w<x;++w){v=y[w]
if(z[v]===a)return v}}}},
bk:{"^":"f;a",
h:function(a){return"RuntimeError: "+H.a(this.a)},
i:{
bl:function(a){return new H.bk(a)}}},
c3:{"^":"d:1;a",
$1:function(a){return this.a(a)}},
c4:{"^":"d:2;a",
$2:function(a,b){return this.a(a,b)}},
c5:{"^":"d;a",
$1:function(a){return this.a(a)}}}],["","",,H,{"^":"",
bX:function(a){return J.b6(a?Object.keys(a):[],null)}}],["","",,H,{"^":"",
l:function(a,b,c){if(a>>>0!==a||a>=c)throw H.c(H.a1(b,a))},
be:{"^":"e;","%":"DataView;ArrayBufferView;U|aB|aC|bd|aD|aE|k"},
U:{"^":"be;",
gk:function(a){return a.length},
$isR:1,
$asR:I.a2},
bd:{"^":"aC;",
l:function(a,b){H.l(b,a,a.length)
return a[b]},
$asE:function(){return[P.aJ]},
$ism:1,
$asm:function(){return[P.aJ]},
"%":"Float32Array|Float64Array"},
k:{"^":"aE;",
$asE:function(){return[P.a5]},
$ism:1,
$asm:function(){return[P.a5]}},
cl:{"^":"k;",
l:function(a,b){H.l(b,a,a.length)
return a[b]},
"%":"Int16Array"},
cm:{"^":"k;",
l:function(a,b){H.l(b,a,a.length)
return a[b]},
"%":"Int32Array"},
cn:{"^":"k;",
l:function(a,b){H.l(b,a,a.length)
return a[b]},
"%":"Int8Array"},
co:{"^":"k;",
l:function(a,b){H.l(b,a,a.length)
return a[b]},
"%":"Uint16Array"},
cp:{"^":"k;",
l:function(a,b){H.l(b,a,a.length)
return a[b]},
"%":"Uint32Array"},
cq:{"^":"k;",
gk:function(a){return a.length},
l:function(a,b){H.l(b,a,a.length)
return a[b]},
"%":"CanvasPixelArray|Uint8ClampedArray"},
cr:{"^":"k;",
gk:function(a){return a.length},
l:function(a,b){H.l(b,a,a.length)
return a[b]},
"%":";Uint8Array"},
aB:{"^":"U+E;"},
aC:{"^":"aB+ag;"},
aD:{"^":"U+E;"},
aE:{"^":"aD+ag;"}}],["","",,P,{"^":"",
bv:function(){var z,y,x
z={}
if(self.scheduleImmediate!=null)return P.bT()
if(self.MutationObserver!=null&&self.document!=null){y=self.document.createElement("div")
x=self.document.createElement("span")
z.a=null
new self.MutationObserver(H.A(new P.bx(z),1)).observe(y,{childList:true})
return new P.bw(z,y,x)}else if(self.setImmediate!=null)return P.bU()
return P.bV()},
cs:[function(a){self.scheduleImmediate(H.A(new P.by(a),0))},"$1","bT",4,0,0],
ct:[function(a){self.setImmediate(H.A(new P.bz(a),0))},"$1","bU",4,0,0],
cu:[function(a){P.bH(0,a)},"$1","bV",4,0,0],
bM:function(){var z,y
for(;z=$.n,z!=null;){$.v=null
y=z.b
$.n=y
if(y==null)$.u=null
z.a.$0()}},
cv:[function(){$.Z=!0
try{P.bM()}finally{$.v=null
$.Z=!1
if($.n!=null)$.$get$Y().$1(P.aI())}},"$0","aI",0,0,4],
bQ:function(a){var z=new P.aA(a)
if($.n==null){$.u=z
$.n=z
if(!$.Z)$.$get$Y().$1(P.aI())}else{$.u.b=z
$.u=z}},
bR:function(a){var z,y,x
z=$.n
if(z==null){P.bQ(a)
$.v=$.u
return}y=new P.aA(a)
x=$.v
if(x==null){y.b=z
$.v=y
$.n=y}else{y.b=x.b
x.b=y
$.v=y
if(y.b==null)$.u=y}},
bN:function(a,b,c,d,e){var z={}
z.a=d
P.bR(new P.bO(z,e))},
bP:function(a,b,c,d,e){var z,y
y=$.z
if(y===c)return d.$1(e)
$.z=c
z=y
try{y=d.$1(e)
return y}finally{$.z=z}},
bx:{"^":"d:3;a",
$1:function(a){var z,y
z=this.a
y=z.a
z.a=null
y.$0()}},
bw:{"^":"d;a,b,c",
$1:function(a){var z,y
this.a.a=a
z=this.b
y=this.c
z.firstChild?z.removeChild(y):z.appendChild(y)}},
by:{"^":"d;a",
$0:function(){this.a.$0()}},
bz:{"^":"d;a",
$0:function(){this.a.$0()}},
bG:{"^":"b;a,0b,c",
E:function(a,b){if(self.setTimeout!=null)this.b=self.setTimeout(H.A(new P.bI(this,b),0),a)
else throw H.c(P.bt("`setTimeout()` not found."))},
i:{
bH:function(a,b){var z=new P.bG(!0,0)
z.E(a,b)
return z}}},
bI:{"^":"d;a,b",
$0:function(){var z=this.a
z.b=null
z.c=1
this.b.$0()}},
aA:{"^":"b;a,0b"},
bn:{"^":"b;"},
bJ:{"^":"b;"},
bO:{"^":"d;a,b",
$0:function(){var z,y,x
z=this.a
y=z.a
if(y==null){x=new P.ak()
z.a=x
z=x}else z=y
y=this.b
if(y==null)throw H.c(z)
x=H.c(z)
x.stack=y.h(0)
throw x}},
bE:{"^":"bJ;",
M:function(a,b){var z,y,x
try{if(C.b===$.z){a.$1(b)
return}P.bP(null,null,this,a,b)}catch(x){z=H.ce(x)
y=H.c0(x)
P.bN(null,null,this,z,y)}},
N:function(a,b){return this.M(a,b,null)},
K:function(a,b){return new P.bF(this,a,b)}},
bF:{"^":"d;a,b,c",
$1:function(a){return this.a.N(this.b,a)},
$S:function(){return{func:1,ret:-1,args:[this.c]}}}}],["","",,P,{"^":"",
ah:function(a,b,c){var z,y,x
if(P.bL(a))return b+"..."+c
z=new P.am(b)
y=$.$get$a_()
y.push(a)
try{x=z
x.a=P.bo(x.gq(),a,", ")}finally{if(0>=y.length)return H.a6(y,-1)
y.pop()}y=z
y.a=y.gq()+c
y=z.gq()
return y.charCodeAt(0)==0?y:y},
bL:function(a){var z,y
for(z=0;y=$.$get$a_(),z<y.length;++z)if(a===y[z])return!0
return!1},
E:{"^":"b;$ti",
gv:function(a){return new H.bb(a,this.gk(a),0)},
L:function(a,b){return this.l(a,b)},
h:function(a){return P.ah(a,"[","]")}}}],["","",,P,{"^":"",
b3:function(a){var z=J.j(a)
if(!!z.$isd)return z.h(a)
return"Instance of '"+H.y(a)+"'"},
af:function(a){if(typeof a==="number"||typeof a==="boolean"||null==a)return J.B(a)
if(typeof a==="string")return JSON.stringify(a)
return P.b3(a)},
bW:{"^":"b;",
h:function(a){return this?"true":"false"}},
"+bool":0,
aJ:{"^":"a8;"},
"+double":0,
f:{"^":"b;"},
ak:{"^":"f;",
h:function(a){return"Throw of null."}},
q:{"^":"f;a,b,c,d",
gu:function(){return"Invalid argument"+(!this.a?"(s)":"")},
gt:function(){return""},
h:function(a){var z,y,x,w,v,u
z=this.c
y=z!=null?" ("+z+")":""
z=this.d
x=z==null?"":": "+z
w=this.gu()+y+x
if(!this.a)return w
v=this.gt()
u=P.af(this.b)
return w+v+": "+H.a(u)},
i:{
aW:function(a,b,c){return new P.q(!0,a,b,c)}}},
bh:{"^":"q;e,f,a,b,c,d",
gu:function(){return"RangeError"},
gt:function(){var z,y,x
z=this.e
if(z==null){z=this.f
y=z!=null?": Not less than or equal to "+H.a(z):""}else{x=this.f
if(x==null)y=": Not greater than or equal to "+H.a(z)
else if(x>z)y=": Not in range "+H.a(z)+".."+H.a(x)+", inclusive"
else y=x<z?": Valid value range is empty":": Only valid value is "+H.a(z)}return y},
i:{
W:function(a,b,c){return new P.bh(null,null,!0,a,b,"Value not in range")}}},
b4:{"^":"q;e,k:f>,a,b,c,d",
gu:function(){return"RangeError"},
gt:function(){if(J.aT(this.b,0))return": index must not be negative"
var z=this.f
if(z===0)return": no indices are valid"
return": index should be less than "+z},
i:{
b5:function(a,b,c,d,e){var z=e!=null?e:J.L(b)
return new P.b4(b,z,!0,a,c,"Index out of range")}}},
bs:{"^":"f;a",
h:function(a){return"Unsupported operation: "+this.a},
i:{
bt:function(a){return new P.bs(a)}}},
bq:{"^":"f;a",
h:function(a){var z=this.a
return z!=null?"UnimplementedError: "+z:"UnimplementedError"},
i:{
az:function(a){return new P.bq(a)}}},
b1:{"^":"f;a",
h:function(a){var z=this.a
if(z==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+H.a(P.af(z))+"."},
i:{
ad:function(a){return new P.b1(a)}}},
al:{"^":"b;",
h:function(a){return"Stack Overflow"},
$isf:1},
b2:{"^":"f;a",
h:function(a){var z=this.a
return z==null?"Reading static variable during its initialization":"Reading static variable '"+z+"' during its initialization"}},
bD:{"^":"b;a",
h:function(a){return"Exception: "+this.a}},
a5:{"^":"a8;"},
"+int":0,
m:{"^":"b;$ti"},
"+List":0,
V:{"^":"b;",
h:function(a){return"null"}},
"+Null":0,
a8:{"^":"b;"},
"+num":0,
b:{"^":";",
h:function(a){return"Instance of '"+H.y(this)+"'"},
toString:function(){return this.h(this)}},
t:{"^":"b;"},
"+String":0,
am:{"^":"b;q:a<",
gk:function(a){return this.a.length},
h:function(a){var z=this.a
return z.charCodeAt(0)==0?z:z},
i:{
bo:function(a,b,c){var z=J.aV(b)
if(!z.p())return a
if(c.length===0){do a+=H.a(z.gn())
while(z.p())}else{a+=H.a(z.gn())
for(;z.p();)a=a+c+H.a(z.gn())}return a}}}}],["","",,W,{"^":"",
bu:function(a,b){var z=new WebSocket(a,b)
return z},
bS:function(a,b){var z=$.z
if(z===C.b)return a
return z.K(a,b)},
cg:{"^":"e;",
h:function(a){return String(a)},
"%":"DOMException"},
N:{"^":"e;",$isN:1,"%":"AbortPaymentEvent|AnimationEvent|AnimationPlaybackEvent|ApplicationCacheErrorEvent|AudioProcessingEvent|BackgroundFetchClickEvent|BackgroundFetchEvent|BackgroundFetchFailEvent|BackgroundFetchedEvent|BeforeInstallPromptEvent|BeforeUnloadEvent|BlobEvent|CanMakePaymentEvent|ClipboardEvent|CloseEvent|CompositionEvent|CustomEvent|DeviceMotionEvent|DeviceOrientationEvent|DragEvent|ErrorEvent|ExtendableEvent|ExtendableMessageEvent|FetchEvent|FocusEvent|FontFaceSetLoadEvent|ForeignFetchEvent|GamepadEvent|HashChangeEvent|IDBVersionChangeEvent|InstallEvent|KeyboardEvent|MIDIConnectionEvent|MIDIMessageEvent|MediaEncryptedEvent|MediaKeyMessageEvent|MediaQueryListEvent|MediaStreamEvent|MediaStreamTrackEvent|MojoInterfaceRequestEvent|MouseEvent|MutationEvent|NotificationEvent|OfflineAudioCompletionEvent|PageTransitionEvent|PaymentRequestEvent|PaymentRequestUpdateEvent|PointerEvent|PopStateEvent|PresentationConnectionAvailableEvent|PresentationConnectionCloseEvent|ProgressEvent|PromiseRejectionEvent|PushEvent|RTCDTMFToneChangeEvent|RTCDataChannelEvent|RTCPeerConnectionIceEvent|RTCTrackEvent|ResourceProgressEvent|SecurityPolicyViolationEvent|SensorErrorEvent|SpeechRecognitionError|SpeechRecognitionEvent|SpeechSynthesisEvent|StorageEvent|SyncEvent|TextEvent|TouchEvent|TrackEvent|TransitionEvent|UIEvent|USBConnectionEvent|VRDeviceEvent|VRDisplayEvent|VRSessionEvent|WebGLContextEvent|WebKitTransitionEvent|WheelEvent;Event|InputEvent"},
ch:{"^":"e;",
F:function(a,b,c,d){return a.addEventListener(b,H.A(c,1),!1)},
"%":"DOMWindow|EventTarget|WebSocket|Window"},
ck:{"^":"e;",
h:function(a){return String(a)},
"%":"Location"},
bc:{"^":"N;",$isbc:1,"%":"MessageEvent"},
bA:{"^":"bn;a,b,c,d,e",
J:function(){var z,y,x
z=this.d
y=z!=null
if(y&&this.a<=0){x=this.b
x.toString
if(y)J.aU(x,this.c,z,!1)}},
i:{
bB:function(a,b,c,d){var z=W.bS(new W.bC(c),W.N)
z=new W.bA(0,a,b,z,!1)
z.J()
return z}}},
bC:{"^":"d;a",
$1:function(a){return this.a.$1(a)}}}],["","",,P,{"^":""}],["","",,P,{"^":""}],["","",,P,{"^":""}],["","",,P,{"^":""}],["","",,Z,{"^":"",
aO:function(){W.bB(W.bu(C.a.m("ws://",window.location.host),H.K(["$livereload"],[P.t])),"message",new Z.ca(),!1)},
ca:{"^":"d;",
$1:function(a){window.location.reload()}}},1]]
setupProgram(dart,0,0)
J.j=function(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.ai.prototype
return J.b8.prototype}if(typeof a=="string")return J.P.prototype
if(a==null)return J.b9.prototype
if(typeof a=="boolean")return J.b7.prototype
if(a.constructor==Array)return J.D.prototype
if(typeof a!="object"){if(typeof a=="function")return J.x.prototype
return a}if(a instanceof P.b)return a
return J.H(a)}
J.aK=function(a){if(typeof a=="string")return J.P.prototype
if(a==null)return a
if(a.constructor==Array)return J.D.prototype
if(typeof a!="object"){if(typeof a=="function")return J.x.prototype
return a}if(a instanceof P.b)return a
return J.H(a)}
J.bY=function(a){if(a==null)return a
if(a.constructor==Array)return J.D.prototype
if(typeof a!="object"){if(typeof a=="function")return J.x.prototype
return a}if(a instanceof P.b)return a
return J.H(a)}
J.bZ=function(a){if(typeof a=="number")return J.O.prototype
if(a==null)return a
if(!(a instanceof P.b))return J.X.prototype
return a}
J.c_=function(a){if(a==null)return a
if(typeof a!="object"){if(typeof a=="function")return J.x.prototype
return a}if(a instanceof P.b)return a
return J.H(a)}
J.aT=function(a,b){if(typeof a=="number"&&typeof b=="number")return a<b
return J.bZ(a).A(a,b)}
J.aU=function(a,b,c,d){return J.c_(a).F(a,b,c,d)}
J.aV=function(a){return J.bY(a).gv(a)}
J.L=function(a){return J.aK(a).gk(a)}
J.B=function(a){return J.j(a).h(a)}
var $=I.p
C.h=J.e.prototype
C.i=J.ai.prototype
C.a=J.P.prototype
C.p=J.x.prototype
C.f=J.bg.prototype
C.c=J.X.prototype
C.b=new P.bE()
C.j=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
C.k=function(hooks) {
  var userAgent = typeof navigator == "object" ? navigator.userAgent : "";
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
C.d=function(hooks) { return hooks; }

C.l=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var ua = navigator.userAgent;
    if (ua.indexOf("DumpRenderTree") >= 0) return hooks;
    if (ua.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
C.m=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (self.HTMLElement && object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof navigator == "object";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
C.n=function(hooks) {
  var userAgent = typeof navigator == "object" ? navigator.userAgent : "";
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
C.o=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
C.e=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
$.h=0
$.r=null
$.aa=null
$.aM=null
$.aG=null
$.aQ=null
$.G=null
$.I=null
$.a4=null
$.n=null
$.u=null
$.v=null
$.Z=!1
$.z=C.b
$=null
init.isHunkLoaded=function(a){return!!$dart_deferred_initializers$[a]}
init.deferredInitialized=new Object(null)
init.isHunkInitialized=function(a){return init.deferredInitialized[a]}
init.initializeLoadedHunk=function(a){var z=$dart_deferred_initializers$[a]
if(z==null)throw"DeferredLoading state error: code with hash '"+a+"' was not loaded"
z($globals$,$)
init.deferredInitialized[a]=true}
init.deferredLibraryParts={}
init.deferredPartUris=[]
init.deferredPartHashes=[];(function(a){for(var z=0;z<a.length;){var y=a[z++]
var x=a[z++]
var w=a[z++]
I.$lazy(y,x,w)}})(["ae","$get$ae",function(){return H.aL("_$dart_dartClosure")},"Q","$get$Q",function(){return H.aL("_$dart_js")},"ao","$get$ao",function(){return H.i(H.F({
toString:function(){return"$receiver$"}}))},"ap","$get$ap",function(){return H.i(H.F({$method$:null,
toString:function(){return"$receiver$"}}))},"aq","$get$aq",function(){return H.i(H.F(null))},"ar","$get$ar",function(){return H.i(function(){var $argumentsExpr$='$arguments$'
try{null.$method$($argumentsExpr$)}catch(z){return z.message}}())},"av","$get$av",function(){return H.i(H.F(void 0))},"aw","$get$aw",function(){return H.i(function(){var $argumentsExpr$='$arguments$'
try{(void 0).$method$($argumentsExpr$)}catch(z){return z.message}}())},"at","$get$at",function(){return H.i(H.au(null))},"as","$get$as",function(){return H.i(function(){try{null.$method$}catch(z){return z.message}}())},"ay","$get$ay",function(){return H.i(H.au(void 0))},"ax","$get$ax",function(){return H.i(function(){try{(void 0).$method$}catch(z){return z.message}}())},"Y","$get$Y",function(){return P.bv()},"a_","$get$a_",function(){return[]}])
I=I.$finishIsolateConstructor(I)
$=new I()
init.metadata=[]
init.types=[{func:1,ret:-1,args:[{func:1,ret:-1}]},{func:1,args:[,]},{func:1,args:[,P.t]},{func:1,ret:P.V,args:[,]},{func:1,ret:-1}]
function convertToFastObject(a){function MyClass(){}MyClass.prototype=a
new MyClass()
return a}function convertToSlowObject(a){a.__MAGIC_SLOW_PROPERTY=1
delete a.__MAGIC_SLOW_PROPERTY
return a}A=convertToFastObject(A)
B=convertToFastObject(B)
C=convertToFastObject(C)
D=convertToFastObject(D)
E=convertToFastObject(E)
F=convertToFastObject(F)
G=convertToFastObject(G)
H=convertToFastObject(H)
J=convertToFastObject(J)
K=convertToFastObject(K)
L=convertToFastObject(L)
M=convertToFastObject(M)
N=convertToFastObject(N)
O=convertToFastObject(O)
P=convertToFastObject(P)
Q=convertToFastObject(Q)
R=convertToFastObject(R)
S=convertToFastObject(S)
T=convertToFastObject(T)
U=convertToFastObject(U)
V=convertToFastObject(V)
W=convertToFastObject(W)
X=convertToFastObject(X)
Y=convertToFastObject(Y)
Z=convertToFastObject(Z)
function init(){I.p=Object.create(null)
init.allClasses=map()
init.getTypeFromName=function(a){return init.allClasses[a]}
init.interceptorsByTag=map()
init.leafTags=map()
init.finishedClasses=map()
I.$lazy=function(a,b,c,d,e){if(!init.lazies)init.lazies=Object.create(null)
init.lazies[a]=b
e=e||I.p
var z={}
var y={}
e[a]=z
e[b]=function(){var x=this[a]
if(x==y)H.cd(d||a)
try{if(x===z){this[a]=y
try{x=this[a]=c()}finally{if(x===z)this[a]=null}}return x}finally{this[b]=function(){return this[a]}}}}
I.$finishIsolateConstructor=function(a){var z=a.p
function Isolate(){var y=Object.keys(z)
for(var x=0;x<y.length;x++){var w=y[x]
this[w]=z[w]}var v=init.lazies
var u=v?Object.keys(v):[]
for(var x=0;x<u.length;x++)this[v[u[x]]]=null
function ForceEfficientMap(){}ForceEfficientMap.prototype=this
new ForceEfficientMap()
for(var x=0;x<u.length;x++){var t=v[u[x]]
this[t]=z[t]}}Isolate.prototype=a.prototype
Isolate.prototype.constructor=Isolate
Isolate.p=z
Isolate.a2=a.a2
return Isolate}}!function(){var z=function(a){var t={}
t[a]=1
return Object.keys(convertToFastObject(t))[0]}
init.getIsolateTag=function(a){return z("___dart_"+a+init.isolateTag)}
var y="___dart_isolate_tags_"
var x=Object[y]||(Object[y]=Object.create(null))
var w="_ZxYxX"
for(var v=0;;v++){var u=z(w+"_"+v+"_")
if(!(u in x)){x[u]=1
init.isolateTag=u
break}}init.dispatchPropertyName=init.getIsolateTag("dispatch_record")}();(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!='undefined'){a(document.currentScript)
return}var z=document.scripts
function onLoad(b){for(var x=0;x<z.length;++x)z[x].removeEventListener("load",onLoad,false)
a(b.target)}for(var y=0;y<z.length;++y)z[y].addEventListener("load",onLoad,false)})(function(a){init.currentScript=a
if(typeof dartMainRunner==="function")dartMainRunner(Z.aO,[])
else Z.aO([])})})()
//# sourceMappingURL=hot_reload_client.dart.js.map
