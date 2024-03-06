Shader "Unlit/body"
{
    Properties
    {
        _MainTex ("maintex", 2D) = "white" {}
        _MaskTex("masktex",2D) = "white"{}
        _CodeAddRimColor("codeaddrimcolor",color)=(0,0,0,0)
        _TestColor("testcolor",Color)=(0,0,0,0)
        _MxCharLightDir("mxcharlightdir",float)=(0.10158,0.9941,0.03812)
        _LightTint("lighttint",color)=(1,1,1)
        _MaskGSensitivity("maskgsensitivity",float)=1
        _Tint("tint",float)=(1,1,1,1)
        _TwoSideTint("twosidetint",float)=(1,1,1)
        _BaseBrightness4("basebrightness4",float)=(0,-0.07,0,0.4)
        _ShadowThreshold4("shadowthreshold4",float)=(0.1,0.54,0.66,0.85)
        _ShadowTintR4("shadowtintr4",color)=(0.85,0.85,0.29,0.62)
        _ShadowTintG4("shadowtintg4",color)=(0.65,0.65,0.079,0.4)
        _ShadowTintB4("shadowtintb4",color)=(0.645,0.74,0.079,0.226)
        _ViewOffset4("viewoffset4",float)=(-0.45,0,0.09,0)
        _ViewPower4("viewpower4",float)=(128,1,45,29)
        _ViewStrength4("viewstrength4",float)=(0.08,0,0.5,0.8)
        _InvViewPower4("invviewpower4",float)=(1,1,3.5,1.9)
        _InvViewStrength4("invviewstrength4",float)=(0,0,0.8,0.1)
        _ViewLightEdge4("viewlightedge4",float)=(0,0,0,0)
        _RimAreaMultiplier4("rimareamultiplier4",float)=(5,5,5,5)
        _RimStrength4("rimstrength4",float)=(1,1,1,1)

        _OutLintWidth("outlinewidth",float)=0.02
        _OutLineZCorrection("outline",range(-1,1))=0.1
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
                float4 normal:NORMAL;
                float2 uv : TEXCOORD0;
                float4 color:COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldnormal:NORMAL;
                float4 vertex : SV_POSITION;
                float4 color:COLOR;
                float3 viewdir:TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MaskTex;
            float4 _MaskTex_ST;

            float4 _TestColor;

            float3 _MxCharLightDir;
            float4 _LightTint;
            float _MaskGSensitivity;
            float4 _Tint;
            float4 _CodeAddRimColor;
            float3 _TwoSideTint;
            float4 _BaseBrightness4;
            float4 _ShadowThreshold4;
            float4 _ShadowTintR4;
            float4 _ShadowTintG4;
            float4 _ShadowTintB4;
            float4 _ViewOffset4;
            float4 _ViewPower4;
            float4 _ViewStrength4;
            float4 _InvViewPower4;
            float4 _InvViewStrength4;
            float4 _ViewLightEdge4;
            float4 _RimAreaMultiplier4;
            float4 _RimStrength4;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldnormal = UnityObjectToWorldNormal(v.normal);
                o.viewdir=normalize(_WorldSpaceCameraPos -mul(unity_ObjectToWorld, v.vertex).xyz);
                o.color = v.color;
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 maincolor = tex2D(_MainTex, i.uv);
                fixed4 maskcolor = tex2D(_MaskTex, i.uv);

                fixed4 maskvector = fixed4(0, 0, 0, 0);
                fixed3 custommask = fixed3(maskcolor.www - fixed3(0.25f, 0.5f, 0.75f));
                fixed3 floornum = floor(custommask);
                maskvector.xyw = ceil(custommask);
                maskvector.xyz = fixed3(-floornum.x, (-floornum.yz) * (maskvector.xy));
                fixed maskg=(1-2*maskcolor.y);

                fixed dotviewpower = dot(_ViewPower4, maskvector);
                fixed3 newviewdir=normalize(dot(_ViewOffset4, maskvector)* _MxCharLightDir + i.viewdir);
                fixed newndotv=dot(i.worldnormal,newviewdir);
                fixed powerndotv = saturate(exp2(log2(saturate(newndotv))*dot(_ViewPower4,maskvector)));

                fixed ndotv=dot(i.worldnormal,i.viewdir);
                fixed ndotl = dot(i.worldnormal,_MxCharLightDir);
                fixed fresnel= 1-ndotv;
                fixed simhalf= ndotv*0.77f+ndotl;

                fixed lightfac = ndotv*4+0.25f;
                // return lightfac;
                fixed maskfac=simhalf+maskg*_MaskGSensitivity;
                // return maskfac;
                fixed scalefresnel = exp2(log2(saturate(fresnel))*dot(_InvViewPower4,maskvector));
                fixed specfac=saturate(maskg*_MaskGSensitivity+scalefresnel);
                specfac=dot(_InvViewStrength4,maskvector)*specfac;
                specfac = specfac+dot(_ViewStrength4,maskvector)*powerndotv;
                specfac=dot(_BaseBrightness4,maskvector)+specfac;
                // return specfac;
                fixed3 spectint=specfac*_LightTint.xyz;
                // return xlat16_1x;

                fixed3 shadowtint=fixed3(dot(_ShadowTintR4,maskvector),dot(_ShadowTintG4,maskvector),dot(_ShadowTintB4,maskvector));
                // return shadowtint.xyzz;
                fixed shadowthreshold=dot(_ShadowThreshold4,maskvector);
                fixed diffusefac=saturate((shadowthreshold-maskfac)*10);
                fixed3 diffusetint=lerp(_LightTint.xyz,shadowtint,diffusefac);

                lightfac=saturate(lightfac);
                lightfac=lightfac*0.4f+0.3f;
                // return xlat16_17;
                fixed3 lighttint=lightfac*_LightTint.xyz;

                fixed rimstrength=dot(_RimStrength4,maskvector);
                fixed rimarea =dot(_RimAreaMultiplier4,maskvector);
                rimarea=saturate(fresnel*rimarea-max(rimarea-1,0));
                fixed rimfac=pow(fresnel,2);
                rimarea=rimarea*i.color.w;
                fixed3 rimtint=rimstrength*rimarea*(_CodeAddRimColor*2-1);
                // return diffusetint.xyzz;
                fixed3 finaltint=rimtint+diffusetint+spectint;
                finaltint=maincolor*_Tint*finaltint;
                return fixed4(finaltint,maincolor.w);
            }
            ENDCG
        }
        Pass
        {
            cull front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 tangent:TANGENT;
                float4 color:COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color:COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _OutLineZCorrection;
            float _OutLintWidth;

            v2f vert (appdata v)
            {
                v2f o;
                // unity_WorldToObject
                // unity_MatrixInvV
                fixed3 xlat0=unity_WorldToObject[0].xyz*UNITY_MATRIX_I_V[0].x;
                xlat0=xlat0+unity_WorldToObject[1].xyz*UNITY_MATRIX_I_V[0].y;
                xlat0=xlat0+unity_WorldToObject[2].xyz*UNITY_MATRIX_I_V[0].z;
                xlat0=xlat0+unity_WorldToObject[3].xyz*UNITY_MATRIX_I_V[0].w;
                fixed2 xlatxy=fixed2(0,0);
                xlatxy.x=dot(xlat0,v.tangent)*UNITY_MATRIX_P[0].x;
                fixed3 xlat1=unity_WorldToObject[0].xyz*UNITY_MATRIX_I_V[1].x;
                xlat1=xlat1+unity_WorldToObject[1].xyz*UNITY_MATRIX_I_V[1].y;
                xlat1=xlat1+unity_WorldToObject[2].xyz*UNITY_MATRIX_I_V[1].z;
                xlat1=xlat1+unity_WorldToObject[3].xyz*UNITY_MATRIX_I_V[1].w;
                xlatxy.y=dot(xlat1,v.tangent)*UNITY_MATRIX_P[1].y;
                fixed2 xlat16_2=xlatxy*rsqrt(max(dot(xlatxy,xlatxy),6.1f));
                o.vertex = UnityObjectToClipPos(v.vertex);
                xlat16_2 = o.vertex.w*v.color.w*_OutLintWidth*xlat16_2;
                xlat16_2.y=(_ScreenParams.x/_ScreenParams.y)*xlat16_2.y;
                o.vertex.xy=o.vertex.xy+xlat16_2;
                o.vertex.z=(-_OutLineZCorrection)*2+o.vertex.z;

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color=v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(0,0,0,1);
                fixed4 maincolor = tex2D(_MainTex, i.uv);
                return maincolor;
            }
            ENDCG
        }
    }
}
