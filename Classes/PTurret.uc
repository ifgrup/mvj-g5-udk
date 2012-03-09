class PTurret extends PActor
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
SetRotation(P.Rotation);

	`log("Rotation:" @Rotation);

}


function GetEnemy()
{
    local PPlayerController PC;

    foreach LocalPlayerControllers(class'PPlayerController', PC)
    {
        if(PC.Pawn != none)
            Enemy = PC.Pawn;
    }
}

auto state Seeking
{
    function BeginState(Name PreviousStateName)
    {
     `Log("pkkkkk");
	 SetTimer(2.0,true,'TimedFire');
	 TimedFire();
    }

    function Tick(float DeltaTime)
    {
       
		 if(Enemy == none)
            GetEnemy();

		  if(Enemy != none)
        {
    	//TimedFire();
        }

       

      
    }
}



function TimedFire()
	{
		local Projectile Proj;
	
		Proj = Spawn(ProjClass,self,,self.Location,self.Rotation,,True);

		if( Proj != None && !Proj.bDeleteMe )
		{
			Proj.Init(Vector(Enemy.Rotation));
		
		
		}
	}



defaultproperties
{


 Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
        bEnabled=TRUE
    End Object
    Components.Add(MyLightEnvironment)
/*
Begin Object class=SkeletalMeshComponent name=SkelMeshComp0
	SkeletalMesh=SkeletalMesh'TurretContent.TurretMesh'
		LightEnvironment=MyLightEnvironment
		End Object
		Components.Add(SkelMeshComp0)
	Mesh=SkelMeshComp0

*/
	  Begin Object Class=StaticMeshComponent Name=TMesh
        StaticMesh=StaticMesh'HU_Deco3.SM.Mesh.S_HU_Deco_SM_HydraulicSupport_C'
       
        LightEnvironment=MyLightEnvironment
       // Scale3D=(X=2.25,Y=2.25,Z=2.25)
    End Object
    Components.Add(TMesh)
    MyMesh=TMesh
	/*
	 Begin Object Class=CylinderComponent Name=CollisionCylinder
        CollisionRadius=32.0
        CollisionHeight=64.0
        BlockNonZeroExtent=true
        BlockZeroExtent=true
        BlockActors=true
        CollideActors=true
    End Object
    CollisionComponent=CollisionCylinder
    Components.Add(CollisionCylinder)
*/
	ProjClass=class'UTGame.UTProj_LinkPowerPlasma'
	TurretHealth=500
	RoundsPerSec=3
}
