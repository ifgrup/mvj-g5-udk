class PEnemy extends GamePawn
Placeable;

var PPawn P; // variable to hold the pawn we bump into
var() int DamageAmount;   //how much brain to munch
var vector DireccionCaida;
var vector FallDirection;
var vector ViewX, ViewY, ViewZ,OldFloor;
var float fTiempoDeSalto; //tiempo que lleva saltando. Si se pasa de un l�mite, para evitar que se pire volando, lo bajamos
var int life,MaxLife;
var int m_puntos_al_morir; //Puntos que da al jugador cuando lo mata

var Vector FloorActual;
var float m_defaultGroundSpeed;

var Texture2D m_portrait;

var int id ; //ID del grupo/spawner/ogro al que pertenece
/**
 * Ponemos el identificador. Debe ser el mismo que el del Spawner que lo gener�
 * */
function SetID(int i)
{
	id = i;
}


function Vector GetPosicionSocketCuerpo();
function Vector GetFireLocation();

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
		if (fTiempoDeSalto>3.0) //Se le ha ido la casta�a al salto. Hay que bajarlo a la tierra.Utilizamos el centro del planeta
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
		// Y vamos al estado PawnFalling, s�lo si no estamos ya claro, para evitar doble push y que al hacer
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
			OldFwdDir = CrossDir cross OldFloor; //El hacia delante que ten�a antes
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

		
	/*Ajustamos el Yaw en funci�n del �ngulo formado por el vector velocidad, y el ViewX, para que el 
		* bicho realmente tenga como ViewX su velocidad. Pero no lo asignamos directamente,sino que dejamos los c�lculos
		* para que la rotaci�n se calcule igual que con el pawn, y luego lo giramos rotando por yaw*/
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
}

function PawnCaidoEncima()
{
	//El Pawn nos acaba de caer encima cuando ca�a de la vista a�rea.
	//Nos chafa, deber�amos hacer un s.part�culas de Chofff de sangre o algo
	self.GotoState('ChafadoPorPawn');
}

function Destruccion(); //Al declararla aqu�, obligamos a definirla para todos

/*Take Damage gen�rico de TODOS los PEnemy.
 * Simplemente decodifica el tipo de da�o, y llama a la funci�n correspondiente seg�n el da�o.
 * Cada Pawn hijo deber� escribir su propio tratamiento para cada tipo de da�o
 */
