class PMisiles extends UTProj_LoadedRocket;
var name disparador; //Qui�n dispara el projectile. Para control de TakeDamage �aposillo...
DefaultProperties
{

	ProjFlightTemplate=ParticleSystem'PGameMisilakos.MisilakoPawn'
	DamageRadius=220.0
	Damage=1
	checkradius=200.0
	speed=135.0
	MaxSpeed=400.0
	RotationRate=(Roll=500)//
	// Flocking
	FlockRadius=120
	FlockStiffness=-40
	FlockMaxForce=800
	FlockCurlForce=650
	
}
