class PEnemy_AI_Bot extends PEnemy_AI_Controller;

var PPathNode theObjective; //Siguiente nodo al que van
var PPathNode nodotemporal; //Para guardar el de antes de aplicar el offset
var int NodeIndex;
var bool bParado;
var int Step;   //Distancia m�nima para considerar que no ha llegado a la base
var bool bPrimeraVez;
var PEmiter m_pEmiter; //Para poder mostrar las part�culas de congelaci�n
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
			continue; //Pasa, no s� en qu� circunstancias...

		if (colegas[i] == PEnemy(self.Pawn))
			continue;

		distcolega = vsize(colegas[i].Location-self.pawn.Location);
		if (distcolega < m_dist_choque_Minion)
		{
			distscoutmio    = vsize(self.Pawn.Location-elscout.Pawn.Location);
			distscoutcolega = vsize(colegas[i].Location-elscout.Pawn.Location);
			//Si yo estoy m�s lejos, me paro y hago un break para no comparar con nadie m�s
			if (distscoutmio > distscoutcolega)
			{   
				Parar();
				//DrawDebugSphere(self.Pawn.Location,80,10,0,0,255,true);
				break; //no tengo que comparar con nadie m�s, ya me he parado
			}

		}
	}
}


/*Desplazamos el pawn en la direcci�n contraria a la velocidad que llevaba, y punto, y aplicamos toque a la torreta*/
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

	//Y al �rbol (SI, lo se. Tendr�amos que haber hecho que torretas y �rboles heredaran de lo mismo...
	if (PTree(torreta) != None)
	{
		`log("Minion contra arbol" @self.Name);
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
	

		if (vsize(self.theBase.Location-self.Pawn.Location) < m_distancia_Base_kamikaze)
        {
			
			GetAxes (self.theBase.Rotation,rx,ry,rz);
			posenemigo = self.theBase.Location + rz*450; //Por no poner un socket en la casa
        }
		else
		{
			if (vsize(PGame(WorldInfo.Game).GetALocalPlayerController().Pawn.Location-self.Pawn.Location) < m_distancia_Base_kamikaze)
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



		//lanzamos to�azo kamikaze

		Proj = Spawn(class'PMisiles',self,,self.Pawn.Location,,,True);
		if (Proj!= None)
		{
			Proj.Init(Normal(posenemigo-self.Pawn.Location));
			self.Pawn.Destroy();
			self.Destroy();
		
		}	

	}




/* --------------- ESTADO IDLE_INICIAL --------------
 * --- Empieza en este estado, y cuando el Pawn reci�n creado llega al suelo, pasamos al estado inicial
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
		//Debemos permanecer en este estado mientras el pawn est� cayendo,
		//y no tengamos nodo objetivo.
		//Lo comprobamos cada segundo
		local vector antes,despues;

		super.Tick(Deltatime);

		
			if(VSize(theBase.Location - Pawn.Location) < m_distancia_Base_kamikaze)
			{
				//Lo paramos, y lo enviamos al estado de ataque a la torre (TowerAttack)
				Velocity = vect(0,0,0);
				Acceleration = vect(0,0,0);
				self.pawn.Velocity = vect(0,0,0);
				self.pawn.Acceleration = vect(0,0,0);

				StopLatentExecution();
				GoToState('TowerAttack');
			}


		if (m_tiempo_tick >= 1.0)
		{
			m_intentos_nuevo_nodo++;
			if (m_b_breakpoint)
			{
				m_b_breakpoint = true;
			}
			m_tiempo_tick = 0; //para el siguiente 'timer'
 
			if (vsize(self.theBase.Location-self.Pawn.Location) < m_distancia_Base_kamikaze)
            {
				 GoToState('TowerAttack');
				 return;
            }

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
				{ //La �nica forma de que GetNextPath devuelva none, a falta de unexpected errors, es que estemos en el �ltimo nodo
				  //Si es as�, es porque no le hemos dado tiempo al scout, o porque hemos llegado a la base. Lo comprobamos
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

	function BumpContraSuelo(Actor suelo,Vector HitNormal)
	{
		PEnemy(self.Pawn).AterrizadoAfterSpawn();
	}

	function ContraTorreta(Actor torreta, optional float dist)
	{
		`log("_ignorado to�azo mientras cayendo "@self.Name);
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
 * --  Tiene que hacerse con la etiqueta Begin y tal porque el MoveToward es ejecuci�n latente, y si no no te deja...
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
		local vector antes,despues;

		super.Tick(DeltaTime);
		if (m_b_breakpoint)
		{
			//_DEBUG_DrawDebugSphere(self.Pawn.Location,35,20,0,0,0,false);
		}
		if(VSize(theBase.Location - Pawn.Location) < m_distancia_Base_kamikaze)
		{
			//Lo paramos, y lo enviamos al estado de ataque a la torre (TowerAttack)
			Velocity = vect(0,0,0);
			Acceleration = vect(0,0,0);
			self.pawn.Velocity = vect(0,0,0);
			self.pawn.Acceleration = vect(0,0,0);

			StopLatentExecution();
			GoToState('TowerAttack');
		}

		if(m_tiempo_tickp >1)
		{
			minionpqpipos1=self.Pawn.Location;
		}

		if(m_tiempo_tickp >30)
		{
			minionpqpipos2=self.Pawn.Location;
  			dpqpi=vsize(minionpqpipos1-minionpqpipos2);

			if(dpqpi==0)
			{
				DrawDebugSphere(self.Pawn.Location,35,20,250,0,0,false);
				
				Velocity = vect(0,0,0);
				Acceleration = vect(0,0,0);
				self.pawn.Velocity = vect(0,0,0);
				self.pawn.Acceleration = vect(0,0,0);

				StopLatentExecution();
				GoToState('TowerAttack');
			}

			m_tiempo_tickp=0;
		}
		


		//Cada segundo, hacemos el control que hac�a inicialmente la funci�n BrainTimer
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
			if(VSize(theBase.Location - Pawn.Location) < m_distancia_Base_kamikaze)
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
				// Si tenemos objetivo, nos movemos a su posici�n
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
					//Podr�amos no hacer nada y esto se ejecutar�a de nuevo al segundo.
					//Pero lo suyo es ir al estado Idle
					//`log("Idle al llegar al nodo");
					//_DEBUGDrawDebugSphere(self.Pawn.Location,25,5,255,255,255,true);
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
					if (m_segundosQuieto == 10)
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
							//_DEBUGDrawDebugSphere(self.Pawn.Location,25,5,255,255,255,true);
							`log("Idle por no tener nodo after quieto");
							GoToState('Idle_Inicial');
						}
					}
				}
				oldDistNodo = distNodo;
				GotoState('GoToNextPath');
			}

		} 
		//El control de proximidad para que se paren si chocan, no tenemos por qu� hacerlo a cada tick:
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
		
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en GOTONEXTPATH REPETICIONES "@self.Name @repeti);
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
		//Hay que congelar al bicho, que se quede quieto, salga el sistema de part�culas del hielo
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

		// Esta funci�n permite ponerle un rango para que el movimiento no sea siempre
		// en l�nea recta. El Pawn se mover� a cualquier punto dentro de las 100 unidades de radio
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
 * --  Estaremos congelados un tiempo, durante el cual, si recibimos m�s de 7 disparos de Giru, o bien 3 de una torreta
 * --  Nos romperemos en mil pedazos
*/
state Congelado
{
	event Tick (float DeltaTime)
	{
		super.Tick(DeltaTime);
		
		//m_pEmiter se destuir� s�lo de momento...cuando lo haga
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
		`log("PEnemy_AI_BOT, Ya estoy congelado, pa qu� sufrir m�s?..."@self.Name);
		//Si ya est� congelado, no vuelve a congelarse, simplemente lo ignoramos
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

	//pawn.bCollideActors = false; //Para que el sistema de part�culas
	//DEBUG_DrawDebugSphere(pawn.Location,80.0,20,255,255,255,true);
	//No modificamos sus variables de destino ni nada, as� al volver al estado de GoToNextPath si es del que viene, seguir�
	//movi�ndose hacia donde iba

    //Lanzo los sistemas de part�culas de congelaci�n
	m_pEmiter=Spawn(class'PEmiter',self,,pawn.Location,pawn.Rotation,,true);
	m_pEmiter.m_tiempoHielo += rand(2) - rand(2); //Random +- 2 segundos para que no todos sean iguales
	m_pEmiter.SpawnEmitter();
}/* ---------------FIN ESTADO CONGELADO --------------*/
//____________________________________________________________________________________________________________________________________

