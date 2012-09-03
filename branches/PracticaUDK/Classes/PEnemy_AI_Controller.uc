class PEnemy_AI_Controller extends AIController;

var PPlayerBase theBase;    //Base objetivo de juego
var float m_tiempo_tick;    //Para control de tiempo. Actualizada en el tick global
var int id;                 //Id del spawner que lo creó. Para identificar el scout y sus minions

var bool m_b_breakpoint; //Se pone a true al disparar con Giru, usado para poner un if y un breakpoint dentro, para
					     //poder debugar un bicho en concreto

var float m_AnguloOffsetInicial; //Angulo con el que fui creado por el EnemySpawner

var vector m_FallDirection; //Dirección de caída para el estado Rebotando
var float m_fTiempoDeSalto;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	theBase = PGame(WorldInfo.Game).PlayerBase;
}

/*Tick global para todos los pEnemys. Controla el tiempo de estado, por lo que TODOS los ticks de los estados/clases hijas
 * deberán invocarlo (oh dioses del tick! te invocamos juas juas :D
 */

function Tick(Float Deltatime)
{
	local PEnemy thePawn;
	super.Tick(DeltaTime);
	
	//Control global de tiempo. Cada estado lo pondrá a cero y controlará a su gusto
	m_tiempo_tick += DeltaTime;

	//Actualización de la rotación del pawn que controlamos
	if (Pawn != None)
	{
		thePawn = PEnemy(Pawn);
		thePawn.ActualizaRotacion(DeltaTime);
		setRotation(thePawn.Rotation);
	}
}


/**
 * Ponemos el identificador. Debe ser el mismo que el del Spawner que lo generó
 * */
function SetID(int i)
{
	id = i;
}

/**
 * Funciones genérica de RecibirDanyo, llamada desde los pawns en su TakeDamage, para cada tìpo de daño.
 * El control de vida y muerte, creo que se debería hacer en el pawn. 
 * Desde el pawn, SIEMPRE Se llama a su owner, o sea, a estas funciones, para ejecutar la gestión del daño, pero
 * para cambiar de estado y tal. O sea, que el tema de restar vida y tal, creo que se puede hacer en pawn.
 * 
 * PEnemy recibe el TakeDamage, decodifica el tipo de daño, ejecuta la funcion de PEnemy o redefinida en las hijas que
 * controla el daño, y luego llama a la función de gestión de controller.
 * Y aquí hacemos lo mismo, una función genérica, y cada hijo de PEnemy_AI_Controller, que redefina su tratamiento
 * para cada estado.
 */
function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser)
{
	`log("PEnemy_AI_Controller, recibido danyo Giru Global, DEBES SOBREESCRIBIRME!!!\n" @self.GetStateName());
	m_b_breakpoint = true; //Para poder poner un breakpoint en un if (m_b_breakpoint), y sólo se parará si
						   //has disparado a ese PEnemy
}

function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser)
{
	`log("PEnemy_AI_Controller, recibido danyo TurretCannon Global, DEBES SOBREESCRIBIRME!!!\n");
}

function ControlTakeDisparoTurretIce(vector HitLocation, vector Momentum, Actor DamageCauser)
{
	`log("PEnemy_AI_Controller, recibido danyo TurretIce Global, DEBES SOBREESCRIBIRME!!!\n");
}


function Control_BaseChangedPenemy(Actor PEnemyOtro)
{
	//`log("PEnemy_AI_Controller::Control_BaseChangedPenemy, DEBES SOBREESCRIBIRME!!!");
	
}

function BumpContraSuelo(Actor suelo, vector HitNormal)
{

}

function PPathNode AplicarOffsetNodo(PPathNode nodo)
{
	local PPathnode p;
	local vector f ;
	local vector v,r ;
	local Quat ernion,ernion2;

	local Rotator rot;
	local vector centro,hitlocation,hitnormal,fintrace;
	local float maxdist,mindist;
	local vector initlocation;

	maxdist = Pgame(Worldinfo.Game).m_max_radiorandom;
	mindist = Pgame(Worldinfo.Game).m_min_radiorandom;
	initlocation = nodo.Location ; //antes de aplicarle el offset

	
	//Creamos una copia de nodo en p
	p = spawn(class'PPathNode',,,nodo.Location);
	p.id = nodo.id;
	p.m_floor_nodo = nodo.m_floor_nodo;
	p.m_direccion_nodo = nodo.m_direccion_nodo;

    
	f = nodo.m_floor_nodo;
	v = nodo.m_direccion_nodo;

	/****************** CON QUATERNIONS *****************/
	if (m_AnguloOffsetInicial != 0)
	{
		ernion =  QuatFromAxisAndAngle(f,self.m_AnguloOffsetInicial); //Está en radianes ya!!
		ernion2 = QuatFromRotator(Rotator(v));
		ernion =  QuatProduct(ernion,ernion2);
		v = vector(QuatToRotator(ernion));
	}

	r = nodo.location + (normal(v) * maxdist); //(mindist + rand(maxdist-mindist));
    nodo.SetLocation(r);

	//Ahora, a colocar el nodo cerquita de la superficie, por si el cálculo ha hecho que esté debajo
	centro = PGame(Worldinfo.Game).m_CentroPlaneta;
	fintrace = r + (r-centro); //Seguro que está por encima del planeta
	trace(hitLocation,hitNormal,fintrace,centro,true,vect(5,5,5));
	if (hitlocation != vect(0,0,0))
	{
		//Lo colocamos en la superficie, un poco por encima just in case
		nodo.SetLocation(hitlocation + 10 *normal(r-centro));
	}
	else
	{
		nodo = nodo;
	}

	/*
	DrawDebugCylinder(initlocation,nodo.Location,3,4,0,100,0,true);
	DrawDebugSphere(initlocation,30,10,255,0,0,true);
	DrawDebugSphere(nodo.Location,30,10,0,0,255,true);
    */
	//`log("OffsetAplicado "@vsize(initlocation-nodo.Location));
	return p;

}

