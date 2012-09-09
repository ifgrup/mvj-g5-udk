class PEnemy_AI_Bot extends PEnemy_AI_Controller;

var PPathNode theObjective; //Siguiente nodo al que van
var PPathNode nodotemporal; //Para guardar el de antes de aplicar el offset
var int NodeIndex;
var bool bParado;
var int Step;   //Distancia mínima para considerar que no ha llegado a la base
var bool bPrimeraVez;
var PEmiter m_pEmiter; //Para poder mostrar las partículas de congelación
var int m_disparos_giru_congelado;//Disparos de giru recibidos mientras estoy congelado
var int m_intentos_nuevo_nodo; //Intentos en idle antes de 'suicidarse'??

/**
 * Inicializamos el objetivo principal 
 */


var float m_dist_choque_Scout;
var float m_dist_choque_Minion;

var int m_year,m_month,m_weekday,m_day,m_hour,m_min,m_sec,m_milisec;
var float ahora, m_last_stop_colision;
var float distNodo,oldDistNodo;
var int m_segundosQuieto;
var float m_distancia_Base_kamikaze; //Distancia a la base en la que se considera que ha llegao


simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	SetCollision( true, true,true);
	self.bCanStepUpOn =false;
	//self.bMovable = false;
	self.bPushedByEncroachers = false;
}

function Parar()
{
	if (!self.IsInState('StopColision'))
	{
		self.PushState('StopColision');
	}
}




function EstanLosColegasCercaNeng()
{
	local array<PEnemy> colegas;
	local PEnemy_AI_Scout elscout;
	local int i;
	local float distscout,distcolega,distscoutmio,distscoutcolega;

	PGame(Worldinfo.Game).GetVectorEnemigos(self.id, colegas,elscout);
	distscout = vsize(self.Pawn.Location-elscout.Pawn.Location);
	if (distscout < m_dist_choque_Scout)
	{
		Parar();
	}

	//Bucle pa los compis
	for (i=0;i<colegas.length;i++)
	{
		if (colegas[i] == None)
			continue; //Pasa, no sé en qué circunstancias...

		if (colegas[i] == PEnemy(self.Pawn))
			continue;

		distcolega = vsize(colegas[i].Location-self.pawn.Location);
		if (distcolega < m_dist_choque_Minion)
		{
			distscoutmio    = vsize(self.Pawn.Location-elscout.Pawn.Location);
			distscoutcolega = vsize(colegas[i].Location-elscout.Pawn.Location);
			//Si yo estoy más lejos, me paro y hago un break para no comparar con nadie más
			if (distscoutmio > distscoutcolega)
			{   
				Parar();
				//DrawDebugSphere(self.Pawn.Location,80,10,0,0,255,true);
				break; //no tengo que comparar con nadie más, ya me he parado
			}

		}
	}
}



/* --------------- ESTADO IDLE_INICIAL --------------
 * --- Empieza en este estado, y cuando el Pawn recién creado llega al suelo, pasamos al estado inicial
 */
