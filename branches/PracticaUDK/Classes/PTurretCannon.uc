class PTurretCannon extends PAutoTurret
	placeable;



defaultproperties
{

	 Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironmentrr
        bEnabled=TRUE
    End Object
    Components.Add(MyLightEnvironmentrr)
Begin Object class=SkeletalMeshComponent name=torretask
        
		AnimTreeTemplate=AnimTree'PGameContentcannon.basecannonAnimTree'
		AnimSets(0)=AnimSet'PGameContentcannon.basecannon'
		CollideActors=true 
		BlockActors=true
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		
		PhysicsAsset=PhysicsAsset'PGameContentcannon.cannonrudk_Physics'
        SkeletalMesh=SkeletalMesh'PGameContentcannon.cannonrudk'
        LightEnvironment=MyLightEnvironmentrr
		bHasPhysicsAssetInstance=true
		bDisableAllRigidBody=true//para que no se caigan las torretas 

        //Translation=(X=0,Y=0,z=-200)
    End Object
    
	TurretMesh=torretask
	
	CollisionComponent=torretask
    bCollideComplex=true
	bDisableAllRigidBody=true
	bDisableClientSidePawnInteractions=true
	Components.Add(torretask) 
	




	Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponent0
		SecondsBeforeInactive=1
	End Object
	MuzzleFlashEffect=ParticleSystemComponent0
	Components.Add(ParticleSystemComponent0)

	Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponent1
		SecondsBeforeInactive=1
	End Object
	DestroyEffect=ParticleSystemComponent1
	Components.Add(ParticleSystemComponent1)

	Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponent2
		SecondsBeforeInactive=10000.0
	End Object
	DamageEffect=ParticleSystemComponent2
	Components.Add(ParticleSystemComponent2)
	
	TurretBones={(
				DestroySocket=FireLocation,
				DamageSocket=FireLocation,
				FireSocket=FireLocation,
				PivotControllerName=PivotController
				)}
				
	TurretSounds={(
				FireSound=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_FireCue',
				DamageSound=SoundCue'A_Weapon_Stinger.Weapons.A_Weapon_Stinger_FireImpactCue',
				SpinUpSound=SoundCue'A_Vehicle_Turret.Cue.AxonTurret_PowerUpCue',
				WakeSound=SoundCue'A_Vehicle_Turret.Cue.A_Turret_TrackStart01Cue',
				SleepSound=SoundCue'A_Vehicle_Turret.Cue.A_Turret_TrackStop01Cue',
				DeathSound=SoundCue'A_Vehicle_Turret.Cue.AxonTurret_PowerDownCue'
				)}
	
	TurretEmitters={(
					DamageEmitter=ParticleSystem'TurretContent.P_TurretDamage',
					MuzzleFlashEmitter=ParticleSystem'WP_Stinger.Particles.P_Stinger_3P_MF_Alt_Fire',
					DestroyEmitter=ParticleSystem'FX_VehicleExplosions.Effects.P_FX_VehicleDeathExplosion',
					DamageEmitterParamName=DamageParticles
					)}

	TurretRotations={(
					IdleRotation=(Pitch=-8192,Yaw=0,Roll=0),
					AlertRotation=(Pitch=0,Yaw=0,Roll=0),
					DeathRotation=(Pitch=8192,Yaw=10922,Roll=4551)
					)}

	MinTurretRotRate=8192
	MaxTurretRotRate=128000
	bEdShouldSnap=true
	ProjClass=class'PGame.PMisiles'
	TurretHealth=500
	RoundsPerSec=50
	
}