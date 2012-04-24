class PAutoTurret extends PKActor  
    abstract;


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
var PEnemy EnemyTarget;	//The new enemy the turret should target - set from the controller or TakeDamage()
var PEnemy LastEnemyTarget;	//The enemy the turret is targeting in the current interpolation

var Vector EnemyDir;	//Vector from the turret's base to the enemy's location this tick
var Vector LastEnemyDir;		//Vector from the turret's base to the enemy's location last tick

var float TotalInterpTime;	//Total number of seconds it will take to interpolate to the target
var Float ElapsedTime;		//Time spent in the current interpolation to the target
var Float RotationAlpha;		//Curret alpha for interpolating to a new rotation
var Rotator StartRotation;	//Beginning rotation for interpolating
var Rotator TargetRotation;	//Desired rotations for interpolating

var Vector FireLocation;		//World position of the firing socket
var Rotator FireRotation;	//World orientation of the firing socket

//var SkelControlSingleBone PivotController;	//Reference to the skelcontrol in the AnimTree
var SkelControlLookAt  PivotController;	//Reference to the skelcontrol in the AnimTree

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
var(Turret) DynamicLightEnvironmentComponent LightEnvironmentrr;	//LightEnvironment for the turret
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

//VICTOR
var float m_tiempotranscurrido;
var int m_numticksrotacion;
var float m_tiemporotando;

event PostInitAnimTree(SkeletalMeshComponent skelcomp)
{
	Super.PostInitAnimTree(skelcomp);
	if (skelcomp==TurretMesh)
		PivotController = SkelControlLookAt (TurretMesh.FindSkelControl(TurretBones.PivotControllerName));
}

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	MaxTurretHealth = TurretHealth;
	OrigMinRotRate = MinTurretRotRate;
	FullRevTime = 65536.0 / Float(MinTurretRotRate);

	//PivotController = SkelControlSingleBone(TurretMesh.FindSkelControl(TurretBones.PivotControllerName));

	//TurretBones.PivotControllerName tiene el nombre del SkelControler creado en el AnimTree
	//Deberá especificarse en cada DefaultProperties. Para TurretCannon por ejemplo es "PivotController"

	TurretMesh.GetSocketWorldLocationAndRotation(TurretBones.FireSocket,FireLocation,FireRotation);

	TurretMesh.AttachComponentToSocket(DamageEffect, TurretBones.DamageSocket);
	TurretMesh.AttachComponentToSocket(MuzzleFlashEffect, TurretBones.FireSocket);
	TurretMesh.AttachComponentToSocket(DestroyEffect, TurretBones.DestroySocket);

	DamageEffect.SetTemplate(TurretEmitters.DamageEmitter);
	MuzzleFlashEffect.SetTemplate(TurretEmitters.MuzzleFlashEmitter);
	DestroyEffect.SetTemplate(TurretEmitters.DestroyEmitter);
	
	/*IMPRESCINDIBLE ponerla sin físicas para que no aplique nada sobre ella y la controlemos nosotros*/
	SetPhysics(PHYS_None);
	
    
}

