class PMisiKamitopota  extends UTProj_LoadedRocket;
var name disparador; //Quién dispara el projectile. Para control de TakeDamage ñaposillo...
DefaultProperties
{

	ProjFlightTemplate=ParticleSystem'PGameMisilakos.topotakamikaze'
	DamageRadius=220.0
	Damage=1
	checkradius=200.0
	speed=135.0
	MaxSpeed=400.0
	RotationRate=(Roll=50000)//
	// Flocking
	FlockRadius=120
	FlockStiffness=-40
	FlockMaxForce=800
	FlockCurlForce=650
	
}
