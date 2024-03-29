class PEnemy_AI_Controller extends AIController;

var PPlayerBase theBase;    //Base objetivo de juego
var float m_tiempo_tick,m_tiempo_tickp;    //Para control de tiempo. Actualizada en el tick global
var int id;                 //Id del spawner que lo cre�. Para identificar el scout y sus minions

var bool m_b_breakpoint; //Se pone a true al disparar con Giru, usado para poner un if y un breakpoint dentro, para
					     //poder debugar un bicho en concreto

var float m_AnguloOffsetInicial; //Angulo con el que fui creado por el EnemySpawner

var vector m_FallDirection; //Direcci�n de ca�da para el estado Rebotando
var float m_fTiempoDeSalto;
var vector m_Floor;

var bool m_ya_en_suelo; //Bump contra suelo y hitwall pueden ejecutarse los dos... el primero marca el booleano para no tratar2veces
var PPathNode m_nodo_para_rebote;
var vector m_velocidadRebote;
var float m_despContraTorreta;//distancia a la que nos mandar� un rebote contra una torreta.
var float m_currentDespContraTorreta; //distancia actual de la torreta contra la que hemos chocado.
var vector m_posContraTorreta; //posici�n a la que nos manda el rebote de la torreta.
var bool m_bPausaContraTorreta; //despu�s del to�azo, tiempo de pausa
var bool m_ChocandoContraTorreta ; //para evitar reentrada porque Bump y BaseChange se ejecutan a la vez ahora...

//Control de disparo al Giru
var float m_max_dist_disparo_ppawn; //distancia m�xima al PPawn en la que le puede disparar si lo ve
var bool  m_disparo_posible;
var float m_tick_disparo;
var float m_timout_entre_disparos; //cada cuanto puedo disparar al Giru
var class<Actor> m_ClaseMisil;
var vector minionpqpipos1;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	theBase = PGame(WorldInfo.Game).PlayerBase;
}

/*Tick global para todos los pEnemys. Controla el tiempo de estado, por lo que TODOS los ticks de los estados/clases hijas
 * deber�n invocarlo (oh dioses del tick! te invocamos juas juas :D
 */

function Tick(Float Deltatime)
{
	local PEnemy thePawn;
	super.Tick(DeltaTime);
	
	//Control global de tiempo. Cada estado lo pondr� a cero y controlar� a su gusto
	m_tiempo_tick += DeltaTime;
	m_tiempo_tickp += DeltaTime;

	//Actualizaci�n de la rotaci�n del pawn que controlamos
	if (Pawn != None)
	{
		thePawn = PEnemy(Pawn);
		thePawn.ActualizaRotacion(DeltaTime);
		setRotation(thePawn.Rotation);
	}
	if (m_Floor != vect(0,0,0))
	{
		//DrawDebugCylinder(self.Pawn.Location,self.Pawn.Location+m_Floor*100,4,4,0,0,1,false);
	}
	
	//Control de timing entre disparos
	m_tick_disparo += DeltaTime;
	if (m_tick_disparo >= m_timout_entre_disparos)
	{
		m_disparo_posible = true;
		m_tick_disparo = 0;
	}
}


/**
 * Ponemos el identificador. Debe ser el mismo que el del Spawner que lo gener�
 * */
function SetID(int i)
{
	id = i;
}

/**
 * Funciones gen�rica de RecibirDanyo, llamada desde los pawns en su TakeDamage, para cada t�po de da�o.
 * El control de vida y muerte, creo que se deber�a hacer en el pawn. 
 * Desde el pawn, SIEMPRE Se llama a su owner, o sea, a estas funciones, para ejecutar la gesti�n del da�o, pero
 * para cambiar de estado y tal. O sea, que el tema de restar vida y tal, creo que se puede hacer en pawn.
 * 
 * PEnemy recibe el TakeDamage, decodifica el tipo de da�o, ejecuta la funcion de PEnemy o redefinida en las hijas que
 * controla el da�o, y luego llama a la funci�n de gesti�n de controller.
 * Y aqu� hacemos lo mismo, una funci�n gen�rica, y cada hijo de PEnemy_AI_Controller, que redefina su tratamiento
 * para cada estado.
 */
function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser)
{
	//_DEBUG `log("PEnemy_AI_Controller, recibido danyo Giru Global, DEBES SOBREESCRIBIRME!!!\n" @self.GetStateName());
	m_b_breakpoint = true; //Para poder poner un breakpoint en un if (m_b_breakpoint), y s�lo se parar� si
						   //has disparado a ese PEnemy
}

