class PEnemy_AI_Bot extends PEnemy_AI_Controller;

var PPathNode theObjective; //Siguiente nodo al que van
var int NodeIndex;
var bool bParado;
var int Step;   //Distancia mínima para considerar que no ha llegado a la base
var bool bPrimeraVez;
var PEmiter m_pEmiter; //Para poder mostrar las partículas de congelación
var int m_disparos_giru_congelado;//Disparos de giru recibidos mientras estoy congelado
/**
 * Inicializamos el objetivo principal 
 */
simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	//SetTimer(3, true, 'BrainTimer');
}


/* --------------- ESTADO IDLE_INICIAL --------------
 * --- Empieza en este estado, y cuando el Pawn recién creado llega al suelo, pasamos al estado inicial
 */
auto state Idle_Inicial
{
	event BeginState(Name PrevName)
	{
		`log("Penemy_AI_Bot creado, estoy en Idle");
		m_tiempo_tick = 0;
	}

	event Tick(float Deltatime)
	{
		//Debemos permanecer en este estado mientras el pawn esté cayendo,
		//y no tengamos nodo objetivo.
		//Lo comprobamos cada segundo
		super.Tick(Deltatime);
		if (m_tiempo_tick >= 1.0)
		{
			m_tiempo_tick = 0; //para el siguiente 'timer'
			if (!Penemy(Pawn).IsInState('Cayendo'))
			{
				//ya ha llegado al suelo
				theObjective = PGame(WorldInfo.Game).GetNextPath(id, NodeIndex);
				if(theObjective != none)
				{
					//Tenemos objetivo. Podemos ir al siguiente estado
					`log("En idle, tengo nodo nuevo y me voy");
					GotoState('GoToNextPath');
				}
			}
		}//if >1 segundo
	}//Tick

	function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en IDLE"@self.Name);
	}
	
	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en IDLE"@self.Name);
	}


}/* --------------- FIN ESTADO IDLE_INICIAL --------------*/
//____________________________________________________________________________________________________________________________________

/* --------------- ESTADO GOTONEXTPATH --------------
 * --- Estado en el que nos movemos hacia el siguiente punto de ruta.
 * --  Tiene que hacerse con la etiqueta Begin y tal porque el MoveToward es ejecución latente, y si no no te deja...
*/

state GoToNextPath
{
	event Tick (float DeltaTime)
	{
		super.Tick(DeltaTime);
		//Cada 3 segundos, hacemos el control que hacía inicialmente la función BrainTimer
		if(m_tiempo_tick >=3.0)
		{
			m_tiempo_tick = m_tiempo_tick - 3.0; //Por intentar autoajustar un poco y que no siempre sea 3s y pico
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
			if(VSize(theObjective.Location - Pawn.Location) < 100)
			{
				theObjective = PGame(WorldInfo.Game).GetNextPath(id, NodeIndex);
				// Si tenemos objetivo, nos movemos a su posición
				if(theObjective != none)
				{
					//`log("Nuevo nodo seleccionado, voy palla");
					GotoState('GoToNextPath'); //Autollamada al begin state para ir hacia el nuevo nodo
				}
				else
				{
					//No hay objetivo
					//Podríamos no hacer nada y esto se ejecutaría de nuevo a los 3 segundos.
					//Pero lo suyo es ir al estado Idle
					//`log("Idle al llegar al nodo");
					GoToState('Idle_Inicial');
				}
			}
			else
			{
				//Igualmente hay que decirle que siga para alante hacia donde iba:
				GotoState('GoToNextPath');
			}

		}   
	}//Tick

	function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en GOTONEXTPATH"@self.Name);
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


Begin:
	m_tiempo_tick = 0;
	if (theObjective != None)
	{
		//DBG WorldInfo.Game.Broadcast(self,Name$" va hacia el path"@theObjective.Name);

		// Esta función permite ponerle un rango para que el movimiento no sea siempre
		// en línea recta. El Pawn se moverá a cualquier punto dentro de las 100 unidades de radio
		// que le estamos indicando.
		//`log("Begin de GoToNextNode");
		MoveToward(theObjective,theObjective,10,true,true);
		
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

}/* ---------------FIN ESTADO TOWER_ATTACK --------------*/
//____________________________________________________________________________________________________________________________________

defaultproperties
{
	theObjective=none
	NodeIndex=0
	Step=400
	bPrimeraVez=true
}
