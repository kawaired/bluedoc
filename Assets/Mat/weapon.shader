Shader "Unlit/weapon"
{
    Properties
    {
        _MainTex ("maintex", 2D) = "white" {}
        _MaskTex("masktex",2D)="white"{}
        _LightTint("lighttint",color)=(1,1,1,1)
        _ShadowTint("shadowtint",color)=(0.545,0.3539,0.2356,1)
        _FakeLightDir("fakelightdir",float)=(0.1,0.65,0)

        _MxCharLightTone("mxcharlightttone",float)=(1,1,1)
        _MxCharLightData("mxcharlightdata",float)=(1,1,0,0)
        _ShadowThreshold("shadowthreshold",float)=0.5
        _ShadowStrong("shadowstrong",float)=10
        _LightValue("lightvalue",float)=0.5
        _LightStrong("lightstrong",float)=40
        _SpecTint("spectint",color)=(1,0.87,0.7,1)
        _SpecStrong("specstrong",float)=0.2

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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float ndotv:TEXCOORD1;
                float ndoth:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MaskTex;
            float4 _MaskTex_ST;

            float4 _LightTint;
            float4 _ShadowTint;
            float3 _FakeLightDir;


            float _ShadowThreshold;
            float _ShadowStrong;
            float _LightValue;
            float _LightStrong;
            float4 _SpecTint;
            float _SpecStrong;

            v2f vert (appdata v)
            {
                v2f o;
                float4 worldpos=mul(unity_ObjectToWorld,v.vertex);
                float3 viewdir=normalize(_WorldSpaceCameraPos-worldpos.xyz);
                float3 worldnormal=UnityObjectToWorldNormal(v.normal);
                // o.vertex = UnityObjectToClipPos(v.v);
                o.uv = v.uv;
                o.ndotv=dot(worldnormal,viewdir);
                o.ndoth=dot(worldnormal,normalize(viewdir+_FakeLightDir));
                o.vertex=UnityWorldToClipPos(worldpos);
                // o.shadowlightfac=_MxCharLightTone.xyz*_ShadowTint.xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 maincolor = tex2D(_MainTex, i.uv);
                fixed4 maskcolor=tex2D(_MaskTex,i.uv);

                fixed diffusebase=saturate(i.ndoth-_ShadowThreshold);
                // return diffusebase;
                fixed diffusemask=saturate(maskcolor.y*2-_ShadowThreshold-1);
                // return diffusemask;
                fixed diffusefac =saturate(diffusebase-diffusemask)*_ShadowStrong;
                // return diffusefac;
                
                // return diffuseTint;
                // return (maskcolor.x*i.ndotv-_LightValue)*_LightStrong;
                // return saturate((maskcolor.x*i.ndotv-_LightValue)*_LightStrong);
                fixed specfac=saturate((maskcolor.x*i.ndotv-_LightValue)*_LightStrong)*_SpecStrong;
                
                fixed4 diffuseTint=lerp(_LightTint,_ShadowTint,diffusefac);
                fixed4 spectint=specfac*_SpecTint*_LightTint;
                fixed4 finaltint = diffuseTint+spectint;
                return maincolor*finaltint;
            }
            ENDCG
        }
    }
}
