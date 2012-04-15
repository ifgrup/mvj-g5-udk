
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


// Para que a nuestro Pawn le afecte la iluminación
var DynamicLightEnvironmentComponent LightEnvironment;
var vector FallDirection;
var float fTiempoDeSalto; //tiempo que lleva saltando. Si se pasa de un límite, para evitar que se pire volando, lo bajamos

/**
 * Añadimos el arma al inventario
 * 
 * */
function AddDefaultInventory()
{
	InvManager.CreateInventory(class'PGame.PWeapon');
}

/** BaseChange
 * Función que se llamará una única vez por Pawn cada vez que cambie el
 * objeto físico sobre el que esté posado el Pawn.
 * Comprobamos si el objeto es de tipo PPaintCanvas y de ser así, le decimos que
 * tiene que cambiar de color/textura.
 */
singular event BaseChange()
{
	//`log('Base Changed');
	if(PPaintCanvas(self.Base) != none)
	{
		PPaintCanvas(self.Base).ChangeTexture();
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
	// Si podemos saltar...
	if(bJumpCapable && !bIsCrouched && !bWantsToCrouch && Physics == PHYS_Spider)
	{
		// Calculamos la velocidad a partir de la constante de salto + el vector de suelo
		Velocity += JumpZ * Floor;

		// Y vamos al estado PawnFalling
		GotoState('PawnFalling');
		//`log('DoJump de PPawn');
		return true;
	}
	`log('DoJump de PPawn NO PUEDE SALTAR');
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
	DrawDebugCylinder(self.Location,self.Location+vector(rPawn)*100,5,20,100,100,0,true);
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
		WorldInfo.Game.Broadcast(self,"Entrando en PawnFalling");
		FallDirection = -Floor;
		
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
			vAlCentro=PPlayerController(self.Controller).m_CentroPlaneta-Location; 
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
//		local rotator routPawn;

		GotoState('');
		PC = PPlayerController(Instigator.Controller);
		PC.ClientMessage("HitWallPawn");
		`log('el pawn ha caido al suelo despues de saltar');
		SetBase(Wall, HitNormal);

		//c3
		//DrawDebugCylinder(self.Location,self.Location+HitNormal*150,4,30,0,200,0,true);

		if(PPaintCanvas(Wall) != none)
		{
			PPaintCanvas(Wall).ChangeTexture();
		}
	}
   
	event EndState(Name NextState)
	{
		FallDirection = vect(0,0,0); // CLEAR DESTINATION FLOOR
		bDirectHitWall = false; 
		SetPhysics(PHYS_Spider); // "Glue" back to surface
		`log('el pawn deja de esar en Falling');
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
		FallDirection = -Floor; //el Floor se lo deberá asignar PC al enviarle a este estado

		// Direct hit wall enabled just for the custom falling
		bDirectHitWall = true;
		//No tocamos las físicas, que siga en flying como en PC
		//La velocidad se la indicamos en PlayerController antes de poner el pawn en este estado
		//Acceleration=Velocity*10;
		
	}

	// cuando llegue al suelo:
	event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
	{
		// switch pawn back to standard state
		local PPlayerController PC;
		local Rotator routPawn;

		
		PC = PPlayerController(Instigator.Controller);
		PC.ClientMessage("HitWallPawn al caer del cielo");
		`log('el pawn ha caido al suelo despues de bajar de vista aerea');
		SetBase(Wall, HitNormal);
		
		//c3
		DrawDebugCylinder(self.Location,self.Location+HitNormal*150,4,30,0,200,0,true);
		OrientarPawnPorNormal(HitNormal,routPawn);
		//Ya ha llegado al suelo. Spidercerdo, spidercerdo..
		GoToState(''); //vuelve el pawn al estado 'normal'
		PC.GotoState('PlayerSpidering');
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
		`log('el pawn deja de esar en FallingSky');
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
		SkeletalMesh=SkeletalMesh'Layout.BadGuy_Green'
		AnimTreeTemplate=AnimTree'CH_AnimHuman_Tree.AT_CH_Human'
		PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
		AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
		Translation=(Z=8.0)
		Scale=1.075
		//General Mesh Properties
		bCacheAnimSequenceNodes=FALSE
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false
		CastShadow=true
		BlockRigidBody=TRUE
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=TRUE
		bUpdateKinematicBonesFromAnimation=true
		bCastDynamicShadow=true
		RBChannel=RBCC_Untitled3
		RBCollideWithChannels=(Untitled3=true)
		LightEnvironment=MyLightEnvironment
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=FALSE
		bHasPhysicsAssetInstance=true
		TickGroup=TG_PreAsyncWork
		MinDistFactorForKinematicUpdate=0.2
		bChartDistanceFactor=true
		RBDominanceGroup=20
		bUseOnePassLightingOnTranslucency=TRUE
		bPerBoneMotionBlur=true
		HiddenGame=False
		BlockNonZeroExtent=True
		BlockZeroExtent=True
		BlockActors=True
		CollideActors=True
	End Object

	// Lo añadimos al motor
	Mesh=WPawnSkeletalMeshComponent
	Components.Add(WPawnSkeletalMeshComponent)


	// Esto tiene algo que ver con el modelo físico de colisiones del modelo
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0021.000000
		CollisionHeight=+0044.000000
		BlockNonZeroExtent=True
		BlockZeroExtent=True
		BlockActors=True
		CollideActors=True
	End Object

	// Lo añadimos al motor
	CylinderComponent=CollisionCylinder
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)

	bCollideComplex=true //VMH: Creo que necesario, aunque el cilindro sigue usándolo, no ho entenc...
	//VLR Inventario para el arma
	InventoryManagerClass=class'PGame.PInventoryManager'
}
