class PEnemyPawn_Minion extends PEnemy;

event TakeDamage(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
    if(PGame(WorldInfo.Game) != none)
        PGame(WorldInfo.Game).EnemyKilled();

    Destroy();
}

defaultproperties
{
	Begin Object Name=WPawnSkeletalMeshComponent
		SkeletalMesh=SkeletalMesh'Layout.GoodGuy_Blue'
	End Object
	GroundSpeed=100.0
}