function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser)
{
	//_DEBUG `log("PEnemy_AI_Controller, recibido danyo TurretCannon Global, DEBES SOBREESCRIBIRME!!!\n");
}

function ControlTakeDisparoTurretIce(vector HitLocation, vector Momentum, Actor DamageCauser)
{
	//_DEBUG `log("PEnemy_AI_Controller, recibido danyo TurretIce Global, DEBES SOBREESCRIBIRME!!!\n");
}


function Control_BaseChangedPenemy(Actor PEnemyOtro)
{
	//`log("PEnemy_AI_Controller::Control_BaseChangedPenemy, DEBES SOBREESCRIBIRME!!!");
	
}

function BumpContraSuelo(Actor suelo, vector HitNormal)
{

}

function ContraBase(); //Sobreescrita por cada hijo

function PPathNode AplicarOffsetNodo(PPathNode nodo)
{
	local PPathnode p;
	local vector f ;
	local vector v,r ;
	local Quat ernion,ernion2;

	local vector centro,hitlocation,hitnormal,fintrace;
	local float maxdist;
	local vector initlocation;

	maxdist = Pgame(Worldinfo.Game).m_max_radiorandom;
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
		ernion =  QuatFromAxisAndAngle(f,self.m_AnguloOffsetInicial); //Est� en radianes ya!!
		ernion2 = QuatFromRotator(Rotator(v));
		ernion =  QuatProduct(ernion,ernion2);
		v = vector(QuatToRotator(ernion));
	}

	r = nodo.location + (normal(v) * maxdist); //(mindist + rand(maxdist-mindist));
        p.SetLocation(r);

	//Ahora, a colocar el nodo cerquita de la superficie, por si el c�lculo ha hecho que est� debajo
	centro = PGame(Worldinfo.Game).m_CentroPlaneta;
	fintrace = r + (r-centro); //Seguro que est� por encima del planeta
	trace(hitLocation,hitNormal,fintrace,centro,true,vect(5,5,5));
	if (hitlocation != vect(0,0,0))
	{
		//Lo colocamos en la superficie, un poco por encima just in case
		p.SetLocation(hitlocation + 10 *normal(r-centro));
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

	if (vsize(initlocation - p.Location) > 200)
	{
		//_DEBUG `log("Kagada en offset");
		return nodo;
	}
	return p;

}

state Rebotando
{
	event Tick(float delta)
	{
		local vector vAlCentro;

		super.tick(delta);
		m_fTiempoDeSalto += delta;

		if (m_fTiempoDeSalto < 0.5)
		{
			return; //Lo dejamos subir libremente hacia la zanahoria medio segundo
		}

		ApplyGravity(delta);

		if (m_fTiempoDeSalto > 2.0)
		{
			vAlCentro=PGame(WorldInfo.Game).GetCentroPlaneta()-self.pawn.Location; 
			m_FallDirection = 2*Normal(vAlCentro); //caer m�s r�pido

		}

	}

	function ApplyGravity(float delta)
	{
		local Vector Gravity;   
		Gravity = m_FallDirection * (WorldInfo.WorldGravityZ/1.5) * -1 * delta;
		self.Pawn.Velocity += Gravity;
		self.Velocity = self.Pawn.Velocity;
	}

	event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
	{
		//Este evento no deber�a ejecutarse NUNCA!!!.... lo dejo por miedito....
		local rotator rot;

		if (m_ya_en_suelo)
		{
			return;
		}
		m_ya_en_suelo = true;


		if (PGame(Worldinfo.game).EsPlaneta(Wall))
		{
			self.SetBase(Wall,hitnormal);
			pawn.SetBase(Wall, HitNormal);
			PEnemy(pawn).OrientarPEnemyPorNormal(HitNormal, rot);
			pawn.SetRotation(rot);
			//_DEBUG `log("Pop 1");
			self.PopState();
		}
		else
		{
			ReboteRespectoA(Wall,HitNormal,true,400);
		}
	}
	
	function BumpContraSuelo(Actor suelo, vector HitNormal)
	{
		local rotator rot;

		if (m_ya_en_suelo)
		{
			return;
		}

		m_ya_en_suelo = true;
		self.SetBase(suelo, HitNormal);
		pawn.SetBase(suelo, HitNormal);
		PEnemy(pawn).OrientarPEnemyPorNormal(HitNormal, rot);
		pawn.SetRotation(rot);

		//_DEBUG `log("Pop 2");
		self.PopState();
		
	}

	event PushedState()
	{
		self.StopLatentExecution();
		self.pawn.bDirectHitWall = true;
		self.pawn.SetPhysics(PHYS_Flying);
		m_fTiempoDeSalto=0.0; //tiempo de salto
		m_ya_en_suelo = false;
	}
	event PoppedState()
	{
		self.pawn.bDirectHitWall = false;
		self.pawn.SetPhysics(PHYS_None);
		self.pawn.SetPhysics(PHYS_Spider);
		
	}

Begin:
	self.Pawn.Velocity=vect(0,0,0);
	self.Pawn.Acceleration = vect(0,0,0);
	self.Velocity=vect(0,0,0);
	self.Acceleration = vect(0,0,0);
	StopLatentExecution();
	self.Pawn.Velocity=vect(0,0,0);
	self.Pawn.Acceleration = vect(0,0,0);
	self.Velocity=vect(0,0,0);
	self.Acceleration = vect(0,0,0);

	self.pawn.bDirectHitWall = true;
	self.pawn.SetPhysics(PHYS_Flying);
	m_fTiempoDeSalto=0.0; //tiempo de salto
	m_ya_en_suelo = false;
	self.pawn.velocity = m_velocidadRebote;
	MoveToDirectNonPathPos (m_nodo_para_rebote.Location,m_nodo_para_rebote,10);
}

