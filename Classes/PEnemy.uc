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

var Vector FloorActual;

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

function ActualizaRotacion(float DeltaTime)
{
	local rotator ViewRotation;
	local vector MyFloor, CrossDir, FwdDir, OldFwdDir, RealFloor;
	local float angulo;
		
	MyFloor = self.Floor;
	if(OldFloor == vect(0,0,1))
	{
		OldFloor = MyFloor;
		OldFloor.X += 0.0001; //para que sean diferentes y entre en el if
	}

		
	//Si estoy saltando, nada de transiciones de normales, sigo teniendo como normal la vertical del salto y punto
	/*****
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
    *************/

		
	/*Ajustamos el Yaw en función del ángulo formado por el vector velocidad, y el ViewX, para que el 
		* bicho realmente tenga como ViewX su velocidad. Pero no lo asignamos directamente,sino que dejamos los cálculos
		* para que la rotación se calcule igual que con el pawn, y luego lo giramos rotando por yaw*/
	//ViewZ = Normal(5*DeltaTime * MyFloor + (1 - 5*DeltaTime) * OldFloor);
		
		
	FloorActual = vinterpto(FloorActual,self.Floor,deltatime,1);
	ViewZ = FloorActual;
	DrawDebugCylinder(self.Location,self.Location+Floor*130,4,10,100,100,50,false);
	DrawDebugCylinder(self.Location,self.Location+FloorActual*130,4,10,100,10,255,false);
		
	ViewX = Normal(5*DeltaTime * Normal(self.velocity) + (1 - 5*DeltaTime) * ViewX);
	ViewY = Normal (ViewZ cross ViewX);
	ViewRotation = OrthoRotation(ViewX,ViewY,ViewZ);
		
	SetRotation(ViewRotation);
	self.SetViewRotation(ViewRotation);
	//self.Mesh.SetRotation(ViewRotation);
	//self.SetViewRotation(ViewRotation);
		
	//Dibujamos cilindro para la direccion de su orientacion, y para su movimiento
	//FlushPersistentDebugLines();
	DrawDebugCylinder(self.Location,self.Location+ViewX*100,5,5,255,0,0,false);
	DrawDebugCylinder(self.Location,self.Location+normal(self.Velocity)*100,5,5,0,0,255,false);
	DrawDebugCylinder(self.Location,self.Location+ViewZ*100,5,5,0,255,0,false);

	GetAxes(self.Rotation,viewx,viewy,viewz);
	DrawDebugCylinder(self.Location,self.Location+ViewX*125,5,5,255,255,255,false);


}

function PawnCaidoEncima()
{
	//El Pawn nos acaba de caer encima cuando caía de la vista aérea.
	//Nos chafa, deberíamos hacer un s.partículas de Chofff de sangre o algo
	self.GotoState('ChafadoPorPawn');
}

/*Take Damage genérico de TODOS los PEnemy.
 * Simplemente decodifica el tipo de daño, y llama a la función correspondiente según el daño.
 * Cada Pawn hijo deberá escribir su propio tratamiento para cada tipo de daño
 */
event TakeDamage(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{

	//PEnemy_AI_Bot(Owner).RecibirDanyo(iDamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
	if (self.Owner == None)
	{
		`log("___________OWNER NULO_____________ MAL ROLLO!!");
		return;
	}
	//Ha sido por disparo de Giru?
	if(PMisiles(DamageCauser) != None && PPlayerController(EventInstigator) != None)
	{
		`log("Giru me ha disparado (Global TakeDamage PEnemy)"@self.Name);
		RecibidoDisparoGiru(HitLocation, Momentum,DamageCauser);
		PEnemy_AI_Controller(Owner).ControlTakeDisparoGiru(HitLocation, Momentum,DamageCauser);
		return;
	}

	//Ha sido por disparo de TurretCannon?
    if(PMisiles(DamageCauser) != None && PMisiles(DamageCauser).disparador == 'PTurretCannon')
	{
		`log("Recibido disparo de TurretCannon(Global TakeDamage PEnemy) "@self.Name);
		RecibidoDisparoTurretCannon(HitLocation,Momentum,DamageCauser);
		PEnemy_AI_Controller(Owner).ControlTakeDisparoTurretCannon(HitLocation, Momentum,DamageCauser);
		return;
	}

	//Ha sido por disparo de TurretIce?
	
	//Ha sido por la trampa tal?

	//Ha sido por la trampa cual?

	//Tratamiento default
	`log("Recibido TakeDamage no sé por quién "@self.Name);
    RecibidoDanyoSinIdentificar(HitLocation,Momentum,DamageCauser);	
} //TakeDamage

function RecibidoDisparoGiru(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	//Tratamiento default de recepción de disparo de Giru. Si no se redefine en las PEnemy hijas, será 
	//este. Si se quiere un tratamiento específico, se redefine el hijo.
	//Y si quiere hacer algo más aparte de esto, pues que haga super.RecibidoDisparoGiru + lo que deba hacer

    life--;
	`log("Vida PEnemy" @life);
	if(life == 0)
	{
		
		Destroy();
		if(PGame(WorldInfo.Game) != none)
		{
		    PGame(WorldInfo.Game).EnemyKilled(self);
		}
	}
}


function RecibidoDisparoTurretCannon(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	//Tratamiento default de recepción de disparo de Giru. Si no se redefine en las PEnemy hijas, será 
	//este. Si se quiere un tratamiento específico, se redefine el hijo.
	//Y si quiere hacer algo más aparte de esto, pues que haga super.RecibidoDisparoGiru + lo que deba hacer

    life-=3; //Cada disparo de torreta es un toñazo 3 veces más grande que el del Giru, por ejemplo
	`log("Vida PEnemy" @life);
	if(life == 0)
	{
		
		Destroy();
		if(PGame(WorldInfo.Game) != none)
		{
		    PGame(WorldInfo.Game).EnemyKilled(self);
		}
	}
}

function RecibidoDanyoSinIdentificar(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	//Creo que no se debería ejecutar nunca, siempre deberíamos saber por qué motivos recibe daño.
	//Pero en desarrollo debería seguir así para poder ir depurando los distintos tipos de daño recibidos
	local int i;
	for (i=0;i<10;i++)
	{
		`log("__________________________!!!____________________");
	}

	`log("__________TAKE DAMAGE SIN IDENTIFICAR!! TRATALO!!!" @life);

}




/** -----------------------
 * ---Estado ChafadoPorPawn---
 * ------------------------
*/
state ChafadoPorPawn
{
	event BeginState(Name PrevName)
	{

		`log('PEnemy en estado Chafado Por Pawn');
		self.Destroy();
	}

	event Tick(float DeltaTime)
	{	
		super.Tick(DeltaTime);
	}

	event EndState(Name NextState)
	{
		`log('el pawn deja de esar en Falling');
	}
}//ChafadoPorPawn



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
		FloorActual = self.Floor; //Para iniciar la interpolación al caer
		
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
		GetAxes(Rotation,ViewX,ViewY,ViewZ);
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
	life=40;
}
