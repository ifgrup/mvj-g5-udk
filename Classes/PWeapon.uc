class PWeapon extends UDKWeapon;
//class PWeapon extends UTWeap_RocketLauncher_Content;
/*
simulated function TimeWeaponEquipping()
{
	AttachWeaponTo( Instigator.Mesh,'SocketCabeza' );
	super.TimeWeaponEquipping();
}
*/

simulated function AttachWeaponTo(SkeletalMeshComponent MeshCpnt, optional Name SocketName)
{
	local PPawn P;
	P = PPawn(Instigator);
	
	MeshCpnt.AttachComponentToSocket(Mesh, SocketName);
	Mesh.SetLightEnvironment(P.LightEnvironment);
}

simulated function ProcessInstantHit(byte FiringMode, ImpactInfo Impact, optional int NumHits)
{
	super.ProcessInstantHit(FiringMode, Impact, NumHits);

    WorldInfo.MyDecalManager.SpawnDecal
    (
	DecalMaterial'HU_Deck.Decals.M_Decal_GooLeak',	// UMaterialInstance used for this decal.
	Impact.HitLocation,	                            // Decal spawned at the hit location.
	rotator(-Impact.HitNormal),	                    // Orient decal into the surface.
	128, 128,	                                    // Decal size in tangent/binormal directions.
	256,	                                        // Decal size in normal direction.
	false,	                                        // If TRUE, use "NoClip" codepath.
	FRand() * 360,	                                // random rotation
	,                    // If non-NULL, consider this component only.
    ,
	,
	,
	,
	,100000
	);
}



simulated function Projectile ProjectileFire()
{
	local Projectile MyProj;
	local PPlayerController pPlayerController;
	local Vector PosInicialDisparo,Dir;
	local Vector DestinoDisparo;

	// Spawn projectile
	pPlayerController=PPlayerController(Instigator.Controller);
	PosInicialDisparo = PPawn(pPlayerController.Pawn).GetPosicionSocketCabeza();
	
	DestinoDisparo = PHud(pPlayerController.myHUD).GetMirillaWorldLocation() ;
	if (DestinoDisparo == vect(0,0,0))
	{
		return None;
	}
	
	Dir =Normal(DestinoDisparo - PosInicialDisparo);//lo dirigimos al tagetlocati�n
	

	MyProj = Spawn(GetProjectileClass(), Self,, PosInicialDisparo);
	if( MyProj != None && !MyProj.bDeleteMe )
	{
		MyProj.Init( Dir );
	}

	pPlayerController.StopFire();
	return MyProj;
}
/*simulated event SetPosition(UDKPawn Holder)
{
    local vector FinalLocation;
    local vector X,Y,Z;

    Holder.GetAxes(Holder.Controller.Rotation,X,Y,Z);
	
    FinalLocation= Holder.GetPawnViewLocation(); //this is in world space.

    FinalLocation = FinalLocation- Y * 12 - Z * 32; // Rough position adjustment

    SetHidden(False);
    SetLocation(FinalLocation);
    SetBase(Holder);

    SetRotation(Holder.Controller.Rotation);
}*/

defaultproperties
{
	/*
	Begin Object Class=SkeletalMeshComponent Name=WeaponMesh
		SkeletalMesh=SkeletalMesh'WP_LinkGun.Mesh.SK_WP_LinkGun_3P'
	End Object
	Mesh=WeaponMesh
	Components.Add(WeaponMesh)
   */
	FiringStatesArray(0)=WeaponFiring
	FiringStatesArray(1)=WeaponFiring
 
	//WeaponFireTypes(0)=EWFT_Projectile
	WeaponFireTypes(0)=EWFT_Projectile
	WeaponFireTypes(1)=EWFT_InstantHit

	WeaponProjectiles(0)=class'PMisiles'
	WeaponProjectiles(1)=none
 
	FireInterval(0)=+0.3
	FireInterval(1)=+0.3
 
	Spread(0)=0.0
	Spread(1)=0.0
 
//	ShotCost(0)=1
//	ShotCost(1)=1
 
	AmmoCount=5
//	MaxAmmoCount=5
 
	InstantHitDamage(0)=0.0
	InstantHitDamage(1)=0.0
	InstantHitMomentum(0)=0.0
	InstantHitMomentum(1)=0.0
	InstantHitDamageTypes(0)=class'DamageType'
	InstantHitDamageTypes(1)=class'DamageType'
	WeaponRange=2000
 
	ShouldFireOnRelease(0)=0
	ShouldFireOnRelease(1)=0

}