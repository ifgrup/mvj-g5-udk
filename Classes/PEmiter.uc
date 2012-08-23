class PEmiter  extends Pawn
	placeable;

var ParticleSystem MyParticleSystem,MyParticleSystem2;
var EmitterSpawnable MyEmitter,MyEmitter2;

var float m_tiempotranscurrido;
var float m_tiempoHielo; //Tiempo que dura el sist. partículas de congelación

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	SpawnEmitter();
}


simulated function SpawnEmitter()
{
    if (WorldInfo.NetMode != NM_DedicatedServer)
    {
        if (MyEmitter2 == None)
        {
            if (MyParticleSystem2 != None)
            {
				MyEmitter2= Spawn(class'EmitterSpawnable',Self,,Location, Rotation);
                MyEmitter2.SetTemplate(MyParticleSystem2);   
				MyEmitter= Spawn(class'EmitterSpawnable',Self,,Location, Rotation);
               MyEmitter.SetTemplate(MyParticleSystem);   
            }
        }
    }
}

function Tick(Float Delta)
{
	super.Tick(Delta);
	m_tiempotranscurrido+=Delta;
	if (m_tiempotranscurrido>m_tiempoHielo)
	{
		//_DEBUG_ ("Destruimos el emiter"@MyEmitter);
		MyEmitter.ShutDown();
		//MyEmitter.Destroy(true);
		m_tiempotranscurrido=0;
	}
}

defaultproperties
{
      //  BlockActors=false
      //  CollideActors=true
      //  LightEnvironment=MyLightEnvironmentrr 
	//MyParticleSystem=ParticleSystem'VH_All.Effects.P_VH_All_Spawn_Blue'
	MyParticleSystem=ParticleSystem'PGameParticles.Particles.CristalesCuarzo'
	MyParticleSystem2=ParticleSystem'PGameContentTice.polvoicecopo'
	m_tiempoHielo = 8
}