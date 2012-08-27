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
	var() ParticleSystem EnConstruccion;
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

var Vector FireLocation,IniFireLocation;		//World position of the firing socket
var Rotator FireRotation,IniFireRotation;	//World orientation of the firing socket

var SkelControlSingleBone PivotController;	//Reference to the skelcontrol in the AnimTree

var Bool bCanFire;		//Is the turret in a firing state?
var Bool bDestroyed;	//Has the turret been destroyed?

var ParticleSystemComponent DamageEffect;		//PSys component for playing damage effects
var ParticleSystemComponent MuzzleFlashEffect;	//PSys component for playing muzzle flashes
var ParticleSystemComponent DestroyEffect;		//PSys component for playing destruction effects
var ParticleSystemComponent EnConstruccionEffect;		//PSys component for playing destruction effects

var Int MaxTurretHealth;		//Max health for this turret
var Float FullRevTime;	//Seconds to make full rev at min rot rate

var Float GElapsedTime;	//Elapsed time since last global tick
var Int OrigMinRotRate;	//Beginning value of MinTurretRotRate


/*Designer editable variables*/
var(Turret) SkeletalMeshComponent TurretMesh;				//SkelMeshComp for the turret
var(Turret) StaticMeshComponent ShieldMesh;				//Mesh del escudo protector

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

//variables seleccion de enemigos y disparo
var PEnemyPawn_Minion enemigoActual;
//var PPawn enemigoActual;

var float RangoDisparo;


//VICTOR
var int m_numticksrotacion;
var vector m_NormalSuelo;
var Quat m_quatTorreta;

var float m_tiempoDesdeAntDisparo; //tiempo desde el anterior disparo.
var float m_TimeoutEntreDisparo; //Tiempo que debe pasar desde un disparo a otro
var float m_TiempoDesdeInicioRotacion; //tiempo transcurrido en la última rotación
var float m_TimeoutEntreRotacionIdle; //Tiempo que debe pasar entre una rotacion random y otra durante el Idle. Es igual al tiempo de rotacion que se le asigna
                                  //a cada rotacion. Esto hace que la velocidad no sea constante, ya que siempre tarda lo mismo en hacer
                                  //cada rotacion. Se podría cambiar
var float m_TimeoutEntreRotacionDisparando;

var float m_TiempoRotacionActual; //lo que tiene que taqrdar la rotacion en curso
var float m_TiempoTranscurridoRotacionActual;
var bool m_tocaRotacionIdle; //Para hacer que en idle haga una pasa cada m_TimeoutEntreRotacionIdle

var float m_tiempoApuntando;//tiempo que llevamos apuntando al entrar en estado NuevoTarget
var float m_tiempoNecesarioApuntar;// Tiempo calculado para que la torreta llegue a apuntar al nuevo target

var int m_TiempoEnConstruccion; //Segundos que estará en construccion

var int m_toques; //toques que lleva de PEnemys.

event PostInitAnimTree(SkeletalMeshComponent skelcomp)
{
	Super.PostInitAnimTree(skelcomp);
	if (skelcomp==TurretMesh)
	{
		PivotController = SkelControlSingleBone(TurretMesh.FindSkelControl(TurretBones.PivotControllerName));
		m_quatTorreta=QuatFromRotator(PivotController.BoneRotation);
	}
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
	
	TurretMesh.AttachComponentToSocket(EnConstruccionEffect, TurretBones.FireSocket); //De momento ahi

	DamageEffect.SetTemplate(TurretEmitters.DamageEmitter);
	MuzzleFlashEffect.SetTemplate(TurretEmitters.MuzzleFlashEmitter);
	DestroyEffect.SetTemplate(TurretEmitters.DestroyEmitter);
	EnConstruccionEffect.SetTemplate(TurretEmitters.EnConstruccion);

	/*IMPRESCINDIBLE ponerla sin físicas para que no aplique nada sobre ella y la controlemos nosotros*/
	SetPhysics(PHYS_None);
}

