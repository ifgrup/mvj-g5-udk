class PEmiter  extends Pawn
	placeable;

var ParticleSystem MyParticleSystem,MyParticleSystem2;
var EmitterSpawnable MyEmitter,MyEmitter2;

var float m_tiempotranscurrido;


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

		if (m_tiempotranscurrido>20)
					{
						`Log("Destruimos el emiter"@MyEmitter);
						MyEmitter.ShutDown();
						//MyEmitter.Destroy(true);

						m_tiempotranscurrido=0;
						
					}



	}

defaultproperties

{
		 //Begin Object Class=StaticMeshComponent Name=DMesh
		//Archetype=InterpActor'PGameContentcannon.escudocca'
        //StaticMesh=StaticMesh'HU_Deco3.SM.Mesh.S_HU_Deco_SM_HydraulicSupport_C'
		// StaticMesh=StaticMesh'PGameContentcannon.Mesh.escudocannon'
		// StaticMesh=StaticMesh'NodeBuddies.3D_Icons.NodeBuddy_LeanLeftS'
		// StaticMesh=StaticMesh'VH_Hoverboard.Mesh.S_energy_Mesh'
		
	// StaticMesh=StaticMesh'EngineVolumetrics.FogEnvironment.Mesh.S_EV_FogVolume_Cylinder_01'
      //  BlockActors=false
      //  CollideActors=true
      //  LightEnvironment=MyLightEnvironmentrr 
		//CollisionComponent=CollisionCylinder1
      //Scale3D=(X=20,Y=20,Z=20)
//ObjectArchetype=InterpActor'PGameContentcannon.escudocca'
   // End Object
  //  Components.Add(DMesh)
	//MyParticleSystem=ParticleSystem'VH_All.Effects.P_VH_All_Spawn_Blue'
	MyParticleSystem=ParticleSystem'PGameParticles.Particles.CristalesCuarzo'
	MyParticleSystem2=ParticleSystem'PGameContentTice.polvoicecopo'
}