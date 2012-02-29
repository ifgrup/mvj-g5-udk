class PEnemy_Boss extends PEnemy
    placeable;

var int life;

defaultproperties
{
    MovementSpeed=128.0
	life=10;

    Begin Object Name=EnemyMesh
        Scale3D=(X=3.0,Y=3.0,Z=3.0)
    End Object

    Begin Object Name=CollisionCylinder
        CollisionRadius=128.0
        CollisionHeight=256.0
    End Object
}


event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	life--;
	if(life == 0)
		Destroy();
}