state Rebotando
{
	event Tick(float delta)
	{
		local vector vAlCentro;

		super.tick(delta);
		m_fTiempoDeSalto += delta;
		ApplyGravity(delta);

		if (m_fTiempoDeSalto > 3.0)
		{
			vAlCentro=PGame(WorldInfo.Game).GetCentroPlaneta()-self.pawn.Location; 
			m_FallDirection = 2*Normal(vAlCentro); //caer más rápido
		}

	}

	function ApplyGravity(float delta)
	{
		local Vector Gravity;   
		Gravity = m_FallDirection * WorldInfo.WorldGravityZ * -1 * delta;
		self.Pawn.Velocity += Gravity;
		self.Velocity = self.Pawn.Velocity;
	}

	event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
	{

		if (PGame(Worldinfo.game).EsPlaneta(Wall))
		{
			//OrientarPawnPorNormal(HitNormal,routPawn);
			self.SetBase(Wall,hitnormal);
			pawn.SetBase(Wall, HitNormal);
			self.PopState();
		}
		else
		{
			ReboteRespectoA(Wall,HitNormal,true,400);
		}
	}
	
	function BumpContraSuelo(Actor suelo, vector HitNormal)
	{
			self.SetBase(suelo, HitNormal);
			pawn.SetBase(suelo, HitNormal);
			self.PopState();
	}

	event PushedState()
	{
		self.StopLatentExecution();
		self.pawn.bDirectHitWall = true;
		self.pawn.SetPhysics(PHYS_Flying);
		m_fTiempoDeSalto=0.0; //tiempo de salto
	}
	event PoppedState()
	{
		self.pawn.bDirectHitWall = false;
		self.pawn.SetPhysics(PHYS_None);
		self.pawn.SetPhysics(PHYS_Spider);
	}
}

function ReboteRespectoA(Actor Other, vector hitnormal,bool bRandom, float altura)
{
	local Vector newLocation,newVel;
	local Vector retroceso;
	local vector vAlCentro,vFloor;
	local vector rx,ry,rz;

	self.StopLatentExecution();
	self.StopLatentExecution();
	self.Velocity = vect(0,0,0);
	self.Acceleration = vect (0,0,0);
	
	GetAxes(self.Pawn.Rotation,rx,ry,rz);


	vAlCentro = normal(PGame(WorldInfo.Game).GetCentroPlaneta() - self.pawn.Location);  

	if (self.Pawn.Floor != vect(0,0,0) && self.Pawn.Floor != vect(0,0,1))
	{
		vFloor = self.Pawn.Floor;
	}
	else
	{
		//vFloor = -vAlCentro;
		vFloor = rz; //La rotación del pawn en eje Z
	}



	if (Other != None) //Es contra algo
	{
		retroceso = Normal(self.pawn.Location-Other.Location);
		if (HitNormal != vect(0,0,0))
		{
			newLocation = self.Pawn.Location + (HitNormal*2);//un poquito patrás de donde venía porsiaca
		}
		else
		{
			newLocation = self.Pawn.Location - (normal(self.Pawn.Velocity)*2); //un poquito patrás de donde venía porsiaca
		}
	
		self.pawn.SetLocation(newLocation);
		//self.pawn.Velocity = (retroceso * vsize(self.Pawn.Velocity)*300) + (vFloor * 700); 
		self.pawn.Velocity = -self.Pawn.Velocity + (vFloor * 500); 

	}
	else
	{
		//Queremos que haga un saltito hacia arriba simplemente, sin alterar su velocidad, por ejemplo al dispararle
		self.pawn.Velocity += vFloor * 300; 
	}
	
	self.m_FallDirection = -vFloor;
	
	if (!self.IsInState('Rebotando'))
	{
		self.PushState('Rebotando');
	}

	return;

	

	//self.pawn.Velocity = (retroceso * vsize(self.Pawn.Velocity)*100) - (vAlCentro * 600); 
	

	if (bRandom)
	{
		newVel = normal( hitNormal* 0.6 +vrand() *0.4);
	}
	else
	{
		if (hitNormal != vect(0,0,0))
		{
			newVel = normal ( MirrorVectorByNormal(self.Pawn.Velocity,hitnormal));
		}
		else
		{
			newVel = retroceso;
		}

	}

	self.StopLatentExecution();
	self.pawn.Velocity = (200*newVel* vsize(self.Pawn.Velocity)) - (vAlCentro * altura); 

	//self.pawn.Velocity = (- self.Pawn.Velocity) + (self.Pawn.JumpZ * vFloor) ;

/*	self.pawn.Velocity *= -1;
	self.pawn.Velocity +=  (self.Pawn.JumpZ * vFloor) ;
	self.Velocity = self.Pawn.Velocity;
*/		
	self.m_FallDirection = vAlCentro;

	
	if (!self.IsInState('Rebotando'))
	{
		self.PushState('Rebotando');
	}
    
}


DefaultProperties
{
	
	m_tiempo_tick=0
}
