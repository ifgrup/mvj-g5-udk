class PEmiter  extends Pawn
	placeable;

var ParticleSystem MyParticleSystem;
var EmitterSpawnable MyEmitter;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	SpawnEmitter();
}


simulated function SpawnEmitter()
{
    if (WorldInfo.NetMode != NM_DedicatedServer)
    {
        if (MyEmitter == None)
        {
            if (MyParticleSystem != None)
            {
				MyEmitter= Spawn(class'EmitterSpawnable',Self,,Location, Rotation);
                MyEmitter.SetTemplate(MyParticleSystem);                    
            }
        }
    }
}


defaultproperties
{
	MyParticleSystem=ParticleSystem'VH_All.Effects.P_VH_All_Spawn_Blue'
}