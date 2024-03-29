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
var float m_TiempoDesdeInicioRotacion; //tiempo transcurrido en la �ltima rotaci�n
var float m_TimeoutEntreRotacionIdle; //Tiempo que debe pasar entre una rotacion random y otra durante el Idle. Es igual al tiempo de rotacion que se le asigna
                                  //a cada rotacion. Esto hace que la velocidad no sea constante, ya que siempre tarda lo mismo en hacer
                                  //cada rotacion. Se podr�a cambiar
var float m_TimeoutEntreRotacionDisparando;

var float m_TiempoRotacionActual; //lo que tiene que taqrdar la rotacion en curso
var float m_TiempoTranscurridoRotacionActual;
var bool m_tocaRotacionIdle; //Para hacer que en idle haga una pasa cada m_TimeoutEntreRotacionIdle

var float m_tiempoApuntando;//tiempo que llevamos apuntando al entrar en estado NuevoTarget
var float m_tiempoNecesarioApuntar;// Tiempo calculado para que la torreta llegue a apuntar al nuevo target

var int m_TiempoEnConstruccion; //Segundos que estar� en construccion

var int m_toques; //toques que lleva de PEnemys.
var int m_toquesToDestroy; //toques con los que se destruye

var EmitterSpawnable m_part_destruccion; 

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
	//Deber� especificarse en cada DefaultProperties. Para TurretCannon por ejemplo es "PivotController"

	TurretMesh.GetSocketWorldLocationAndRotation(TurretBones.FireSocket,FireLocation,FireRotation);

	TurretMesh.AttachComponentToSocket(DamageEffect, TurretBones.DamageSocket);
	TurretMesh.AttachComponentToSocket(MuzzleFlashEffect, TurretBones.FireSocket);
	TurretMesh.AttachComponentToSocket(DestroyEffect, TurretBones.DestroySocket);
	
	TurretMesh.AttachComponentToSocket(EnConstruccionEffect, TurretBones.FireSocket); //De momento ahi

	DamageEffect.SetTemplate(TurretEmitters.DamageEmitter);
	MuzzleFlashEffect.SetTemplate(TurretEmitters.MuzzleFlashEmitter);
	DestroyEffect.SetTemplate(TurretEmitters.DestroyEmitter);
	EnConstruccionEffect.SetTemplate(TurretEmitters.EnConstruccion);

	
	m_part_destruccion = Spawn(class'EmitterSpawnable',Self);
 	if (m_part_destruccion != none)
	{
			m_part_destruccion.ParticleSystemComponent.bAutoActivate = false; 
			m_part_destruccion.SetTemplate(ParticleSystem'PGameParticles.Particles.P_Explo_Torreta');
	}

	/*IMPRESCINDIBLE ponerla sin f�sicas para que no aplique nada sobre ella y la controlemos nosotros*/
	SetPhysics(PHYS_None);
}

function Toque()
{
	PlaySound(PGame(WorldInfo.Game).SONIDOS_JUEGO.TocalaOtraVezSam(GIRU_CONTRA_TORRETA),,,true,self.Location);
	self.m_toques++;
	if (m_toques >= m_toquesToDestroy)
	{
		Destruccion();
	}
}

