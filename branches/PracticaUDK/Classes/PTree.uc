class PTree extends PKActor;

var(Tree) SkeletalMeshComponent TreeMesh;

var SkeletalMesh skMesh0;
var PhysicsAsset physAsset0;
var SkeletalMesh skMesh1;
var PhysicsAsset physAsset1;
var SkeletalMesh skMesh2;
var PhysicsAsset physAsset2;

var MaterialInstanceConstant mat;

simulated function PostBeginPlay()
{
	local int i, j;
	local SkeletalMesh sk;
	local PhysicsAsset pa;
	local array<MaterialInstanceConstant> m;

	i=Rand(3);
	switch(i)
	{
	case 0:
		sk=skMesh0;
		pa=physAsset0;
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol01_MAT_01');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol01_MAT_02');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol01_MAT_03');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol01_MAT_04');
		break;
	case 1:
		sk=skMesh1;
		pa=physAsset1;
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol03_MAT_01');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol03_MAT_02');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol03_MAT_03');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol03_MAT_04');
		break;
	case 2:
		sk=skMesh2;
		pa=physAsset2;
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol04_MAT_01');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol04_MAT_02');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol04_MAT_03');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol04_MAT_04');
		break;
	}

	TreeMesh.SetSkeletalMesh(sk);
	TreeMesh.SetPhysicsAsset(pa);

	j = Rand(m.Length);
	TreeMesh.SetMaterial(0, m[j]);
}

defaultproperties
{
	Begin Object class=SkeletalMeshComponent name=tree
		SkeletalMesh=SkeletalMesh'Vegetacion.Arbol01'
		PhysicsAsset=PhysicsAsset'Vegetacion.Arbol01_Physics'
		CollideActors=true
		BlockActors=true
		BlockZeroExtent=true
		BlockNonZeroExtent=true
		BlockRigidBody=true
		bHasPhysicsAssetInstance=true
		bUpdateKinematicBonesFromAnimation=false
		PhysicsWeight=1.0
		RBChannel=RBCC_GameplayPhysics
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE)
		LightEnvironment=MyLightEnvironment
		bSkipAllUpdateWhenPhysicsAsleep=TRUE
		bBlockFootPlacement=false
    End Object

	TreeMesh=tree
	skMesh0=SkeletalMesh'Vegetacion.Arbol01'
	physAsset0=PhysicsAsset'Vegetacion.Arbol01_Physics'
	skMesh1=SkeletalMesh'Vegetacion.Arbol03'
	physAsset1=PhysicsAsset'Vegetacion.Arbol03_Physics'
	skMesh2=SkeletalMesh'Vegetacion.Arbol04'
	physAsset2=PhysicsAsset'Vegetacion.Arbol04_Physics'

	CollisionComponent=tree
//	bCollideComplex=true 
	bCanStepUpOn=false
	BlockRigidBody=true
	bCollideActors=true
	bCollideWorld=true
	//CollisionType=COLLIDE_BlockAll
	Components.Add(tree) 

	Physics=PHYS_None
}
