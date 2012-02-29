class PAutoTurret extends Pawn HideCategories(AI,Camera,Debug,Pawn,Physics)
	placeable;


//Min and Max Rotators Struct - limiting turret rotation
struct RotationRange
{
	var() Rotator RotLimitMin;
	var() Rotator RotLimitMax;
	var() Bool bLimitPitch;
	var() Bool bLimitYaw;
	var() Bool bLimitRoll;
	
	structdefaultproperties
	{
		RotLimitMin=(Pitch=-65536,Yaw=-65536,Roll=-65536)
		RotLimitMax=(Pitch=65536,Yaw=65536,Roll=65536)
	}
};

// Sounds for turret behaviors
struct TurretSoundGroup
{
	var() SoundCue FireSound;
	var() SoundCue DamageSound;
	var() SoundCue SpinUpSound;
	var() SoundCue WakeSound;
	var() SoundCue SleepSound;
	var() SoundCue DeathSound;
};

//PSystems for the turret
struct TurretEmitterGroup
{
	var() ParticleSystem DamageEmitter;
	var() ParticleSystem MuzzleFlashEmitter;
	var() ParticleSystem DestroyEmitter;
	var() Float MuzzleFlashDuration;
	var() Name DamageEmitterParamName;
	var() Bool bStopDamageEmitterOnDeath;
	
	structdefaultproperties
	{
		MuzzleFlashDuration=0.33
	}
};

//Bone, Socket, Controller names
struct TurretBoneGroup
{
	var() Name DestroySocket;
	var() Name DamageSocket;
	var() Name FireSocket;
	var() Name PivotControllerName;
};

//Rotators defining turret poses
struct TurretRotationGroup
{
	var() Rotator IdleRotation;
	var() Rotator AlertRotation;
	var() Rotator DeathRotation;
	var() Bool bRandomDeath;
};


/*Class variables*/
var PPawn EnemyTarget;	//The new enemy the turret should target - set from the controller or TakeDamage()
var PPawn LastEnemyTarget;	//The enemy the turret is targeting in the current interpolation

var Vector EnemyDir;	//Vector from the turret's base to the enemy's location this tick
var Vector LastEnemyDir;		//Vector from the turret's base to the enemy's location last tick

var float TotalInterpTime;	//Total number of seconds it will take to interpolate to the target
var Float ElapsedTime;		//Time spent in the current interpolation to the target
var Float RotationAlpha;		//Curret alpha for interpolating to a new rotation
var Rotator StartRotation;	//Beginning rotation for interpolating
var Rotator TargetRotation;	//Desired rotations for interpolating

var Vector FireLocation;		//World position of the firing socket
var Rotator FireRotation;	//World orientation of the firing socket

var SkelControlSingleBone PivotController;	//Reference to the skelcontrol in the AnimTree

var Bool bCanFire;		//Is the turret in a firing state?
var Bool bDestroyed;	//Has the turret been destroyed?

var ParticleSystemComponent DamageEffect;		//PSys component for playing damage effects
var ParticleSystemComponent MuzzleFlashEffect;	//PSys component for playing muzzle flashes
var ParticleSystemComponent DestroyEffect;		//PSys component for playing destruction effects

var Int MaxTurretHealth;		//Max health for this turret
var Float FullRevTime;	//Seconds to make full rev at min rot rate

var Float GElapsedTime;	//Elapsed time since last global tick
var Int OrigMinRotRate;	//Beginning value of MinTurretRotRate


/*Designer editable variables*/
var(Turret) SkeletalMeshComponent TurretMesh;				//SkelMeshComp for the turret
var(Turret) DynamicLightEnvironmentComponent LightEnvironment;	//LightEnvironment for the turret
var(Turret) SkeletalMesh DestroyedMesh;						//SkelMesh to show when turret is destroyed

var(Turret) TurretBoneGroup TurretBones;	//Bone, Socket, Controller names

