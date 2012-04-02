class PTurret extends PKActor
    abstract;
var Pawn P;
var Pawn Enemy;
var int TurretHealth;

var(Turret) class<Projectile> ProjClass;
var(Turret) Int RoundsPerSec;				//Number of rounds to fire per second

function PostBeginPlay()
{

/*
local PPlayerController PC;

    foreach LocalPlayerControllers(class'PPlayerController', PC)
    {
        if(PC.Pawn != none)
            P = PC.Pawn;
    }
*/

 local PEnemyBot PC;
 local UTPawn pa;

    foreach VisibleCollidingActors(class'PEnemyBot', PC,2000.f)
    {
		`log("veo veo "@PC);
    if(PC.Pawn != none)
           Enemy = PC.Pawn;
    }
foreach WorldInfo.AllPawns(class'UTPawn', pa)
			{
			`log("encuentra argo marika2 " @pa);

			}

	

}


function GetEnemy()
{
    local PEnemy_Minion PC;
	local UTPawn pa;
    
	foreach WorldInfo.AllPawns(class'UTPawn',pa)
			{
			`log("encuentra argo marika " @pa.Location);
			Enemy=pa;
			}

	/*foreach VisibleCollidingActors(class'PEnemy_Minion', PC,2000.f)
    {
		`log("veo veo "@PC);
      if(PC != none)
           Enemy = PC.UTPawn;
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
     
		 if(Enemy == none)
            GetEnemy();

		  if(Enemy != none)
        {
    //	TimedFire();
        }

       

      
    }
}



function TimedFire()
	{
		local Projectile Proj;
	
		Proj = Spawn(ProjClass,self,,self.Location,self.Rotation,,True);

		if( Proj != None && !Proj.bDeleteMe )
		{
			`log("la loca del enemy " @Enemy.Location);
			`log("la rota del enemy " @Enemy.RotationRate);
			Proj.Init(Vector(Enemy.Rotation));
		
		
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
        //StaticMesh=StaticMesh'HU_Deco3.SM.Mesh.S_HU_Deco_SM_HydraulicSupport_C'
		StaticMesh=StaticMesh'PGameContentrr.cannon003'
        BlockActors=false
        CollideActors=true
        LightEnvironment=MyLightEnvironmentrr 
		//CollisionComponent=CollisionCylinder1
       // Scale3D=(X=2.25,Y=2.25,Z=2.25)
    End Object
    Components.Add(DMesh)
    MyMesh=DMesh
	CollisionComponent=DMesh
	

	ProjClass=class'PGame.PMisiles'
	TurretHealth=500
	RoundsPerSec=3
}
