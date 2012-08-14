
/** En UDK un Pawn es cualquier objeto que:
 * - Pueda controlar el jugador
 * - Pueda controlar la IA
 * - Pueda controlar mediante scripts
 * 
 * Por ejemplo: Un Pawn podr�a ser el personaje jugador, un enemigo, un compa�ero controlado por la IA 
 * o un amigo que juegue con nosotros en modo multijugador.
 * No se considera Pawn cosas como misiles, disparos, items, etc.
 */

// Siempre debemos derivar nuestra clase Pawn de GamePawn
class PPawn extends GamePawn;
// 

// Para que a nuestro Pawn le afecte la iluminaci�n
var DynamicLightEnvironmentComponent LightEnvironment;
var vector FallDirection;
var float fTiempoDeSalto; //tiempo que lleva saltando. Si se pasa de un l�mite, para evitar que se pire volando, lo bajamos
var vector m_TranslateZ;
var bool m_VenimosDeBump;
var vector m_ULtimoFloorAntesSalto; //Por si en el salto el floor se ha perdido al saltar, chocar, etc
var int m_DistanciaAlSuelo; //Distancia del robot al suelo
var int m_backupDistanciaAlSuelo; //para guardar el valor de m_DistanciaAlSuelo cuando se modifica

var Actor m_BasePlaneta;
var bool m_BasePlanetaGuardado;

//Los sistemas de part�culas del robot, para poder encenderlos y apagarlos todos juntos:
var array<EmitterSpawnable>	m_ParticulasPropulsoresRobot;
var vector m_NormalAlCaerSuelo;
var bool m_RecienEstrellado;
var bool m_permiteMoverSaltando;

//Guardamos valores del translateZ para hacer la media y que el translate sea m�s suave
var array<float> m_array_translatez;

var float m_tiempoEstado;

//Indices del vector de part�culas de m_ParticulasPropulsoresRobot
var int m_idx_brazo_ido,m_idx_brazo_dcho,m_idx_antebrazo_ido,m_idx_antebrazo_dcho,m_idx_base;

var int m_roll_antes_caer_cielo; //Roll que ten�amos antes de caer del cielo para mantener la orientaci�n
var bool m_bEstoyCayendoDelCielo; //Para saber si debemos utilizar m_roll_antes_caer_cielo o no

function float CalcularMediaTranslateZ(float valorZ)
{
	local int i;
	local float z;
	local int tam;
	tam=20;

	//a�adimos al array, y calculamos la media
	m_array_translatez.AddItem(valorZ);
	if (m_array_translatez.Length > tam)
	{
		m_array_translatez.Remove(0,1);
	}
	z=0;
	for (i=0;i<m_array_translatez.Length;i++)
	{
		z+=m_array_translatez[i]/m_array_translatez.Length;
	}
	//`log("Filtro vale "@z @m_array_translatez.Length @valorZ);
	return z;
}

event Tick(float DeltaTime)
{
    local vector vlocation,vnormal;
	local vector vZ;
	local vector rx,ry,rz;
	local vector posActual;
	local float valorZ;


	super.Tick(DeltaTime);
	//if (self.IsInState('PawnFalling') || self.IsInState('PawnFallingSky') || self.IsInState('PawnFlaying'))

	if (!self.IsInState('PPawn') && !self.IsInState('PawnPreparandoFlaying'))
	{
		//No hacemos nada si no est� caminando
		return;
	}
		
	//Actualizamos el Floor, que nos har� falta para el salto, sobretodo despu�s de chocar contra algo
	if (m_ULtimoFloorAntesSalto!=self.Floor)
	{
		self.m_ULtimoFloorAntesSalto=self.Floor;
		//`log("FT "@self.m_ULtimoFloorAntesSalto);
	};

	//Calculamos la distancia del bicho al suelo
	GetAxes(Rotation,rx,ry,rz);
	posActual = self.Location; 

	trace(vlocation,vnormal,posActual - rz*200,posActual,true,vect(1,1,1));
	//FlushPersistentDebugLines();
	//DrawDebugCylinder(self.Location,self.Location-Floor*300,5,5,0,10,10,true);
	//DrawDebugCylinder(self.Location,self.Location-rz*200,5,15,0,0,255,true);
	//DrawDebugCylinder(posActual,vlocation,5,15,0,0,255,true);
	if (vlocation == vect(0,0,0))
		`log("Trace nulo");
	
	//DrawDebugSphere(posActual,5,50,200,0,0,true);
	//DrawDebugSphere(vlocation,5,50,200,200,0,true);
	

	vZ.X=0;
	vZ.Y=0;
	valorZ = vsize( Normal(vlocation - posActual) * (vsize(vlocation-posActual)-m_DistanciaAlSuelo));
	vz.Z = CalcularMediaTranslateZ(valorZ);
	if (vz.Z > vsize(vlocation-posActual))
	{
		`log("Bajo tierra");
		//Lo corregimos, fijando la distancia al suelo
		vz.Z=vsize(vlocation-posActual)-m_DistanciaAlSuelo;
	}

	mesh.SetTranslation(-vz);
	m_TranslateZ = -vz;
	//DrawDebugSphere(posActual,5,50,200,0,0,true);
}


