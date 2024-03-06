Shader "Unlit/eyemouth"
{
    Properties
    {
        _EyeTex("eyetex", 2D) = "white" {}
        _MouthTex("mouthtex",2D)="white"{}
        _MouthXIndex("mouthxindex",range(0,7))=0
        _MouthYIndex("mouthyindex",range(0,7))=0
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _EyeTex;
            float4 _EyeTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 eyecolor = tex2D(_EyeTex, i.uv);
                fixed2 stepuv = (fixed2(0.25f,0.25f)>=i.uv);
                eyecolor=(1-stepuv.x*stepuv.y)*eyecolor;
                clip(eyecolor.a-0.01f);
                return eyecolor;
            }
            ENDCG
        }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 mouthuv:TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MouthTex;
            float4 _MouthTex_ST;

            int _MouthXIndex;
            int _MouthYIndex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.mouthuv=v.uv*0.5f+fixed2(0.125f*floor(_MouthXIndex),0.125f*floor(_MouthYIndex));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 mouthcolor=tex2D(_MouthTex,i.mouthuv);
                fixed2 stepuv = (fixed2(0.25f,0.25f)>=i.uv);
                return stepuv.x*stepuv.y*mouthcolor;
            }
            ENDCG
        }
    }
}
