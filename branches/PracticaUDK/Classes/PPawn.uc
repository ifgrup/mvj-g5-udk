
/** En UDK un Pawn es cualquier objeto que:
 * - Pueda controlar el jugador
 * - Pueda controlar la IA
 * - Pueda controlar mediante scripts
 * 
 * Por ejemplo: Un Pawn podría ser el personaje jugador, un enemigo, un compañero controlado por la IA 
 * o un amigo que juegue con nosotros en modo multijugador.
 * No se considera Pawn cosas como misiles, disparos, items, etc.
 */

// Siempre debemos derivar nuestra clase Pawn de GamePawn
class PPawn extends GamePawn;
// 

// Para que a nuestro Pawn le afecte la iluminación
var DynamicLightEnvironmentComponent LightEnvironment;
var vector FallDirection;
var float fTiempoDeSalto; //tiempo que lleva saltando. Si se pasa de un límite, para evitar que se pire volando, lo bajamos
var vector m_TranslateZ;
var bool m_VenimosDeBump;
var vector m_ULtimoFloorAntesSalto; //Por si en el salto el floor se ha perdido al saltar, chocar, etc
var int m_DistanciaAlSuelo; //Distancia del robot al suelo


var Actor m_BasePlaneta;
var bool m_BasePlanetaGuardado;

//Los sistemas de partículas del robot, para poder encenderlos y apagarlos todos juntos:
var array<ParticleSystemComponent>	m_ParticulasPropulsoresRobot;
var vector m_NormalAlCaerSuelo;
var bool m_RecienEstrellado;

