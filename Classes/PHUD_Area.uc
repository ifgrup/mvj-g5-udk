class PHUD_Area extends pawn;

/*Clase que instancia una luz y efectos al ir pasando el mouse por el planeta en la vista aerea*/

var PointLightComponent m_luz;
var ParticleSystem m_ParticleSystem;
var EmitterSpawnable m_Emitter;
var Color c,c1,c2,c3;

event PostBeginPlay()
{
	//Inicializar las propiedades 
	

}

function posicionarLuz(vector pos)
{
	m_luz.SetTranslation(pos);
	
}

function interruptor(bool encendido)
{
	m_luz.SetEnabled(encendido);
}

function ColorEstado(Hbt HbtActive)
{
	/*if(estado)
	{
		m_luz.SetLightProperties(500.0,c,);
	}
	else
	{
		m_luz.SetLightProperties(150.0,c2,);
	}
*/




	switch (HbtActive)
					{
						case hbt1:
								m_luz.SetLightProperties(100.0,c,);
							break;

						case hbt2:
								m_luz.SetLightProperties(100.0,c1,);
					
							break;

						case hbt3:
								m_luz.SetLightProperties(100.0,c2,);
							break;

						case hbt4:
								m_luz.SetLightProperties(100.0,c3,);
							break;
					}


















}












DefaultProperties
{
	
	Begin Object Class=PointLightComponent Name=LaLuz
		Radius=800
		bForceDynamicLight = TRUE
		CastDynamicShadows = TRUE
		LightColor = (r=255,g=0,b=0)
		Brightness = 100
	
		
	End Object
	m_luz= LaLuz
	Components.Add(LaLuz);

	m_ParticleSystem=ParticleSystem'PGameParticles.Particles.CristalesCuarzo'
	c=(r=233,g=66,b=12)
	c1=(r=33,g=171,b=236)
	c2=(r=179,g=61,b=233)
	c3=(r=120,g=224,b=30)
	
}