auto state Idle_Inicial
{
	event BeginState(Name PrevName)
	{
		//_DEBUG_ ("Penemy_AI_Bot creado, estoy en Idle");
		m_tiempo_tick = 0;
	}

	event Tick(float Deltatime)
	{
		//Debemos permanecer en este estado mientras el pawn esté cayendo,
		//y no tengamos nodo objetivo.
		//Lo comprobamos cada segundo
		local vector antes,despues;

		super.Tick(Deltatime);
		if (m_tiempo_tick >= 1.0)
		{
			m_intentos_nuevo_nodo++;
			if (m_b_breakpoint)
			{
				m_b_breakpoint = true;
			}
			m_tiempo_tick = 0; //para el siguiente 'timer'
			if (!Penemy(Pawn).IsInState('Cayendo'))
			{
				//ya ha llegado al suelo
				theObjective = PGame(WorldInfo.Game).GetNextPath(id, NodeIndex);
				if(theObjective != none)
				{
					m_intentos_nuevo_nodo = 0;
					if (m_b_breakpoint)
					{
						antes = theObjective.Location;
						//_DEBUG_DrawDebugSphere(antes,30,10,255,0,0,true);
						//_DEBUG_DrawDebugSphere(self.Pawn.Location,35,20,0,0,0,false);
					}
					nodotemporal = theObjective;
					theObjective = AplicarOffsetNodo(nodotemporal); //Para el pseudo-flocking
					//nodotemporal = none ; //Porque si no el garbage no se lo carga creo...

					if (m_b_breakpoint)
					{
						despues = theObjective.Location;
						//_DEBUG_DrawDebugSphere(despues,30,10,0,0,255,true);
						//_DEBUG_DrawDebugCylinder(antes,despues,5,10,0,255,0,true);
					}

					//Tenemos objetivo. Podemos ir al siguiente estado
					//_DEBUG_ ("En idle, tengo nodo nuevo y me voy");
					GotoState('GoToNextPath');
				}
				else
				{ //La única forma de que GetNextPath devuelva none, a falta de unexpected errors, es que estemos en el último nodo
				  //Si es así, es porque no le hemos dado tiempo al scout, o porque hemos llegado a la base. Lo comprobamos
                  if (vsize(self.theBase.Location-self.Pawn.Location) < m_distancia_Base_kamikaze)
                  {
					 GoToState('TowerAttack');
                  }
				  else if (m_intentos_nuevo_nodo >15)
				  {
					GoToState('TowerAttack'); //Yo lo enviaba a explotar y punto, rollo suicida
					`log("_____________No encuentro nodo, ataquer!" @self.Name);
				  }

				  if (self.m_b_breakpoint)
				  {
						m_tiempo_tick = m_tiempo_tick;
				  }
				  
				}
			}
			else if (self.m_b_breakpoint)
			{
					m_tiempo_tick = m_tiempo_tick;
			}
		}//if >1 segundo
	}//Tick

	function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en IDLE"@self.Name);
		self.m_b_breakpoint = true;
	}
	
	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en IDLE"@self.Name);
	}

Begin:
	self.stoplatentexecution();
	self.velocity = vect (0,0,0);
	self.pawn.velocity = vect (0,0,0);
	m_intentos_nuevo_nodo = 0;

	


}/* --------------- FIN ESTADO IDLE_INICIAL --------------*/
//____________________________________________________________________________________________________________________________________

/* --------------- ESTADO GOTONEXTPATH --------------
 * --- Estado en el que nos movemos hacia el siguiente punto de ruta.
 * --  Tiene que hacerse con la etiqueta Begin y tal porque el MoveToward es ejecución latente, y si no no te deja...
*/

state GoToNextPath
{
	event SeePlayer(Pawn seen)
	{
		if (PPawn(seen) != None)
		{
			if (m_disparo_posible && vsize(self.Pawn.Location - seen.Location) < m_max_dist_disparo_ppawn )
			{
				self.DisparaAPPawn(PPawn(seen));
			}
		}
	}

	event Tick (float DeltaTime)
	{
		local vector antes,despues;

		super.Tick(DeltaTime);
		if (m_b_breakpoint)
		{
			DrawDebugSphere(self.Pawn.Location,35,20,0,0,0,false);
		}


		//Cada segundo, hacemos el control que hacía inicialmente la función BrainTimer
		if (theObjective == None)
		{
			GoToState('Idle_Inicial');
			return;
		}
		//_DEBUG_DrawDebugCylinder(self.Pawn.Location,theObjective.Location,3,4,0,0,200,false);
		//_DEBUG_DrawDebugCylinder(self.Pawn.Location,nodotemporal.Location,3,4,200,0,200,false);
		//_DEBUG_DrawDebugSphere(theObjective.Location,25,10,0,0,200,false);

		if(m_tiempo_tick >=1.0)
		{
			m_tiempo_tick = m_tiempo_tick - 1.0; //Por intentar autoajustar un poco y que no siempre sea 1s y pico
			// Comprobamos si hemos llegado al destino
			if(VSize(theBase.Location - Pawn.Location) < Step)
			{
				//Lo paramos, y lo enviamos al estado de ataque a la torre (TowerAttack)
				Velocity = vect(0,0,0);
				Acceleration = vect(0,0,0);
				StopLatentExecution();
				GoToState('TowerAttack');
			}

			// Comprobamos si hemos llegado al nodo y pedimos el siguiente punto de ruta
			distNodo = VSize(theObjective.Location - Pawn.Location);
			if(distNodo < 100)
			{
				theObjective = PGame(WorldInfo.Game).GetNextPath(id, NodeIndex);
				// Si tenemos objetivo, nos movemos a su posición
				if(theObjective != none)
				{
					if (m_b_breakpoint)
					{
						antes = theObjective.Location;
						//_DEBUG_DrawDebugSphere(antes,30,10,255,0,0,true);
						//_DEBUG_DrawDebugSphere(self.Pawn.Location,35,20,0,0,0,false);
					}
					nodotemporal = theObjective;
					theObjective = AplicarOffsetNodo(nodotemporal); //Para el pseudo-flocking
					//nodotemporal = none ; //Porque si no el garbage no se lo carga creo...
			
					if (m_b_breakpoint)
					{
						despues = theObjective.Location;
						//_DEBUG_DrawDebugSphere(despues,30,10,0,0,255,true);
						//_DEBUG_DrawDebugCylinder(antes,despues,5,10,0,255,0,true);
					}

					//`log("Nuevo nodo seleccionado, voy palla");

					GotoState('GoToNextPath'); //Autollamada al begin state para ir hacia el nuevo nodo
				}
				else
				{
					//No hay objetivo
					//Podríamos no hacer nada y esto se ejecutaría de nuevo al segundo.
					//Pero lo suyo es ir al estado Idle
					//`log("Idle al llegar al nodo");
					DrawDebugSphere(self.Pawn.Location,25,5,255,255,255,true);
					`log("Idle por no tener nodo after GetNextNode");
					GoToState('Idle_Inicial');

				}
			}
			else
			{
				//Igualmente hay que decirle que siga para alante hacia donde iba.
				//Pero si por lo que sea estamos parados porque el MoveTo considera que ha llegado, hay que ir
				//al siguiente nodo.
				//Control de que se queda quieto:
				if (abs(distNodo - oldDistNodo)<0.1)
				{
					m_segundosQuieto +=1;
					if (m_segundosQuieto == 2)
					{
						m_segundosQuieto = 0;
						theObjective = PGame(WorldInfo.Game).GetNextPath(id, NodeIndex);
						if (theObjective != None)
						{
							if (m_b_breakpoint)
							{
								antes = theObjective.Location;
								//_DEBUG_DrawDebugSphere(antes,30,10,255,0,0,true);
								//_DEBUG_DrawDebugSphere(self.Pawn.Location,35,20,0,0,0,false);
							}

							nodotemporal = theObjective;
							theObjective = AplicarOffsetNodo(nodotemporal); //Para el pseudo-flocking
							//nodotemporal = none ; //Porque si no el garbage no se lo carga creo...
			
							if (m_b_breakpoint)
							{
								despues = theObjective.Location;
								//_DEBUG_DrawDebugSphere(despues,30,10,0,0,255,true);
								//_DEBUG_DrawDebugCylinder(antes,despues,5,10,0,255,0,true);
							}
						}
						else
						{
							//No tiene nodo destino, y no hemos llegado a la base. Nos vamos a Idle
							DrawDebugSphere(self.Pawn.Location,25,5,255,255,255,true);
							`log("Idle por no tener nodo after quieto");
							GoToState('Idle_Inicial');
						}
					}
				}
				oldDistNodo = distNodo;
				GotoState('GoToNextPath');
			}

		} 
		EstanLosColegasCercaNeng();
	}//Tick


	function Parar()
	{
		if (!self.IsInState('StopColision'))
		{
			self.PushState('StopColision');
		}
	}

	function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en GOTONEXTPATH"@self.Name);
		//self.PushState('StopColision');
		ReboteRespectoA( None,vect(0,0,0),false,300);
		self.m_b_breakpoint = true;
	}
	
	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, ControlTakeDisparoTurretCannon en GOTONEXTPATH"@self.Name);
	}

	function ControlTakeDisparoTurretIce(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, ControlTakeDisparoTurretIce en GOTONEXTPATH"@self.Name);
		//Hay que congelar al bicho, que se quede quieto, salga el sistema de partículas del hielo
		//y que cuando acabe de estar congelado, vuelva a este estado.
		self.PushState('Congelado');
	}

	function Control_BaseChangedPenemy(Actor PEnemyOtro)
	{   
	//`log("PEnemy_AI_Controller::Control_BaseChangedPenemy, DEBES SOBREESCRIBIRME!!!");
	//PEnemyPawn_Minion(self.Pawn).PararEsperar();
	self.PushState('StopColision');
	}



