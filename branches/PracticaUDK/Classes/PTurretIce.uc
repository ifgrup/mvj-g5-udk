class PTurretIce extends PAutoTurret
	placeable;


struct DisparoHielo
{
	var float Tiempo;
	var float tiempo_anterior_hurt;
	var float Radio;
	var EmitterSpawnable ParticulasNieblaHielo;
	var bool borrar; //maracado como borrado pero no eliminado hasta haber tratado todos justincase
};

var array<DisparoHielo> m_array_disparos_hielo;
var float m_radioinicial;
var float m_alturainicial;

//Funcion definida en PAutoTurret, redefinida en cada hija
function DisparoTorreta()
{   
		//Emitimos un sistema de part�culas que va desde la torreta hacia fuera, en c�rculo, y todo aquello que toca,
		//lo convierte en hielo.
		//local PEmiter pem;
		//_DEBUG_ ("DIsparo Ice");
		GeneraNuevaOndaHielo();
		//pem=Spawn(class'PEmiter',self,,enemigoactual.Location+vect(300,0,0),enemigoactual.Rotation,,true);
		//pem.SpawnEmitter();
}


function GeneraNuevaOndaHielo()
{
	local EmitterSpawnable PSC;
	local DisparoHielo disparo;

	//disparo = new DisparoHielo;

	PSC = Spawn(class'EmitterSpawnable',Self);
	if (PSC != None)
	{
		//PSC.SetTemplate(ParticleSystem'PGameParticles.Particles.PruebaEsferaHielo');
		PSC.SetTemplate(ParticleSystem'PGameParticles.Particles.ToroideAzul');
				
		disparo.ParticulasNieblaHielo = PSC;
		disparo.Tiempo = 0;
		disparo.Radio = 50; //Inicialmente, para que no parezca que sale de dentro de la torreta?
		disparo.borrar = false;
		m_array_disparos_hielo.AddItem(disparo);
	}

}


function HacerDanyoRadial (float DamageRadius)
{
	//Porque HurtRadius utiliza en el foreach de VisibleCollidingActors 'Actor', y eso
	//hace que pille el escudo de la torreta y nada m�s..

	local PEnemyPawn_Minion	Victim;

	// Prevent HurtRadius() from being reentrant.
	if ( bHurtEntry )
		return ;

	
	bHurtEntry = true;
	foreach CollidingActors(class'PEnemyPawn_Minion', Victim, DamageRadius, FireLocation)//,,,,, HitInfo )
	{
		//Victim.TakeRadiusDamage(InstigatedByController, BaseDamage, DamageRadius, DamageType, Momentum, HurtOrigin, bDoFullDamage, self);
		Victim.TakeRadiusDamage(None, 1.0, DamageRadius, none, 0.0, FireLocation, false, self);
	}
	bHurtEntry = false;
}

//En TurretAuto, la Cannon vamos, cuando pasas a estado NuevoTarget, tiene que rotar hasta que apunta correctamente
//En nuestro caso, al ser radial, no tiene que apuntar, o sea que en cuanto tiene target, puede disparar.
//As� que sobreescribmos el estado NuevoTarget, para que directamente pase a disparar
state NuevoTarget
{
	event BeginState(Name PreviousStateName)
	{
		//_DEBUG_ ("Turret Ice, enemeigo seleccionado, pues a congelar");
		GoToState('Disparando');
	}
}

state Idle //�APAAAAAAAAAAAA TEMPORALLLLLLLLL
{
	event BeginState(Name PreviousStateName)
	{
		
		GoToState('Disparando');
	}
}

