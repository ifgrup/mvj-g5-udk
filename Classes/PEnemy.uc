class PEnemy extends GamePawn
Placeable;

var PPawn P; // variable to hold the pawn we bump into
var() int DamageAmount;   //how much brain to munch
var vector DireccionCaida;
var vector FallDirection;
var vector ViewX, ViewY, ViewZ,OldFloor;
var float fTiempoDeSalto; //tiempo que lleva saltando. Si se pasa de un límite, para evitar que se pire volando, lo bajamos
var int life,MaxLife;
var int m_puntos_al_morir; //Puntos que da al jugador cuando lo mata

var Vector FloorActual;
var float m_defaultGroundSpeed;

var Texture2D m_portrait;



function Vector GetPosicionSocketCuerpo();


function Texture2D GetPortrait()
{
	return m_portrait;
}

function SetColor(LinearColor Col)
{
	
}

function OrientarPEnemyPorNormal ( Vector normalsuelo, out Rotator pawnRotation)
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
	pawnRotation=rPawn;
}


function ApplyGravity(float DeltaTime)
{
		local Vector Gravity;
		local vector vAlCentro;

		fTiempoDeSalto+=DeltaTime;
		if (fTiempoDeSalto>3.0) //Se le ha ido la castaña al salto. Hay que bajarlo a la tierra.Utilizamos el centro del planeta
		{
			vAlCentro=PGame(WorldInfo.Game).GetCentroPlaneta()-Location; 
			FallDirection = Normal(vAlCentro);
			//_DEBUG_ DrawDebugSphere(Location,100,30,255,10,10,false);
			//_DEBUG_ ("volviendo pa la tierra neng! hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh" @self.Name);
		}

		Gravity = FallDirection * WorldInfo.WorldGravityZ * -1 * DeltaTime;

		// Add force to velocity
		Velocity += Gravity;
		////_DEBUG_ ('Gravity on Pawn en estado Falling');
}

simulated function PostBeginPlay()
{
   super.PostBeginPlay();

    // Turning collision on for skelmeshcomp and off for cylinder
	CylinderComponent.SetActorCollision(false, false);
	
    //Hacemos que caigan hasta el suelo. Una vez en el suelo, spider
    //GoToState('Cayendo');
}

function bool Salta( bool bUpdating , optional bool bParado = false)
{
	local vector vAlCentro;
	// Si podemos saltar...
	if(bJumpCapable && !bIsCrouched && !bWantsToCrouch)// && Physics == PHYS_Spider)
	{
		// Calculamos la velocidad a partir de la constante de salto + el vector de suelo
		if(!bParado && Floor != vect(0,0,1))
		{
			Velocity = - Velocity + (JumpZ/10) * Floor;
			FallDirection = -Floor;
		}
		else
		{
			vAlCentro=PGame(WorldInfo.Game).GetCentroPlaneta()-Location; 
			Velocity = -Velocity + (JumpZ/10) *(-1)* Normal(vAlCentro) + VRand() * (jumpZ/20);
			FallDirection =  Normal(vAlCentro);
			//DrawDebugCylinder(self.Location,self.Location-Normal(vAlCentro)*300,6,12,0,255,0,true);
    	}
		// Y vamos al estado PawnFalling, sólo si no estamos ya claro, para evitar doble push y que al hacer
		//pop, no vuelva al estado original
		if (!self.IsInState('PawnFalling'))
		{
			self.PushState('PawnFalling');
		}
		return true;
	}
	//_DEBUG_ ('Salta de PEnemy NO PUEDE SALTAR');
	return false;
}