Begin:
	m_tiempo_tick = 0;
	if (theObjective != None)
	{
		//DBG WorldInfo.Game.Broadcast(self,Name$" va hacia el path"@theObjective.Name);

		// Esta función permite ponerle un rango para que el movimiento no sea siempre
		// en línea recta. El Pawn se moverá a cualquier punto dentro de las 100 unidades de radio
		// que le estamos indicando.
		//`log("Begin de GoToNextNode");
		
		//VICTOR MoveToward(theObjective,theObjective,10,true,true);
		
		MoveToDirectNonPathPos (theObjective.Location,theObjective,10,true);
		
	}
}/* ---------------FIN ESTADO IDLE_INICIAL --------------*/
//____________________________________________________________________________________________________________________________________




/* --------------- ESTADO CONGELADO --------------
 * --- Nos acaba de disparar la torreta hielo
 * --  Estaremos congelados un tiempo, durante el cual, si recibimos más de 7 disparos de Giru, o bien 3 de una torreta
 * --  Nos romperemos en mil pedazos
*/
state Congelado
{
	event Tick (float DeltaTime)
	{
		super.Tick(DeltaTime);
		
		//m_pEmiter se destuirá sólo de momento...cuando lo haga
		if (m_pEmiter == None) //Alguna vez ha pasado, supongo que el tick entra antes que el begin asigne el emiter..
			return;

		if(m_tiempo_tick >= m_pEmiter.m_tiempoHielo)
		{
			if (PEnemy(Pawn).life > 0)
			{
				//Si sigue vivo, que siga caminando o lo que estuviera haciendo en el estado anterior
				self.PopState();
			}
		}
	}
	
	function ControlTakeDisparoTurretIce(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, Ya estoy congelado, pa qué sufrir más?..."@self.Name);
		//Si ya está congelado, no vuelve a congelarse, simplemente lo ignoramos
		return;
	}

	function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en Congelado"@self.Name);
		m_disparos_giru_congelado++;
		if (m_disparos_giru_congelado > 5)
		{
			GoToState('DeadAnyicos');
		}
	}