var(Turret) TurretRotationGroup TurretRotations;	//Rotations defining turret poses
var(Turret) RotationRange RotLimit;			//Rotation limits for turret
var(Turret) Int MinTurretRotRate;				//Min Rotation speed Rot/Second
var(Turret) Int MaxTurretRotRate;				//Max Rotation speed Rot/Second

var(Turret) class<Projectile> ProjClass;	//Type of projectile the turret fires
var(Turret) Int RoundsPerSec;				//Number of rounds to fire per second
var(Turret) Int AimRotError;				//Maximum units of error in turret aiming

var(Turret) TurretEmitterGroup TurretEmitters;	//PSystems used by the turret

var(Turret) TurretSoundGroup TurretSounds;		//Sounds used for different turret behaviors

var(Turret) Int TurretHealth;		//Initial amount of health for the turret



event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	MaxTurretHealth = TurretHealth;
	OrigMinRotRate = MinTurretRotRate;
	FullRevTime = 65536.0 / Float(MinTurretRotRate);

	PivotController = SkelControlSingleBone(Mesh.FindSkelControl(TurretBones.PivotControllerName));

	Mesh.GetSocketWorldLocationAndRotation(TurretBones.FireSocket,FireLocation,FireRotation);

	Mesh.AttachComponentToSocket(DamageEffect, TurretBones.DamageSocket);
	Mesh.AttachComponentToSocket(MuzzleFlashEffect, TurretBones.FireSocket);
	Mesh.AttachComponentToSocket(DestroyEffect, TurretBones.DestroySocket);

	DamageEffect.SetTemplate(TurretEmitters.DamageEmitter);
	MuzzleFlashEffect.SetTemplate(TurretEmitters.MuzzleFlashEmitter);
	DestroyEffect.SetTemplate(TurretEmitters.DestroyEmitter);

	SetPhysics(PHYS_None);
}

auto state Idle
{
	event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
	{
		Global.TakeDamage(Damage,InstigatedBy,HitLocation,Momentum,DamageType,HitInfo,DamageCauser);

		if(TurretHealth > 0)
		{
			GotoState('Alert');
		}
	}

	function Tick(Float Delta)
	{
		local Float currDot;
		local Float thisDot;
		local PPawn P;
		local Bool bHasTarget;
		
		currDot = -1.01;
	
		if(GElapsedTime > 0.5 && !bDestroyed)
		{
			GElapsedTime = 0.0;
			bHasTarget = false;

			foreach WorldInfo.AllPawns(class'PGame.PPawn', P)
			{
				if(FastTrace(P.Location, FireLocation))
				{
					thisDot = Normal(Vector(PivotController.BoneRotation)) Dot
							Normal(((P.Location - FireLocation) << Rotation));
	
					if(	P.Health > 0 &&
						VSize(P.Velocity) > 16.0 &&
						thisDot >= 0.0 &&
						thisDot >= currDot	)
					{
						EnemyTarget = P;
		                    currDot = thisDot;
		                    bHasTarget = true;
					}
				}
			}
	
			if(bHasTarget && !bDestroyed && !IsInState('Defend'))
			{
				GotoState('Defend');
			}
			else if(!bHasTarget && !bDestroyed && IsInState('Defend'))
			{
				GotoState('Alert');
			}
		}
		else
		{
			GElapsedTime += Delta;
		}
	}
	
	function BeginIdling()
	{
		DoRotation(TurretRotations.IdleRotation, 1.0);

          if(TurretSounds.SleepSound != None)
			PlaySound(TurretSounds.SleepSound);
	}
	
	event BeginState(Name PreviousStateName)
	{
		if(PreviousStateName != 'Alert')
		{
			DoRotation(TurretRotations.AlertRotation, 1.0);
			SetTimer(1.0,false,'BeginIdling');
		}
		else
			BeginIdling();
	}
}

