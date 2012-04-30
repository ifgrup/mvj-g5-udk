class PEnemy_Boss extends PEnemy
    placeable;






event TakeDamage(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	life--;
	if(life == 0)
		Destroy();
}
defaultproperties
{
    MovementSpeed=128.0
	life=1000;
}