Shader "Unlit/CubeShader"
{
   Properties {
        _Color ("Base Color", Color) = (1, 1, 1, 1)
    }
 
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100
 
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
 
            struct appdata_t {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
 
            struct v2f {
                float4 pos : POSITION;
                float3 normal : TEXCOORD0;
            };
 
            float4 _Color;
 
            v2f vert (appdata_t v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                return o;
            }
 
            half4 frag (v2f i) : SV_Target {
                // Normal vektörünü renk olarak kullan, burada r, g, b kanalları normal vektörün x, y, z bileşenlerine karşılık gelir
                half3 color = 0.5 * (i.normal + 1.0);
                return half4(color * _Color, 1);
            }
            ENDCG
        }
    }
}