event TakeDamage(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{

	//PEnemy_AI_Bot(Owner).RecibirDanyo(iDamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
	if (self.Owner == None)
	{
		//_DEBUG `log("___________OWNER NULO_____________ MAL ROLLO!!");
		return;
	}
	//Ha sido por disparo de Giru?
	if(PMisiles(DamageCauser) != None && PPlayerController(EventInstigator) != None)
	{
		//_DEBUG_ ("Giru me ha disparado (Global TakeDamage PEnemy)"@self.Name);
		RecibidoDisparoGiru(HitLocation, Momentum,DamageCauser);
		if (Owner != None) //entre el primer if y este parece que muere... viva la mutex del UDK...
		{
			PEnemy_AI_Controller(Owner).ControlTakeDisparoGiru(HitLocation, Momentum,DamageCauser);
		}
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
		//_DEBUG_ ("Recibida congelaci�n de TurretIce (Global TakeDamage PEnemy) "@self.Name);
		RecibidoDisparoTurretIce(HitLocation,Momentum,DamageCauser);
		PEnemy_AI_Controller(Owner).ControlTakeDisparoTurretIce(HitLocation, Momentum,DamageCauser);
		return;
	}
	
	//Ha sido por la trampa tal?

	//Ha sido por la trampa cual?

	//Tratamiento default
	//_DEBUG_ ("Recibido TakeDamage no s� por qui�n "@self.Name);
    RecibidoDanyoSinIdentificar(HitLocation,Momentum,DamageCauser);	
} //TakeDamage





/************ FUNCIONES DE RECEPCION DE DISPAROS. DEBEN SER SOBREESCRITAS EN CLASES HIJAS *************/

function RecibidoDisparoGiru(vector HitLocation, vector Momentum,Actor DamageCauser);
function RecibidoDisparoTurretCannon(vector HitLocation, vector Momentum,Actor DamageCauser);
function RecibidoDisparoTurretIce(vector HitLocation, vector Momentum,Actor DamageCauser);
function RecibidoDanyoSinIdentificar(vector HitLocation, vector Momentum,Actor DamageCauser)
{
	//Creo que no se deber�a ejecutar nunca, siempre deber�amos saber por qu� motivos recibe da�o.
	//Pero en desarrollo deber�a seguir as� para poder ir depurando los distintos tipos de da�o recibidos
	local int i;
	for (i=0;i<3;i++)
	{
		//_DEBUG `log("__________________________!!!____________________");
	}

	//_DEBUG `log("__________TAKE DAMAGE SIN IDENTIFICAR!! TRATALO!!!" @life);

}




/** -----------------------
 * ---Estado ChafadoPorPawn---
 * ------------------------
*/
state ChafadoPorPawn
{
	event BeginState(Name PrevName)
	{

		//_DEBUG `log('PEnemy en estado Chafado Por Pawn');
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
 * Estado personalizado al que pasar� el Pawn cada vez que salte.
 * Se utiliza para saber c�mo y hacia d�nde aplicar la gravedad
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
		if (fTiempoDeSalto>2.0) //Se le ha ido la casta�a al salto. Hay que bajarlo a la tierra.Utilizamos el centro del planeta
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
		//Nada m�s empezar estamos en este estado, cayendo desde el EnemySpawner.
		//Nos ponemos en physics flying hasta llegar al suelo, y luego, pasamos a spider y al comportamiento normal
		local Vector vCaida;

		vCaida=PGame(WorldInfo.Game).GetCentroPlaneta()-Location;
		Velocity=Normal(vCaida) * WorldInfo.WorldGravityZ * -1; //Lo decimos la velocidad a la que volar� hasta el suelo, como si estuviera cayendo
		SetPhysics(PHYS_Flying);
		DireccionCaida=Normal(vCaida);
		//`log('Enemy entrando en estado CAYENDO');
		bDirectHitWall = true;
		OldFloor=vect(0,0,1);

		GetAxes(Rotation,ViewX,ViewY,ViewZ);
		FloorActual = self.Floor; //Para iniciar la interpolaci�n al caer
		
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

		//Si al caer choca contra otro penemy que est� en el suelo, saltar� por Bump o por BaseChange, y en el estado
		//de PawnFalling ya detectar� el HitWall, y por tanto este HitWall no se producir� nunca.
		//As� pues, hay que estar en este estado hasta que se ejecute este HitWall, o bien hasta que este pawn
		//tenga una base diferente de none, o mejor,  igual al planeta
		if (self.Base != None && PGame(Worldinfo.game).EsPlaneta(self.Base))
		{
			//Lo mismo que en el caso del HitWall, volvemos al estado 'base'
			GotoState(''); //estado default
		}
	}

	/********
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
    **********/

	event EndState(Name NextState)
	{
		
		//_DEBUG_ ('Enemy sale de estado Cayendo '@NextState);
	}

}//state Cayendo

function AterrizadoAfterSpawn()
{
	//De reci�n creado, he llegado al suelo
	bDirectHitWall = false; 
	SetPhysics(PHYS_None);
	SetPhysics(PHYS_Spider); // "Glue" back to surface
		
	GotoState(''); //estado default
	GetAxes(Rotation,ViewX,ViewY,ViewZ);
	//_DEBUG `log("__Aterrizado " @self.Name);
}

//over-ride epics silly character stuff
simulated function SetCharacterClassFromInfo(class<UTFamilyInfo> Info)
{
	return;
}



event HitWall(Vector HitNormal, Actor Wall,PrimitiveComponent WallComp)
{

	local PAutoTurret ptorreta;
	local PTree parbol;
	local PPlayerBase pbase;


	if (PEnemy_AI_Controller(Owner).GetStateName() == 'TowerAttack')
	{
		return;
	}

	if (PGame(Worldinfo.Game).EsPlaneta(Wall))
	{
		//To�azo contra el suelo? pos interesa principalmente para el controler por si al caer de un rebote no se cosca
		//y no desapila el estado.
		//_DEBUG `log("HitWall gral suelo!");
		PEnemy_AI_Controller(Owner).BumpContraSuelo(Wall,HitNormal);
		return;
	}


	ptorreta = PAutoTurret(Wall);
	if ( ptorreta != None )  //Si nos chocamos contra una torreta
	{
		//_DEBUG `log("HitWall gral torreta!");
		PEnemy_AI_Controller(Owner).ContraTorreta(ptorreta);
	}

	parbol = PTree(Wall);
	if ( parbol != None )  //Si nos chocamos contra un arbol
	{
		//_DEBUG`log("Hitwall gral  �rbol neng!" @self.Name @Wall.Name);
		PEnemy_AI_Controller(Owner).ContraTorreta(parbol);
	}

	pbase = PPlayerBase(Wall);
	if (pbase != None)
	{
		//_DEBUG `log("HitWall gral casa!");
		PEnemy_AI_Controller(Owner).ContraBase();
	}
}



simulated event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
{

	local PEnemy Pbump;
	local PAutoTurret ptorreta;
	local PTree parbol;
	local PPlayerBase pbase;

	if (Owner == None)
	{
		return;
	}

	if (PEnemy_AI_Controller(Owner).GetStateName() == 'TowerAttack')
	{
		return;
	}

	if ( (Other == None) || Other.bStatic )
		return;

	if (PGame(Worldinfo.Game).EsPlaneta(other))
	{
		//To�azo contra el suelo? pos interesa principalmente para el controler por si al caer de un rebote no se cosca
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
		return; //ya t�
	}

	ptorreta = PAutoTurret(Other);
	if ( ptorreta != None )  //Si nos chocamos contra una torreta
	{
		//_DEBUG `log("Bump torreta!");
		PEnemy_AI_Controller(Owner).ContraTorreta(ptorreta);
	}

	parbol = PTree(Other);
	if ( parbol != None )  //Si nos chocamos contra un arbol
	{
		//_DEBUG `log("S'ha comio un �rbol neng!" @self.Name @Other.Name);
		PEnemy_AI_Controller(Owner).ContraTorreta(parbol);
	}

	pbase = PPlayerBase(Other);
	if (pbase != None)
	{
		//_DEBUG `log("Bump casa!");
		PEnemy_AI_Controller(Owner).ContraBase();
	}
	//super.Bump( Other, OtherComp, HitNormal );
}


/** BaseChange
 Si un enemigo se sube encima de otro, le hacemos saltar fuera de �l.
 Si no se sobrescribiera este evento, el comportamiento normal acaba llamando
 a TakeDamage y no nos interesa
*/
singular event BaseChange()
{
	local PAutoTurret ptorreta;
	local PTree pArbol;
	local PPlayerBase pbase;

	if (Owner == None)
	{
		return;
	}

	if (PEnemy_AI_Controller(Owner).GetStateName() == 'TowerAttack')
	{
		return;
	}


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
		//To�azo contra el suelo? pos interesa principalmente para el controler por si al caer de un rebote no se cosca
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
		//_DEBUG `log("BaseChange torreta!");
		PEnemy_AI_Controller(Owner).ContraTorreta(ptorreta);
	}
	
	parbol = PTree(Base);
	if ( parbol != None )  //Si nos chocamos contra una torreta
	{
		//_DEBUG `log("BaseChange arbol!" @self.Name @PEnemy_AI_Controller(Owner).GetStateName() ) ;
		PEnemy_AI_Controller(Owner).ContraTorreta(parbol);
	}

	pbase = PPlayerBase(Base);
	if (pbase != None)
	{
		//_DEBUG `log("BaseChange casa!" @self.Name);
		PEnemy_AI_Controller(Owner).ContraBase();
	}

	
}//BaseChange


event Touch(actor other, PrimitiveComponent othercomp,vector HitLocation,vector HitNormal)
{

}

singular event bool EncroachingOn(Actor Other)
{

	//Si es un ogro, no hace nada, como hasta ahora (espero)
	//Si es un minion, que pegue el saltito
	if (PEnemyPawn_Scout(self) != None)
	{
		return true;
	}

	if (PEnemy_AI_Controller(Owner) != None)
	{
		PEnemy_AI_Controller(Owner).ReboteRespectoA( None,vect(0,0,0),false,300);
	}

	return true;
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


	//ControllerClass=class'PEnemyBot'
	bDontPossess=false
	//bNotifyStopFalling=true --> si quisi�ramos controlar el fin del falling as�, se ejecutar�a StoppedFalling.
	DamageAmount=10
	bCanClimbUp=true
	bCanClimbLadders=true
	MaxStepHeight=45
	WalkableFloorZ=0
	life=12
	MaxLife=80
}
