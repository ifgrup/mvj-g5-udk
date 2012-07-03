class PEnemyPawn_Minion extends PEnemy;

var MaterialInstanceConstant mat;
var SkeletalMeshComponent ColorMesh;
var LinearColor Col1, Col2;

simulated function PostBeginPlay()
{
	Col1 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	Col2 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	mat = new class'MaterialInstanceConstant';
	mat = ColorMesh.CreateAndSetMaterialInstanceConstant(0);
	mat.SetParent(Material'Gelatinos.Walker.Gelatino_Walker_MASTER');
	mat.SetVectorParameterValue('ColorBase', Col1);
	mat.SetVectorParameterValue('DetailColor', Col2);

	ColorMesh.SetMaterial(0, mat);
}

function SetColor(LinearColor Col)
{
	Col1 = Col;
	mat.SetVectorParameterValue('ColorBase', Col1);
}

event TakeDamage(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
    if(PGame(WorldInfo.Game) != none)
        PGame(WorldInfo.Game).EnemyKilled();
	life--;
	if(life == 0)
		Destroy();
  
}

defaultproperties
{
	
	Begin Object Name=WPawnSkeletalMeshComponent
		//SkeletalMesh=SkeletalMesh'Gelatinos.Walker.GelatinoBipedoEsqueleto'
		//Translation=(Z=-70.0)
		//Scale=3
		
		//ogro
		/*
		SkeletalMesh=SkeletalMesh'Ogro.Ogre'
		AnimTreeTemplate=AnimTree'Ogro.Ogro_AnimTree'
		PhysicsAsset=PhysicsAsset'Ogro.Ogre_Physics_V2'
		AnimSets(0)=AnimSet'Ogro.Ogro_Anim'
		Translation=(Z=-70.0)
		Scale=3
		*/
		//otro para demo
		SkeletalMesh=SkeletalMesh'CH_LIAM_Cathode.Mesh.SK_CH_LIAM_Cathode'
		AnimTreeTemplate=AnimTree'CH_AnimHuman_Tree.AT_CH_Human'
		PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
		AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
		Scale=3

		bCacheAnimSequenceNodes=FALSE
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false
		CastShadow=true
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=TRUE
		bUpdateKinematicBonesFromAnimation=true
		bCastDynamicShadow=true
		LightEnvironment=MyLightEnvironment
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=FALSE
		bUseOnePassLightingOnTranslucency=TRUE
		bPerBoneMotionBlur=true
		HiddenGame=False
	End Object

	//ColorMesh=WPawnSkeletalMeshComponent
	 Mesh=WPawnSkeletalMeshComponent
	GroundSpeed=300.0
}
