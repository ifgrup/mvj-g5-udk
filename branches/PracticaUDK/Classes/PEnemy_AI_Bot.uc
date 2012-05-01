class PEnemy_AI_Bot extends AIController;

var PPlayerBase theBase;
var PPathNode theObjective;
var int id;
var int NodeIndex;
var bool bParado;
var int Step;
var bool bPrimeraVez;

/**
 * Inicializamos el objetivo principal e iniciamos el timer
 */
simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	
	theBase = PGame(WorldInfo.Game).PlayerBase;

	SetTimer(3, true, 'BrainTimer');
}

/**
 * Ponemos el identificador de este Explorador. Debe ser el mismo que el del Spawner que lo generó
 * */
function SetID(int i)
{
	id = i;
}

/**
 * Función que ejecuta el timer.
 * */
function BrainTimer()
{
	
	if(bPrimeraVez == true)
	{
		bPrimeraVez = false;
		theObjective = PGame(WorldInfo.Game).GetNextPath(id, NodeIndex);
	}

	// Comprobamos si hemos llegado al destino
	if(VSize(theBase.Location - Pawn.Location) < Step)
	{
		Velocity = vect(0,0,0);
		Acceleration = vect(0,0,0);
		StopLatentExecution();
	}

	// Actualizamos el objetivo, pidiéndole al juego un nuevo punto de ruta
	if(VSize(theObjective.Location - Pawn.Location) < 100)
	{
		theObjective = PGame(WorldInfo.Game).GetNextPath(id, NodeIndex);
	}

	// Si tenemos objetivo, nos movemos a su posición
	if(theObjective != none)
	{
		GotoState('GoToNextPath');
	}

	// Si no tenemos objetivo, esperamos a que se genere uno nuevo.
	if(theObjective == none)
	{
		NodeIndex--;
		GotoState('Idle');
	}
}

// Esperamos :)
function Wait()
{
	ClearTimer('Wait');
	theObjective = PGame(WorldInfo.Game).GetNextPath(id, NodeIndex);
	if(theObjective == none)
	{
		NodeIndex--;
		GotoState('Idle');
	}
	SetTimer(1, true, 'BrainTimer');
}

// Estado de espera... en este tiempo se tendría que generar un nuevo punto de ruta
state Idle
{

Begin:
	ClearTimer('BrainTimer');
	SetTimer(1, true, 'Wait');
}

/**
 * Estado en el que nos movemos hacia el siguiente punto de ruta.
 */
state GoToNextPath
{
Begin:
	if (theObjective != None)
	{
		WorldInfo.Game.Broadcast(self,Name$" va hacia el path"@theObjective.Name);

		// Esta función permite ponerle un rango para que el movimiento no sea siempre
		// en línea recta. El Pawn se moverá a cualquier punto dentro de las 100 unidades de radio
		// que le estamos indicando.
		MoveToward(theObjective,,10,true,true);
	}
}

defaultproperties
{
	NodeIndex=0
	Step=400
	theObjective=none
	bPrimeraVez=true
}