function ActualizaRotacion(float DeltaTime)
{
	local rotator ViewRotation;
	local vector MyFloor;//, CrossDir, FwdDir, OldFwdDir, RealFloor;
		
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
	/*
	DrawDebugCylinder(self.Location,self.Location+Floor*130,4,10,100,100,50,false);
	DrawDebugCylinder(self.Location,self.Location+FloorActual*130,4,10,100,10,255,false);
	*/

	ViewX = Normal(5*DeltaTime * Normal(self.velocity) + (1 - 5*DeltaTime) * ViewX);
	ViewY = Normal (ViewZ cross ViewX);
	ViewRotation = OrthoRotation(ViewX,ViewY,ViewZ);
		
	SetRotation(ViewRotation);
	self.SetViewRotation(ViewRotation);
		
	//Dibujamos cilindro para la direccion de su orientacion, y para su movimiento
	//FlushPersistentDebugLines();
	/*
	DrawDebugCylinder(self.Location,self.Location+ViewX*100,5,5,255,0,0,false);
	DrawDebugCylinder(self.Location,self.Location+normal(self.Velocity)*100,5,5,0,0,255,false);
	DrawDebugCylinder(self.Location,self.Location+ViewZ*100,5,5,0,255,0,false);
    */
	if (PEnemyPawn_Minion(self) != none)
	{
		//DrawDebugSphere(self.Location+ViewZ*300,90,25,255,255,0,false);
	}
	//GetAxes(self.Rotation,viewx,viewy,viewz);

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
		//_DEBUG_ ("Giru me ha disparado (Global TakeDamage PEnemy)"@self.Name);
		RecibidoDisparoGiru(HitLocation, Momentum,DamageCauser);
		PEnemy_AI_Controller(Owner).ControlTakeDisparoGiru(HitLocation, Momentum,DamageCauser);
		return;
	}

	//Ha sido por disparo de TurretCannon?
    if(PMisiles(DamageCauser) != None && PMisiles(DamageCauser).disparador == 'PTurretCannon')
	{
		//_DEBUG_ ("Recibido disparo de TurretCannon(Global TakeDamage PEnemy) "@self.Name);
		RecibidoDisparoTurretCannon(HitLocation,Momentum,DamageCauser);
		PEnemy_AI_Controller(Owner).ControlTakeDisparoTurretCannon(HitLocation, Momentum,DamageCauser);
		return;
	}
	//Ha sido por disparo de TurretIce?
	if(PTurretIce(DamageCauser) != None)
	{
		//_DEBUG_ ("Recibida congelación de TurretIce (Global TakeDamage PEnemy) "@self.Name);
		RecibidoDisparoTurretIce(HitLocation,Momentum,DamageCauser);
		PEnemy_AI_Controller(Owner).ControlTakeDisparoTurretIce(HitLocation, Momentum,DamageCauser);
		return;
	}
	
	//Ha sido por la trampa tal?

	//Ha sido por la trampa cual?

	//Tratamiento default
	//_DEBUG_ ("Recibido TakeDamage no sé por quién "@self.Name);
    RecibidoDanyoSinIdentificar(HitLocation,Momentum,DamageCauser);	
} //TakeDamage

function RecibidoDisparoGiru(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	//Tratamiento default de recepción de disparo de Giru. Si no se redefine en las PEnemy hijas, será 
	//este. Si se quiere un tratamiento específico, se redefine el hijo.
	//Y si quiere hacer algo más aparte de esto, pues que haga super.RecibidoDisparoGiru + lo que deba hacer

    life--;
	//_DEBUG_ ("Vida PEnemy" @life);
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
	//Tratamiento default de recepción de disparo de TurretIce. Si no se redefine en las PEnemy hijas, será 
	//este. Si se quiere un tratamiento específico, se redefine el hijo.
	//Y si quiere hacer algo más aparte de esto, pues que haga super.RecibidoDisparoTurretCannon + lo que deba hacer

    life-=3; //Cada disparo de torreta es un toñazo 3 veces más grande que el del Giru, por ejemplo
	//_DEBUG_ ("Vida PEnemy" @life);
	if(life == 0)
	{
		
		Destroy();
		if(PGame(WorldInfo.Game) != none)
		{
		    PGame(WorldInfo.Game).EnemyKilled(self);
		}
	}
}

function RecibidoDisparoTurretIce(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	//Tratamiento default de recepción de disparo de TurretIce. Si no se redefine en las PEnemy hijas, será 
	//este. Si se quiere un tratamiento específico, se redefine el hijo.
	//Y si quiere hacer algo más aparte de esto, pues que haga super.RecibidoDisparoTurretIce + lo que deba hacer

    //No afecta a la vida, simplemente lo para (por ejemplo)..
	//Así que no hay que hacer nada más de momento
}



