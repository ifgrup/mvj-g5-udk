class PEnemy_AI_Bot extends PEnemy_AI_Controller;

var PPathNode theObjective; //Siguiente nodo al que van
var int NodeIndex;
var bool bParado;
var int Step;   //Distancia mínima para considerar que no ha llegado a la base
var bool bPrimeraVez;

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

	function RecibirDanyo(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
	{
		`log("RecibirDanyo en estado IdleInicial");
	}

	event EndState(name NextStateName)
	{
		`log("Penemy_AI_Bot saliendo de idle");
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

		}   
	}//Tick

	function RecibirDanyo(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
	{
		`log("RecibirDanyo en estado GoToNextPath");
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

/* --------------- ESTADO TOWER_ATTACK --------------
 * --- Estado en el que nos estamos cerca de la torre Base, y atacamos a lo borrico.
 */

state TowerAttack
{

	function RecibirDanyo(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
	{
		`log("RecibirDanyo en estado TowerAttack");
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
