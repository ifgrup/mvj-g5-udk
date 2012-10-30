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

var int m_ticks_colegas_cerca; //Intento de optimizar llamadas en ticks

var vector locaKamikaze,locaKamikazeini;  //punto para hacer el kamikaze
var float m_currentDespkamikaze;
var int repeti;
var float dpqpi;

var int m_tiempo_max_kamikaze;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	SetCollision( true, true,true);
	self.bCanStepUpOn =false;
	//self.bMovable = false;
	self.bPushedByEncroachers = false;
	minionpqpipos1=vect(0,0,0);
	dpqpi=-5;
	

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

	if(elscout == None)
	{
		return;
	}

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

	//Y al árbol (SI, lo se. Tendríamos que haber hecho que torretas y árboles heredaran de lo mismo...
	if (PTree(torreta) != None)
	{
		//_DEBUG `log("Minion contra arbol" @self.Name);
		PTree(torreta).Toque();
	}

	if (!self.IsInState('TonyaoContraTorreta'))
	{
		self.PushState('TonyaoContraTorreta');
	}
}



function kamikaze ()
{
		//local PPawn gppawn;
		local PAutoTurret torreta;
		local vector posenemigo;
		local Projectile Proj;
		local vector rx,ry,rz;
		local class<Actor> clasedisparo;
		local vector posdisparo;
		local LinearColor colordisparo;

		if (vsize(self.theBase.Location-locaKamikazeini) < m_distancia_Base_kamikaze)
        {
			
			GetAxes (self.theBase.Rotation,rx,ry,rz);
			posenemigo = self.theBase.Location + rz*450; //Por no poner un socket en la casa
        }
		else
		{
			if (vsize(PGame(WorldInfo.Game).GetALocalPlayerController().Pawn.Location-locaKamikazeini) < m_distancia_Base_kamikaze)
			{
				posenemigo=	PPAwn(PGame(WorldInfo.Game).GetALocalPlayerController().Pawn).GetPosicionSocketCuerpo();
			}
			else
			{
				posenemigo=self.pawn.location+vrand()*500;
			
				foreach VisibleCollidingActors(class'PAutoTurret', torreta,2000.f,self.Pawn.Location,,vect(100,100,100),true)
				{
					posenemigo=torreta.Location;
					break;
			
				}
			}
		}



		//lanzamos toñazo kamikaze
		posdisparo = PEnemyPawn_Minion(self.pawn).GetFireLocation();
		clasedisparo = PEnemyPawn_Minion(self.Pawn).m_ClaseMisilKamikaze;
		colordisparo = PEnemyPawn_Minion(self.Pawn).Col1;
	

		//Eliminamos al Pawn
		PEnemyPawn_Minion(self.Pawn).Destruccion();
		self.Pawn=None;

		Proj =Projectile(Spawn(clasedisparo,self,,posdisparo,,,True));
		if (Proj!= None)
		{
			
			if(PMisiKamimoco(Proj)!=None)
			{
				PMisiKamimoco(Proj).colormoco(colordisparo);
			}
			//Lanzamos el disparo
			Proj.Init(Normal(posenemigo-posdisparo));

		}	

		//Nos autoeliminamos
		self.Destroy();
}




/* --------------- ESTADO IDLE_INICIAL --------------
 * --- Empieza en este estado, y cuando el Pawn recién creado llega al suelo, pasamos al estado inicial
 */
auto state Idle_Inicial
{
	event Tick(float Deltatime)
	{
		//Debemos permanecer en este estado mientras el pawn esté cayendo,
		//y no tengamos nodo objetivo.
		//Lo comprobamos cada segundo

		super.Tick(Deltatime);

		if (m_tiempo_tick >= 1.0)
		{
			m_tiempo_tick = 0; //para el siguiente 'timer'

			if(VSize(theBase.Location - Pawn.Location) < m_distancia_Base_kamikaze)
			{
				//Lo paramos, y lo enviamos al estado de ataque a la torre (TowerAttack)
				Velocity = vect(0,0,0);
				Acceleration = vect(0,0,0);
				self.pawn.Velocity = vect(0,0,0);
				self.pawn.Acceleration = vect(0,0,0);

				StopLatentExecution();
				GoToState('TowerAttack');
				return;
			}
			m_intentos_nuevo_nodo++;
 

			if (!Penemy(Pawn).IsInState('Cayendo'))
			{
				//ya ha llegado al suelo
				theObjective = PGame(WorldInfo.Game).GetNextPath(id, NodeIndex);
				if(theObjective != none)
				{
					m_intentos_nuevo_nodo = 0;
					
					nodotemporal = theObjective;
					theObjective = AplicarOffsetNodo(nodotemporal); //Para el pseudo-flocking
					nodotemporal = none ; //Porque si no el garbage no se lo carga creo...
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
				  else if (m_intentos_nuevo_nodo >6)
				  {
					GoToState('TowerAttack'); //Yo lo enviaba a explotar y punto, rollo suicida
					//_DEBUG `log("_____________No encuentro nodo, ataquer!" @self.Name);
				  }
				  
				}
			}
		}//if >1 segundo
	}//Tick

	function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		//_DEBUG `log("PEnemy_AI_BOT, ControlTakeDisparoGiru en IDLE"@self.Name);
		self.m_b_breakpoint = true;
	}
	
	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		//_DEBUG `log("PEnemy_AI_BOT, ControlTakeDisparoGiru en IDLE"@self.Name);
	}

	function BumpContraSuelo(Actor suelo,Vector HitNormal)
	{
		PEnemy(self.Pawn).AterrizadoAfterSpawn();
	}

	function ContraTorreta(Actor torreta, optional float dist)
	{
		//_DEBUG `log("_ignorado toñazo mientras cayendo "@self.Name);
	}