function RotaParaApuntarA(vector newTarget)
{
	local vector va,vt,va_r,vt_r;
	local vector IniFireLocation;
	local vector vx,vy,vz;
	local bool bkk;

	local float alfa1,alfa2;
	local rotator rTorreta,ract,rnew,IniFireRotation,rva,rvt;
	local float cosalfa, alfa,dpitch;
	local Vector va_ud,vt_ud;

	local vector vsigno;
	local float pdesp;

	TurretMesh.GetSocketWorldLocationAndRotation('FireLocation',FireLocation,FireRotation);
    TurretMesh.GetSocketWorldLocationAndRotation('SocketPivote',IniFireLocation,IniFireRotation);

	
	PivotController.TargetLocation=newtarget;
	//Normal(newTarget-FireLocation);
//	(Normal(newTarget-FireLocation))
	FlushPersistentDebugLines();
	DrawDebugCylinder(FireLocation,newtarget,5,30,200,0,0,true);

}
/*******************
	return;

	/***DEBUG***
    va=FireLocation-IniFireLocation;
	FlushPersistentDebugLines();
	DrawDebugCylinder(IniFireLocation,IniFireLocation+va*2,4,15,100,0,0,true);
	DrawDebugCylinder(IniFireLocation,newtarget,4,15,0,100,0,true);
	DrawDebugSphere(IniFireLocation,60,30,200,0,0,true);
	DrawDebugSphere(FireLocation,25,30,0,0,200,true);
    ****DEBUG***/

	rTorreta=PivotController.BoneRotation; //vector de la rotación actual
		

	
	//va es el vector del cannon. vprojCannon su proyeccion con Z=0 (en vector2D)
	va=FireLocation-IniFireLocation; //vector de disparo actual. 
	va_r=Normal2D(va);
	
	//va es el vector del nuevo disparo. vprojDisparo su proyeccion con Z=0 (en vector2D)
	vt=newTarget-IniFireLocation;
	vt_r=Normal2D(vt);
		
	cosalfa=(NoZDot(va_r,vt_r)) ;// / (VSize2D(vprojCannon)*VSize2D(vprojDisparo));
	alfa=Acos(cosalfa)*RadToDeg;
	
	//Control del signo
	vsigno=va cross vt;
	

	pdesp=alfa*DegToUnrRot;
	if (vsigno.Z >=0)
	{
		`log('Arriba');
		rTorreta.Pitch=(65535+(rTorreta.Pitch-pdesp))%65535;
	}
	else
	{
		rTorreta.Pitch=(65535+(rTorreta.Pitch+pdesp))%65535;
		`log('Abajo');
    }
	
    Normalize(rTorreta);
    DoRotation(rTorreta,1.0);
    return;

    //AHORA PARA UP/DOWN
	//hay que considerar la torreta ya girada, y calcular con esa rotación ya realizada
    va=FireLocation-IniFireLocation; //vector de disparo actual. 
	
    
    rva.Pitch=0;
	rva.Yaw=pdesp;
	rva.Roll=0;
	va=va<<rva; //en va tenemos el disparo a donde apuntaría la torreta después de la rotación de pitch que va a hacer.
    
	
    vt=newTarget-IniFireLocation;
	
	rva=Rotator(va);
	rvt=Rotator(vt);
	dpitch=rvt.pitch-rva.pitch;
	rTorreta.yaw=(65535+(rTorreta.Yaw+dpitch))%65535;
	`log("beta "  @dpitch * UnrRotToDeg);

	FlushPersistentDebugLines();
	DrawDebugCylinder(IniFireLocation,IniFireLocation+vector(rva)*200,4,15,100,0,0,true);
	DrawDebugCylinder(IniFireLocation,IniFireLocation+vector(rvt)*200,4,15,0,0,200,true);
	DrawDebugCylinder(IniFireLocation,newtarget,4,15,0,100,0,true);
	

	/*
	va_ud.X=va.X;
	va_ud.Y=va.Z;
    va_ud.Z=0;
	va_ud=Normal2d(va_ud);

	vt_ud.X=vt.X;
	vt_ud.Y=vt.Z;
	vt_ud.z=0;
	vt_ud=Normal2d(vt_ud);

	cosalfa=(NoZDot(va_ud,vt_ud)) ;// / (VSize2D(vprojCannon)*VSize2D(vprojDisparo));
	alfa=Acos(cosalfa)*RadToDeg;


	pdesp=alfa*DegToUnrRot;

	rTorreta.roll=(65535+(rTorreta.roll-pdesp))%65535;
	*/

    Normalize(rTorreta);
	DoRotation(rTorreta,1.0);

}
******************/

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

	function TiempodeMorir(vector locaEnemigo)
	{
		local Projectile Proj;
		//return;

		Proj = Spawn(class'UTProj_Rocket',self,,FireLocation,,,True);
		Proj.Init(Normal(locaEnemigo-FireLocation));
		
	}

	function Tick(Float Delta)
	{
		local Float currDot;
		local Float thisDot;
		local PEnemy P;
		local Bool bHasTarget;
		local Actor a;
		local Vector HitLocation, Hitnormal;
		local PPAwn prota;
		local PEnemyPawn_Minion enemigo;
		
		m_tiempotranscurrido+=Delta;
        

		foreach WorldInfo.AllPawns(class'PEnemyPawn_Minion',enemigo)
		{
			
		
	     //  	RotaParaApuntarA(Prota.Location);
			if (m_tiempotranscurrido>5)
			{
				RotaParaApuntarA(enemigo.Location);
				`Log("encuentra enemigo???"@enemigo.Location);
				m_tiempotranscurrido=0;
				TiempodeMorir(enemigo.Location);
			}
        }
	}//Tick	
}//state


