class PNubeIra extends Actor placeable;

var EmitterSpawnable m_particulas_rayitos,m_particulas_rayaco;
var StaticMeshComponent laMesh;
var bool m_b_activa;
var int m_rayitos;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	SetCollision(false,false,false);
	CollisionComponent.SetActorCollision(false,false,false);

	
	//Inicialización del sistema de partículas de la Nube de Ira
	m_particulas_rayitos = Spawn(class'EmitterSpawnable',Self);
	if (m_particulas_rayitos != None)
	{
		m_particulas_rayitos.ParticleSystemComponent.bAutoActivate = false;
		m_particulas_rayitos.ParticleSystemComponent.SetActive(false);
		m_particulas_rayitos.SetTemplate(ParticleSystem'PGameParticles.Particles.NubeIra');
		m_particulas_rayitos.SetFloatParameter('ParamAlpha',0.3);	
	}

	//Inicialización del sistema de partículas del rayaco de la Nube de Ira
	m_particulas_rayaco = Spawn(class'EmitterSpawnable',Self);
	if (m_particulas_rayaco != None)
	{
		m_particulas_rayitos.ParticleSystemComponent.bAutoActivate = false;
		m_particulas_rayaco.SetTemplate(ParticleSystem'PGameParticles.Particles.RayoIra');
		//m_particulas_rayaco.SetTemplate(ParticleSystem'Eat3DCinematicUDK_Content_Done.ToBeMade.Lightning_Par');
		m_particulas_rayaco.ParticleSystemComponent.SetActive(false);
	}

	Desactivar();//Inicialmente desactivado

}

function bool EstaActiva()
{
	return m_b_activa;
}

function Activar()
{
	m_b_activa = true;
	self.laMesh.SetHidden(false);
	if (!m_particulas_rayitos.ParticleSystemComponent.bIsActive)
	{
		m_particulas_rayitos.ParticleSystemComponent.SetActive(true);  
	}

}

function Posicionar(Vector loca, Rotator rotGiru)
{
	local vector rx,ry,rz;
	local rotator rot;
	local Quat qact,qgiro;

	self.SetLocation(loca);
	m_particulas_rayitos.SetLocation(loca);
	//Y la giro, porque mola más, y por el editor no se hacerlo, y paso de abrir el 3DSMAX y reimportar y hostias ;)
	GetAxes(rotGiru,rx,ry,rz);
	qact  = QuatFromRotator(rotGiru);
	qgiro = QuatFromAxisAndAngle(rz,80); 
	qact  = QuatProduct(qgiro,qact);
	rot   = QuatToRotator(qact);
	SetRotation(rot);

}

function SetNumRayitos(int rayitos)
{
	m_particulas_rayitos.SetFloatParameter('NumRayitos',rayitos);
	m_rayitos = rayitos;
	Dimensionar();
}

function Rayaco()
{
	m_particulas_rayaco.SetRotation(self.Rotation);
	m_particulas_rayaco.SetLocation(self.Location); //Donde está la nube
	m_particulas_rayaco.ParticleSystemComponent.SetActive(true);
}

function Desactivar()
{
	m_b_activa = false;
	self.laMesh.SetHidden(true);
	if (m_particulas_rayitos.ParticleSystemComponent.bIsActive)
	{
		m_particulas_rayitos.ParticleSystemComponent.SetActive(false);
	}
	m_rayitos = 0;
}

function Dimensionar()
{
	local float s;
	local vector tamrayitos;
	
	s= fclamp((m_rayitos+20)/100.0,0.2,1.2); //100 es el máximo, así que ..
	laMesh.SetScale(s);
	tamrayitos.X=s;
	tamrayitos.Y=s;
	tamrayitos.Z=s;

	m_particulas_rayitos.SetVectorParameter('Tamanyo',tamrayitos);
}

DefaultProperties
{

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true
	End Object

	LightEnvironment=MyLightEnvironment
	Components.Add(MyLightEnvironment)

	begin object class=StaticMeshComponent Name=NubeMesh
		StaticMesh=StaticMesh'PGameParticles.Nube'
		LightEnvironment=MyLightEnvironment
	end object
	Components.Add(NubeMesh);
	CollisionComponent=NubeMesh
	laMesh=NubeMesh	
	// Lo añadimos al motor
	//CylinderComponent=CollisionCylinder
	//CollisionComponent=CollisionCylinder
	//Components.Add(CollisionCylinder)

	bWorldGeometry=true
	TickGroup=TG_PreAsyncWork
	bStatic=false
	bCanBeDamaged=true
	bCollideActors=true
	bBlockActors=true
	bNoEncroachCheck=true
}


