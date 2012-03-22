class PTurret extends PKActor
    abstract;
var Pawn P;
var Pawn Enemy;
var int TurretHealth;

var(Turret) class<Projectile> ProjClass;
var(Turret) Int RoundsPerSec;				//Number of rounds to fire per second
function PostBeginPlay()
{


local PPlayerController PC;

    foreach LocalPlayerControllers(class'PPlayerController', PC)
    {
        if(PC.Pawn != none)
            P = PC.Pawn;
    }

	

}


function GetEnemy()
{
    local PPlayerController PC;
/*
    foreach LocalPlayerControllers(class'PPlayerController', PC)
    {
        if(PC.Pawn != none)
            Enemy = PC.Pawn;
    }*/
}

auto state Seeking
{
    function BeginState(Name PreviousStateName)
    {
     
	 SetTimer(2.0,true,'TimedFire');
	 TimedFire();
    }

    function Tick(float DeltaTime)
    {
       /*
		 if(Enemy == none)
            GetEnemy();

		  if(Enemy != none)
        {
    	//TimedFire();
        }

       */

      
    }
}



function TimedFire()
	{
		local Projectile Proj;
	
		Proj = Spawn(ProjClass,self,,self.Location,self.Rotation,,True);

		if( Proj != None && !Proj.bDeleteMe )
		{
			//Proj.Init(Vector(Enemy.Rotation));
		
		
		}
	}



defaultproperties
{


 Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironmentrr
        bEnabled=TRUE
    End Object
    Components.Add(MyLightEnvironmentrr)
/*
Begin Object class=SkeletalMeshComponent name=SkelMeshComp0
	SkeletalMesh=SkeletalMesh'TurretContent.TurretMesh'
		LightEnvironment=MyLightEnvironment
		End Object
		Components.Add(SkelMeshComp0)
	Mesh=SkelMeshComp0

*/ 
	/*Begin Object Class=CylinderComponent Name=CollisionCylinder1
        CollisionRadius=32.0
        CollisionHeight=64.0
        BlockNonZeroExtent=true
        BlockZeroExtent=true
        BlockActors=true
        CollideActors=true
    End Object
   
   Components.Add(CollisionCylinder1)*/

	  Begin Object Class=StaticMeshComponent Name=DMesh
        StaticMesh=StaticMesh'HU_Deco3.SM.Mesh.S_HU_Deco_SM_HydraulicSupport_C'
        BlockActors=true
        CollideActors=true
        LightEnvironment=MyLightEnvironmentrr 
		CollisionComponent=CollisionCylinder1
       // Scale3D=(X=2.25,Y=2.25,Z=2.25)
    End Object
    Components.Add(DMesh)
    MyMesh=DMesh
	CollisionComponent=DMesh
	

	ProjClass=class'UTGame.UTProj_LinkPowerPlasma'
	TurretHealth=500
	RoundsPerSec=3
}
