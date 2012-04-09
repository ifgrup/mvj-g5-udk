class PTurret extends PKActor  
    abstract;
var Pawn P;
var Pawn Enemy;
var int TurretHealth;

var(Turret) class<Projectile> ProjClass;
var(Turret) Int RoundsPerSec;				//Number of rounds to fire per second





var Vector FireLocation;		
var Rotator FireRotation,rTorreta;	

var SkelControlSingleBone TurretControl;

var(Turret) SkeletalMeshComponent TurretMesh;	

simulated function   PostBeginPlay()
{
 local PEnemyBot PC;
 local UTPawn pa;


/*
local PPlayerController PC;

    foreach LocalPlayerControllers(class'PPlayerController', PC)
    {
        if(PC.Pawn != none)
            P = PC.Pawn;
    }
*/


// camputaramos del AnimTree SkelControlSingleBone con nombre PivotController
   TurretControl = SkelControlSingleBone(TurretMesh.FindSkelControl('PivotController'));
TurretControl.bApplyRotation = true;
		TurretControl.SetSkelControlStrength(1.0, 0.5);
		TurretControl.BlendInTime = 5.0;
		TurretControl.bAddRotation = true;
		TurretControl.BoneRotation = rTorreta;


//PivotController = SkelControlSingleBone(Mesh.FindSkelControl('pako'));

//Asignamos la localización y la rotación del socket con nombre FireLocation a las siguientes vars FireLocation y FireRotation 
TurretMesh.GetSocketWorldLocationAndRotation('FireLocation',FireLocation,FireRotation);
DrawDebugCylinder(FireLocation,FireLocation+vector(FireRotation)*100,4,30,0,200,0,true);
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

TurretControl.bApplyRotation = true;
		//TurretControl.SetSkelControlStrength(1.0, 0.5);
		//TurretControl.BlendInTime = 5.0;
		TurretControl.bAddRotation = true;
		
		TurretControl.BoneRotation = Enemy.Rotation;
TurretMesh.GetSocketWorldLocationAndRotation('FireLocation',FireLocation,FireRotation);
DrawDebugCylinder(FireLocation,FireLocation+vector(FireRotation)*100,4,30,0,200,0,true);

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
	//TurretControl.BoneRotation = rTorreta;
`log("la rotacion de la torreta " @rTorreta);
		//Proj = Spawn(ProjClass,self,,self.Location,self.Rotation,,True);
		Proj = Spawn(ProjClass,self,,FireLocation,FireRotation,,True);
		if( Proj != None && !Proj.bDeleteMe )
		{
			  GetEnemy();
			`log("la loca del enemy " @FireLocation);
			`log("la rota del enemy " @FireRotation);
			Proj.Init(Vector(FireRotation));
			//Proj.Init(Enemy.Location);
		
		
		}
	}



defaultproperties
{


 Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironmentrr
        bEnabled=TRUE
    End Object
    Components.Add(MyLightEnvironmentrr)
	



/*
	  Begin Object Class=StaticMeshComponent Name=DMesh
        //StaticMesh=StaticMesh'HU_Deco3.SM.Mesh.S_HU_Deco_SM_HydraulicSupport_C'
		StaticMesh=StaticMesh'PGameContentrr.cannon003'
        BlockActors=false
        CollideActors=true
        LightEnvironment=MyLightEnvironmentrr 
		//CollisionComponent=CollisionCylinder1
    //   Scale3D=(X=5,Y=5,Z=5)
    End Object
    Components.Add(DMesh)
    MyMesh=DMesh
	CollisionComponent=DMesh*/
	
	
 Begin Object class=SkeletalMeshComponent name=torretask
        
		AnimTreeTemplate=AnimTree'PGameContentcannon.basecannonAnimTree'
		AnimSets(0)=AnimSet'PGameContentcannon.basecannon'
		CollideActors=false 
		BlockActors=true
		BlockNonZeroExtent=true
		BlockZeroExtent=false
       
		PhysicsAsset=PhysicsAsset'PGameContentcannon.cannonrudk_Physics'
        SkeletalMesh=SkeletalMesh'PGameContentcannon.cannonrudk'
        LightEnvironment=MyLightEnvironmentrr
		bHasPhysicsAssetInstance=true
		
        //Translation=(X=0,Y=0,z=-200)
    End Object
    
	TurretMesh=torretask
    
	
	CollisionComponent=torretask
    bCollideComplex=true
	Components.Add(torretask) 

	
	ProjClass=class'PGame.PMisiles'
	TurretHealth=500
	RoundsPerSec=3
}
