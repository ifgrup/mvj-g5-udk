class PEnemyPawn extends PPawn
	placeable;

var Pawn P;

var SkeletalMesh defaultMesh;
var MaterialInterface defaultMaterial;
var AnimTree defaultAnimTree;
var array<AnimSet> defaultAnimSet;
var AnimNodeSequence defaultAnimSeq;
var PhysicsAsset defaultPhysicsAsset;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	SetPhysics(PHYS_Spider);
}

event Tick(float DeltaTime)
{

}

// called when the pawn lands or hits another surface
event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
{
	SetPhysics(PHYS_Spider);
}

simulated function SetCharacterClassFromInfo(class <UTFamilyInfo> Info)
{
	Mesh.SetSkeletalMesh(defaultMesh);
	Mesh.SetMaterial(0, defaultMaterial);
	Mesh.SetPhysicsAsset(defaultPhysicsAsset);
	Mesh.AnimSets = defaultAnimSet;
	Mesh.SetAnimTreeTemplate(defaultAnimTree);
}

simulated event Bump(Actor Other, PrimitiveComponent OtherComp, Vector HitNormal)
{
	`Log("Bump");
	Super.Bump(Other, OtherComp, HitNormal);
	if(Other == none || Other.bStatic)
	{
		return;
	}

	P = Pawn(Other);

	if(P != none)
	{
		if(P.Health > 1)
			P.Health--;
	}
}

DefaultProperties
{
	/*
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
	End Object*/

	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment
/*
	Begin Object Class=SkeletalMeshComponent Name=WPawnSkeletalMeshComponent
		AnimTreeTemplate=AnimTree'CH_AnimHuman_Tree.AT_CH_Human'
		SkeletalMesh=SkeletalMesh'Layout.BadGuy_Red'
		PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
		AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
	End Object*/
	
	Mesh=WPawnSkeletalMeshComponent
	Components.Add(WPawnSkeletalMeshComponent)
	
	// Esto tiene algo que ver con el modelo físico de colisiones del modelo
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0021.000000
		CollisionHeight=+0044.000000
		BlockNonZeroExtent=True
		BlockZeroExtent=True
		BlockActors=True
		CollideActors=True
	End Object

	// Lo añadimos al motor
	//CylinderComponent=CollisionCylinder
	CollisionComponent=CollisionCylinder
    Components.Add(CollisionComponent);

	AirSpeed=100
	GroundSpeed=100
	ControllerClass=class'PEnemyBot'
}
