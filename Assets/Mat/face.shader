Shader "Unlit/face"
{
    Properties
    {
        _MainTex ("Maintex", 2D) = "white" {}
        _MaskTex("masktex",2D)="white"{}
        _ShaodwLightDir("shadowlightdir",float)=(1,1,1)
        _MaskGSensitivity("maskgsensitivity",float)=0.5
        _ShadowThreshold("shadowthreshold",float)=0
        _MxCharLightDir("mxcharlightdir",float)=(1,1,1)
        _LightTint("lighttint",Color)=(1,1,1,1)
        _ShadowTint("shadowtint",Color)=(0.6,0.6,0.6,1)

        _RimAreaMultiplier("rimareamultiplier",float)=0.5
        _RimAreaLeveler("rimarealeveler",float)=0.5
        _RimTint("rimtint",color)=(0.2,0.2,0.2,0.2)
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
                float3 normal:NORMAL;
                float4 color:COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldnormal:NORMAL;
                float3 viewdir:TEXCOORD1;
                float3 shadowlightdir:TEXCOORD2;
                float4 color:COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MaskTex;
            float4 _MaskTex_ST;

            float3 _ShaodwLightDir;
            float _MaskGSensitivity;
            float _ShadowThreshold;
            float3 _MxCharLightDir;
            float _RimAreaMultiplier;
            float _RimAreaLeveler;
            float4 _RimTint;
            float4 _LightTint;
            float4 _ShadowTint;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                fixed4 worldpos=mul(unity_ObjectToWorld,v.vertex);
                o.worldnormal=UnityObjectToWorldNormal(v.normal);
                o.viewdir=normalize(_WorldSpaceCameraPos-worldpos.xyz);
                o.shadowlightdir=normalize(UnityObjectToWorldDir(_ShaodwLightDir));
                o.uv = v.uv;
                o.color=v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // return i.color.w;
                fixed4 maincolor = tex2D(_MainTex, i.uv);
                fixed4 maskcolor=tex2D(_MaskTex,i.uv);
                fixed ndots=dot(i.worldnormal,i.shadowlightdir);
                fixed ndotv=dot(i.worldnormal,i.viewdir);
                fixed maskg=maskcolor.y*2-1;
                fixed simhalf=ndotv*0.77f+ndots;
                fixed diffusefac = saturate((_MaskGSensitivity*maskg+_ShadowThreshold-simhalf)*2);
                fixed4 diffusetint=lerp(_LightTint,_ShadowTint,diffusefac);
                // return diffusetint;
                fixed ndotl=dot(i.worldnormal,_MxCharLightDir);
                fixed diffusemask=(saturate(ndotl*4+0.25)*0.4+0.3);
                fixed rimfac=saturate((1-ndotv)*_RimAreaMultiplier-_RimAreaLeveler);
                fixed4 rimtint=rimfac*diffusemask*(_RimTint*2-1)*i.color.w;
                // return diffusemask;
                // return rimfac;
                // return (_RimTint*2-1);
                // return i.color.w;
                // return rimtint;
                return (rimtint+diffusetint)*maincolor;
            }
            ENDCG
        }
    }
}
