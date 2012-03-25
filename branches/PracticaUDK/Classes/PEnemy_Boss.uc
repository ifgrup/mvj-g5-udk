class PEnemy_Boss extends PEnemy
    placeable;

var int life;

defaultproperties
{
    MovementSpeed=128.0
	life=10;
}


event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	life--;
	if(life == 0)
		Destroy();
}