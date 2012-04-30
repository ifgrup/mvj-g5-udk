class PEnemyPawn_Scout extends PEnemy;

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
		SkeletalMesh=SkeletalMesh'Layout.BadGuy_Red'
	End Object
	GroundSpeed=200.0
}
