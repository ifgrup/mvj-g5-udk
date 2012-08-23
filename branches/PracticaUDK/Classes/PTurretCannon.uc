class PTurretCannon extends PAutoTurret
	placeable;


//Funcion definida en PAutoTurret, redefinida en cada hija
function DisparoTorreta()
{
	local Projectile Proj;
	//_DEBUG_ ("DIsparo Torreta");
	
	TurretMesh.GetSocketWorldLocationAndRotation('FireLocation',FireLocation,FireRotation);
	TurretMesh.GetSocketWorldLocationAndRotation('SocketPivote',IniFireLocation,IniFireRotation);
	
	Proj = Spawn(class'PMisiles',self,,FireLocation,,,True);
	PMisiles(Proj).disparador = 'PTurretCannon';
	Proj.Init(Normal(FireLocation-IniFireLocation));
}


defaultproperties
{

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironmentrr
        bEnabled=TRUE
    End Object
    Components.Add(MyLightEnvironmentrr)
	Begin Object class=SkeletalMeshComponent name=torretask
    	SkeletalMesh=SkeletalMesh'PGameContentcannon.cannonrudk'

		AnimTreeTemplate=AnimTree'PGameContentcannon.basecannonAnimTree'
		AnimSets(0)=AnimSet'PGameContentcannon.basecannon'
		
		bHasPhysicsAssetInstance=true
		PhysicsAsset=PhysicsAsset'PGameContentcannon.cannonrudk_Physics'
        
        LightEnvironment=MyLightEnvironmentrr
		
		bDisableAllRigidBody=true//para que no se caigan las torretas cuando las toquemos ##@|#|""$!!!

		CollideActors=true 
		BlockActors=true
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockRigidBody=true
        //Translation=(X=0,Y=0,z=-200)
    End Object

	TurretMesh=torretask //Por eso podemos acceder a la mesh con TurretMesh ;)
	CollisionComponent=torretask
	//Colisiones, su puta madre
	bCollideComplex=true 
	bCanStepUpOn=false
	BlockRigidBody=true
	bCollideActors=true
	bCollideWorld=true
	CollisionType=COLLIDE_BlockAll
	
	//VMHbDisableClientSidePawnInteractions=true

	Components.Add(torretask) 
	
    //Sistemas de partículas propios de TurretCannon
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
	
	Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponentEnConstruccion
		SecondsBeforeInactive=3.0
	End Object
	EnConstruccionEffect=ParticleSystemComponentEnConstruccion
	Components.Add(ParticleSystemComponentEnConstruccion)
	

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
					EnConstruccion=ParticleSystem'PGameParticles.Particles.EnConstruccion',
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
	RangoDisparo=3000

	

}