state() Alert
{
	function IdleTimer()
	{
		if(!bDestroyed)
		{
			GotoState('Idle');
		}
	}
	
	function Tick(Float Delta)
	{
		local Rotator AnimRot;

		Global.Tick(Delta);

		AnimRot.Yaw = MinTurretRotRate * Delta;
		PivotController.BoneRotation += AnimRot;

		if(RotLimit.bLimitYaw)
		{
			if(	PivotController.BoneRotation.Yaw >= RotLimit.RotLimitMax.Yaw 	||
				PivotController.BoneRotation.Yaw <= RotLimit.RotLimitMin.Yaw	)
			{
				MinTurretRotRate *= -1;
			}
		}
	}

	event BeginState(Name PreviousStateName)
	{
		local Rotator AlertRot;
		local Float RevTime;

		AlertRot = TurretRotations.AlertRotation;
		AlertRot.Yaw = PivotController.BoneRotation.Yaw % 65536;

		if(RotLimit.bLimitYaw)
		{
			if(AlertRot.Yaw > Float(RotLimit.RotLimitMax.Yaw + RotLimit.RotLimitMin.Yaw) / 2.0)
			{
				RevTime = (Float(AlertRot.Yaw - RotLimit.RotLimitMin.Yaw) / Float(OrigMinRotRate)) +
						(Float(RotLimit.RotLimitMax.Yaw - RotLimit.RotLimitMin.Yaw) / Float(OrigMinRotRate)) +
						(Float(RotLimit.RotLimitMax.Yaw - TurretRotations.AlertRotation.Yaw) / Float(OrigMinRotRate));

				MinTurretRotRate = -1 * OrigMinRotRate;
			}
			else
			{
				RevTime = (Float(RotLimit.RotLimitMax.Yaw - AlertRot.Yaw) / Float(OrigMinRotRate)) +
						(Float(RotLimit.RotLimitMax.Yaw - RotLimit.RotLimitMin.Yaw) / Float(OrigMinRotRate)) +
						(Float(TurretRotations.AlertRotation.Yaw - RotLimit.RotLimitMin.Yaw) / Float(OrigMinRotRate));

				MinTurretRotRate = OrigMinRotRate;
			}
		}
		else
		{
			RevTime = FullRevTime;
			if(AlertRot.Yaw > (TurretRotations.AlertRotation.Yaw + 32768))
			{
				RevTime += Float(AlertRot.Yaw - (TurretRotations.AlertRotation.Yaw + 65536)) / 
						Float(OrigMinRotRate);

				MinTurretRotRate = -1 * OrigMinRotRate;
			}
			else
			{
				RevTime += Float(TurretRotations.AlertRotation.Yaw - AlertRot.Yaw) / 
						Float(OrigMinRotRate);

				MinTurretRotRate = OrigMinRotRate;
			}
		}
		
		SetTimer(RevTime + 1.0,false,'Idletimer');

		DoRotation(AlertRot, 1.0);

          if(TurretSounds.WakeSound != None)
			PlaySound(TurretSounds.WakeSound);
	}
}

