class PHUD_Area extends pawn;

/*Clase que instancia una luz y efectos al ir pasando el mouse por el planeta en la vista aerea*/

var PointLightComponent m_luz;
var ParticleSystem m_ParticleSystem;
var EmitterSpawnable m_Emitter;
var Color c,c2;

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

function ColorEstado(bool estado)
{
	if(estado)
	{
		m_luz.SetLightProperties(500.0,c,);
	}
	else
	{
		m_luz.SetLightProperties(150.0,c2,);
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
	c=(r=0,g=255,b=0)
	c2=(r=255,g=0,b=0)
	
}
