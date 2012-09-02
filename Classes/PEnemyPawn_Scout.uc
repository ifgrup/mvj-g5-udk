class PEnemyPawn_Scout extends PEnemy;

var MaterialInstanceConstant mat;
var SkeletalMeshComponent ColorMesh;
var LinearColor Col1;

simulated function PostBeginPlay()
{
	//super.PostBeginPlay();
	Col1 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	mat = new class'MaterialInstanceConstant';
	mat = ColorMesh.CreateAndSetMaterialInstanceConstant(0);
	mat.SetParent(Material'Gelatinos.Gusano.GelatinoGusanoMat_MASTER');
	mat.SetVectorParameterValue('ColorBase', Col1);

	ColorMesh.SetMaterial(0, mat);
}

function SetColor(LinearColor Col)
{
	Col1 = Col;
	mat.SetVectorParameterValue('ColorBase', Col1);
}



defaultproperties
{
	Begin Object Name=PEnemySkeletalMeshComponent
		//SkeletalMesh=SkeletalMesh'Gelatinos.Gusano.GelatinoGusano01'
		SkeletalMesh=SkeletalMesh'Ogro.Ogre'
		PhysicsAsset=PhysicsAsset'Ogro.Ogre_Physics_V2'
		AnimTreeTemplate=AnimTree'Ogro.Ogro_AnimTree'
		AnimSets(0)=AnimSet'Ogro.Ogro_Anim'


		Translation=(Z=-50.0)
		Scale=3
	End Object

	ColorMesh=PEnemySkeletalMeshComponent

	GroundSpeed=100.0
	m_defaultGroundSpeed=GroundSpeed
	m_puntos_al_morir = 300
}