state Defend
{
	function BeginFire()
	{
		if(RoundsPerSec > 0)
		{
			SetTimer(1.0/RoundsPerSec,true,'TimedFire');
			bCanFire = true;
		}
	}

	function TimedFire()
	{
		local Projectile Proj;
	
		Proj = Spawn(ProjClass,self,,FireLocation,FireRotation,,True);

		if( Proj != None && !Proj.bDeleteMe )
		{
			Proj.Init(Vector(FireRotation));
		}

		if(TurretEmitters.MuzzleFlashEmitter != None)
		{
			MuzzleFlashEffect.ActivateSystem();
			SetTimer(TurretEmitters.MuzzleFlashDuration,false,'StopMuzzleFlash');
		}

		if(TurretSounds.FireSound != None)
			PlaySound(TurretSounds.FireSound);
	}

	function StopMuzzleFlash()
	{
		MuzzleFlashEffect.DeactivateSystem();
	}
	
	function Tick(Float Delta)
	{
		local Rotator InterpRot;
		local Rotator DiffRot;
		local Int MaxDiffRot;

		Global.Tick(Delta);

		if(bCanFire)
		{
			EnemyDir = EnemyTarget.Location - Location;

			if(	EnemyTarget != LastEnemyTarget 	||
				ElapsedTime >= TotalInterpTime 	||
				EnemyDir != LastEnemyDir			)
			{
				LastEnemyDir = EnemyDir;
				LastEnemyTarget = EnemyTarget;
				StartRotation = PivotController.BoneRotation;
				TargetRotation = Rotator((EnemyTarget.Location - FireLocation) << Rotation);
				DiffRot = TargetRotation - StartRotation;
				MaxDiffRot = Max(Max(DiffRot.Pitch,DiffRot.Yaw),DiffRot.Roll);
				TotalInterpTime = Abs(Float(MaxDiffRot) / Float(MaxTurretRotRate));
				ElapsedTime = Delta;
			}
			else
			{
				ElapsedTime += Delta;
			}

			RotationAlpha = FClamp(ElapsedTime / TotalInterpTime,0.0,1.0);
			InterpRot = RLerp(StartRotation,TargetRotation,RotationAlpha,true);

			if(RotLimit.bLimitPitch)
				InterpRot.Pitch = Clamp(InterpRot.Pitch, RotLimit.RotLimitMin.Pitch, RotLimit.RotLimitMax.Pitch);

			if(RotLimit.bLimitYaw)
				InterpRot.Yaw = Clamp(InterpRot.Yaw, RotLimit.RotLimitMin.Yaw, RotLimit.RotLimitMax.Yaw);

			if(RotLimit.bLimitRoll)
				InterpRot.Roll = Clamp(InterpRot.Roll, RotLimit.RotLimitMin.Roll, RotLimit.RotLimitMax.Roll);

			PivotController.BoneRotation = InterpRot;

			Mesh.GetSocketWorldLocationAndRotation(TurretBones.FireSocket,FireLocation,FireRotation);

			FireRotation.Pitch += Rand(AimRotError * 2) - AimRotError;
			FireRotation.Yaw += Rand(AimRotError * 2) - AimRotError;
			FireRotation.Roll += Rand(AimRotError * 2) - AimRotError;
		}
	}


	event BeginState(Name PreviousStateName)
	{
		if(PreviousStateName == 'Alert')
		{
			if(IstImerActive('IdleTimer'))
				ClearTimer('IdleTimer');
		}
	
		bCanFire = false;
		
		Mesh.GetSocketWorldLocationAndRotation(TurretBones.FireSocket,FireLocation,FireRotation);
		
		DoRotation(Rotator((EnemyTarget.Location - FireLocation) << Rotation), 1.0);
		
		if(TurretSounds.SpinUpsound != None)
			PlaySound(TurretSounds.SpinUpSound);
		
		SetTimer(1.0,false,'BeginFire');
	}
	
	event EndState(Name NewStateName)
	{
          ClearTimer('TimedFire');
	}
}

state Dead
{
	ignores Tick, Takedamage;
	
	function PlayDeath()
	{
		if(TurretEmitters.DestroyEmitter != None)
			DestroyEffect.ActivateSystem();

		if(TurretSounds.DeathSound != None)
			PlaySound(TurretSounds.DeathSound);

		if(DestroyedMesh != None)
			Mesh.SetSkeletalMesh(DestroyedMesh);

		if(TurretEmitters.bStopDamageEmitterOnDeath)
			DamageEffect.DeactivateSystem();
	}

	function DoRandomDeath()
	{
		local Rotator DeathRot;
	
		DeathRot = RotRand(true);

		if(RotLimit.bLimitPitch)
			DeathRot.Pitch = Clamp(DeathRot.Pitch, RotLimit.RotLimitMin.Pitch, RotLimit.RotLimitMax.Pitch);
		if(RotLimit.bLimitYaw)
			DeathRot.Yaw = Clamp(DeathRot.Yaw, RotLimit.RotLimitMin.Yaw, RotLimit.RotLimitMax.Yaw);
		if(RotLimit.bLimitRoll)
			DeathRot.Roll = Clamp(DeathRot.Roll, RotLimit.RotLimitMin.Roll, RotLimit.RotLimitMax.Roll);
		
		DoRotation(DeathRot, 1.0);
	}

	event BeginState(Name PreviousSateName)
	{
		bDestroyed = true;
		if(!TurretRotations.bRandomDeath)
			DoRotation(TurretRotations.DeathRotation, 1.0);
		else
			DoRandomDeath();
		SetTimer(1.0,false,'PlayDeath');
	}
}

