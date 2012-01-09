
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


// Para que a nuestro Pawn le afecte la iluminaci�n
var DynamicLightEnvironmentComponent LightEnvironment;
var vector FallDirection;
defaultproperties
{
	/** Propiedades que daremos por defecto
	 * La mayor�a no s� para qu� sirven :D
	 */
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

	bRollToDesired=True
	
	//VMH
	bUseCylinderCollision=True

	// No s� que es esto :D
	Components.Remove(Sprite)

	/* Hacemos que el Pawn pueda estar afectado por la iluminaci�n.
	 * Si no incluimos esto, el Pawn no estar� iluminado y se ver� totalmente oscuro.
	 */
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
	End Object

	// Una vez configurada la iluminaci�n, la a�adimos al renderizador... o algo
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	/** Propiedades de visualizaci�n del Pawn:
	 * - Esqueleto que usar�
	 * - Modelo 3D que usar�
	 * - Set de animaciones
	 * - Modelo f�sico del modelo
	 * Y dem�s cosas que no acabo de ver para qu� son :D
	 */
	Begin Object Class=SkeletalMeshComponent Name=WPawnSkeletalMeshComponent
		//Your Mesh Properties
		SkeletalMesh=SkeletalMesh'CH_LIAM_Cathode.Mesh.SK_CH_LIAM_Cathode'
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

	// Lo a�adimos al motor
	Mesh=WPawnSkeletalMeshComponent
	Components.Add(WPawnSkeletalMeshComponent)

	// Esto tiene algo que ver con el modelo f�sico de colisiones del modelo
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0021.000000
		CollisionHeight=+0044.000000
		BlockNonZeroExtent=True
		BlockZeroExtent=True
		BlockActors=True
		CollideActors=True
	End Object

	// Lo a�adimos al motor
	//CylinderComponent=CollisionCylinder
	CollisionComponent=WPawnSkeletalMeshComponent
    Components.Add(CollisionComponent);
	
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
	// Si podemos saltar...
	if(bJumpCapable && !bIsCrouched && !bWantsToCrouch && Physics == PHYS_Spider)
	{
		// Calculamos la velocidad a partir de la constante de salto + el vector de suelo
		Velocity += JumpZ * Floor;

		// Y vamos al estado PawnFalling
		GotoState('PawnFalling');
		return true;
	}

	return false;
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
		FallDirection = vect(0,0,0);
		
		// If no destination pawn falls back to the same floor
		if(FallDirection == vect(0,0,0))
		FallDirection = -Floor;

		// Direct hit wall enabled just for the custom falling
		bDirectHitWall = true;

		// flying instead of Falling as flying allows for custom gravity
		SetPhysics(PHYS_Flying);
		
		
	}

	event Tick(float DeltaTime)
	{	
		// continue normal updates
		super.Tick(DeltaTime);

		// Apply Gravitational Force
		ApplyGravity(DeltaTime);
	}

	/** Adds gravity to the velocity based on floor normal pawn was last on */
	function ApplyGravity(float DeltaTime)
	{
		local Vector Gravity;

		Gravity = FallDirection * WorldInfo.WorldGravityZ * -1 * DeltaTime;

		// Add force to velocity
		Velocity += Gravity;
	}

	// called when the pawn lands or hits another surface
	
	event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
	{
		// switch pawn back to standard state
		local PPlayerController PC;
		GotoState('');
		PC = PPlayerController(Instigator.Controller);
		PC.ClientMessage("HitWallPawn");
		//SetBase(Wall, HitNormal);
	}
   
	event EndState(Name NextState)
	{
		FallDirection = vect(0,0,0); // CLEAR DESTINATION FLOOR
		bDirectHitWall = false; 
		SetPhysics(PHYS_Spider); // "Glue" back to surface
	}
}