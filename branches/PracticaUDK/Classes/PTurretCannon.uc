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
		
		PhysicsAsset=PhysicsAsset'PGameContentcannon.cannonrudk_Physics'
		bHasPhysicsAssetInstance=true
        SkeletalMesh=SkeletalMesh'PGameContentcannon.cannonrudk'
        LightEnvironment=MyLightEnvironmentrr
		
		//bDisableAllRigidBody=true//para que no se caigan las torretas 


		CollideActors=true 
		BlockActors=true
		BlockNonZeroExtent=true
		BlockZeroExtent=true

	bDisableAllRigidBody=true

        //Translation=(X=0,Y=0,z=-200)
    End Object
    
	TurretMesh=torretask
	
	CollisionComponent=torretask
    bCollideComplex=true
	
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
				DamageSound=SoundCue'A_Music_GoDown.MusicSegments.A_Music_GoDown_Ambient01Cue',
				SpinUpSound=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_FireCue',
				WakeSound=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_FireCue',
				SleepSound=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_FireCue',
				DeathSound=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_FireCue'
				)}
	
	TurretEmitters={(
					DamageEmitter=ParticleSystem'WP_LinkGun.Effects.P_FX_LinkGun_3P_Beam_MF_Red',
					MuzzleFlashEmitter=ParticleSystem'WP_LinkGun.Effects.P_FX_LinkGun_3P_Beam_MF_Red',
					DestroyEmitter=ParticleSystem'WP_LinkGun.Effects.P_FX_LinkGun_3P_Beam_MF_Red',
					DamageEmitterParamName=DamageParticles
					)}

	TurretRotations={(
					IdleRotation=(Pitch=0,Yaw=15000,Roll=0),
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