function RecibidoDanyoSinIdentificar(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	//Creo que no se debería ejecutar nunca, siempre deberíamos saber por qué motivos recibe daño.
	//Pero en desarrollo debería seguir así para poder ir depurando los distintos tipos de daño recibidos
	local int i;
	for (i=0;i<3;i++)
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
		//`log('el pawn deja de esar en ChafadoPorPawn');
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
	event Tick(float DeltaTime)
	{	
		local vector vAlCentro;

		super.Tick(DeltaTime);

		// Apply Gravitational Force
		ApplyGravity(DeltaTime);
		fTiempoDeSalto+=DeltaTime;
		if (fTiempoDeSalto>2.0) //Se le ha ido la castaña al salto. Hay que bajarlo a la tierra.Utilizamos el centro del planeta
		{
			vAlCentro=PGame(WorldInfo.Game).GetCentroPlaneta()-Location; 
			FallDirection = Normal(vAlCentro);
			//DrawDebugSphere(Location,100,30,255,10,10,false);
			//`log("volviendo pa la tierra neng! hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh" @self.Name);
		}
	}//Tick


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
		//`log("__HA LLEGADO a la tierra neng!" @self.Name);
		//SI el Wall sigue siendo otro PEnemy, pasando, hay que volver a saltar:
		if(PEnemy(Wall) != None)
		{
			Velocity = -FallDirection * 150;
			fTiempoDeSalto = 0;
			SetBase(None);
		}
		else
		{
			SetBase(Wall, HitNormal);

			self.PopState();
		}

	}
   
	event PoppedState()
	{
		FallDirection = vect(0,0,0); // CLEAR DESTINATION FLOOR
		bDirectHitWall = false; 
		SetPhysics(PHYS_Spider); // "Glue" back to surface
		//`log('el pawn deja de esar en Falling');
	}


Begin :
	//`log('PEnemy estado Falling');
	//DBG WorldInfo.Game.Broadcast(self,"Entrando en PawnFalling");
	
    // Direct hit wall enabled just for the custom falling
	bDirectHitWall = true;
	// flying instead of Falling as flying allows for custom gravity
	SetPhysics(PHYS_Flying);
	fTiempoDeSalto=0.0; //tiempo de salto

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
		//`log('Enemy entrando en estado CAYENDO');
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

		//Si al caer choca contra otro penemy que esté en el suelo, saltará por Bump o por BaseChange, y en el estado
		//de PawnFalling ya detectará el HitWall, y por tanto este HitWall no se producirá nunca.
		//Así pues, hay que estar en este estado hasta que se ejecute este HitWall, o bien hasta que este pawn
		//tenga una base diferente de none, o mejor,  igual al planeta
		if (self.Base != None && PGame(Worldinfo.game).EsPlaneta(self.Base))
		{
			//Lo mismo que en el caso del HitWall, volvemos al estado 'base'
			GotoState(''); //estado default
		}
	}
	// cuando llegue al suelo:
	event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
	{
		//_DEBUG_ ('Enemy ha llegado al suelo');
		//SetBase(Wall, HitNormal);
		bDirectHitWall = false; 
		SetPhysics(PHYS_None);
		SetPhysics(PHYS_Spider); // "Glue" back to surface
		
		GotoState(''); //estado default
		GetAxes(Rotation,ViewX,ViewY,ViewZ);
	}
   
	event EndState(Name NextState)
	{
		
		//_DEBUG_ ('Enemy sale de estado Cayendo '@NextState);
	}

}//state Cayendo


//over-ride epics silly character stuff
simulated function SetCharacterClassFromInfo(class<UTFamilyInfo> Info)
{
	return;
}



simulated event HitWall(Vector HitNormal, Actor Wall,PrimitiveComponent WallComp)
{

	local PAutoTurret ptorreta;
	local PTree parbol;
	local PPlayerBase pbase;


	if (PGame(Worldinfo.Game).EsPlaneta(Wall))
	{
		//Toñazo contra el suelo? pos interesa principalmente para el controler por si al caer de un rebote no se cosca
		//y no desapila el estado.
		`log("HitWall gral suelo!");
		PEnemy_AI_Controller(Owner).BumpContraSuelo(Wall,HitNormal);
		return;
	}


	ptorreta = PAutoTurret(Wall);
	if ( ptorreta != None )  //Si nos chocamos contra una torreta
	{
		`log("HitWall gral torreta!");
		PEnemy_AI_Controller(Owner).ContraTorreta(ptorreta);
	}

	parbol = PTree(Wall);
	if ( parbol != None )  //Si nos chocamos contra un arbol
	{
		`log("Hitwall gral  árbol neng!" @self.Name @Wall.Name);
		PEnemy_AI_Controller(Owner).ContraTorreta(parbol);
	}

	pbase = PPlayerBase(Wall);
	if (pbase != None)
	{
		`log("HitWall gral casa!");
		PEnemy_AI_Controller(Owner).ContraBase();
	}
}