function Toque()
{
	self.m_toques++;
	if (m_toques >=3)
	{
		self.Destroy();
	}
}

 //Para sistema de partículas en construccion
 function InicioConstruccion()
 {
	local Vector escala;
	
	//Ocultamos la mesh de la torreta y la del escudo para mostrar el sistema de partículas de EnConstruccion
	TurretMesh.SetHidden(true);
	ShieldMesh.SetHidden(true);
	
	EnConstruccionEffect.ActivateSystem();
	escala=vect(5,5,5);
	EnConstruccionEffect.SetScale3D(escala); //Porque inicialmente se ve mu shiquinino ;)
 }

 function FinConstruccion()
 {
	//Volvemos a mostrar la torreta y su escudo
	TurretMesh.SetHidden(false);
	ShieldMesh.SetHidden(false);
	EnConstruccionEffect.DeactivateSystem();
 }


//Funciones a sobreescribir en cada hija
 function DisparoTorreta();



function setNormalSuelo(vector normal)
{
	m_NormalSuelo=normal;
}

function DoRotation(Rotator NewRotation, Float InterpTime)
{
	/***
	ClearTimer('RotateTimer');//Anulamos cualquier otra rotación que hubiera en curso
	StartRotation = PivotController.BoneRotation;
	TargetRotation = NewRotation;
	RotationAlpha = 0.0;
	TotalInterpTime = InterpTime;
	SetTimer(0.05,true,'RotateTimer'); //25 veces por segundo is enough
   ***/
	//`log("DoRotation");

	m_TiempoRotacionActual=0; //Intentamos parar la rotacion actual
	TargetRotation=NewRotation; //El nuevo Destino
	StartRotation=PivotController.BoneRotation; //Desde donde estamos hasta el destino
	m_TiempoRotacionActual=InterpTime;
	m_TiempoTranscurridoRotacionActual=0;
	
}

function RotateTimer()
{
	
	RotationAlpha += (0.05/TotalInterpTime);
	if(RotationAlpha <= TotalInterpTime)
		PivotController.BoneRotation = RLerp(StartRotation,TargetRotation,RotationAlpha,true);
	else
		ClearTimer('RotateTimer');

}


//Timer global que updatea la rotacion de la torreta, para que siempre se dirija hacia el destino definido en TargetLocation
function Tick(Float Delta)
{
	local float incAlfa;
	super.Tick(Delta);
	
	m_TiempoTranscurridoRotacionActual+=Delta;
	
	//Hacemos que se dirija hacia el TargetRotation, pero sólo si no ha llegado claro
	if(m_TiempoRotacionActual !=0 && m_TiempoTranscurridoRotacionActual < (m_TiempoRotacionActual))
	{
		incAlfa=m_TiempoTranscurridoRotacionActual/m_TiempoRotacionActual;
		PivotController.BoneRotation = RLerp(StartRotation,TargetRotation,incAlfa,true);
    }
}