Begin:
	self.stoplatentexecution();
	self.velocity = vect (0,0,0);
	self.pawn.velocity = vect (0,0,0);
	m_intentos_nuevo_nodo = 0;
	m_tiempo_tick = 0;

	


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
		//_DEBUG `log ("HE visto a este pawn "@seen.Name);

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
		super.Tick(DeltaTime);
		
		//tema ñordamiento 
		if(m_tiempo_tickp > 10)
		{
			
			
  			dpqpi=VSize(minionpqpipos1- self.pawn.Location);
			if(dpqpi<1)
			{
				
				Velocity = vect(0,0,0);
				Acceleration = vect(0,0,0);
				self.pawn.Velocity = vect(0,0,0);
				self.pawn.Acceleration = vect(0,0,0);

				StopLatentExecution();
				GoToState('TowerAttack');
				return;
			}
			minionpqpipos1 = self.Pawn.Location;
			m_tiempo_tickp=0;
		}
		


		//Cada segundo, hacemos el control que hacía inicialmente la función BrainTimer
	
		//_DEBUG_DrawDebugCylinder(self.Pawn.Location,theObjective.Location,3,4,0,0,200,false);
		//_DEBUG_DrawDebugCylinder(self.Pawn.Location,nodotemporal.Location,3,4,200,0,200,false);
		//_DEBUG_DrawDebugSphere(theObjective.Location,25,10,0,0,200,false);

		if(m_tiempo_tick >=1.0)
		{
			m_tiempo_tick = 0;

			if(VSize(theBase.Location - Pawn.Location) < m_distancia_Base_kamikaze)
			{
				//Lo paramos, y lo enviamos al estado de ataque a la torre (TowerAttack)
				Velocity = vect(0,0,0);
				Acceleration = vect(0,0,0);
				self.pawn.Velocity = vect(0,0,0);
				self.pawn.Acceleration = vect(0,0,0);

				StopLatentExecution();
				GoToState('TowerAttack');
				return;
			}


			if (theObjective == None)
			{
				GoToState('Idle_Inicial');
				return;
			}


			// Comprobamos si hemos llegado al nodo y pedimos el siguiente punto de ruta
			distNodo = VSize(theObjective.Location - Pawn.Location);
			if(distNodo < 100)
			{
				theObjective = PGame(WorldInfo.Game).GetNextPath(id, NodeIndex);
				// Si tenemos objetivo, nos movemos a su posición
				if(theObjective != none)
				{
					nodotemporal = theObjective;
					theObjective = AplicarOffsetNodo(nodotemporal); //Para el pseudo-flocking
					GotoState('GoToNextPath'); //Autollamada al begin state para ir hacia el nuevo nodo
				}
				else
				{
					//No hay objetivo
					//Podríamos no hacer nada y esto se ejecutaría de nuevo al segundo.
					//Pero lo suyo es ir al estado Idle
					//`log("Idle al llegar al nodo");
					//_DEBUGDrawDebugSphere(self.Pawn.Location,25,5,255,255,255,true);
					//_DEBUG`log("Idle por no tener nodo after GetNextNode");
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
					if (m_segundosQuieto == 5)
					{
						m_segundosQuieto = 0;
						theObjective = PGame(WorldInfo.Game).GetNextPath(id, NodeIndex);
						if (theObjective != None)
						{
							nodotemporal = theObjective;
							theObjective = AplicarOffsetNodo(nodotemporal); //Para el pseudo-flocking
							//nodotemporal = none ; //Porque si no el garbage no se lo carga creo...
						}
						
					}
				}
				oldDistNodo = distNodo;
				GotoState('GoToNextPath');
			}

		} 
		//El control de proximidad para que se paren si chocan, no tenemos por qué hacerlo a cada tick:
		m_ticks_colegas_cerca = (m_ticks_colegas_cerca+1) %3 ;
		if (m_ticks_colegas_cerca == 0)
		{
			EstanLosColegasCercaNeng();
		}
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
		
		//_DEBUG `log("PEnemy_AI_BOT, ControlTakeDisparoGiru en GOTONEXTPATH REPETICIONES "@self.Name @repeti);
		//self.PushState('StopColision');
		ReboteRespectoA( None,vect(0,0,0),false,300);
		self.m_b_breakpoint = true;
	}
	
	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		//_DEBUG `log("PEnemy_AI_BOT, ControlTakeDisparoTurretCannon en GOTONEXTPATH"@self.Name);
	}

	function ControlTakeDisparoTurretIce(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		//_DEBUG `log("PEnemy_AI_BOT, ControlTakeDisparoTurretIce en GOTONEXTPATH"@self.Name);
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
	repeti++;
	if (theObjective != None)
	{
		//DBG WorldInfo.Game.Broadcast(self,Name$" va hacia el path"@theObjective.Name);

		// Esta función permite ponerle un rango para que el movimiento no sea siempre
		// en línea recta. El Pawn se moverá a cualquier punto dentro de las 100 unidades de radio
		// que le estamos indicando.
		//`log("Begin de GoToNextNode");
		 StopLatentExecution();
		 MoveToward(theObjective,theObjective,10,true,true);
		
		//VICTOR MoveToDirectNonPathPos (theObjective.Location,theObjective,10,true);
		
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

	//Todas las funciones sobreescribibles las dejamos vacías just in case
	function ContraBase() {}
	function ContraTorreta(Actor torreta, optional float dist=m_despContraTorreta){}
	function BumpContraSuelo(Actor suelo, vector HitNormal) {}
	
	event PoppedState()
	{
		//_DEBUG `log("_____ME PIRO__" @m_tiempo_tick);
		m_disparos_giru_congelado=0;
	}

	event Tick (float DeltaTime)
	{
		super.Tick(DeltaTime);
		self.Pawn.Velocity=vect(0,0,0);
		self.Pawn.Acceleration=vect(0,0,0);
		self.Velocity=vect(0,0,0);
		self.Acceleration=vect(0,0,0);

		if(m_tiempo_tick >= 4)
		{
			if(Pawn != None)
			{
				DesactivarPartCongelacion();
				if (PEnemy(Pawn).life > 0)
				{
					//Si sigue vivo, que siga caminando o lo que estuviera haciendo en el estado anterior
					m_tiempo_tickp=0;
					self.PopState();
				}
			}
		}
	}
	
	function ControlTakeDisparoTurretIce(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		//_DEBUG `log("PEnemy_AI_BOT, Ya estoy congelado, pa qué sufrir más?..."@self.Name);
		//Si ya está congelado, no vuelve a congelarse, simplemente lo ignoramos
		return;
	}

	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		//Sumamos 3 a los disparos recibidos mientras congelado, de forma que un disparo de turret cannon
		//en este estado, es como 3 disparos de Giru:
		m_disparos_giru_congelado += 3;
		if (m_disparos_giru_congelado > 5)
		{
			DesactivarPartCongelacion();
			GoToState('DeadAnyicos');
		}
	}

	function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		//_DEBUG `log("PEnemy_AI_BOT, ControlTakeDisparoGiru en Congelado"@self.Name);
		m_disparos_giru_congelado++;
		if (m_disparos_giru_congelado > 2) //COn 3 toques, rebentaos
		{
			DesactivarPartCongelacion();
			GoToState('DeadAnyicos');
		}
	}

	function ActivarPartCongelacion()
	{
		PEnemyPawn_Minion(self.Pawn).ActivarPartCongelacion();
	}

	function DesactivarPartCongelacion()
	{
		PEnemyPawn_Minion(self.Pawn).DesactivarPartCongelacion();
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
	//DEBUG_DrawDebugSphere(pawn.Location,80.0,20,255,255,255,true);
	//No modificamos sus variables de destino ni nada, así al volver al estado de GoToNextPath si es del que viene, seguirá
	//moviéndose hacia donde iba

    //Lanzo los sistemas de partículas de congelación
	ActivarPartCongelacion();
	PlaySound(PGame(WorldInfo.Game).SONIDOS_JUEGO.TocalaOtraVezSam(MINION_CONGELADO),,,true,self.Location);
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
	function ContraBase() {}
	function ContraTorreta(Actor torreta, optional float dist=m_despContraTorreta){}
	function BumpContraSuelo(Actor suelo, vector HitNormal) {}
	
	function ActivarPartDeadAnyicos()
	{
		local EmitterSpawnable part;
		part = Spawn(class'EmitterSpawnable',Self,,self.pawn.location,self.pawn.Rotation);
		part.SetTemplate(ParticleSystem'PGameParticles.Particles.P_Anyicos_Hielo');
		part.ParticleSystemComponent.SetActive(true);
	}


	event BeginState(name PreviousStateName)
	{
		//Sistema de partículas de cachos de hielo a saco.
		//_DEBUG `log("Soy un PEnemy_AI_Bot, y el puto Giru de los huevos me ha destruído");
		ActivarPartDeadAnyicos();
		SetCollision(false,false,false);
		PEnemyPawn_Minion(self.Pawn).DestruccionPorHielo();
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
		//_DEBUG `log("PEnemy_AI_BOT, ControlTakeDisparoGiru en StopColision "@self.Name);
		self.m_b_breakpoint = true;
	}

	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser){}
	function ControlTakeDisparoTurretIce(vector HitLocation, vector Momentum, Actor DamageCauser){}
	
	function ContraTorreta(Actor torreta,optional float dist)
	{
		//Lo ignoramos también. Si está quieto, sólo chocaría si algún otro le empujara...
		//y en breves instantes saldrá de este estado o sea que...
	}
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
		//_DEBUG `log("PEnemy_AI_BOT, ControlTakeDisparoGiru en TowerAttack"@self.Name);
	}
	
	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		//_DEBUG `log("PEnemy_AI_BOT, ControlTakeDisparoGiru en TowerAttack"@self.Name);
	}

	function ContraBase()
	{
		//_DEBUG `log ("Minion estonyao contra base "@self.Name);
		self.pawn.Destroy();
		self.Destroy();
	}

	function  ContraTorreta(Actor torreta, optional float dist=m_despContraTorreta)
	{
		if (PTree(torreta)!=None)
		{
			PTree(torreta).Destruccion();
		}

		if (PAutoTurret(torreta) != None)
		{
			PAutoTurret(torreta).Destruccion();
		}

	}

	
	
	event Tick(float delta)
	{
		local vector desp;
		local vector despues,antes;
		

		super.tick(delta);
		
		Velocity = vect(0,0,0);
		Acceleration = vect(0,0,0);
		Pawn.Velocity = vect(0,0,0);
		Pawn.Acceleration = vect(0,0,0);
		

		if 	(m_currentDespkamikaze >= vsize(locaKamikaze-locaKamikazeini)
			|| (m_tiempo_tick > m_tiempo_max_kamikaze) 	)
		{
			//_DEBUG_DrawDebugSphere(self.Pawn.Location,40,10,0,100,0,false);
			kamikaze();
		}
		else
		{
			desp = normal(locaKamikaze-self.pawn.location); //de donde estoy hasta el destino del toñazo
			//desp = (desp * 10* delta) / (1+m_tiempo_tick); //intento de desaceleración
			//desp = desp * 20 * (1/(1+m_tiempo_tick));
			desp = desp * 100 * delta ;
			antes = self.Pawn.Location;
			self.pawn.setLocation( self.Pawn.Location+ desp);
			despues = self.Pawn.Location;

			m_currentDespkamikaze += vsize(despues-antes);

			//_DEBUG `log("current desp "@self.Name @m_currentDespContraTorreta);
	
			//_DEBUG_DrawDebugSphere(self.Pawn.Location,40,10,32,63,63,false);
		}
		
	}


