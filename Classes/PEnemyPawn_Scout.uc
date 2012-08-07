class PEnemyPawn_Scout extends PEnemy;

var MaterialInstanceConstant mat;
var SkeletalMeshComponent ColorMesh;
var LinearColor Col1;

simulated function PostBeginPlay()
{
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

event TakeDamage(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local float dst;

	PEnemy_AI_Bot(Owner).RecibirDanyo(iDamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);

	if(PMisiles(DamageCauser) != None)
	{
		dst = vsize (self.Location - PEnemy_AI_Bot(Owner).theBase.Location);
		`log("Scout: el puto Giru me ha disparado a dist de base ="@dst);
	}

   
	life--;
	if(life == 0)
	{
		
		Destroy();
		if(PGame(WorldInfo.Game) != none)
		{
		    PGame(WorldInfo.Game).ScoutKilled();
			PGame(WorldInfo.Game).SetCredito(PGame(WorldInfo.Game).creditos+ m_puntos_al_morir);
		}
	}
  
}

defaultproperties
{
	Begin Object Name=WPawnSkeletalMeshComponent
		SkeletalMesh=SkeletalMesh'Gelatinos.Gusano.GelatinoGusano01'
		Translation=(Z=-50.0)
		Scale=3
	End Object

	ColorMesh=WPawnSkeletalMeshComponent

	GroundSpeed=300.0
	m_puntos_al_morir = 300
}
