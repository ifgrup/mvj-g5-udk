class PEnemy_AI_Controller extends AIController;

var PPlayerBase theBase;    //Base objetivo de juego
var float m_tiempo_tick;    //Para control de tiempo. Actualizada en el tick global
var int id;                 //Id del spawner que lo creó. Para identificar el scout y sus minions

var bool m_b_breakpoint; //Se pone a true al disparar con Giru, usado para poner un if y un breakpoint dentro, para
					     //poder debugar un bicho en concreto

var float m_AnguloOffsetInicial; //Angulo con el que fui creado por el EnemySpawner

var vector m_FallDirection; //Dirección de caída para el estado Rebotando
var float m_fTiempoDeSalto;
var vector m_Floor;

var bool m_ya_en_suelo; //Bump contra suelo y hitwall pueden ejecutarse los dos... el primero marca el booleano para no tratar2veces
var PPathNode m_nodo_para_rebote;
var vector m_velocidadRebote;
var float m_despContraTorreta;//distancia a la que nos mandará un rebote contra una torreta.
var float m_currentDespContraTorreta; //distancia actual de la torreta contra la que hemos chocado.
var vector m_posContraTorreta; //posición a la que nos manda el rebote de la torreta.
var bool m_bPausaContraTorreta; //después del toñazo, tiempo de pausa
var bool m_ChocandoContraTorreta ; //para evitar reentrada porque Bump y BaseChange se ejecutan a la vez ahora...

//Control de disparo al Giru
var float m_max_dist_disparo_ppawn; //distancia máxima al PPawn en la que le puede disparar si lo ve
var bool  m_disparo_posible;
var float m_tick_disparo;
var float m_timout_entre_disparos; //cada cuanto puedo disparar al Giru
var class<Actor> m_ClaseMisil;

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
	if (m_Floor != vect(0,0,0))
	{
		DrawDebugCylinder(self.Pawn.Location,self.Pawn.Location+m_Floor*100,4,4,0,0,1,false);
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
        p.SetLocation(r);

	//Ahora, a colocar el nodo cerquita de la superficie, por si el cálculo ha hecho que esté debajo
	centro = PGame(Worldinfo.Game).m_CentroPlaneta;
	fintrace = r + (r-centro); //Seguro que está por encima del planeta
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
		`log("Kagada en offset");
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
		ApplyGravity(delta);

		if (m_fTiempoDeSalto > 2.0)
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
		if (m_ya_en_suelo)
		{
			return;
		}
		m_ya_en_suelo = true;


		if (PGame(Worldinfo.game).EsPlaneta(Wall))
		{
			//OrientarPawnPorNormal(HitNormal,routPawn);
			self.SetBase(Wall,hitnormal);
			pawn.SetBase(Wall, HitNormal);
			`log("Pop 1");
			self.PopState();
		}
		else
		{
			ReboteRespectoA(Wall,HitNormal,true,400);
		}
	}
	
	function BumpContraSuelo(Actor suelo, vector HitNormal)
	{
		if (m_ya_en_suelo)
		{
			return;
		}

		m_ya_en_suelo = true;
		self.SetBase(suelo, HitNormal);
		pawn.SetBase(suelo, HitNormal);
		`log("Pop 2");
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
		vFloor = rz; //La rotación del pawn en eje Z
	}

    m_Floor = vFloor;

	
	if (Other != None) //Es contra algo
	{
		/****************** CON QUATERNIONS *****************/
		ernion =  QuatFromAxisAndAngle(ry,205 * DegToRad); 
		ernion2 = QuatFromRotator(Rotator(rx)); //Rx lleva su dirección
		ernion =  QuatProduct(ernion,ernion2);
		v = vector(QuatToRotator(ernion));

		v = normal (v) * Vsize(self.Pawn.Velocity)*30; //Nueva velocidad
		DrawDebugCylinder(self.Pawn.Location,self.Pawn.Location+normal (self.Pawn.Velocity) * 100,5,5,0,200,0,false);
	}
	else
	{
		//Queremos que haga un saltito hacia arriba simplemente, sin alterar su velocidad, por ejemplo al dispararle
		v=self.pawn.Velocity += vFloor * 100; 
	}
	
	self.m_FallDirection = -vFloor;
	
	//y para que vaya, creo la puta zanahoria de los cojones...
	
	self.m_nodo_para_rebote = spawn(class'PPathNode',,,self.Pawn.Location + normal (v) * 120);
	newLocation = self.Pawn.Location + normal (v) * 10;
	self.pawn.SetLocation(newLocation);

	m_velocidadRebote = v;
	DrawDebugSphere(m_nodo_para_rebote.Location,25,5,200,0,0,false);
	
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
		`log("Kagada... no sé qué hacer...\n");
		newLocation = punto; //sin clavarlo....
	}
	else
	{
		newLocation = HitLocation - (vAlCentro*20); //un pelín parriba
	}

	return newLocation;
}