function Tick(Float Delta)
{
	local Float currDot,thisDot;
	local PPawn P;
	local Bool bHasTarget;
	
	currDot = -1.01;

	if(GElapsedTime > 0.5 && !bDestroyed)
	{
		GElapsedTime = 0.0;
		bHasTarget = false;

		foreach WorldInfo.AllPawns(class'PGame.PPawn',P)
		{
			if(FastTrace(P.Location,FireLocation))
			{
				thisDot = Normal(Vector(PivotController.BoneRotation)) Dot
						Normal(((P.Location - FireLocation) << Rotation));
				if(P.Health > 0 && thisDot >= currDot)
				{
					EnemyTarget = P;
	                    currDot = thisDot;
	                    bHasTarget = true;
				}
			}
		}

		if(bHasTarget && !IsInState('Defend'))
		{
			GotoState('Defend');
		}
		else if(!bHasTarget && IsInState('Defend'))
		{
			GotoState('Alert');
		}
	}
	else
	{
		GElapsedTime += Delta;
	}
}

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	TurretHealth -= Damage;

	if(TurretEmitters.DamageEmitter != None)
	{
		DamageEffect.SetFloatParameter(TurretEmitters.DamageEmitterParamName,FClamp(1-(Float(TurretHealth)/Float(MaxTurretHealth)),0.0,1.0));
	}

	if(TurretSounds.DamageSound != None)
		PlaySound(TurretSounds.DamageSound);

	if(InstigatedBy.Pawn != None)
		EnemyTarget = PPawn(InstigatedBy.Pawn);
	
	if(TurretHealth <= 0)
	{
		GotoState('Dead');
	}
}

function DoRotation(Rotator NewRotation, Float InterpTime)
{
	StartRotation = PivotController.BoneRotation;
	TargetRotation = NewRotation;
	RotationAlpha = 0.0;
	TotalInterpTime = InterpTime;
	SetTimer(0.033,true,'RotateTimer');
}

function RotateTimer()
{
	RotationAlpha += 0.033;
	if(RotationAlpha <= TotalInterpTime)
		PivotController.BoneRotation = RLerp(StartRotation,TargetRotation,RotationAlpha,true);
	else
		ClearTimer('RotateTimer');
}

defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
   	End Object
   	LightEnvironment=MyLightEnvironment
   	Components.Add(MyLightEnvironment)

	Begin Object class=SkeletalMeshComponent name=SkelMeshComp0
		SkeletalMesh=SkeletalMesh'TurretContent.TurretMesh'
		AnimTreeTemplate=AnimTree'TurretContent.TurretAnimTree'
		PhysicsAsset=PhysicsAsset'TurretContent.TurretMesh_Physics'
		LightEnvironment=MyLightEnvironment
	End Object
	Components.Add(SkelMeshComp0)
	TurretMesh=SkelMeshComp0
	Mesh=SkelMeshComp0

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
				DestroySocket=DamageLocation,
				DamageSocket=DamageLocation,
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
	TurretHealth=500
	AimRotError=128
	ProjClass=class'UTGame.UTProj_LinkPowerPlasma'
	RoundsPerSec=3
	bEdShouldSnap=true
}