event Tick(float DeltaTime)
{
    local vector vlocation,vnormal;
	local vector vZ;

	super.Tick(DeltaTime);
	//if (self.IsInState('PawnFalling') || self.IsInState('PawnFallingSky') || self.IsInState('PawnFlaying'))

	if (!self.IsInState('PPawn'))
	{
		//No hacemos nada si no está caminando
		return;
	}
		
	//Actualizamos el Floor, que nos hará falta para el salto, sobretodo después de chocar contra algo
	if (m_ULtimoFloorAntesSalto!=self.Floor)
	{
		self.m_ULtimoFloorAntesSalto=self.Floor;
		`log("FT "@self.m_ULtimoFloorAntesSalto);
	};

	//Calculamos la distancia del bicho al suelo
	trace(vlocation,vnormal,self.Location - Floor*300,self.Location,true,vect(0,0,1));

	//FlushPersistentDebugLines();
	//DrawDebugSphere(vlocation,10,50,200,0,0,true);
	vZ.X=0;
	vZ.Y=0;
	vz.Z=vsize(location-vlocation)-m_DistanciaAlSuelo;
	mesh.SetTranslation(-vz);
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


	//Si estoy saltando y choco,hago salto en dirección contraria, de forma análoga que si estoy caminando
	//Por tanto, no hay que hacer distinción, si bumpea por salto o por andar tiene que hacer exactamente lo mismo.

	self.Velocity=retroceso*Fclamp(Vsize(Velocity),100,300); 
	
    //Guardamos el jumpz anterior para luego restaurarlo.
	jump_z_temp = self.JumpZ;
	self.JumpZ = aceleracion_caida;

   //just in case, podríamos poner  como floor de salto contra torreta el de la normal de la torreta
   //por si el impacto es en un montículo de terreno con inclinación muy diferente a dicha normal,
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
	local ParticleSystemComponent PSC;

	super.PostBeginPlay();
	//CollisionComponent = Mesh;
    // Turning collision on for skelmeshcomp and off for cylinder
	CylinderComponent.SetActorCollision(false, false);
	Mesh.SetActorCollision(true, true);
	Mesh.SetTraceBlocking(true, true);

	if (self.Mesh.GetSocketByName('Socket_Cabeza') != none)
	{
		PSC = new () class'ParticleSystemComponent';
		if (PSC != none)
		{
			PSC.SetTemplate(ParticleSystem'CTF_Flag_IronGuard.Effects.P_CTF_Flag_IronGuard_Idle_Blue');
			self.Mesh.AttachComponentToSocket(PSC, 'Socket_Cabeza');
			m_ParticulasPropulsoresRobot.AddItem(PSC);
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Brazo_Derecho') != None)
	{
		PSC = new () class'ParticleSystemComponent';
		if (PSC != None)
		{
			PSC.SetTemplate(ParticleSystem'DunDefVFX.FX.Tower_FX.magicMissleProjectile_vFX');
			self.Mesh.AttachComponentToSocket(PSC, 'Socket_Brazo_Derecho');
			m_ParticulasPropulsoresRobot.AddItem(PSC);
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Antebrazo_Derecho') != none)
	{
		PSC = new () class'ParticleSystemComponent';
		if (PSC != none)
		{
			PSC.SetTemplate(ParticleSystem'DunDefVFX.FX.Tower_FX.magicMissleProjectile_vFX');
			self.Mesh.AttachComponentToSocket(PSC, 'Socket_Antebrazo_Derecho');
			m_ParticulasPropulsoresRobot.AddItem(PSC);
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Brazo_Izquierdo') != None)
	{
		PSC = new () class'ParticleSystemComponent';
		if (PSC != None)
		{
			PSC.SetTemplate(ParticleSystem'DunDefVFX.FX.Tower_FX.magicMissleProjectile_vFX');
			self.Mesh.AttachComponentToSocket(PSC, 'Socket_Brazo_Izquierdo');
			m_ParticulasPropulsoresRobot.AddItem(PSC);
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Antebrazo_Izquierdo') != none)
	{
		PSC = new () class'ParticleSystemComponent';
		if (PSC != none)
		{
			PSC.SetTemplate(ParticleSystem'DunDefVFX.FX.Tower_FX.magicMissleProjectile_vFX');
			self.Mesh.AttachComponentToSocket(PSC, 'Socket_Antebrazo_Izquierdo');
			m_ParticulasPropulsoresRobot.AddItem(PSC);
		}
	}

	if (self.Mesh.GetSocketByName('Socket_Base') != none)
	{
		PSC = new () class'ParticleSystemComponent';
		if (PSC != none)
		{
			PSC.SetTemplate(ParticleSystem'DunDefVFX.FX.Tower_FX.magicMissleProjectile_vFX');
			self.Mesh.AttachComponentToSocket(PSC, 'Socket_Base');
			m_ParticulasPropulsoresRobot.AddItem(PSC);
		}
	}
}


function EstadoPropulsores(bool bEstado)
{
	local int i;

	for (i=0;i<m_ParticulasPropulsoresRobot.Length;i++)
	{
		if(bEstado)
		{
			m_ParticulasPropulsoresRobot[i].ActivateSystem();
		}
		else
		{
			m_ParticulasPropulsoresRobot[i].DeactivateSystem();
		}
	}
}

function OrientarPropulsores(Rotator pRotator)
{
	local int i;
	local Rotator r;

	for (i=0;i<m_ParticulasPropulsoresRobot.Length;i++)
	{
		//m_ParticulasPropulsoresRobot[i].SetRotation(pRotator);
		r=m_ParticulasPropulsoresRobot[i].Rotation;
		r.Pitch+=32000;
		m_ParticulasPropulsoresRobot[i].SetRotation(r);
	}

}


/**
 * Añadimos el arma al inventario
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
 * Función que se llamará una única vez por Pawn cada vez que cambie el
 * objeto físico sobre el que esté posado el Pawn.
 * Comprobamos si el objeto es de tipo PPaintCanvas y de ser así, le decimos que
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
			ReboteRespectoA(Base);
	     }
		 else
		 {
			//Por si nos subimos a un extremo de un objeto y el spyder trepa...
			ReboteRespectoA(Base, 200);
			/* Esto era la opción de simplemente alejarlo un pelín, pero daba problemas
			 * No lo borro just in case, aunque si se demuestra que lo del rebote funciona, a eliminarlo ;)
			direc=Base.Location-self.Location;
			self.SetLocation(self.Location+Normal(-direc)*5); //Nos alejamos un pelín
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


/** Función DoJump
 * Sobreescribimos la función para decirle que si estás en disposición de saltar, no estas agachado (ni agachándote) 
 * y tienes un modelo físico válido, calcules la velocidad (el vector velocidad por el que te moverás) a partir de 
 * una constante de la altura a la que puedes saltar (JumpZ) y el vector del suelo.
 * 
 * El vector de suelo (Floor) siempre se considera en UDK como la superficie sobre la cual estás de pie.
 */
function bool DoJump( bool bUpdating )
{
	local vector tmpFloor;

	// Si podemos saltar...
	//Controlamos que no vengamos del Bump contra la torreta en este if. En el else sí se hace ese salto

	//IMPORTANTE!!!
	//Por cosas del UDK que desconozco, es mejor pasarle al Estado PawnFalling del salto la dirección de caída
	//con el floor que ahora sabemos que tenemos, o en el bump, si ya estaba saltando, como el Floor será de 0,0,1, 
	//hará cositas raras. Por tanto, FallDirection lo inicializamos aquí, y no en el BeginState de PawnFalling.
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
	//Si no puede saltar porque ya está saltando, no salta.
	//Pero si está saltando y la petición de salto viene desde el evento Bump, significa que durante el recorrido
	//del salto, ha encontrado una colisión, y se ha solicitado que salte hacia atrás.
	//En ese caso, sí que lo permitimos
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
 * Recibe la normal del suelo donde se acaba de colocar tras un salto o al volver de la vista aérea
 * En función de esa normal, orientamos al pawn
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
 * Estado personalizado al que pasará el Pawn cada vez que salte.
 * Se utiliza para saber cómo y hacia dónde aplicar la gravedad
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
	}

	event Tick(float DeltaTime)
	{	
		local vector vAlCentro;

		super.Tick(DeltaTime);

		// Apply Gravitational Force
		ApplyGravity(DeltaTime);
		fTiempoDeSalto+=DeltaTime;
		if (fTiempoDeSalto>3.0) //Se le ha ido la castaña al salto. Hay que bajarlo a la tierra.Utilizamos el centro del planeta
		{
			vAlCentro=PGame(WorldInfo.Game).GetCentroPlaneta()-Location; 
			FallDirection = Normal(vAlCentro);
			`log("volviendo pa la tierra neng!");
		}
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

		GotoState('');
		PC = PPlayerController(Instigator.Controller);
		PC.ClientMessage("HitWallPawn");
		`log('el pawn ha caido al suelo despues de saltar');
		SetBase(Wall, HitNormal);

		if(PPaintCanvas(Wall) != none)
		{
			PPaintCanvas(Wall).ChangeTexture();
		}
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
 * Copia de PawnFalling, con 4 cambios para la gestión de cuando caemos del cielo después de estar en vista aérea
 */
state PawnFallingSky
{
    ignores BaseChange;

	event BeginState(Name PrevName)
	{
		`log('pawn cayendo del cielo');
		// Direct hit wall enabled just for the custom falling
		bDirectHitWall = true;
		//No tocamos las físicas, que siga en flying como en PC
	}

	// cuando llegue al suelo:
	event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
	{
		// switch pawn back to standard state
		local PPlayerController PC;


		PC = PPlayerController(Instigator.Controller);
		PC.ClientMessage("HitWallPawn al caer del cielo_________________________________________");
		`log('el pawn ha caido al suelo despues de bajar de vista aerea');
		SetBase(Wall, HitNormal);
		
		if(PPaintCanvas(Wall) != none)
		{
			PPaintCanvas(Wall).ChangeTexture();
		}

		//Se acaba de estoñar contra el suelo.
		//Guardamos la normal del piñazo para luego orientar el Pawn más tade
		m_NormalAlCaerSuelo=HitNormal;
		GoToState('PawnRecienCaido'); 
	}

	event EndState(Name NextState)
	{

		bDirectHitWall = false; 
		SetPhysics(PHYS_None);
		SetPhysics(PHYS_Spider); // "Glue" back to surface. Si no, se iría cayendo
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
		//Al PlayerController le ponemos también en un estado dummy para que no pueda hacer nada el jugador
		local PPlayerController PC;

		PC = PPlayerController(Instigator.Controller);
		PC.GotoState('PlayerRecienCaido');

		SetTimer(2,false,'TimerCaida');
	}

	function TimerCaida()
	{

		//Apagamos el sistema de partículas, y volvemos a la normalidad
		GoToState('');

	}
	
	event EndState(Name nexstate)
	{
		local PPlayerController PC;
		local Rotator routPawn;

		PC = PPlayerController(Instigator.Controller);
   
		OrientarPawnPorNormal(m_NormalAlCaerSuelo,routPawn);
		PC.GotoState('PlayerSpidering'); //--> OJO con la ÑAPA en player Controller para coger el floor inicial...

		EstadoPropulsores(true);
	}

}


//STATE PAWNFLAYING:

state PawnFlaying
{
	//En este estado, no queremos que el pawn haga absolutamente nada, ya que estará invisible, y el control lo haremos
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

	/** Hacemos que el Pawn pueda estar afectado por la iluminación.
	 * Si no incluimos esto, el Pawn no estará iluminado y se verá totalmente oscuro.
	 */
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
	End Object


	// Una vez configurada la iluminación, la añadimos al renderizador...
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	/** Propiedades de visualización del Pawn:
	 * - Esqueleto que usará
	 * - Modelo 3D que usará
	 * - Set de animaciones
	 * - Modelo físico del modelo
	 */
	Begin Object Class=SkeletalMeshComponent Name=WPawnSkeletalMeshComponent
		//Your Mesh Properties
		//SkeletalMesh=SkeletalMesh'CH_LIAM_Cathode.Mesh.SK_CH_LIAM_Cathode'
		//SkeletalMesh=SkeletalMesh'Layout.BadGuy_Green'
		//SkeletalMesh=SkeletalMesh'Personaje.Ogre'
		SkeletalMesh=SkeletalMesh'Giru.Giru'
		//AnimTreeTemplate=AnimTree'CH_AnimHuman_Tree.AT_CH_Human'
		//PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
		//PhysicsAsset=PhysicsAsset'Personaje.Ogre_Physics_V2'
		PhysicsAsset=PhysicsAsset'Giru.Giru_Physics'
		//AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'

		Scale=1.5

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

	// Lo añadimos al motor
	Mesh=WPawnSkeletalMeshComponent
	Components.Add(WPawnSkeletalMeshComponent)



	// Esto tiene algo que ver con el modelo físico de colisiones del modelo
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0021.000000
		CollisionHeight=+0044.000000
	End Object

	// Lo añadimos al motor
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

	m_DistanciaAlSuelo=40
}