/*Desplazamos el pawn en la dirección contraria a la velocidad que llevaba, y punto, y aplicamos toque a la torreta*/
function ContraTorreta(Actor torreta, optional float dist=m_despContraTorreta)
{
	local Vector newLocation;

	if (m_ChocandoContraTorreta)
	{
		return;
	}
	m_ChocandoContraTorreta = true;


	newLocation = self.Pawn.Location - (normal(self.Pawn.Velocity) * 0.6* dist);
	newLocation = newLocation + (normal(vrand()) * 0.4*dist); //40% de random, a ver si puede ser...

	self.StopLatentExecution();
	self.Velocity = vect(0,0,0);
	self.Acceleration = vect (0,0,0);
	self.pawn.Velocity = vect(0,0,0);
	self.pawn.Acceleration = vect (0,0,0);
	
	m_posContraTorreta = self.ProyectarPuntoSuelo(newLocation);

	//_DEBUG_DrawDebugCylinder(self.Pawn.Location,m_posContraTorreta,3,3,200,0,0,false);
	//_DEBUG_DrawDebugSphere(m_posContraTorreta,15,4,0,1,0,false);

	//Aplicamos choque a la torreta!!
	if (PAutoTurret(torreta) != None)
	{
		PAutoTurret(torreta).Toque();
	}

	if (!self.IsInState('TonyaoContraTorreta'))
	{
		self.PushState('TonyaoContraTorreta');
	}
}



state TonyaoContraTorreta
{
	event Tick(float delta)
	{
		local vector desp;

		super.tick(delta);
		DrawDebugSphere(self.Pawn.Location,40,10,255,117,138,false);
		self.pawn.setLocation( self.ProyectarPuntoSuelo(self.pawn.location)); //Para fijarlo en tierra
		if (m_currentDespContraTorreta < m_despContraTorreta)
		{
			desp = normal(m_posContraTorreta-self.pawn.location); //de donde estoy hasta el destino del toñazo
			//desp = (desp * 10* delta) / (1+m_tiempo_tick); //intento de desaceleración
			//desp = desp * 20 * (1/(1+m_tiempo_tick));
			desp = desp * 50 * delta ;
	
			self.pawn.setLocation( self.ProyectarPuntoSuelo(self.pawn.location + desp));
			m_currentDespContraTorreta += vsize(desp);
			//_DEBUG `log("current desp "@self.Name @m_currentDespContraTorreta);
	
			DrawDebugSphere(self.Pawn.Location,40,10,32,63,63,false);
		}

		if (m_currentDespContraTorreta >= m_despContraTorreta && !m_bPausaContraTorreta)
		{
			m_bPausaContraTorreta = true;//Empieza el tiempo de que está estoñao (partículas y tal)
			m_tiempo_tick = 0;
		}

		if (m_bPausaContraTorreta && m_tiempo_tick >= 3)
		{
				m_bPausaContraTorreta = false;
				m_ChocandoContraTorreta = false;
				self.PopState();
		}
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
	//Primero lo colocamos 50 unidades alejado del toñazo, para evitar dumps repetitivos
	//Luego en el tick, lo movemos hasta el nuevo destino
	m_currentDespContraTorreta = 30;
	
	self.pawn.setLocation(ProyectarPuntoSuelo(self.pawn.location + normal(m_posContraTorreta-self.pawn.location)  * m_currentDespContraTorreta));
	m_tiempo_tick = 0;
	
}


/*Disparo del PEnemy al Giru.
 * Cada hijo de PEnemy debe indicar la clase de PMisil en su propiedad m_ClaseMisil
 * Y llamar a esat función cuando desee dispara. Se hace actualmente en el SeePlayer
 * También son definibles los timeouts entre disparos y la distancia máxima en la que se considera
 * que se le puede disparar
 */
function DisparaAPPawn(PPawn giru)
{
	local vector minionpos,ppawnpos;
	local Projectile Proj;

	minionpos = self.Pawn.Location  ;
	ppawnpos =  giru.GetPosicionSocketCuerpo();
			
	minionpos+= 150 * normal(ppawnpos - minionpos);
	//Obtener pos del socket del minion
	//Mesh.GetSocketWorldLocationAndRotation('FireLocation',FireLocation,FireRotation);

	Proj = Projectile (Spawn( m_ClaseMisil ,self,,minionpos,,,True));
	Proj.Init(Normal(ppawnpos-minionpos));
	self.m_disparo_posible = false ; //Debe pasar otro intervalo para que vuelva a disparar
}

DefaultProperties
{
	
	m_tiempo_tick=0
	m_despContraTorreta = 100;
}
