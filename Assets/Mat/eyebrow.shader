Shader "Unlit/eyebrow"
{
    Properties
    {
        _MxCharLightTone("mxcharlighttone",float)=(1,1,1,1)
        _MxCharLightData("mxcharlightdata",float)=(1,1,1,1)
        _Tint("tint",color)=(1,1,1,1)
        _ZCorrection("zcorrection",float)=0.0264
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };
            float4 _Tint;
            float _ZCorrection;

            v2f vert (appdata v)
            {
                v2f o;
                float3 objpos=mul(unity_WorldToObject,fixed4(_WorldSpaceCameraPos,1)).xyz;
                float3 objectviewdir=normalize(objpos-v.vertex.xyz);
                float3 offectdir=objectviewdir*_ZCorrection+v.vertex.xyz;
                o.vertex = UnityObjectToClipPos(fixed4(offectdir,1));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _Tint;
            }
            ENDCG
        }
    }
}
