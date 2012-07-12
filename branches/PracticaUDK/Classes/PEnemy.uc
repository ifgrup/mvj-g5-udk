class PEnemy extends UTPawn
Placeable;

var PPawn P; // variable to hold the pawn we bump into
var() int DamageAmount;   //how much brain to munch
var vector DireccionCaida;
var vector FallDirection;
var vector ViewX, ViewY, ViewZ,OldFloor;
var float fTiempoDeSalto; //tiempo que lleva saltando. Si se pasa de un límite, para evitar que se pire volando, lo bajamos
var int life;
var int m_puntos_al_morir; //Puntos que da al jugador cuando lo mata

function SetColor(LinearColor Col)
{

}

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
 * Estado personalizado al que pasará el Pawn cada vez que salte.
 * Se utiliza para saber cómo y hacia dónde aplicar la gravedad
 */
state PawnFalling
{


	event BeginState(Name PrevName)
	{

		`log('pawn en estado Falling');
		//DBG WorldInfo.Game.Broadcast(self,"Entrando en PawnFalling");
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
		//Nada más empezar estamos en este estado, cayendo desde el EnemySpawner.
		//Nos ponemos en physics flying hasta llegar al suelo, y luego, pasamos a spider y al comportamiento normal
		local Vector vCaida;

		vCaida=PGame(WorldInfo.Game).GetCentroPlaneta()-Location;
		Velocity=Normal(vCaida) * WorldInfo.WorldGravityZ * -1; //Lo decimos la velocidad a la que volará hasta el suelo, como si estuviera cayendo
		SetPhysics(PHYS_Flying);
		DireccionCaida=Normal(vCaida);
		`log('Enemy entrando en estado CAYENDO');
		bDirectHitWall = true;
		OldFloor=vect(0,0,1);
		GetAxes(Rotation,ViewX,ViewY,ViewZ);
		
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
		//DBG DrawDebugCone(self.Location,Velocity,100,0.01,0.1,20,MakeColor(200,0,0));
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


//orientar a los enemigos
event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);
	acutalizaRotacion(DeltaTime);

}


function acutalizaRotacion(float DeltaTime)
	{
		local rotator ViewRotation;
		local vector MyFloor, CrossDir, FwdDir, OldFwdDir, RealFloor;

		
		//ClientMessage("UPdate Estado spider" $ DeltaTime);
 
		//Mientras salta, Pawn.Base vale None
		//Si tiene que saltar, saltará en la vertical que YA tiene al estar caminando sobre el planeta
		//por lo que no hay que cambiar ninguna rotación
		
			MyFloor = self.Floor;
		//Si estoy saltando, nada de transiciones de normales, sigo teniendo como normal la vertical del salto y punto
		if ( MyFloor != OldFloor )
		{
			// smoothly transition between floors
			//Para colocar al bicho en la perpendicular del suelo
			RealFloor = MyFloor;
			MyFloor = Normal(6*DeltaTime * MyFloor + (1 - 6*DeltaTime) * OldFloor);
 
			if ( (RealFloor dot MyFloor) > 0.999 )
			{
				MyFloor = RealFloor;
			}
			else
			{
				// translate view direction
				CrossDir = Normal(RealFloor Cross OldFloor);
				FwdDir = CrossDir cross MyFloor; //Hacia delante, forward
				OldFwdDir = CrossDir cross OldFloor; //El hacia delante que tenía antes
				ViewX = MyFloor * (OldFloor dot ViewX) + CrossDir * (CrossDir dot ViewX) + FwdDir * (OldFwdDir dot ViewX);
				ViewX = Normal(ViewX);
				ViewZ = MyFloor * (OldFloor dot ViewZ) + CrossDir * (CrossDir dot ViewZ) + FwdDir * (OldFwdDir dot ViewZ);
				ViewZ = Normal(ViewZ);
				OldFloor = MyFloor;
				ViewY = Normal(MyFloor cross ViewX);
				//Pawn.mesh.SetRotation(OrthoRotation(ViewX,ViewY,ViewZ));
			}
		}
 
		//Guardamos aLookUp para GetPlayerViewPoint
		//mUltimoLookup=PlayerInput.aLookUp;

		//Ahora giro de la cámara.
		//Al girar por aTurn,sólo nos afectará la rotación sobre el eje Z.
		//Por tanto, la Z quedará igual, la X es la que rotará, y la Y será el producto cartesiano de la nueva X por la Z que ya tenemos
		/*if ( (PlayerInput.aTurn != 0))
		{
		   // adjust Yaw based on aTurn
			if ( PlayerInput.aTurn != 0 )
			{
				ViewX = Normal(ViewX + 10 * ViewY * Sin(0.0005*DeltaTime*PlayerInput.aTurn));
			}
 			// calculate new Y axis
			ViewY = Normal(MyFloor cross ViewX);
 		}*/

		ViewRotation = OrthoRotation(ViewX,ViewY,ViewZ);
		
		SetRotation(ViewRotation);
		/*if(Pawn != None)
		{
			Pawn.SetRotation(ViewRotation);
		}	*/	
		
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
		
		
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
		
	End Object

	RagdollLifespan=180.0 //how long the dead body will hang around for

	AirSpeed=200
	GroundSpeed=200

	ControllerClass=class'PEnemyBot'
	bDontPossess=false
	//bNotifyStopFalling=true --> si quisiéramos controlar el fin del falling así, se ejecutaría StoppedFalling.
	DamageAmount=10
	bCanClimbUp=true
	bCanClimbLadders=true
	MaxStepHeight=45
	WalkableFloorZ=0
	life=100;
}