function ReboteRespectoA(Actor Other, vector hitnormal,bool bRandom, float altura)
{
	local Vector newLocation,v;
	local vector vFloor;
	local vector rx,ry,rz;
	local Quat ernion,ernion2;

	self.StopLatentExecution();
	
	GetAxes(self.Pawn.Rotation,rx,ry,rz);

	if (self.Pawn.Floor != vect(0,0,0) && self.Pawn.Floor != vect(0,0,1))
	{
		vFloor = self.Pawn.Floor;
	}
	else
	{
		vFloor = rz; //La rotaci�n del pawn en eje Z
	}

    m_Floor = vFloor;

	
	if (Other != None) //Es contra algo
	{
		/****************** CON QUATERNIONS *****************/
		ernion =  QuatFromAxisAndAngle(ry,205 * DegToRad); 
		ernion2 = QuatFromRotator(Rotator(rx)); //Rx lleva su direcci�n
		ernion =  QuatProduct(ernion,ernion2);
		v = vector(QuatToRotator(ernion));

		v = normal (v) * Vsize(self.Pawn.Velocity)*30; //Nueva velocidad
		//DrawDebugCylinder(self.Pawn.Location,self.Pawn.Location+normal (self.Pawn.Velocity) * 100,5,5,0,200,0,false);
	}
	else
	{
		//Queremos que haga un saltito hacia arriba simplemente, sin alterar su velocidad, por ejemplo al dispararle
		v=self.pawn.Velocity += vFloor * 250; 
	}
	
	self.m_FallDirection = -vFloor;
	
	//y para que vaya, creo la puta zanahoria de los cojones...
	
	self.m_nodo_para_rebote = spawn(class'PPathNode',,,self.Pawn.Location + normal (v) * 150);
	newLocation = self.Pawn.Location + normal (v) * 10;
	self.pawn.SetLocation(newLocation);

	m_velocidadRebote = v;
	//_DEBUG_DrawDebugSphere(m_nodo_para_rebote.Location,25,5,200,0,0,true);
	
	if (!self.IsInState('Rebotando'))
	{
		self.PushState('Rebotando');
	}
  
}



function vector ProyectarPuntoSuelo(vector punto)
{
	local Vector newLocation,vAlCentro,HitLocation,HitNormal,centro;
	local bool bfound;
	local actor HitActor;

	centro = PGame(WorldInfo.Game).GetCentroPlaneta();
	vAlCentro = Normal(centro - punto); 

	foreach TraceActors(class'Actor',HitActor, HitLocation, HitNormal,centro,punto-(vAlCentro*3000),vect(10,10,10),,TRACEFLAG_Bullet)
	{
		if(PGame(Worldinfo.Game).EsPlaneta(HitActor))
		{
			bfound = true;
			break;
		}
	}		

	if (!bfound)
	{
		//_DEBUG `log("Kagada... no s� qu� hacer...\n");
		newLocation = punto; //sin clavarlo....
	}
	else
	{
		newLocation = HitLocation - (vAlCentro*12); //un pel�n parriba
	}

	return newLocation;
}



function vector ProyectarPuntoKamikaze()
{
	return self.Pawn.Location+self.Pawn.Floor*1000;
}



function ContraTorreta(Actor torreta, optional float dist=m_despContraTorreta)
{
	//_DEBUG `log("ContraTorreta no tratado" @self.name);
}