/***********************
        return;
		currDot = -1.01;
	
		//Recalcula enemigo cada medio segundo
		if(GElapsedTime > 0.5 && !bDestroyed)
		{
			GElapsedTime = 0.0;
			bHasTarget = false;
			//
			TurretMesh.GetSocketWorldLocationAndRotation('FireLocation',FireLocation,FireRotation);
			//DrawDebugCylinder(FireLocation,FireLocation+vector(FireRotation)*100,4,30,0,200,0,true);
			//foreach VisibleCollidingActors(class'PEnemy', P,200.f,,,vect(10,10,10),true)
			foreach WorldInfo.AllPawns(class'PEnemy', P)
			{
			//	`Log("encuentra argo la location del enemy " @P.Location);
				DrawDebugLine(P.Location,FireLocation,255,0,0);
				//a=trace(HitLocation, Hitnormal,P.Location,FireLocation,false,,,TRACEFLAG_Bullet);
				//if(a!=None)
				//	`log("trace con su puta madre"@a.name);
				if(P.FastTrace(P.Location, FireLocation))
				//if(a==None)
				{
					`Log("encuentra argo con el fast ");


					
					thisDot = Normal(Vector(PivotController.BoneRotation)) Dot
							Normal(((P.Location - FireLocation) << Rotation));
	
					if(	P.Health > 0 &&
						//Ignoramos la velocidad a la hora de elegir enemigo
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
				`log("Estoy en Defend dentro de Idle...");
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
		//VMH:
		return;

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
		return;

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
			`Log("tiepo pa morir");
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
		return;

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

			TurretMesh.GetSocketWorldLocationAndRotation(TurretBones.FireSocket,FireLocation,FireRotation);

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
		
		
		TurretMesh.GetSocketWorldLocationAndRotation(TurretBones.FireSocket,FireLocation,FireRotation);
		
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
			TurretMesh.SetSkeletalMesh(DestroyedMesh);

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
	local PEnemy P;
	local Bool bHasTarget;
	
	return;

	currDot = -1.01;

	if(GElapsedTime > 0.5 && !bDestroyed)
	{
		GElapsedTime = 0.0;
		bHasTarget = false;

		foreach WorldInfo.AllPawns(class'PEnemy',P)
		{
			
			if(P.FastTrace(P.Location,FireLocation))
			
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

	//No queremos que quien nos acaba de hacer pupita sea nuesto enemigo
	/*
	if(InstigatedBy.Pawn != None)
		EnemyTarget = PPawn(InstigatedBy.Pawn);
	*/

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
	m_tiemporotando=0;
}

function RotateTimer()
{
	
	RotationAlpha += 0.033;
	if(RotationAlpha <= TotalInterpTime)
		PivotController.BoneRotation = RLerp(StartRotation,TargetRotation,RotationAlpha,true);
	else
		ClearTimer('RotateTimer');
   
    return;
    /**
	local float incpitch,incyaw;
	local int offsetpitchtotal,offsetyawtotal;

	offsetpitchtotal=TargetRotation.Pitch-StartRotation.Pitch;
	offsetyawtotal=TargetRotation.Yaw-startrotation.Yaw;

	incpitch=(offsetpitchtotal*0.033)/TotalInterpTime;
	incyaw=(offsetyawtotal*0.033)/TotalInterpTime;


	PivotController.BoneRotation.Pitch =(65535+(PivotController.BoneRotation.Pitch+incpitch))%65535; 
	//PivotController.BoneRotation.yaw =(65535+(PivotController.BoneRotation.yaw+incyaw))%65535; 
	

	m_tiemporotando+=0.033;
	if (m_tiemporotando >= TotalInterpTime)
	{
		ClearTimer('RotateTimer');
	}
   ********/
	
}
***********************/

defaultproperties
{

	 Begin Object Class=StaticMeshComponent Name=DMesh
		//Archetype=InterpActor'PGameContentcannon.escudocca'
        //StaticMesh=StaticMesh'HU_Deco3.SM.Mesh.S_HU_Deco_SM_HydraulicSupport_C'
		 StaticMesh=StaticMesh'PGameContentcannon.Mesh.escudocannon'
        BlockActors=false
        CollideActors=true
        LightEnvironment=MyLightEnvironmentrr 
		//CollisionComponent=CollisionCylinder1
      Scale3D=(X=20,Y=20,Z=20)
//ObjectArchetype=InterpActor'PGameContentcannon.escudocca'
    End Object
    Components.Add(DMesh)

}