function ReboteRespectoA(Actor Other, float aceleracion_caida = JumpZ)
{
	local Vector newLocation;
	local Vector retroceso;
	local float jump_z_temp;


	m_VenimosDeBump=true; //Para control del salto

	//Hacemos que la velocidad sea la opuesta al vector formado por PAwn.Location -> Other.Location	retroceso=Normal(self.Location-Other.Location);
	//Nos colocamos ligeramente alejados del colisionado, por intentar evitar que si ha entrado en la caja de colision,
	//el inicio del salto siga estando dentro de la caja y vuelva a ejecutarse el Bump
	retroceso=Normal(self.Location-Other.Location);
	newLocation=self.Location+retroceso*2;
	self.SetLocation(newLocation);


	//Si estoy saltando y choco,hago salto en direcci�n contraria, de forma an�loga que si estoy caminando
	//Por tanto, no hay que hacer distinci�n, si bumpea por salto o por andar tiene que hacer exactamente lo mismo.

	self.Velocity=retroceso*Fclamp(Vsize(Velocity),100,500); 
	
	
    //Guardamos el jumpz anterior para luego restaurarlo.
	jump_z_temp = self.JumpZ;
	self.JumpZ = aceleracion_caida;

   //just in case, podr�amos poner  como floor de salto contra torreta el de la normal de la torreta
   //por si el impacto es en un mont�culo de terreno con inclinaci�n muy diferente a dicha normal,
   //evitar un raro efecto
   //De momento, lo comento, ya veremos si es necesario
    /*
	if (PAutoTurret(Other) != None)
	{
		m_ULtimoFloorAntesSalto = PAutoTurret(Other).m_NormalSuelo;
	}
    */
	self.DoJump(true);
	self.JumpZ = jump_z_temp; //restauramos jupz
	
	m_VenimosDeBump=false;
}


/*
 * Intento de hacer que al caer el Pawn rebota a saco. Pero no lo consigo porque enseguida que empieza
 * se produce el evento Bump normal con su velocidad, as� que no sirve de mucho.
 * Pero hay que implementarlo por si NO se ejecuta el Bump normal luego.
 */
function ReboteGrandeBumpCayendo(Actor Other, Vector BumpLocation, Vector BumpNormal,float aceleracion_caida = JumpZ)
{
	local float jump_z_temp;

	m_VenimosDeBump=true; //Para control del salto

	
	self.Velocity = (BumpNormal Cross normal(-self.Velocity)) *500;//rebote a tomar por culo
	
	DrawDebugCylinder(self.Location,self.Location+self.Velocity,3,5,100,255,50,true);
    //Guardamos el jumpz anterior para luego restaurarlo.
	jump_z_temp = self.JumpZ;
	self.JumpZ = 2000;
	self.DoJump(true);
	self.JumpZ = jump_z_temp; //restauramos jupz
	
	m_VenimosDeBump=false;
}


singular event Bump(Actor Other,PrimitiveComponent OtherComp, Vector HitNormal)
{
	if(PAutoTurret(Other)!= None)
	{  //Es una torreta. Rebotamos
		`log("Bump contra Torreta"@Other.Name);
		ReboteRespectoA(Other);
	}
	else
	{
		`log("Bump contra Noseque"@Other.Name);
		ReboteRespectoA(Other,200);
	}
	
}


event Touch(Actor Other,PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	`log("TOUUUUUUCH!!");
}
event bool EncroachingOn(Actor Other)
{
	`log("ENCROACHING OOOOOOOOON!!");
	
	return true; //to cancel the move
}

event EncroachedBy(Actor Other)
{
	`log("ENCROACHED BYYY!!");
}

event RanInto (Actor Other)
{
	`log("RANITOOOOO!!");


}