Begin:

	m_tiempo_tick = 0;
	m_disparos_giru_congelado = 0;
	//Paramos su movimiento
	StopLatentExecution();
	Velocity = vect(0,0,0);
	Acceleration = vect(0,0,0);
	pawn.Velocity = vect(0,0,0);
	pawn.Acceleration = vect(0,0,0);

	//pawn.bCollideActors = false; //Para que el sistema de partículas
	DrawDebugSphere(pawn.Location,80.0,20,255,255,255,true);
	//No modificamos sus variables de destino ni nada, así al volver al estado de GoToNextPath si es del que viene, seguirá
	//moviéndose hacia donde iba

    //Lanzo los sistemas de partículas de congelación
	m_pEmiter=Spawn(class'PEmiter',self,,pawn.Location,pawn.Rotation,,true);
	m_pEmiter.m_tiempoHielo += rand(2) - rand(2); //Random +- 2 segundos para que no todos sean iguales
	m_pEmiter.SpawnEmitter();
}/* ---------------FIN ESTADO CONGELADO --------------*/
//____________________________________________________________________________________________________________________________________

/* --------------- ESTADO DEAD_ANYICOS --------------
 * --- Estábamos congelados, y el puto Giru nos ha disparado 400 veces, así que rebentamos en cachitos de hielo
 */