function Destruccion()
{
	//Part�culas y dem�s, y Destroy
	`log("Destruccion torreta "@self.Name);
	//DrawDebugSphere(self.Location,200,100,200,0,0,true);
	ShieldMesh.SetHidden(true); //Quitamos el escudo
	m_part_destruccion.ParticleSystemComponent.SetActive(true);
	SetTimer(0.6,false,'TorretaMuerta'); //Para dar tiempo al s.part�culas
	if (PTurretCannon(self) != None)
	{
		PGame(Worldinfo.Game).m_TextoPendiente = "Cannon Turret Destroyed!!";
	}
	else
	{
		PGame(Worldinfo.Game).m_TextoPendiente = "Ice Turret Destroyed!!";
	}
}

function TorretaMuerta()
{
	PlaySound(PGame(WorldInfo.Game).SONIDOS_JUEGO.TocalaOtraVezSam(TORRETA_DESTROZADA),,,true,self.Location);
	m_part_destruccion.ParticleSystemComponent.SetActive(false);
	self.Destroy();
}

 //Para sistema de part�culas en construccion
 function InicioConstruccion()
 {
	local Vector escala;
	
	//Ocultamos la mesh de la torreta y la del escudo para mostrar el sistema de part�culas de EnConstruccion
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
	ClearTimer('RotateTimer');//Anulamos cualquier otra rotaci�n que hubiera en curso
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
	
	//Hacemos que se dirija hacia el TargetRotation, pero s�lo si no ha llegado claro
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
    //Ya sabemos el �ngulo alfa de la rotaci�n. Lo aplicamos antes de hacer los c�lculos para el up/down:
 
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
		m_TiempoRotacionActual=0; //Utilizo esta variable por no crear otra s�lo para eso.
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
			//S�lo recalculamos cuando la rotaci�n en curso haya acabado.
			//por tanto, aqu� no hacemos nada
			return;
		}

		seleccionarTarget();
        if(enemigoActual==None) 
        {
			//No ha encontrado enemigo. As� que hacemos una rotaci�n random como si estuviera apuntando
			//hacemos que sea m�nimo de 30 grados, m�ximo de 90
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
			m_TiempoDesdeInicioRotacion=0; //Para reiniciar control del tiempo que est� rotando
		}
		else
		{
			//Ha seleccionado un nuevo enemigo. Vamos a buscarlo, y cancelamos la rotaci�n actual
			//_DEBUG_ ("Nuevo Target seleccionado");
			m_TiempoRotacionActual=0;//Para parar la rotacion actual
			GoToState('NuevoTarget');
		}
	} //Tick de Idle

	event EndState(name NextState)
	{
		//Porsiaca, cancelamos la rotaci�n en curso
		ClearTimer('RotateTimer');
	}

}//State Idle

state Disparando
{
	event BeginState(Name PreviousStateName)
	{
		m_tiempoDesdeAntDisparo=0;
		m_TiempoDesdeInicioRotacion=0;
		//Si hemos llegado aqu� es porque ya ha apuntado y est� en la direcci�n correcta, no hay que rotar
		//_DEBUG_ ("Estado Disparando");
	
	}


	function Tick(Float Delta)
	{
		local vector HitLocation,Hitnormal;
		local Actor obstaculo;
		local bool diparacontraalgo;
        super.Tick(Delta);
		TurretMesh.GetSocketWorldLocationAndRotation('FireLocation',FireLocation,FireRotation);
        TurretMesh.GetSocketWorldLocationAndRotation('SocketPivote',IniFireLocation,IniFireRotation);
		
        m_tiempoDesdeAntDisparo+=Delta;
		m_TiempoDesdeInicioRotacion+=Delta; //Rotacion para apuntar

		if(enemigoActual!=None) 
		{
			//trace para controlar que no disparemos al planeta. 
			
			obstaculo=trace(HitLocation, Hitnormal,enemigoActual.GetPosicionSocketCuerpo(),FireLocation,false,,,TRACEFLAG_Bullet);
			
			if(obstaculo!= None)
			{
				diparacontraalgo= PGame(Worldinfo.game).EsPlaneta(obstaculo);

				if(!diparacontraalgo)
				{
				
					if(PAutoTurret(obstaculo)!=None)
					{
						diparacontraalgo=true;
					
					}
				
				
				}
			
			}
				
			if (Vsize(enemigoActual.Location-FireLocation)>(RangoDisparo+200) || diparacontraalgo || enemigoActual.life <=0 )
			{
				enemigoActual=None;
				//DEBUG ("Estabamos disparando pero est� fuera de rango. Volvemos a Idle");
				GoToState('Idle');
			}
			else
			{
				//El disparo y el rec�lculo de posici�n, a diferentes timeouts:
				//Primero tiempo entre disparos
				if(  m_tiempoDesdeAntDisparo> m_TimeoutEntreDisparo)
				{
					DisparoTorreta(); //Funci�n a sobrescribir en cada torreta hija!!

					m_tiempoDesdeAntDisparo=0;
				}

				//Luego tiempo entre rotaciones para reapuntar
				if (m_TiempoDesdeInicioRotacion > m_TimeoutEntreRotacionDisparando)
				{
					
						m_TiempoDesdeInicioRotacion=0;
						RotaParaApuntarA(enemigoActual.GetPosicionSocketCuerpo(),m_TimeoutEntreRotacionDisparando);
					
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
		m_tiempoApuntando=0xFFFF; //Para que nada m�s empezar a tickear reapunte. Si no, el primer medio segundo se lo saltar�a
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
		dirEnemigo=Normal(enemigoActual.GetPosicionSocketCuerpo()-IniFireLocation);
		dotprot=dirActual dot dirEnemigo;
		if (dotprot>0 && dotprot > 0.95)
		{
			//Est� casi apuntado, que empiece a disparar
			//_DEBUG_ ("A DISPARAR!!");
			GoToState('Disparando');
		}
		else
		{
			//si no ha podido apuntar en el tiempo necesario, si falta poco volvemos a intentar, si no, a Idle 
			if(m_tiempoApuntando>m_tiempoNecesarioApuntar) //cada medio segundo reapuntamos por si el enemigo se ha ido moviendo 
			{
				dirActual=Normal(FireLocation-IniFireLocation);
				dirEnemigo=Normal(enemigoActual.GetPosicionSocketCuerpo()-IniFireLocation);

			    //LOLOFlushPersistentDebugLines();
		        //DrawDebugCylinder(FireLocation,enemigoActual.Location,3,10,200,0,0,true);


				dotprot=dirActual dot dirEnemigo;
			    //_DEBUG_ ("Sin apuntar, reintentamos");
				m_tiempoNecesarioApuntar=1.3-dotprot;
				//_DEBUG_ ("DOT PROT REINTENTO ES: "@dotprot);
				RotaParaApuntarA(enemigoActual.GetPosicionSocketCuerpo(),m_tiempoNecesarioApuntar);
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
		local bool diparacontraalgo;
		local Actor obstaculo;
		local vector HitLocation, Hitnormal;
		denemigo=RangoDisparo+1;
		tenemigo=None;
		diparacontraalgo=false;
		foreach WorldInfo.AllPawns(class'PEnemyPawn_Minion',enemigo,self.Location,RangoDisparo)
		//foreach WorldInfo.AllPawns(class'PPawn',enemigo,self.Location,RangoDisparo)
		{
			//control de obstaculos
			obstaculo=trace(HitLocation, Hitnormal,enemigo.GetPosicionSocketCuerpo(),FireLocation,false,,,TRACEFLAG_Bullet);
			
			if(obstaculo!= None)
			{
				diparacontraalgo= PGame(Worldinfo.game).EsPlaneta(obstaculo);

				if(!diparacontraalgo)
				{
				
					if(PAutoTurret(obstaculo)!=None)
					{
						diparacontraalgo=true;
					
					}
				
				
				}
			
			}//

			if(vsize(enemigo.Location-self.Location)<denemigo && !diparacontraalgo )
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
	RangoDisparo=1000
	m_TimeoutEntreDisparo=0.33  //3 disparos por segundo
	m_TimeoutEntreRotacionIdle=3 //Random cada 3 segundos
	m_TimeoutEntreRotacionDisparando=0.2 //Reapunta al target 5 veces por segundo
	m_TiempoTranscurridoRotacionActual=0
	m_tocaRotacionIdle=true
	m_TiempoEnConstruccion=5 //5 segundos en construccion. Cada hija lo podr� redefinir
	toques = 0
	m_toquesToDestroy = 10
}