simulated event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
{

	local PEnemy Pbump;
	local PAutoTurret ptorreta;
	local PTree parbol;
	local PPlayerBase pbase;

	if ( (Other == None) || Other.bStatic )
		return;

	if (PGame(Worldinfo.Game).EsPlaneta(other))
	{
		//Toñazo contra el suelo? pos interesa principalmente para el controler por si al caer de un rebote no se cosca
		//y no desapila el estado.
		PEnemy_AI_Controller(Owner).BumpContraSuelo(other,HitNormal);
		return;
	}

	Pbump = PEnemy(Other); //the pawn we might have bumped into

	if ( Pbump != None )  //Si nos chocamos contra otro PEnemy
	{
		self.Velocity = 30 * (other.Location - self.Location);
		self.Acceleration = vect (0,0,0);
		Salta(true);
		return; //ya tá
	}

	ptorreta = PAutoTurret(Other);
	if ( ptorreta != None )  //Si nos chocamos contra una torreta
	{
		`log("Bump torreta!");
		PEnemy_AI_Controller(Owner).ContraTorreta(ptorreta);
	}

	parbol = PTree(Other);
	if ( parbol != None )  //Si nos chocamos contra un arbol
	{
		`log("S'ha comio un árbol neng!" @self.Name @Other.Name);
		PEnemy_AI_Controller(Owner).ContraTorreta(parbol);
	}

	pbase = PPlayerBase(Other);
	if (pbase != None)
	{
		`log("Bump casa!");
		PEnemy_AI_Controller(Owner).ContraBase();
	}
	//super.Bump( Other, OtherComp, HitNormal );
}


/** BaseChange
 Si un enemigo se sube encima de otro, le hacemos saltar fuera de él.
 Si no se sobrescribiera este evento, el comportamiento normal acaba llamando
 a TakeDamage y no nos interesa
*/
singular event BaseChange()
{
	local PAutoTurret ptorreta;
	local PTree pArbol;
	local PPlayerBase pbase;

	if( Base == None)
	{
		if ( GetStateName() != 'PawnFalling' && GetStateName() != 'Cayendo' ) 
	    {
			//_DEBUG_ ('Base Changed to None en estado '@GetStateName() @self.Name);
			return;
	    }
		else
		{
		   return;
		}
	}

	if (PGame(Worldinfo.game).EsPlaneta(Base))
	{
		//Toñazo contra el suelo? pos interesa principalmente para el controler por si al caer de un rebote no se cosca
		//y no desapila el estado.
		PEnemy_AI_Controller(Owner).BumpContraSuelo(Base,vect(0,0,1));
		return;
	}

	if(PEnemy(Base) != None)
	{
		//_DEBUG_ ("PEnemy encima de otro "@self.Name @self.GetStateName());
		//PEnemy_AI_Controller(Owner).Control_BaseChangedPenemy(Base);
		self.Velocity = vect(0,0,0);
		self.Acceleration = vect (0,0,0);
		//self.Velocity = 100 * (base.Location -self.Location);
		self.Velocity = 20 * (self.Location-base.Location) + 10  *Vrand();
		self.SetBase(None);
		Salta(true,true);
		//DrawDebugCylinder(self.Location,self.Location+floor*3000,6,15,200,0,200,true);
		return;

	}

	ptorreta = PAutoTurret(Base);
	if ( ptorreta != None )  //Si nos chocamos contra una torreta
	{
		`log("BaseChange torreta!");
		PEnemy_AI_Controller(Owner).ContraTorreta(ptorreta);
	}
	
	parbol = PTree(Base);
	if ( parbol != None )  //Si nos chocamos contra una torreta
	{
		`log("BaseChange arbol!");
		PEnemy_AI_Controller(Owner).ContraTorreta(parbol);
	}

	pbase = PPlayerBase(Base);
	if (pbase != None)
	{
		`log("BaseChange casa!" @self.Name);
		PEnemy_AI_Controller(Owner).ContraBase();
	}

	
}//BaseChange


event Touch(actor other, PrimitiveComponent othercomp,vector HitLocation,vector HitNormal)
{
	local int i;
	i=0;
	
}

event bool EncroachingOn(Actor Other)
{
	return false;
}

event EncroachedBy(Actor other)
{
	return;
}


defaultproperties 
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
		InvisibleUpdateTime=1
		MinTimeBetweenFullUpdates=.2
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment


	Begin Object Class=SkeletalMeshComponent Name=PEnemySkeletalMeshComponent
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

	Components.Add(PEnemySkeletalMeshComponent)

	RagdollLifespan=180.0 //how long the dead body will hang around for

	AirSpeed=200
	GroundSpeed=200


	m_portrait=Texture2D'PGameHudIco.Topota_Icono'


	ControllerClass=class'PEnemyBot'
	bDontPossess=false
	//bNotifyStopFalling=true --> si quisiéramos controlar el fin del falling así, se ejecutaría StoppedFalling.
	DamageAmount=10
	bCanClimbUp=true
	bCanClimbLadders=true
	MaxStepHeight=45
	WalkableFloorZ=0
	life=40
	MaxLife=80
}
