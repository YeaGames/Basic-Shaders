Shader "Custom/ToonShaderImproved"
{
    Properties
    {
        _BaseMap            ("Texture", 2D)                       = "white" {}
        _BaseColor          ("Color", Color)                      = (0.5,0.5,0.5,1)
        _BaseAlpha          ("Alpha", Range(0, 1))                = 0.5
        
        [Space]
        _ShadowStep         ("ShadowStep", Range(0, 1))           = 0.5
        _ShadowStepSmooth   ("ShadowStepSmooth", Range(0, 1))     = 0.04
        
        [Space] 
        _SpecularStep       ("SpecularStep", Range(0, 1))         = 0.6
        _SpecularStepSmooth ("SpecularStepSmooth", Range(0, 1))   = 0.05
        [HDR]_SpecularColor ("SpecularColor", Color)              = (1,1,1,1)
        
        [Space]
        _RimStep            ("RimStep", Range(0, 1))              = 0.65
        _RimStepSmooth      ("RimStepSmooth",Range(0,1))          = 0.4
        _RimColor           ("RimColor", Color)                   = (1,1,1,1)
        
        [Space]   
        _OutlineWidth      ("OutlineWidth", Range(0.0, 1.0))      = 0.15
        _OutlineColor      ("OutlineColor", Color)                = (0.0, 0.0, 0.0, 1)

        [Space]
        _Distance          ("Distance", Float)                    = 1
        _Amplitude         ("Amplitude", Float)                   = 1
        _Speed             ("Speed", Float)                       = 1
        _Amount            ("Amount", Range(0.0,1.0))             = 1
        _IsFlody           ("IsFloody", Range(0.0,0.1))           = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        ZWrite off
        Blend SrcAlpha OneMinusSrcAlpha


        Pass
        {
            Name "Object"
            Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag


                #include "UnityCG.cginc"
                //#include "Lighting.cginc"
                #include "AutoLight.cginc"


                sampler2D _BaseMap;
                float4 _BaseMap_ST;

                CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _BaseAlpha;
                float _ShadowStep;
                float _ShadowStepSmooth;
                float _SpecularStep;
                float _SpecularStepSmooth;
                float4 _SpecularColor;
                float _RimStepSmooth;
                float _RimStep;
                float4 _RimColor;
                float _Distance;
                float _Amplitude;
                float _Speed;
                float _Amount;
                float _IsFlody;
                CBUFFER_END
                
                 

                struct MeshData
                {
                    float4 vertex : POSITION;
                    float3 positionWS : TEXCOORD7;
                    float3 normal : NORMAL;
                    float3 tangent : TANGENT;
                    float2 uv : TEXCOORD0;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                struct InterPolators
                {
                    float2 uv : TEXCOORD0;
                    //float4 vertex : SV_POSITION;
                    float4 normalWS      : TEXCOORD1;    // xyz: normal, w: viewDir.x
                    float4 tangentWS     : TEXCOORD2;    // xyz: tangent, w: viewDir.y
                    float4 bitangentWS   : TEXCOORD3;    // xyz: bitangent, w: viewDir.z
                    float3 viewDirWS     : TEXCOORD4;
                    float4 shadowCoord	 : TEXCOORD5;	// shadow receive 
                    //float4 fogCoord	     : TEXCOORD6;	
                    float3 positionWS	 : TEXCOORD7;	
                    float4 positionCS    : SV_POSITION;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                

                InterPolators vert (MeshData input)
                {
                    InterPolators o = (InterPolators)0;
                    //o.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                    //o.positionCS = UnityObjectToClipPos(input.vertex);
                    
                    if(_IsFlody > 0){
                        input.vertex.y += sin(_Time.y * _Speed + input.vertex.x * _Amplitude) * _Distance * _Amount;
                        input.vertex.x += sin(_Time.y * _Speed + input.vertex.y * _Amplitude) * _Distance * _Amount;
                    }
                    
                    UNITY_SETUP_INSTANCE_ID(input);
                    UNITY_TRANSFER_INSTANCE_ID(input, o);

                    //VertexPositionInputs vertexInput = GetVertexPositionInputs(input.vertex.xyz);
                    //VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangent);

                    //ComputeScreenPos(o.positionCS)

                    float3 viewDirWS = _WorldSpaceCameraPos - o.positionWS;
                    o.positionCS = UnityObjectToClipPos(input.vertex); 
                    o.positionWS = input.positionWS;
                    o.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                    //o.normalWS = float4(input.normal, viewDirWS.x);
                    o.normalWS = float4(UnityObjectToWorldNormal(input.normal),viewDirWS.x);
                    o.tangentWS = float4(UnityObjectToWorldNormal(input.normal),viewDirWS.y);
                    o.bitangentWS = float4(UnityObjectToWorldNormal(input.normal),viewDirWS.z);
                    o.viewDirWS = viewDirWS;
                    

                    return o;
                }

                float4 frag (InterPolators input) : SV_TARGET
                {
                    UNITY_SETUP_INSTANCE_ID(input);

                    float2 uv = input.uv;
                    float3 N = normalize(input.normalWS.xyz);
                    float3 T = normalize(input.tangentWS.xyz);
                    float3 B = normalize(input.bitangentWS.xyz);
                    float3 V = normalize(input.viewDirWS.xyz);
                    float3 L = normalize(_WorldSpaceLightPos0.xyz);
                    float3 H = normalize(V+L);

                    float NV = dot(N,V);
                    float NH = dot(N,H);
                    float NL = dot(N,L);

                    NL = NL * 0.5 + 0.5;

                    float4 baseMap = tex2D(_BaseMap,input.uv);

                    // return NH;
                    float specularNH = smoothstep((1-_SpecularStep * 0.05)  - _SpecularStepSmooth * 0.05, (1-_SpecularStep* 0.05)  + _SpecularStepSmooth * 0.05, NH);
                    float shadowNL = smoothstep(_ShadowStep - _ShadowStepSmooth, _ShadowStep + _ShadowStepSmooth, NL);

                    TRANSFER_SHADOW(input.shadowCoord)

                    //shadow
                    float shadow = SHADOW_ATTENUATION(input.shadowCoord);

                    //rim
                    float rim = smoothstep((1-_RimStep) - _RimStepSmooth * 0.5, (1-_RimStep) + _RimStepSmooth * 0.5, 0.5 - NV);

                    //diffuse
                    float3 diffuse = unity_LightColor0.rgb * baseMap.xyz * _BaseColor.rgb * shadowNL * shadow;

                    //specular
                    float3 specular = _SpecularColor.rgb * shadow * shadowNL *  specularNH;

                    //ambient
                    float3 ambient =  rim * _RimColor.rgb + ShadeSH9(half4(N,1)).xyz * _BaseColor.rgb * baseMap.xyz;

                    float3 finalColor = diffuse + ambient + specular;
                    
                    float4 returnColor = float4(finalColor, 0.5);
                    returnColor.a = _BaseAlpha;
                    return returnColor;
                }

            ENDCG
        }
        // Outline
        Pass
        {
            Name "Outline"
            Cull Front
            //ZTest Always
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile_fog
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "UnityCG.cginc"

            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                //float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos      : SV_POSITION;
                //float4 fogCoord	: TEXCOORD0;	
            };
            
            float _OutlineWidth;
            float4 _OutlineColor;
            float _BaseAlpha;
            float _Distance;
            float _Amplitude;
            float _Speed;
            float _Amount;
            float _IsFlody;
            
            v2f vert(appdata v)
            {
                v2f o;
                if(_IsFlody > 0){
                    v.vertex.y += sin(_Time.y * _Speed + v.vertex.x * _Amplitude) * _Distance * _Amount;
                    v.vertex.x += sin(_Time.y * _Speed + v.vertex.y * _Amplitude) * _Distance * _Amount;
                }
                
                //VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                //o.pos = TransformObjectToHClip(float3(v.vertex.xyz + v.normal * _OutlineWidth * 0.1));
                o.pos = UnityObjectToClipPos(v.vertex.xyz + v.normal * _OutlineWidth); 
                //o.fogCoord = ComputeFogFactor(vertexInput.positionCS.z);

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 finalColor = _OutlineColor.rgb;//MixFog(_OutlineColor.rgb, i.fogCoord);
                float4 returnColor = float4(finalColor,1.0);
                returnColor.a = _BaseAlpha / 2;
                return returnColor;
            }
            
            ENDHLSL
        }
    }  
   Fallback "VertexLit"     
}