function RotaParaApuntarA(vector newTarget,float tiempoDeRotacion)
{
    local vector va,vt;
    local vector vplano1,vplano2,vplano3;
    local float beta;
    local rotator rTorreta,rva,rvt;
    local float alfa,alfa_Rad,beta_rad;
    local Vector dist;
    local Quat qPitch;
    local vector X,Y,Z;

	//`log("Apunto");

    TurretMesh.GetSocketWorldLocationAndRotation('FireLocation',FireLocation,FireRotation);
    TurretMesh.GetSocketWorldLocationAndRotation('SocketPivote',IniFireLocation,IniFireRotation);
    
    rTorreta=PivotController.BoneRotation;
    
    //va es el vector del cannon. vprojCannon su proyeccion con Z=0 (en vector2D)
    va=FireLocation-IniFireLocation; //vector de disparo actual. 
    //va es el vector del nuevo disparo. vprojDisparo su proyeccion con Z=0 (en vector2D)
    vt=newTarget-IniFireLocation;

    //CALCULO CON ROTATOR
    rva=Rotator(va);
    rvt=Rotator(vt);

    //DrawDebugCylinder(IniFireLocation,IniFireLocation+Normal(vt)*300,3,10,200,0,0,true);
    vPlano1=IniFireLocation;
    vPlano2=FireLocation;
    vPlano3=IniFireLocation+ ((vPlano2-vPlano1) cross m_NormalSuelo);
    dist=PointProjectToPlane(newTarget,vPlano1,vPlano2,vPlano3);
    
    vt=dist-IniFireLocation;
    rvt=Rotator(vt);
    alfa=rvt.Yaw-rva.Yaw;
    alfa=alfa*UnrRotToDeg;
    //Ya sabemos el ángulo alfa de la rotación. Lo aplicamos antes de hacer los cálculos para el up/down:
 
    if (true)
    {
  
        alfa_rad=alfa*DegToRad;
        rTorreta=QuatToRotator(m_quatTorreta);
        GetAxes(rTorreta,X,Y,Z);
        qPitch=QuatFromAxisAndAngle(Y,alfa_rad);
        m_quatTorreta=QuatProduct(qPitch,m_quatTorreta);
        
        rTorreta=QuatToRotator(m_quatTorreta);
		rTorreta.Roll=0;
        //PivotController.BoneRotation=rTorreta;
    }

    //Proyeccion en el plano para up/down
    TurretMesh.GetSocketWorldLocationAndRotation('FireLocation',FireLocation,FireRotation);
    TurretMesh.GetSocketWorldLocationAndRotation('SocketPivote',IniFireLocation,IniFireRotation);
    vPlano1=IniFireLocation;
    vPlano2=FireLocation;
    vPlano3=IniFireLocation+m_NormalSuelo;
    dist=PointProjectToPlane(newTarget,vPlano1,vPlano2,vPlano3);
    
    vt=dist-IniFireLocation;
    rvt=Rotator(vt);
    rva=Rotator(va);
    beta=(rvt.pitch-rva.Pitch);
    beta=beta*UnrRotToDeg;
    //`log("alfa y beta" @alfa  @beta);
    if(true)
    {
       
        beta_rad=beta*DegToRad;
        rTorreta=QuatToRotator(m_quatTorreta);
        GetAxes(rTorreta,X,Y,Z);
        qPitch=QuatFromAxisAndAngle(Z,beta_rad);
        m_quatTorreta=QuatProduct(qPitch,m_quatTorreta);

        rTorreta=QuatToRotator(m_quatTorreta);
        rTorreta.roll=0;
        //PivotController.BoneRotation=rTorreta;
    }

	DoRotation(rTorreta,tiempoDeRotacion);
}

auto state EnConstruccion
{
	event BeginState(Name PreviousStateName)
	{
		//_DEBUG_ ("En Construccion");
		InicioConstruccion(); //Funcion Virtual a sobreescribir
		m_TiempoRotacionActual=0; //Utilizo esta variable por no crear otra sólo para eso.
		//VIVA EL C++ Y LAS VARIABLES STATIC!!!! CUANTO LO ECHO DE MENOSSSS!!! :D
	}

	function Tick(Float Delta)
	{
		m_TiempoRotacionActual+=delta;
		if (m_TiempoRotacionActual > m_TiempoEnConstruccion)
		{
			//_DEBUG_ ("Dejo de estar En Construccion");
			FinConstruccion();//Funcion Virtual a sobreescribir
			GotoState('Idle');
		}
	}
	event EndState(Name PreviousStateName)
	{
		FinConstruccion();//Funcion Virtual a sobreescribir
	}
}

state Idle
{

	event BeginState(Name PreviousStateName)
	{
		m_tiempoDesdeAntDisparo=0;
		m_TiempoDesdeInicioRotacion=0;
		//_DEBUG_ ("Idle");
	}

	event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
	{
		Global.TakeDamage(Damage,InstigatedBy,HitLocation,Momentum,DamageType,HitInfo,DamageCauser);

		if(TurretHealth > 0)
		{
			//GotoState('Alert');
		}
	}


	function Tick(Float Delta)
	{
		local Rotator rActual;
		local int     random;

		super.Tick(Delta);

		m_TiempoDesdeInicioRotacion+=Delta;

        TurretMesh.GetSocketWorldLocationAndRotation('FireLocation',FireLocation,FireRotation);
        TurretMesh.GetSocketWorldLocationAndRotation('SocketPivote',IniFireLocation,IniFireRotation);

		if (m_TiempoDesdeInicioRotacion < m_TimeoutEntreRotacionIdle)
		{
			//Sólo recalculamos cuando la rotación en curso haya acabado.
			//por tanto, aquí no hacemos nada
			return;
		}

		seleccionarTarget();
        if(enemigoActual==None) 
        {
			//No ha encontrado enemigo. Así que hacemos una rotación random como si estuviera apuntando
			//hacemos que sea mínimo de 30 grados, máximo de 90
			//Para que no sea movimiento continuo, una de cada dos veces que no haga nada
			if (m_tocaRotacionIdle)
			{
				rActual=PivotController.BoneRotation;
				random=30+(rand(60)*DegToUnrRot);
				if ((random%2)==0)
				{
					random=-random;
				}
				rActual.Yaw=(rActual.Yaw+random) %65535;
				rActual.Roll=0;
				rActual.Pitch=0;
				Normalize(rActual);
				DoRotation(rActual,m_TimeoutEntreRotacionIdle);
			}
			m_tocaRotacionIdle=!m_tocaRotacionIdle;
			m_TiempoDesdeInicioRotacion=0; //Para reiniciar control del tiempo que está rotando
		}
		else
		{
			//Ha seleccionado un nuevo enemigo. Vamos a buscarlo, y cancelamos la rotación actual
			//_DEBUG_ ("Nuevo Target seleccionado");
			m_TiempoRotacionActual=0;//Para parar la rotacion actual
			GoToState('NuevoTarget');
		}
	} //Tick de Idle

	event EndState(name NextState)
	{
		//Porsiaca, cancelamos la rotación en curso
		ClearTimer('RotateTimer');
	}

}//State Idle

