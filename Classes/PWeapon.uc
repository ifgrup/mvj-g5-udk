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
	local Vector vDestinoTrace,HitLocation,HitNormal;

	// Spawn projectile
	pPlayerController=PPlayerController(Instigator.Controller);
	PosInicialDisparo = PPawn(pPlayerController.Pawn).GetPosicionSocketCabeza();
	DestinoDisparo = PHud(pPlayerController.myHUD).GetMirillaWorldLocation() ;
	if(DestinoDisparo == vect(0,0,0))
	{
		//Ahorramos cálculos, return. No sé en qué condiciones puede pasar esto la verdad...

		return None;
	}
	
	//Hacemos el Trace para el cálculo desde el bicho, y no desde la mirilla.
	//Ponemos 100 unidades más por si por el ángulo, nos quedamos cortos
	vDestinoTrace=Normal(DestinoDisparo-PosInicialDisparo) * (vsize(DestinoDisparo-PosInicialDisparo) + 100);

	//Para el trace, para que no de hit con el propio pawn, empezamos 100 unidades más tarde (habría que usar cylinder radius...)
	
	Trace(HitLocation, HitNormal, PosInicialDisparo+vDestinoTrace,PosInicialDisparo+normal(vDestinoTrace)*10, true,,, TRACEFLAG_Bullet);
	//Si realmente ha cambiado, actualizamos el destino del disparo
	if (HitLocation != vect(0,0,0) && vsize(HitLocation-DestinoDisparo)>1)
	{
		`log("Nuevo destino disparo "@HitLocation @DestinoDisparo);
		FlushPersistentDebugLines();
		DrawDebugCylinder(PosInicialDisparo,HitLocation,2,6,0,200,0,true);
		DrawDebugCylinder(PosInicialDisparo,DestinoDisparo,2,6,200,0,0,true);

		DestinoDisparo=HitLocation;
	}

	
	Dir = Normal(DestinoDisparo - PosInicialDisparo);//lo dirigimos al tagetlocatión
	MyProj = Spawn(GetProjectileClass(), Self,, PosInicialDisparo);
	if( MyProj != None && !MyProj.bDeleteMe )
	{
		MyProj.Init( Dir );
	}

	//pPlayerController.StopFire();
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