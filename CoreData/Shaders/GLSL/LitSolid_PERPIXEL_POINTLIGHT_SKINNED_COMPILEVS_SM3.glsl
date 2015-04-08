uniform vec3 cAmbientStartColor ;
uniform vec3 cAmbientEndColor ;
uniform mat3 cBillboardRot ;
uniform vec3 cCameraPos ;
uniform mat3 cCameraRot ;
uniform float cNearClip ;
uniform float cFarClip ;
uniform vec4 cDepthMode ;
uniform vec3 cFrustumSize ;
uniform float cDeltaTime ;
uniform float cElapsedTime ;
uniform vec4 cGBufferOffsets ;
uniform vec3 cLightDir ;
uniform vec4 cLightPos ;
uniform mat4 cModel ;
uniform mat4 cViewProj ;
uniform vec4 cUOffset ;
uniform vec4 cVOffset ;
uniform mat4 cZone ;
uniform mat4 cLightMatrices [ 4 ] ;
uniform vec4 cSkinMatrices [ 64 * 3 ] ;
attribute vec4 iPos ;
attribute vec3 iNormal ;
attribute vec4 iColor ;
attribute vec2 iTexCoord ;
attribute vec2 iTexCoord2 ;
attribute vec4 iTangent ;
attribute vec4 iBlendWeights ;
attribute vec4 iBlendIndices ;
attribute vec3 iCubeTexCoord ;
attribute vec4 iCubeTexCoord2 ;
attribute vec4 iInstanceMatrix1 ;
attribute vec4 iInstanceMatrix2 ;
attribute vec4 iInstanceMatrix3 ;
mat4 GetSkinMatrix ( vec4 blendWeights , vec4 blendIndices )
{
    ivec4 idx = ivec4 ( blendIndices ) * 3 ;
    const vec4 lastColumn = vec4 ( 0.0 , 0.0 , 0.0 , 1.0 ) ;
    return mat4 ( cSkinMatrices [ idx . x ] , cSkinMatrices [ idx . x + 1 ] , cSkinMatrices [ idx . x + 2 ] , lastColumn ) * blendWeights . x + mat4 ( cSkinMatrices [ idx . y ] , cSkinMatrices [ idx . y + 1 ] , cSkinMatrices [ idx . y + 2 ] , lastColumn ) * blendWeights . y + mat4 ( cSkinMatrices [ idx . z ] , cSkinMatrices [ idx . z + 1 ] , cSkinMatrices [ idx . z + 2 ] , lastColumn ) * blendWeights . z + mat4 ( cSkinMatrices [ idx . w ] , cSkinMatrices [ idx . w + 1 ] , cSkinMatrices [ idx . w + 2 ] , lastColumn ) * blendWeights . w ;
}
mat3 GetNormalMatrix ( mat4 modelMatrix )
{
    return mat3 ( modelMatrix [ 0 ] . xyz , modelMatrix [ 1 ] . xyz , modelMatrix [ 2 ] . xyz ) ;
}
vec2 GetTexCoord ( vec2 texCoord )
{
    return vec2 ( dot ( texCoord , cUOffset . xy ) + cUOffset . w , dot ( texCoord , cVOffset . xy ) + cVOffset . w ) ;
}
vec4 GetClipPos ( vec3 worldPos )
{
    vec4 ret = cViewProj * vec4 ( worldPos , 1.0 ) ;
    gl_ClipVertex = ret ;
    return ret ;
}
float GetZonePos ( vec3 worldPos )
{
    return clamp ( ( cZone * vec4 ( worldPos , 1.0 ) ) . z , 0.0 , 1.0 ) ;
}
float GetDepth ( vec4 clipPos )
{
    return dot ( clipPos . zw , cDepthMode . zw ) ;
}
vec3 GetBillboardPos ( vec4 iPos , vec2 iSize , mat4 modelMatrix )
{
    return ( modelMatrix * iPos ) . xyz + cBillboardRot * vec3 ( iSize . x , iSize . y , 0.0 ) ;
}
vec3 GetBillboardNormal ( )
{
    return vec3 ( - cBillboardRot [ 2 ] [ 0 ] , - cBillboardRot [ 2 ] [ 1 ] , - cBillboardRot [ 2 ] [ 2 ] ) ;
}
vec3 GetWorldPos ( mat4 modelMatrix )
{
    return ( iPos * modelMatrix ) . xyz ;
}
vec3 GetWorldNormal ( mat4 modelMatrix )
{
    return normalize ( iNormal * GetNormalMatrix ( modelMatrix ) ) ;
}
vec3 GetWorldTangent ( mat4 modelMatrix )
{
    mat3 normalMatrix = GetNormalMatrix ( modelMatrix ) ;
    return normalize ( iTangent . xyz * normalMatrix ) ;
}
vec4 GetScreenPos ( vec4 clipPos )
{
    return vec4 ( clipPos . x * cGBufferOffsets . z + cGBufferOffsets . x * clipPos . w , clipPos . y * cGBufferOffsets . w + cGBufferOffsets . y * clipPos . w , 0.0 , clipPos . w ) ;
}
vec2 GetScreenPosPreDiv ( vec4 clipPos )
{
    return vec2 ( clipPos . x / clipPos . w * cGBufferOffsets . z + cGBufferOffsets . x , clipPos . y / clipPos . w * cGBufferOffsets . w + cGBufferOffsets . y ) ;
}
vec2 GetQuadTexCoord ( vec4 clipPos )
{
    return vec2 ( clipPos . x / clipPos . w * 0.5 + 0.5 , clipPos . y / clipPos . w * 0.5 + 0.5 ) ;
}
vec2 GetQuadTexCoordNoFlip ( vec3 worldPos )
{
    return vec2 ( worldPos . x * 0.5 + 0.5 , - worldPos . y * 0.5 + 0.5 ) ;
}
vec3 GetFarRay ( vec4 clipPos )
{
    vec3 viewRay = vec3 ( clipPos . x / clipPos . w * cFrustumSize . x , clipPos . y / clipPos . w * cFrustumSize . y , cFrustumSize . z ) ;
    return cCameraRot * viewRay ;
}
vec3 GetNearRay ( vec4 clipPos )
{
    vec3 viewRay = vec3 ( clipPos . x / clipPos . w * cFrustumSize . x , clipPos . y / clipPos . w * cFrustumSize . y , 0.0 ) ;
    return ( cCameraRot * viewRay ) * cDepthMode . x ;
}
vec3 GetAmbient ( float zonePos )
{
    return cAmbientStartColor + zonePos * cAmbientEndColor ;
}
varying vec2 vTexCoord ;
varying vec3 vNormal ;
varying vec4 vWorldPos ;
varying vec3 vCubeMaskVec ;
void VS ( )
{
    mat4 modelMatrix = GetSkinMatrix ( iBlendWeights , iBlendIndices ) ;
    vec3 worldPos = GetWorldPos ( modelMatrix ) ;
    gl_Position = GetClipPos ( worldPos ) ;
    vNormal = GetWorldNormal ( modelMatrix ) ;
    vWorldPos = vec4 ( worldPos , GetDepth ( gl_Position ) ) ;
    vTexCoord = GetTexCoord ( iTexCoord ) ;
    vec4 projWorldPos = vec4 ( worldPos , 1.0 ) ;
    vCubeMaskVec = mat3 ( cLightMatrices [ 0 ] [ 0 ] . xyz , cLightMatrices [ 0 ] [ 1 ] . xyz , cLightMatrices [ 0 ] [ 2 ] . xyz ) * ( worldPos - cLightPos . xyz ) ;
}
void PS ( )
{
    vec4 diffColor = cMatDiffColor ;
    vec3 specColor = cMatSpecColor . rgb ;
    vec3 normal = normalize ( vNormal ) ;
    float fogFactor = GetFogFactor ( vWorldPos . w ) ;
    vec3 lightColor ;
    vec3 lightDir ;
    vec3 finalColor ;
    float diff = GetDiffuse ( normal , vWorldPos . xyz , lightDir ) ;
    lightColor = cLightColor . rgb ;
    finalColor = diff * lightColor * diffColor . rgb ;
    gl_FragColor = vec4 ( GetLitFog ( finalColor , fogFactor ) , diffColor . a ) ;
}