state Disparando
{
	event BeginState(Name PreviousStateName)
	{
		m_tiempoDesdeAntDisparo=0;
		m_TiempoDesdeInicioRotacion=0;
		//Si hemos llegado aquí es porque ya ha apuntado y está en la dirección correcta, no hay que rotar
		//_DEBUG_ ("Estado Disparando");
	
	}


	function Tick(Float Delta)
	{

        super.Tick(Delta);
		TurretMesh.GetSocketWorldLocationAndRotation('FireLocation',FireLocation,FireRotation);
        TurretMesh.GetSocketWorldLocationAndRotation('SocketPivote',IniFireLocation,IniFireRotation);
		
        m_tiempoDesdeAntDisparo+=Delta;
		m_TiempoDesdeInicioRotacion+=Delta; //Rotacion para apuntar

		if(enemigoActual!=None) 
		{
				
			if (Vsize(enemigoActual.Location-FireLocation)>(RangoDisparo+200) )//|| enemigoActual.life==0)
			{
				enemigoActual=None;
				//_DEBUG_ ("Estabamos disparando pero está fuera de rango. Volvemos a Idle");
				GoToState('Idle');

			}
			else
			{
				//El disparo y el recálculo de posición, a diferentes timeouts:
				//Primero tiempo entre disparos
				if(  m_tiempoDesdeAntDisparo> m_TimeoutEntreDisparo)
				{
					DisparoTorreta(); //Función a sobrescribir en cada torreta hija!!

					m_tiempoDesdeAntDisparo=0;
				}

				//Luego tiempo entre rotaciones para reapuntar
				if (m_TiempoDesdeInicioRotacion > m_TimeoutEntreRotacionDisparando)
				{
					
						m_TiempoDesdeInicioRotacion=0;
						RotaParaApuntarA(enemigoActual.Location,m_TimeoutEntreRotacionDisparando);
					
				}
			}
		}
		else //Porsiaca, si no hay enemigo, volvemos a Idle
		{
			GoToState('Idle');
		}
       
	}//Tick	

}//state Disparando


