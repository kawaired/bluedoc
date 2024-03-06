Shader "Unlit/hair"
{
    Properties
    {
        _MainTex ("maintex", 2D) = "white" {}
        _MaskTex("masktex",2D)="white"{}
        _SpecTex("spectex",2D)="white"{}
        _MxCharLightDir("mxcharlightdir",float)=(0.1016,0.9941,0.3813)
        _MxCharShadowTone("mxcharshadowtone",float)=(1,1,1)
        _MxCharLightData("mxcharlightdata",float)=(1,1,1,1)
        _ShadowThreshold("shaodwthreshold",float)=0.47
        _LightTint("lighttint",color)=(1,1,1,1)
        _ShadowTint("shadowtint",color)=(0.717,0.524,0.555,1)

            // float4 _MxCharLightData;
        _MaskGSensitivity("maskgsensitivity",float)=1.61
        _Tint("tint",float)=(1,1,1,1)
        _RimAreaMultiplier("rimareamultiplier",float)=5
        _RimAreaLeveler("rimarealeveler",float)=1
        _RimStrength("rimstength",float)=1

        _TwoSideTint("twosidetint",color)=(1,1,1,1)
        _SpecDirMultiplier("specdirmultiplier",float)=(0.37,0,0)
        _SpecTopMultiplier("spectopmultiplier",float)=5.8
        _SpecTopLeveler("spectopleveler",float)=4.8
        _SpecBotArea("specbotarea",float)=0.674
        _SpecBotMultiplier("specbotmultiplier",float)=2.2
        _SpecStrength("specstrength",float)=0.9
        _SpecColorTint("spectcolortint",color)=(1,1,1,1)
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
                float3 normal : NORMAL;
                float4 color:COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldnormal:NORMAL;
                float4 color:COLOR;
                float3 viewdir : TEXCOORD2;
                float3 viewdiroffset:TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MaskTex;
            float4 _MaskTex_ST;
            sampler2D _SpecTex;
            float4 _SpecTex_ST;

            float3 _MxCharLightDir;
            float3 _MxCharShadowTone;
            float4 _MxCharLightData;
            float _ShadowThreshold;
            float4 _LightTint;
            float4 _ShadowTint;

            float3 _MxCharLightTone;
            float _MaskGSensitivity;
            float4 _Tint;
            float _RimAreaMultiplier;
            float _RimAreaLeveler;
            float _RimStrength;
            float4 _TwoSideTint;
            float3 _SpecDirMultiplier;
            float _SpecTopMultiplier;
            float _SpecTopLeveler;
            float _SpecBotArea;
            float _SpecBotMultiplier;
            float _SpecStrength;
            float4 _SpecColorTint;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldnormal=normalize(UnityObjectToWorldNormal(v.normal));
                fixed4 worldpos=mul(unity_ObjectToWorld,v.vertex);
                o.viewdir=normalize(_WorldSpaceCameraPos-worldpos.xyz);
                o.viewdiroffset=normalize(o.viewdir+_MxCharLightDir);
                o.uv = v.uv;
                o.color=v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 maincolor = tex2D(_MainTex, i.uv);
                fixed4 maskcolor=tex2D(_MaskTex,i.uv);
                fixed4 speccolor=tex2D(_SpecTex,i.uv);  
                
                fixed ndotl=dot(i.worldnormal,_MxCharLightDir);
                fixed ndotv=dot(i.worldnormal,i.viewdir);
                fixed simhalf=ndotv*0.77+ndotl;   
                
                fixed2 lightfac=ndotl*fixed2(4,0.33f)+fixed2(0.25f,0.5f); 
                fixed maskfac=maskcolor.y*2-1;
                maskfac = simhalf-maskfac*_MaskGSensitivity-_ShadowThreshold;
                fixed specmask=saturate(maskfac*5-0.5f);
                
                // fixed simhalf=ndotv*0.77+ndotl;
                // fixed maskfac=maskcolor.y*2-1;
                // maskfac = simhalf-maskfac*_MaskGSensitivity-_ShadowThreshold;
                fixed diffusefac=saturate(maskfac*(-20));
                fixed4 diffusetint=lerp(_LightTint,_ShadowTint,diffusefac);
                // return diffusetint;

                fixed3 specdir = normalize(UnityObjectToWorldDir(speccolor.xyz*2-fixed3(1,1,1)));
                // return specdir.xyzz;
                // return dot(specdir,i.viewdiroffset);
                // return dot(speccolor.xyz*2-fixed3(1,1,1),_SpecDirMultiplier);
                // return (dot(specdir,i.viewdiroffset)+dot(speccolor.xyz*2-fixed3(1,1,1),_SpecDirMultiplier));
                fixed specfac=dot(specdir,i.viewdiroffset)+dot(speccolor.xyz*2-fixed3(1,1,1),_SpecDirMultiplier);
                // return specfac;
                fixed specbot=pow(max(specfac,-_SpecBotArea)+_SpecBotArea,2)*_SpecBotMultiplier;
                specbot=(specfac<0)*specbot;
                // return specbot;
                fixed spectop=(1-specfac)*_SpecTopMultiplier-_SpecTopLeveler;
                spectop=(specfac>=0)*spectop;
                // return spectop;
                // return specbot+spectop;
                // return 1-speccolor.w;
                // return specbot+spectop-(1-speccolor.w);
                // return spectop;
                // return speccolor.w;
                fixed finspecfac=max(specbot+spectop-(1-speccolor.w),0)*_SpecStrength;
                fixed4 spectint=(lightfac.x*0.4f+0.3f)*_LightTint*specmask*finspecfac*(_SpecColorTint*2-1);
                // return spectint;

                fixed fresnel=1-ndotv;
                fixed rimfac=saturate(fresnel*_RimAreaMultiplier-_RimAreaLeveler)*i.color.w*_RimStrength;
                fixed4 rimtint=rimfac*_LightTint*(lightfac.x*0.4f+0.3f);
                // return rimtint;

                fixed4 finaltint=spectint+rimtint+diffusetint;
                fixed4 finalcolor = finaltint*maincolor*_Tint;
                fixed4 twosidecolor=maincolor*lightfac.y*_TwoSideTint;
                // return finalcolor;
                // return twosidecolor;
                return twosidecolor+finalcolor;
            }
            ENDCG
        }
    }
}