state TonyaoContraTorreta
{
	function ContraTorreta(Actor torreta, optional float dist=m_despContraTorreta)
	{
		//_DEBUG_`log("ContraTorreta ignorado, ya estonyao" @self.name);
	}

	event Tick(float delta)
	{
		local vector desp;

		super.tick(delta);
		//_DEBUG_ DrawDebugSphere(self.Pawn.Location,40,10,255,117,138,false);
		self.pawn.setLocation( self.ProyectarPuntoSuelo(self.pawn.location)); //Para fijarlo en tierra
		if (m_currentDespContraTorreta < m_despContraTorreta)
		{
			desp = normal(m_posContraTorreta-self.pawn.location); //de donde estoy hasta el destino del to�azo
			//desp = (desp * 10* delta) / (1+m_tiempo_tick); //intento de desaceleraci�n
			//desp = desp * 20 * (1/(1+m_tiempo_tick));
			desp = desp * 50 * delta ;
	
			self.pawn.setLocation( self.ProyectarPuntoSuelo(self.pawn.location + desp));
			m_currentDespContraTorreta += vsize(desp);
			//_DEBUG `log("current desp "@self.Name @m_currentDespContraTorreta);
	
			//DrawDebugSphere(self.Pawn.Location,40,10,32,63,63,false);
		}

		if (m_currentDespContraTorreta >= m_despContraTorreta && !m_bPausaContraTorreta)
		{
			m_bPausaContraTorreta = true;//Empieza el tiempo de que est� esto�ao (part�culas y tal)
			m_tiempo_tick = 0;
		}

		if (m_bPausaContraTorreta && m_tiempo_tick >= 3)
		{
				m_bPausaContraTorreta = false;
				m_ChocandoContraTorreta = false;
				self.PopState();
		}

		//Para evitar rebote infinito:
		if (m_tiempo_tick > 5)
		{
			m_ChocandoContraTorreta = false;
			self.PopState();
		}
	}

	function BumpContraSuelo(Actor suelo,vector HitNormal)
	{
		//Si durante el rebote, antes de alejarse a la distancia dicha, toca el suelo, se parar�, y jam�s
		//legar� a esa distancia, por lo que se quedar� parado in eternum
		//As� que si toca el suelo, finalizamos el rebote
		//_DEBUG `log("_Contra suelo after rebote "@self.Name);
		m_tiempo_tick = 0;
		m_ChocandoContraTorreta = false;
		m_bPausaContraTorreta = false;
		self.PopState();
	}

Begin:
	self.Pawn.Velocity=vect(0,0,0);
	self.Pawn.Acceleration = vect(0,0,0);
	self.Velocity=vect(0,0,0);
	self.Acceleration = vect(0,0,0);
	StopLatentExecution();
	self.Pawn.Velocity=vect(0,0,0);
	self.Pawn.Acceleration = vect(0,0,0);
	self.Velocity=vect(0,0,0);
	self.Acceleration = vect(0,0,0);
	//Primero lo colocamos 50 unidades alejado del to�azo, para evitar dumps repetitivos
	//Luego en el tick, lo movemos hasta el nuevo destino
	m_currentDespContraTorreta = 20;
	
	self.pawn.setLocation(ProyectarPuntoSuelo(self.pawn.location + normal(m_posContraTorreta-self.pawn.location)  * m_currentDespContraTorreta));
	m_tiempo_tick = 0;
	
}


/*Disparo del PEnemy al Giru.
 * Cada hijo de PEnemy debe indicar la clase de PMisil en su propiedad m_ClaseMisil
 * Y llamar a esta funci�n cuando desee dispara. Se hace actualmente en el SeePlayer
 * Tambi�n son definibles los timeouts entre disparos y la distancia m�xima en la que se considera
 * que se le puede disparar
 */
function DisparaAPPawn(PPawn giru)
{
	local vector FireLocation,ppawnpos;
	local Projectile Proj;

	//minionpos = self.Pawn.Location  ;
	ppawnpos =  giru.GetPosicionSocketCuerpo();
			
	//minionpos+= 150 * normal(ppawnpos - minionpos);
	//Obtener pos del socket del minion
	FireLocation = PEnemy(self.Pawn).GetFireLocation();

	Proj = Projectile (Spawn( m_ClaseMisil ,self,,FireLocation,,,True));
	if (Proj!= None)
	{
		Proj.Init(Normal(ppawnpos-FireLocation));
		self.m_disparo_posible = false ; //Debe pasar otro intervalo para que vuelva a disparar
	}
}

DefaultProperties
{
	
	m_tiempo_tick=0
	m_tiempo_tickp=0
	m_despContraTorreta = 40
	minionpqpipos1=(X=0,Y=0,Z=0);
	
}