state NuevoTarget
{
	event BeginState(Name PreviousStateName)
	{
		//_DEBUG_ ("NuevoTarget");
		m_tiempoApuntando=0xFFFF; //Para que nada más empezar a tickear reapunte. Si no, el primer medio segundo se lo saltaría
	}


	function Tick(Float Delta)
	{
		local Vector dirActual,dirEnemigo;
		local float dotprot,dist;

        super.Tick(Delta);
		m_tiempoApuntando+=Delta;
		
		TurretMesh.GetSocketWorldLocationAndRotation('FireLocation',FireLocation,FireRotation);
        TurretMesh.GetSocketWorldLocationAndRotation('SocketPivote',IniFireLocation,IniFireRotation);

        if (enemigoActual == None)
        {
			//_DEBUG_ ("Nada que hacer aqui, no hay target");
			GoToState('Idle');
			return;
        }
		
		//LOLOFlushPersistentDebugLines();
		//DBG DrawDebugCylinder(FireLocation,enemigoActual.Location,5,10,0,0,255,true);
        dist=Vsize(enemigoActual.Location-IniFireLocation);
		if (dist > (RangoDisparo+100) )//|| enemigoActual.life==0)
		{
				enemigoActual=None;
				//_DEBUG_ ("Sale de rango mientras apuntamos, volvemos a Idle");
				GoToState('Idle');
				return;
		}


		dirActual=Normal(FireLocation-IniFireLocation);
		dirEnemigo=Normal(enemigoActual.location-IniFireLocation);
		dotprot=dirActual dot dirEnemigo;
		if (dotprot>0 && dotprot > 0.95)
		{
			//Está casi apuntado, que empiece a disparar
			//_DEBUG_ ("A DISPARAR!!");
			GoToState('Disparando');
		}
		else
		{
			//si no ha podido apuntar en el tiempo necesario, si falta poco volvemos a intentar, si no, a Idle 
			if(m_tiempoApuntando>m_tiempoNecesarioApuntar) //cada medio segundo reapuntamos por si el enemigo se ha ido moviendo 
			{
				dirActual=Normal(FireLocation-IniFireLocation);
				dirEnemigo=Normal(enemigoActual.location-IniFireLocation);

			    //LOLOFlushPersistentDebugLines();
		        //DrawDebugCylinder(FireLocation,enemigoActual.Location,3,10,200,0,0,true);


				dotprot=dirActual dot dirEnemigo;
			    //_DEBUG_ ("Sin apuntar, reintentamos");
				m_tiempoNecesarioApuntar=1.3-dotprot;
				//_DEBUG_ ("DOT PROT REINTENTO ES: "@dotprot);
				RotaParaApuntarA(enemigoActual.Location,m_tiempoNecesarioApuntar);
				m_tiempoApuntando=0;

			}
		
		}

	}//Tick	

}//state NuevoTarget







	function seleccionarTarget()
	{
		local float denemigo;
		local PEnemyPawn_Minion enemigo,tenemigo;
		//local PPawn enemigo,tenemigo;

		denemigo=RangoDisparo+1;
		tenemigo=None;
		
		foreach WorldInfo.AllPawns(class'PEnemyPawn_Minion',enemigo,self.Location,RangoDisparo)
		//foreach WorldInfo.AllPawns(class'PPawn',enemigo,self.Location,RangoDisparo)
		{
			if(vsize(enemigo.Location-self.Location)<denemigo)
			{
				tenemigo=enemigo;
				denemigo=vsize(enemigo.Location-self.Location);
			}
		}

		if (tenemigo!=None)
		{
			enemigoActual=tenemigo;
		}

	}


	function TiempodeMorir(vector locaEnemigo)
	{
		local Projectile Proj;
		//return;
		TurretMesh.GetSocketWorldLocationAndRotation('FireLocation',FireLocation,FireRotation);
		TurretMesh.GetSocketWorldLocationAndRotation('SocketPivote',IniFireLocation,IniFireRotation);

		
		Proj = Spawn(class'PMisiles',self,,FireLocation,,,True);
		Proj.Init(Normal(locaEnemigo-FireLocation));
		
	}





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


	//Escudo que rodea a las torretas
	Begin Object Class=StaticMeshComponent Name=DMesh
	    StaticMesh=StaticMesh'PGameContentcannon.Mesh.escudocannon'
        BlockActors=true
        CollideActors=true
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		RBCollideWithChannels=(Pawn=true)
		BlockRigidBody=true
		
        //LightEnvironment=MyLightEnvironmentrr 
		Scale3D=(X=20,Y=20,Z=20)
    End Object

	//bCollideComplex=true
	ShieldMesh=DMesh
	Components.Add(DMesh)

	//TurretMesh se asigna en cada torreta hija con la mesh que corresponde a la propia torreta
	RangoDisparo=1300
	m_TimeoutEntreDisparo=0.33  //3 disparos por segundo
	m_TimeoutEntreRotacionIdle=3 //Random cada 3 segundos
	m_TimeoutEntreRotacionDisparando=0.2 //Reapunta al target 5 veces por segundo
	m_TiempoTranscurridoRotacionActual=0
	m_tocaRotacionIdle=true
	m_TiempoEnConstruccion=5 //5 segundos en construccion. Cada hija lo podrá redefinir
	toques = 0
}