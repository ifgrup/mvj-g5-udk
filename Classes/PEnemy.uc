class PEnemy extends UTPawn
Placeable;

var PPawn P; // variable to hold the pawn we bump into
var() int DamageAmount;   //how much brain to munch
var vector DireccionCaida;
var vector FallDirection;
var float fTiempoDeSalto; //tiempo que lleva saltando. Si se pasa de un l�mite, para evitar que se pire volando, lo bajamos

simulated function PostBeginPlay()
{
   super.PostBeginPlay();

   //Hacemos que caigan hasta el suelo. Una vez en el suelo, spider
   GoToState('Cayendo');
}

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
		if (fTiempoDeSalto>3.0) //Se le ha ido la casta�a al salto. Hay que bajarlo a la tierra.Utilizamos el centro del planeta
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
		GotoState('');
		SetBase(Wall, HitNormal);
	}
   
	event EndState(Name NextState)
	{
		FallDirection = vect(0,0,0); // CLEAR DESTINATION FLOOR
		bDirectHitWall = false; 
		SetPhysics(PHYS_Spider); // "Glue" back to surface
		`log('el pawn deja de esar en Falling');
	}
}

auto state Cayendo
{
	event BeginState(name EstadoPrevio)
	{
		//Nada m�s empezar estamos en este estado, cayendo desde el EnemySpawner.
		//Nos ponemos en physics flying hasta llegar al suelo, y luego, pasamos a spider y al comportamiento normal
		local Vector vCaida;

		vCaida=PGame(WorldInfo.Game).GetCentroPlaneta()-Location;
		Velocity=Normal(vCaida) * WorldInfo.WorldGravityZ * -1; //Lo decimos la velocidad a la que volar� hasta el suelo, como si estuviera cayendo
		SetPhysics(PHYS_Flying);
		DireccionCaida=Normal(vCaida);
		`log('Enemy entrando en estado CAYENDO');
		bDirectHitWall = true;
	}
	
	/** Adds gravity to the velocity based on floor normal pawn was last on */
	function ApplyGravity(float DeltaTime)
	{
		local Vector Gravity;

		Gravity = DireccionCaida * WorldInfo.WorldGravityZ * -1 * DeltaTime;

		// Add force to velocity
		Velocity += Gravity;
		//`log('Gravity on Pawn en estado Falling');
	}

	event Tick(float delta)
	{
		//`log("->" @self.Location @self.Velocity);
		DrawDebugCone(self.Location,Velocity,100,0.01,0.1,20,MakeColor(200,0,0));
		ApplyGravity(delta);
	}
	// cuando llegue al suelo:
	event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
	{
		`log('Enemy ha llegado al suelo');
		//SetBase(Wall, HitNormal);
		bDirectHitWall = false; 
		SetPhysics(PHYS_None);
		SetPhysics(PHYS_Spider); // "Glue" back to surface

		GotoState(''); //estado default
	}
   
	event EndState(Name NextState)
	{
		
		`log('Enemy sale de estado Cayendo '@NextState);
	}

}//state Cayendo


//over-ride epics silly character stuff
simulated function SetCharacterClassFromInfo(class<UTFamilyInfo> Info)
{
	return;
}

simulated event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
{

	if ( (Other == None) || Other.bStatic )
		return;

	P = PPawn(Other); //the pawn we might have bumped into

	if ( P != None)  //if we hit a pawn
	{
		if (PEnemy(Other) != None)  //we hit another zombie
		{
			DoJump(true);
			return; //dont do owt
		}
	}
	
	super.Bump( Other, OtherComp, HitNormal );
}

defaultproperties 
{
	Begin Object Name=WPawnSkeletalMeshComponent
		AnimTreeTemplate=AnimTree'CH_AnimHuman_Tree.AT_CH_Human'
		SkeletalMesh=SkeletalMesh'CH_IronGuard_Male.Mesh.SK_CH_IronGuard_MaleA'
		AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
		PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
		bCacheAnimSequenceNodes=FALSE
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false
		CastShadow=true
		bCastDynamicShadow=true
		LightEnvironment=MyLightEnvironment
		bAcceptsDynamicDecals=true
		MinDistFactorForKinematicUpdate=0.2
		bChartDistanceFactor=true
		RBDominanceGroup=20
		bUseOnePassLightingOnTranslucency=TRUE
		HiddenGame=False
		CollideActors=false
	End Object

	RagdollLifespan=180.0 //how long the dead body will hang around for

	AirSpeed=200
	GroundSpeed=200

	ControllerClass=class'PEnemyBot'
	bDontPossess=false
	//bNotifyStopFalling=true --> si quisi�ramos controlar el fin del falling as�, se ejecutar�a StoppedFalling.
	DamageAmount=10
}