state Disparando
{
	event BeginState(name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
		m_tiempoDesdeAntDisparo = m_TimeoutEntreDisparo -0.2; //Para que nada m�s empezar dispare

	}

	function Tick(float DeltaTime)
	{
		//Vamos incrementando el radio del sistema de part�culas, y vamos ejecutando el TakeDamage Radial para
		//congelar aquello que est� afectado por el radio.
		//Tambi�n vamos haciendo el efecto de sinus para el movimiento de la part�cula
		local int i;
		local float tiempo_i;
		local float radio_i;
		local vector radio_v;
		local rotator r;
		local quat qat,qy;
		local vector rx,ry,rz;
		local float parasin;

		super.Tick(DeltaTime);

		for (i=0;i<m_array_disparos_hielo.Length;i++)
		{
			m_array_disparos_hielo[i].Tiempo += DeltaTime;
			if (m_array_disparos_hielo[i].Tiempo > 6)
			{
				//Si ha pasado el tiempo, la eliminamos. Primero marcamos como borrable, y luego borramos
				m_array_disparos_hielo[i].borrar = true;
			}
			else
			{
				//Incrementamos radio, aplicamos damage, y movemos la part�cula sinusoidalmente (toma palabrita ;) 
				tiempo_i = m_array_disparos_hielo[i].Tiempo;
				radio_i = m_radioinicial + tiempo_i * 70; 
				radio_v.X = radio_i;
				radio_v.y = radio_i;
				radio_v.z = 500;
				//m_array_disparos_hielo[i].ParticulasNieblaHielo.SetFloatParameter('RadioToroide',radio_i); 
				
				m_array_disparos_hielo[i].ParticulasNieblaHielo.SetVectorParameter('RadioToroide',radio_v); 
				//m_array_disparos_hielo[i].ParticulasNieblaHielo.SetFloatParameter('RadioCilindro',radio_i); 
				parasin = 200 + sin (tiempo_i*2) * 150;
				`log ("Altura "@parasin);
				//m_array_disparos_hielo[i].ParticulasNieblaHielo.SetFloatParameter('AlturaCilindro',parasin); 
				m_array_disparos_hielo[i].ParticulasNieblaHielo.SetFloatParameter('AlturaCilindro',100); 
				
				
				//hay que orientar en la perpendicular
				r=rotator(-m_NormalSuelo);
				qat = QuatFromRotator(r);
				GetAxes(r,rx,ry,rz);
				qy  = QuatFromAxisAndAngle(ry,-90*DegToRad);
				qat = QuatProduct(qy,qat);
				r= QuatToRotator(qat);
				m_array_disparos_hielo[i].ParticulasNieblaHielo.SetRotation(r);


				DrawDebugSphere(self.Location,radio_i,5,255,255,255,false);

				//S�lo recalculamos damage cada medio segundo, no vale la pena cargar a cada tick
				if ((tiempo_i - m_array_disparos_hielo[i].tiempo_anterior_hurt)>0.5)
				{
					//self.HurtRadius(1.0,radio_i,none,0,FireLocation);
					HacerDanyoRadial(radio_i);
					m_array_disparos_hielo[i].tiempo_anterior_hurt = tiempo_i;

				}
				//Sin para mover las part�culas
				//m_array_disparos_hielo[i].ParticulasNieblaHielo.SetFloatParameter('ParamAltura',sin(tiempo_i)); //Al principio abajo del todo
			}
		}
		for (i=0;i<m_array_disparos_hielo.Length;i++)
		{
			if(m_array_disparos_hielo[i].borrar)
			{
				m_array_disparos_hielo[i].ParticulasNieblaHielo.Destroy();
				m_array_disparos_hielo.Remove(i,1);
			}
		}
	}//Tick



}//StateDisparando


defaultproperties
{

	 Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironmentrr
        bEnabled=TRUE
    End Object
    Components.Add(MyLightEnvironmentrr)
	Begin Object class=SkeletalMeshComponent name=torretask
        
		AnimTreeTemplate=AnimTree'PGameContentTice.baseIceAnimTree'
		AnimSets(0)=AnimSet'PGameContentTice.basecannon'
		//USAMOS LAS MISMAS COLISIONES QUE LA TURRETCANON, POR LO QUE USAMOS SU PHYSICS ASSET!!
		PhysicsAsset=PhysicsAsset'PGameContentcannon.cannonrudk_Physics'
		bHasPhysicsAssetInstance=true
        SkeletalMesh=SkeletalMesh'PGameContentTice.icecannonrudk'
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
					DamageEmitterParamName=DamageParticles,
					EnConstruccion=ParticleSystem'PGameParticles.Particles.EnConstruccion'
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
	m_TimeoutEntreDisparo=10 //Disparo de hielo cada 3 segundos
	m_radioinicial = 300;
	m_alturainicial = 300;

}