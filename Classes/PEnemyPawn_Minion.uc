class PEnemyPawn_Minion extends PEnemy;

var MaterialInstanceConstant mat;
var SkeletalMeshComponent ColorMesh;
var LinearColor Col1, Col2;

function PostBeginPlay()
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
		SkeletalMesh=SkeletalMesh'Gelatinos.Walker.GelatinoBipedoEsqueleto'
		Translation=(Z=-70.0)
		Scale=0.7
	End Object

	ColorMesh=WPawnSkeletalMeshComponent

	GroundSpeed=100.0
}