simulated function PostBeginPlay()
{
	//local ParticleSystemComponent PSC;
    local EmitterSpawnable PSC;
	super.PostBeginPlay();
	//CollisionComponent = Mesh;
    // Turning collision on for skelmeshcomp and off for cylinder
	CylinderComponent.SetActorCollision(false, false);
	Mesh.SetActorCollision(true, true);
	Mesh.SetTraceBlocking(true, true);

	if (self.Mesh.GetSocketByName('Socket_Cabeza') != none)
	{
		PSC = Spawn(class'EmitterSpawnable',Self);
		if (PSC != none)
		{
			PSC.SetTemplate(ParticleSystem'CTF_Flag_IronGuard.Effects.P_CTF_Flag_IronGuard_Idle_Blue');
			self.Mesh.AttachComponentToSocket(PSC.ParticleSystemComponent, 'Socket_Cabeza');
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Brazo_Derecho') != None)
	{
		PSC = Spawn(class'EmitterSpawnable',Self);
		if (PSC != None)
		{
			PSC.SetTemplate(ParticleSystem'Giru.Materials.particulas_propulsor');
			self.Mesh.AttachComponentToSocket(PSC.ParticleSystemComponent, 'Socket_Brazo_Derecho');
			m_ParticulasPropulsoresRobot.AddItem(PSC);
			m_idx_brazo_dcho = m_ParticulasPropulsoresRobot.Length -1;
			PSC.SetFloatParameter('ParamAlpha',0.3);			
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Antebrazo_Derecho') != none)
	{
		PSC = Spawn(class'EmitterSpawnable',Self);

		if (PSC != none)
		{
			PSC.SetTemplate(ParticleSystem'Giru.Materials.particulas_propulsor');
			self.Mesh.AttachComponentToSocket(PSC.ParticleSystemComponent, 'Socket_Antebrazo_Derecho');
			m_ParticulasPropulsoresRobot.AddItem(PSC);
			m_idx_antebrazo_dcho = m_ParticulasPropulsoresRobot.Length -1;
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Brazo_Izquierdo') != None)
	{
		PSC = Spawn(class'EmitterSpawnable',Self);

		if (PSC != None)
		{
			PSC.SetTemplate(ParticleSystem'Giru.Materials.particulas_propulsor');
			self.Mesh.AttachComponentToSocket(PSC.ParticleSystemComponent, 'Socket_Brazo_Izquierdo');
			m_ParticulasPropulsoresRobot.AddItem(PSC);
			m_idx_brazo_ido = m_ParticulasPropulsoresRobot.Length -1;
			PSC.SetFloatParameter('ParamAlpha',0.3);			
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Antebrazo_Izquierdo') != none)
	{
		PSC = Spawn(class'EmitterSpawnable',Self);
		if (PSC != none)
		{
			PSC.SetTemplate(ParticleSystem'Giru.Materials.particulas_propulsor');
			self.Mesh.AttachComponentToSocket(PSC.ParticleSystemComponent, 'Socket_Antebrazo_Izquierdo');
			m_ParticulasPropulsoresRobot.AddItem(PSC);

			m_idx_antebrazo_ido = m_ParticulasPropulsoresRobot.Length -1;
			PSC.SetFloatParameter('ParamAlpha',0.3);			
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Base') != none)
	{
		PSC = Spawn(class'EmitterSpawnable',Self);

		if (PSC != none)
		{
			PSC.SetTemplate(ParticleSystem'Giru.Materials.particulas_propulsor');
			self.Mesh.AttachComponentToSocket(PSC.ParticleSystemComponent, 'Socket_Base');
			m_ParticulasPropulsoresRobot.AddItem(PSC);
			m_idx_base = m_ParticulasPropulsoresRobot.Length -1;
			PSC.SetFloatParameter('ParamAlpha',0.1);			
			`log("" @PSC.ParticleSystemComponent.InstanceParameters[0].Name);
			`log("" @PSC.ParticleSystemComponent.InstanceParameters[0].Scalar);
			`log("" @PSC.ParticleSystemComponent.InstanceParameters[0].ParamType);

		}
	}
}

function Vector GetPosicionSocketCabeza()
{
	local vector sLocation;
	local rotator sRotation;

	self.Mesh.GetSocketWorldLocationAndRotation('Socket_Cabeza',sLocation,sRotation);
	return sLocation;

}

function EstadoPropulsores(bool bEstado)
{
	local int i;

	for (i=0;i<m_ParticulasPropulsoresRobot.Length;i++)
	{
		if(bEstado)
		{
			m_ParticulasPropulsoresRobot[i].ParticleSystemComponent.ActivateSystem();
		}
		else
		{
			m_ParticulasPropulsoresRobot[i].ParticleSystemComponent.DeactivateSystem();
		}
	}
}

function OrientarPropulsores(float player_aTurn, float player_astrafe,float player_aforward)
{
	local Rotator r;
	//`log("escaalar " @player_aTurn @player_astrafe @player_aforward);
	
	//Los dos brazos tendr�n la misma rotaci�n, as� que usamos una de cualquiera de los dos para los c�lculos
	r=m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.Rotation;

	if (player_astrafe <0 || player_aTurn <0)
    {
		//Girando a la izquierda
		m_ParticulasPropulsoresRobot[m_idx_brazo_dcho].ParticleSystemComponent.SetFloatParameter('ParamAlpha',1);
		m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.SetFloatParameter('ParamAlpha',0.2);

		r.yaw =-15*DegToUnrRot;
    }
	else if (player_astrafe >0 || player_aTurn >0)
	{
		//Girando a la derecha
		m_ParticulasPropulsoresRobot[m_idx_brazo_dcho].ParticleSystemComponent.SetFloatParameter('ParamAlpha',0.2);
		m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.SetFloatParameter('ParamAlpha',1);

		r.yaw = 15*DegToUnrRot;
	}
	else if (player_astrafe ==0 && player_aTurn == 0)
	{
		//es cero
		m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.SetFloatParameter('ParamAlpha',0.3);
		m_ParticulasPropulsoresRobot[m_idx_brazo_dcho].ParticleSystemComponent.SetFloatParameter('ParamAlpha',0.3);
		r.yaw = 0;
	}

	//___Y AHORA PARA EL MOVIMIENTO HACIA DELANTE Y HACIA ATRAS _________
	if (player_aforward >0)
	{
		r.pitch = -25*DegToUnrRot;
		m_ParticulasPropulsoresRobot[m_idx_brazo_dcho].ParticleSystemComponent.SetFloatParameter('ParamAlpha',1);
		m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.SetFloatParameter('ParamAlpha',1);

	}
	else if  (player_aforward <0)
	{
		r.pitch = 25*DegToUnrRot;
		m_ParticulasPropulsoresRobot[m_idx_brazo_dcho].ParticleSystemComponent.SetFloatParameter('ParamAlpha',1);
		m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.SetFloatParameter('ParamAlpha',1);

	}
	else if  (player_aforward == 0)
	{
		r.pitch = 0;
		m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.SetFloatParameter('ParamAlpha',0.3);
		m_ParticulasPropulsoresRobot[m_idx_brazo_dcho].ParticleSystemComponent.SetFloatParameter('ParamAlpha',0.3);

	}
    
	//Y asignamos la nueva rotaci�n a los 2 brazos
	m_ParticulasPropulsoresRobot[m_idx_brazo_ido].ParticleSystemComponent.SetRotation(r);
	m_ParticulasPropulsoresRobot[m_idx_brazo_dcho].ParticleSystemComponent.SetRotation(r);



}

function PotenciaPropulsorBase(float pot)
{
	//Ponemos la potencia del proyector base.
	//La usamos para el salto, para que en el momento del salto pase a m�xima potencia
	//Y luego vaya bajando. Se hace en el tick del estado Falling.
	m_ParticulasPropulsoresRobot[m_idx_base].ParticleSystemComponent.SetFloatParameter('ParamAlpha',pot);
}


/**
 * A�adimos el arma al inventario
 * 
 * */
function AddDefaultInventory()
{
	InvManager.CreateInventory(class'PGame.PWeapon');
}

exec function qbase()
{
	`log("La Base actual es "@self.Base);
}
/** BaseChange
 * Funci�n que se llamar� una �nica vez por Pawn cada vez que cambie el
 * objeto f�sico sobre el que est� posado el Pawn.
 * Comprobamos si el objeto es de tipo PPaintCanvas y de ser as�, le decimos que
 * tiene que cambiar de color/textura.
 */
singular event BaseChange()
{
	local vector direc;

	if (Base!=None) `log('Base Changed '@self.Base.Name);
	else `log('Base Changed to None');
    
	if(PPaintCanvas(self.Base) != none)
	{
		PPaintCanvas(self.Base).ChangeTexture();
	}

	if (!m_BasePlanetaGuardado && Base.Name=='StaticMeshActor_1')
	{
		//El planeta. Lo guardamos
		m_BasePlaneta=Base;
		m_BasePlanetaGuardado=true;
	}
	//Hacemos lo mismo que en Bump pa probar
	if(Base!=None && Base.Name!= 'StaticMeshActor_1')
	{
	     if(PAutoTurret (Base) != None)
	     {  //Es una torreta. Rebotamos
			if (GetStateName() == 'PawnFallingSky')
			{
				//self.m_ULtimoFloorAntesSalto = 
				ReboteRespectoA(Base,500);
			}
			else
			{
				ReboteRespectoA(Base);
			}
	     }
		 else
		 {
			//Por si nos subimos a un extremo de un objeto y el spyder trepa...
			ReboteRespectoA(Base, 200);
			/* Esto era la opci�n de simplemente alejarlo un pel�n, pero daba problemas
			 * No lo borro just in case, aunque si se demuestra que lo del rebote funciona, a eliminarlo ;)
			direc=Base.Location-self.Location;
			self.SetLocation(self.Location+Normal(-direc)*5); //Nos alejamos un pel�n
		 	self.SetBase(m_BasePlaneta);
			*/

		 }
	}
}

// called when the pawn lands or hits another surface
event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
{
	
	//`log('Hit Wall neng');
	GotoState('');
	SetBase(Wall, HitNormal);

	if(PPaintCanvas(Wall) != none)
	{
		PPaintCanvas(Wall).ChangeTexture();
	}
}


/** Funci�n DoJump
 * Sobreescribimos la funci�n para decirle que si est�s en disposici�n de saltar, no estas agachado (ni agach�ndote) 
 * y tienes un modelo f�sico v�lido, calcules la velocidad (el vector velocidad por el que te mover�s) a partir de 
 * una constante de la altura a la que puedes saltar (JumpZ) y el vector del suelo.
 * 
 * El vector de suelo (Floor) siempre se considera en UDK como la superficie sobre la cual est�s de pie.
 */
function bool DoJump( bool bUpdating )
{
	local vector tmpFloor;

	// Si podemos saltar...
	//Controlamos que no vengamos del Bump contra la torreta en este if. En el else s� se hace ese salto

	//IMPORTANTE!!!
	//Por cosas del UDK que desconozco, es mejor pasarle al Estado PawnFalling del salto la direcci�n de ca�da
	//con el floor que ahora sabemos que tenemos, o en el bump, si ya estaba saltando, como el Floor ser� de 0,0,1, 
	//har� cositas raras. Por tanto, FallDirection lo inicializamos aqu�, y no en el BeginState de PawnFalling.
	//A tener en cuenta por si se necesita el salto desde otro sitio.

	if(!m_VenimosDeBump && bJumpCapable && !bIsCrouched && !bWantsToCrouch && Physics == PHYS_Spider)
	{
		// Calculamos la velocidad a partir de la constante de salto + el vector de suelo
		tmpFloor=Floor;
		if (Floor == vect(0,0,1) || Floor== vect(0,0,0))
		{
			`log ("No lo entiendo...");
			tmpFloor=m_ULtimoFloorAntesSalto;
		}

		Velocity += JumpZ * tmpFloor;
		FallDirection = -tmpFloor;
		// Y vamos al estado PawnFalling
		`log('SALTO NORMAL  ' @tmpFloor);
		GotoState('PawnFalling');
		//`log('DoJump de PPawn');
		return true;
	}
 	`log('DoJump de PPawn NO PUEDE SALTAR');
	//Si no puede saltar porque ya est� saltando, no salta.
	//Pero si est� saltando y la petici�n de salto viene desde el evento Bump, significa que durante el recorrido
	//del salto, ha encontrado una colisi�n, y se ha solicitado que salte hacia atr�s.
	//En ese caso, s� que lo permitimos
	if(m_VenimosDeBump)
	{
		`log('SALTO por BUMP ' @m_ULtimoFloorAntesSalto);
		DrawDebugCylinder(self.Location,self.Location+m_ULtimoFloorAntesSalto*100,4,10,0,255,255,true);
		Velocity += JumpZ * m_ULtimoFloorAntesSalto;
		FallDirection = -m_ULtimoFloorAntesSalto;
		GotoState('PawnFalling');
		return true;
	}
	return false;
}


/*
 * Funcion OrientarPawnPorNormal.
 * Recibe la normal del suelo donde se acaba de colocar tras un salto o al volver de la vista a�rea
 * En funci�n de esa normal, orientamos al pawn
 */

function OrientarPawnPorNormal ( Vector normalsuelo, out Rotator pawnRotation)
{
	local Rotator rPawn;
	local Vector rX,rY,rZ;
	local Quat quatRZ,quatNormal;

	rPawn=Rotator(-normalsuelo);

	quatNormal=QuatFromRotator(rPawn);
	GetAxes(rPawn,rX,rY,rZ);
	quatRZ=QuatFromAxisAndAngle(rY,-90*DegToRad);
	quatRZ=QuatProduct(quatRZ,quatNormal);
	rPawn=QuatToRotator(quatRZ);

	//Intentamos mantener la orientaci�n de roll de cuando est�bamos arriba :
	if (m_bEstoyCayendoDelCielo)
	{
		m_bEstoyCayendoDelCielo = false;
		quatNormal=QuatFromRotator(rPawn);
		GetAxes(rPawn,rX,rY,rZ);
		quatRZ=QuatFromAxisAndAngle(rZ,m_roll_antes_caer_cielo*UnrRotToRad);
		quatRZ=QuatProduct(quatRZ,quatNormal);
		rPawn=QuatToRotator(quatRZ);
	}

    SetRotation(rPawn);
	self.Floor=normalsuelo;
	pawnRotation=rPawn;
	//c4 
	//DrawDebugCylinder(self.Location,self.Location+vector(rPawn)*100,5,20,255,0,0,true);
	//DrawDebugCylinder(self.Location,self.Location+normalSuelo*100,5,20,0,255,0,true);
}

/** -----------------------
 * ---Estado PawnFalling---
 * ------------------------
 * 
 * Estado personalizado al que pasar� el Pawn cada vez que salte.
 * Se utiliza para saber c�mo y hacia d�nde aplicar la gravedad
 */
state PawnFalling
{


	event BeginState(Name PrevName)
	{

		`log('pawn en estado Falling');
		//DBG WorldInfo.Game.Broadcast(self,"Entrando en PawnFalling");
		//VMH: Lo inicializo en DoJump 
		//FallDirection = -Floor;
		
        // Direct hit wall enabled just for the custom falling
		bDirectHitWall = true;

		// flying instead of Falling as flying allows for custom gravity
		SetPhysics(PHYS_Flying);
		fTiempoDeSalto=0.0; //tiempo de salto
		m_permiteMoverSaltando=true; //Si el salto se prolonga no permitimos que 'vuele'
		PotenciaPropulsorBase(1.0); //El m�ximo
	}

	event Tick(float DeltaTime)
	{	
		local vector vAlCentro;

		super.Tick(DeltaTime);

		// Apply Gravitational Force
		ApplyGravity(DeltaTime);
		fTiempoDeSalto+=DeltaTime;
		if (fTiempoDeSalto>3.0) //Se le ha ido la casta�a al salto. Hay que bajarlo a la tierra.Utilizamos el centro del planeta
		{
			vAlCentro=PGame(WorldInfo.Game).GetCentroPlaneta()-Location; 
			FallDirection = Normal(vAlCentro);
			`log("volviendo pa la tierra neng!");
			m_permiteMoverSaltando=false;
			PotenciaPropulsorBase(0); //parecer� pr�cticamente apagado
		}
		PotenciaPropulsorBase(fclamp(1-(fTiempoDeSalto),0.1,0.8)); //Va perdiendo potencia
		
	}

	/** Adds gravity to the velocity based on floor normal pawn was last on */
	function ApplyGravity(float DeltaTime)
	{
		local Vector Gravity;

		Gravity = FallDirection * WorldInfo.WorldGravityZ * -1 * DeltaTime;

		// Add force to velocity
		Velocity += Gravity;
		//`log('Gravity on Pawn en estado Falling');
	}

	// called when the pawn lands or hits another surface
	event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
	{
		// switch pawn back to standard state
		local PPlayerController PC;
		local Rotator routPawn;

		GotoState('');
		PC = PPlayerController(Instigator.Controller);
		PC.ClientMessage("HitWallPawn");

		if (Wall == m_BasePlaneta)
		{
			OrientarPawnPorNormal(HitNormal,routPawn);
			PC.GotoState('PlayerSpidering'); //Porque si veniamos de rebote al caer del planeta, el PC esta en otro estado
			
			`log('el pawn ha caido al suelo despues de saltar');
			SetBase(Wall, HitNormal);
		}
		else
		{
			ReboteRespectoA(Wall);
		}

		if(PPaintCanvas(Wall) != none)
		{
			PPaintCanvas(Wall).ChangeTexture();
		}
		PotenciaPropulsorBase(0.1); //El valor base
	}
   
	event EndState(Name NextState)
	{
		FallDirection = vect(0,0,0); // CLEAR DESTINATION FLOOR
		bDirectHitWall = false; 
		SetPhysics(PHYS_None); 
		SetPhysics(PHYS_Spider); // "Glue" back to surface
		
		`log('el pawn deja de esar en Falling y va a '@NextState);
	}
}



/** -----------------------
 * ---Estado PawnFallingSky---
 * ------------------------
 * 
 * Copia de PawnFalling, con 4 cambios para la gesti�n de cuando caemos del cielo despu�s de estar en vista a�rea
 */
state PawnFallingSky
{
    ignores BaseChange;

	event BeginState(Name PrevName)
	{
		`log('pawn cayendo del cielo');
		// Direct hit wall enabled just for the custom falling
		bDirectHitWall = true;
		//No tocamos las f�sicas, que siga en flying como en PC
		m_bEstoyCayendoDelCielo = true; //Para que sepa que venimos de caer del cielo

	}

	singular event Bump(Actor Other,PrimitiveComponent OtherComp, Vector HitNormal)
    {
		//SI mientras cae choca contra algo.
		//el tratamiento NO SE PORQUE se ejecuta este en lugar del hitwall, supongo que porque una torreta por ejemplo
		//no la considera como Wall.... Total, hacemos un tratamiento an�logo, con otros estados casi copiados.
		local PPlayerController PC;
		PC = PPlayerController(Instigator.Controller);
		
		if(PAutoTurret(Other)!= None)
		{  //Es una torreta. Rebotamos
		   PC.GotoState('PlayerBumpCayendo');
		   ReboteGrandeBumpCayendo(Other,self.location,HitNormal, 100);
		}
		else if (PEnemy(Other)!=None)
		{
			//Lo reventamos llamando a su PawnCaidoEncima
			//Debe asegurarse que se elimina, se chafa, para que al hacer return
			//no vuelva a ejecutarse este Bump
			`log("Bump contra un PEnemy "@Other.Name);
			if(!PEnemy(Other).IsInState('ChafadoPorPawn')) //Estado en el que le pongamos cuando lo chafemos, por si est� un rato
			{
				PEnemy(Other).PawnCaidoEncima();
			}
			return; //No hacemos nada m�s con �l, lo ignoramos, hasta llegar al suelo
		}
		else if (Other.Name == 'PShield_0')
		{
			`log("Bump contra el escudo, lo ignoramos");
			return; //lo ignoramos, para que siga cayendo
		}
		else
		{
			`log("Bump contra NO SE QU�!!! CUIDADOOOOOOO!!!");
			return; //lo ignoramos, para que siga cayendo
		}
    }
	// cuando llegue al suelo:
	event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
	{
		// switch pawn back to standard state
		local PPlayerController PC;


		if (Wall.Name == 'PShield_0')
		{
			return; //Lo ignoramos, para que siga cayendo
		}
		PC = PPlayerController(Instigator.Controller);
		PC.ClientMessage("HitWallPawn al caer del cielo_________________________________________");
		
		if (Wall == self.m_BasePlaneta)
		{
			`log('el pawn ha caido al suelo despues de bajar de vista aerea');
			SetBase(Wall, HitNormal);
			
			if(PPaintCanvas(Wall) != none)
			{
				PPaintCanvas(Wall).ChangeTexture();
			}
	
			//Se acaba de esto�ar contra el suelo.
			//Guardamos la normal del pi�azo para luego orientar el Pawn m�s tade
			m_NormalAlCaerSuelo=HitNormal;
			GoToState('PawnRecienCaido'); 
		}
		else
		{
			`log('el pawn ha caido contra algo desde el cielo '@wall.Name);
			self.m_ULtimoFloorAntesSalto = HitNormal;
			self.ReboteRespectoA(wall,500);
			
		}
	}//event HitWall

	event EndState(Name NextState)
	{

		bDirectHitWall = false; 
		SetPhysics(PHYS_None);
		SetPhysics(PHYS_Spider); // "Glue" back to surface. Si no, se ir�a cayendo
		`log('el pawn deja de esar en FallingSky y va a '@NextState);
	}
}

//STATE PawnRecienCaido
state PawnRecienCaido
{
	//ignores HitWall;

	event BeginState(Name prevstate)
	{
		//S.Particules de caida, y a los dos segundos, volvemos al estao normal.
		//Al PlayerController le ponemos tambi�n en un estado dummy para que no pueda hacer nada el jugador
		local PPlayerController PC;

		PC = PPlayerController(Instigator.Controller);
		PC.GotoState('PlayerRecienCaido');

		SetTimer(2,false,'TimerCaida');
	}

	function TimerCaida()
	{

		//Apagamos el sistema de part�culas, y volvemos a la normalidad
		GoToState('');

	}
	
	event EndState(Name nexstate)
	{
		local PPlayerController PC;
		local Rotator routPawn;

		PC = PPlayerController(Instigator.Controller);
   
		OrientarPawnPorNormal(m_NormalAlCaerSuelo,routPawn);
		DrawDebugCylinder(self.Location,self.location+self.Floor*140,6,10,255,0,0,true);
		PC.GotoState('PlayerSpidering'); //--> OJO con la �APA en player Controller para coger el floor inicial...

		EstadoPropulsores(true);
	}

}


//STATE PAWNFLAYING:

state PawnFlaying
{
	//En este estado, no queremos que el pawn haga absolutamente nada, ya que estar� invisible, y el control lo haremos
	//entero desde PPlayerController, con el estado PlayerFlaying

	event BeginState(Name PreviousState)
	{
		`log("Pawn en PawnFlaying, previous was: "@PreviousState);
		//Invisible, y a volar!
		Mesh.SetOwnerNoSee(true);
		SetPhysics(PHYS_Flying);
		
	}
	
	event EndState(Name NextState)
	{
		`log("Pawn END state: "@NextState);
		//la ponemos visible de nuevo
		Mesh.SetOwnerNoSee(false);
		
	}

}//STATE PLAYERFLAYING


/******************************************************************************************************************/
state PawnPreparandoFlaying
{
	event BeginState(Name prevstate)
	{
		`log("Preparando para saltar");
		m_tiempoEstado=0;
		m_backupDistanciaAlSuelo = m_DistanciaAlSuelo; //Porque lo modificamos, para restaurarlo
	}

	event EndState(Name nextstate)
	{
		`log("Fin de PlayerPreparandoFlaying");
		m_DistanciaAlSuelo = m_backupDistanciaAlSuelo;
	}

	event Tick(float DeltaTime)
	{
		local PPlayerController PC;
		local vector Parriba;
		local vector vx,vy,vz;

		m_tiempoEstado += DeltaTime;
		
		PC = PPlayerController(Instigator.Controller);

		if(m_tiempoEstado < 2)
		{
			//Vamos disminuyendo m_DistanciaAlSuelo para que baje
			//Tenemos que ir llamando al Tick del estado base para que lo haga
			//Pero s�lo en este if,no hacer sl super.Tick al principio de la funci�n
			//O el efecto de salto no se notar� puesto que el tick lo baja al suelo
			super.Tick(DeltaTime);
			
			m_DistanciaAlSuelo -= int(1+(m_tiempoEstado*1.5));
			if (m_DistanciaAlSuelo <2) //que no llegue al suelo
			{
				m_DistanciaAlSuelo = 2;
			}
		}
		else if (m_tiempoEstado >2 && m_tiempoEstado <2.5)
		{
			//Iniciamos el despegue parriba
			GetAxes(self.Rotation,vX,vY,vZ);
			Parriba = 50 * vZ ;
			self.SetLocation(self.Location+Parriba);
			
		}
		else if (m_tiempoEstado > 2.5)
		{
			
			PC.GotoState('PlayerFlaying'); //El PC ya pone al Pawn en el estado que toca
		}
	}

}//state PawnPreparandoFlaying


defaultproperties
{
	// Propiedades que daremos por defecto
	WalkingPct=+0.4
	CrouchedPct=+0.4
	BaseEyeHeight=38.0
	EyeHeight=38.0
	GroundSpeed=440.0
	AirSpeed=440.0
	WaterSpeed=220.0
	AccelRate=2048.0
	JumpZ=500.0
	CrouchHeight=29.0
	CrouchRadius=21.0
	WalkableFloorZ=0.78
	bDirectHitWall=true
	bRollToDesired=True
	

	// Elimina el sprite del editor
	Components.Remove(Sprite)

	/** Hacemos que el Pawn pueda estar afectado por la iluminaci�n.
	 * Si no incluimos esto, el Pawn no estar� iluminado y se ver� totalmente oscuro.
	 */
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
	End Object


	// Una vez configurada la iluminaci�n, la a�adimos al renderizador...
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	/** Propiedades de visualizaci�n del Pawn:
	 * - Esqueleto que usar�
	 * - Modelo 3D que usar�
	 * - Set de animaciones
	 * - Modelo f�sico del modelo
	 */
	Begin Object Class=SkeletalMeshComponent Name=WPawnSkeletalMeshComponent
		//Your Mesh Properties
		//SkeletalMesh=SkeletalMesh'CH_LIAM_Cathode.Mesh.SK_CH_LIAM_Cathode'
		//SkeletalMesh=SkeletalMesh'Layout.BadGuy_Green'
		//SkeletalMesh=SkeletalMesh'Personaje.Ogre'
		
		//AnimTreeTemplate=AnimTree'CH_AnimHuman_Tree.AT_CH_Human'
		//PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
		//PhysicsAsset=PhysicsAsset'Personaje.Ogre_Physics_V2'
	
		//AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'

		//ogro

		//SkeletalMesh=SkeletalMesh'Ogro.Ogre'
		//AnimTreeTemplate=AnimTree'Ogro.Ogro_AnimTree'
		//PhysicsAsset=PhysicsAsset'Ogro.Ogre_Physics_V2'
		//AnimSets(0)=AnimSet'Ogro.Ogro_Anim'

		//giru
		SkeletalMesh=SkeletalMesh'Giru.Giru'
		PhysicsAsset=PhysicsAsset'Giru.Giru_Physics'
		Scale=0.8

		//General Mesh Properties
		bCacheAnimSequenceNodes=FALSE
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false
		CastShadow=true
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=TRUE
		bUpdateKinematicBonesFromAnimation=true
		bCastDynamicShadow=true
		LightEnvironment=MyLightEnvironment
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=FALSE
		bUseOnePassLightingOnTranslucency=TRUE
		bPerBoneMotionBlur=true
		HiddenGame=False
	End Object

	// Lo a�adimos al motor
	Mesh=WPawnSkeletalMeshComponent
	Components.Add(WPawnSkeletalMeshComponent)



	// Esto tiene algo que ver con el modelo f�sico de colisiones del modelo
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0021.000000
		CollisionHeight=+0044.000000
	End Object

	// Lo a�adimos al motor
	CylinderComponent=CollisionCylinder

	//Components.Remove(CollisionCylinder)

	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
	//VLR Inventario para el arma
	InventoryManagerClass=class'PGame.PInventoryManager'

	//Para colisiones:
	bCollideComplex=true
	BlockRigidBody=true
	bCollideActors=true
	bCollideWorld=true
	CollisionType=COLLIDE_BlockAll
	
	m_BasePlaneta = None
	m_BasePlanetaGuardado = false

	m_DistanciaAlSuelo = 10
}