/* --------------- ESTADO DEAD_ANYICOS --------------
 * --- Est�bamos congelados, y el puto Giru nos ha disparado 400 veces, as� que rebentamos en cachitos de hielo
 */

state DeadAnyicos
{
	ignores TakeDamage,SeePlayer,Bump,Touch,BaseChange;

	//Todas las funciones sobreescribibles las dejamos vac�as just in case
	function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser){}
	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser){}
	function ControlTakeDisparoTurretIce(vector HitLocation, vector Momentum, Actor DamageCauser){}
	

	event BeginState(name PreviousStateName)
	{
		//Sistema de part�culas de cachos de hielo a saco.
		`log("Soy un PEnemy_AI_Bot, y el puto Giru de los huevos me ha destru�do");
		self.Destroy();
		self.Pawn.Destroy();
	}


}/* ---------------FIN ESTADO TOWER_ATTACK --------------*/
//__________________



/* --------------- ESTADO STOP_COLISION --------------
 * --- Est�bamos andando, hemos hecho BaseChange contra otro coleguilla, espermos 1 segundo
 */

state StopColision
{
	//Todas las funciones sobreescribibles las dejamos vac�as just in case
	function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en StopColision "@self.Name);
		self.m_b_breakpoint = true;
	}

	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser){}
	function ControlTakeDisparoTurretIce(vector HitLocation, vector Momentum, Actor DamageCauser){}
	
	function ContraTorreta(Actor torreta,optional float dist)
	{
		//Lo ignoramos tambi�n. Si est� quieto, s�lo chocar�a si alg�n otro le empujara...
		//y en breves instantes saldr� de este estado o sea que...
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
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en TowerAttack"@self.Name);
	}
	
	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en TowerAttack"@self.Name);
	}

	function ContraBase()
	{
		`log ("Minion estonyao contra base "@self.Name);
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
		

		super.tick(delta);
		
		Velocity = vect(0,0,0);
		Acceleration = vect(0,0,0);
		Pawn.Velocity = vect(0,0,0);
		Pawn.Acceleration = vect(0,0,0);
		

		if 	(m_currentDespkamikaze >= vsize(locaKamikaze-locaKamikazeini)
			|| (m_tiempo_tick > m_tiempo_max_kamikaze) 	)
		{
			DrawDebugSphere(self.Pawn.Location,40,10,0,100,0,false);
			kamikaze();
		}
		else
		{
			desp = normal(locaKamikaze-self.pawn.location); //de donde estoy hasta el destino del to�azo
			//desp = (desp * 10* delta) / (1+m_tiempo_tick); //intento de desaceleraci�n
			//desp = desp * 20 * (1/(1+m_tiempo_tick));
			desp = desp * 100 * delta ;
	
			self.pawn.setLocation( self.Pawn.Location+ desp);
			m_currentDespkamikaze += vsize(desp);
			//_DEBUG `log("current desp "@self.Name @m_currentDespContraTorreta);
	
			DrawDebugSphere(self.Pawn.Location,40,10,32,63,63,false);
		}
		
	}

/*
event EndState(name NextStateName)
	{
		`log ("_**********************_____EEEE_____ saliendo de kamikaze");
	}
	event PoppedState()
	{
			`log("_____******************__PPPPPPPPPPPP___ saliendo de kamikaze");
	}

*/
Begin:
	StopLatentExecution();
	m_tiempo_tick = 0;
	Velocity = vect(0,0,0);
   	Acceleration = vect(0,0,0);
	Pawn.Velocity = vect(0,0,0);
	Pawn.Acceleration = vect(0,0,0);
	StopLatentExecution();
	DrawDebugSphere(pawn.Location,80,60,100,0,100,false);
	//PEnemyPawn_Minion(self.Pawn).activarParticulasKamikaze();
	locaKamikaze=ProyectarPuntoKamikaze();
	locaKamikazeini=pawn.Location;
	pawn.SetPhysics(PHYS_None);
	//pawn.SetPhysics(PHYS_Flying);
//	pawn.SetLocation(locaKamikaze);
	
	//MoveToDirectNonPathPos(locaKamikaze);
//	SetTimer(8,false,'kamikaze');
	DrawDebugSphere(locaKamikaze,80,20,0,50,100,true);
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