state DeadAnyicos
{
	ignores TakeDamage,SeePlayer,Bump,Touch,BaseChange;

	//Todas las funciones sobreescribibles las dejamos vacías just in case
	function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser){}
	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser){}
	function ControlTakeDisparoTurretIce(vector HitLocation, vector Momentum, Actor DamageCauser){}
	

	event BeginState(name PreviousStateName)
	{
		//Sistema de partículas de cachos de hielo a saco.
		`log("Soy un PEnemy_AI_Bot, y el puto Giru de los huevos me ha destruído");
		self.Destroy();
		self.Pawn.Destroy();
	}


}/* ---------------FIN ESTADO TOWER_ATTACK --------------*/
//__________________



/* --------------- ESTADO STOP_COLISION --------------
 * --- Estábamos andando, hemos hecho BaseChange contra otro coleguilla, espermos 1 segundo
 */

state StopColision
{
	//Todas las funciones sobreescribibles las dejamos vacías just in case
	function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en StopColision "@self.Name);
		self.m_b_breakpoint = true;
	}

	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser){}
	function ControlTakeDisparoTurretIce(vector HitLocation, vector Momentum, Actor DamageCauser){}
	
	/*
	event Tick(float delta)
	{
		local Vector Gravity;
		local vector vAlCentro;
		local vector FallDirection;

		super.Tick(delta);
		if (m_tiempo_tick > 3.0)
		{
			self.PopState();
			//self.Possess(m_PawnAntesUnpossess,false);

		}
	}
   */
	
Begin:
	
	//`log("Soy un PEnemy_AI_Bot, y me paro porque he enculao a un colega");
	//old_velocity=pawn.Velocity;

	if (m_b_breakpoint)
	{
		m_b_breakpoint = true;
	}
	GetSystemTime(m_year,m_month,m_weekday,m_day,m_hour,m_min,m_sec,m_milisec);
	ahora = m_sec+m_milisec/1000.0;
	if (abs(ahora-m_last_stop_colision) >= 0.5)
	{
		StopLatentExecution();
		Velocity = vect(0,0,0);
		Acceleration = vect(0,0,0);
		pawn.Velocity = vect(0,0,0);
		pawn.Acceleration = vect(0,0,0);
		Sleep(0.6);
		//PEnemyPawn_Minion(self.pawn).PararEsperar();   
		m_tiempo_tick = 0;
	}
	else
	{
		//`log("no me paro otra vez");
	}
	GetSystemTime(m_year,m_month,m_weekday,m_day,m_hour,m_min,m_sec,m_milisec);
	m_last_stop_colision = m_sec+m_milisec/1000.0;

	self.PopState();

}/* ---------------FIN ESTADO TOWER_ATTACK --------------*/
//__________________






/* --------------- ESTADO TOWER_ATTACK --------------
 * --- Estado en el que nos estamos cerca de la torre Base, y atacamos a lo borrico.
 */

state TowerAttack
{

	function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en TowerAttack"@self.Name);
	}
	
	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en TowerAttack"@self.Name);
	}

	event Tick(float delta)
	{

		super.Tick(delta);
		if (m_tiempo_tick < 10 )
		{
			DrawDebugSphere(self.Pawn.Location,m_tiempo_tick*10,20,0,50,100,false);
			self.Pawn.Acceleration = vect (0,0,0);
			self.Pawn.Velocity = vect(0,0,0);
		}
		else
		{
			m_tiempo_tick = 0;
		}
	}
   
Begin:
	StopLatentExecution();
	m_tiempo_tick = 0;
	self.Velocity = vect(0,0,0);
    self.Acceleration = vect(0,0,0);
	self.Pawn.Velocity = vect(0,0,0);
	self.Pawn.Acceleration = vect(0,0,0);

	

}/* ---------------FIN ESTADO TOWER_ATTACK --------------*/
//____________________________________________________________________________________________________________________________________

defaultproperties
{
	theObjective=none
	NodeIndex=0
	Step=400
	bPrimeraVez=true
	bMovable=false
	m_dist_choque_Minion=250
	m_dist_choque_Scout=125
	m_distancia_Base_kamikaze=150
	m_max_dist_disparo_ppawn=400
	m_timout_entre_disparos = 3
	m_ClaseMisil=class 'PMisilMinion'
}