Begin:
	StopLatentExecution();
	m_tiempo_tick = 0;
	Velocity = vect(0,0,0);
   	Acceleration = vect(0,0,0);
	Pawn.Velocity = vect(0,0,0);
	Pawn.Acceleration = vect(0,0,0);
	StopLatentExecution();
	//_DEBUG	DrawDebugSphere(pawn.Location,80,60,100,0,100,false);
	PEnemyPawn_Minion(self.Pawn).activarParticulasKamikaze();
	locaKamikaze=ProyectarPuntoKamikaze();
	locaKamikazeini=pawn.Location;
	pawn.SetPhysics(PHYS_None);
	//pawn.SetPhysics(PHYS_Flying);
//	pawn.SetLocation(locaKamikaze);
	
	//MoveToDirectNonPathPos(locaKamikaze);
//	SetTimer(8,false,'kamikaze');
	//_DEBUG DrawDebugSphere(locaKamikaze,80,20,0,50,100,true);
	m_tiempo_tick=0;
	//self.pawn.GoToState('');
	m_currentDespkamikaze=0;
		

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
	m_distancia_Base_kamikaze=1700
	m_max_dist_disparo_ppawn=400
	m_timout_entre_disparos = 3
	m_ClaseMisil=class 'PMisilMinion'
	m_tiempo_max_kamikaze = 10
}
