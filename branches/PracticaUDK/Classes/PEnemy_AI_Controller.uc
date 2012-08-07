class PEnemy_AI_Controller extends AIController;

var PPlayerBase theBase;    //Base objetivo de juego
var float m_tiempo_tick;    //Para control de tiempo. Actualizada en el tick global
var int id;                 //Id del spawner que lo creó. Para identificar el scout y sus minions

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
 * Función genérica de RecibirDanyo, llamada desde los pawns en su TakeDamage.
 * Lo hacemos así para no tener que duplicar estados en los Pawns. Cada Pawn, en su takeDamage, llama a esta función
 * directamente con los mismos parámetros, y la gestión del daño la hace el controller, sobreescribiendo esta función en cada uno
 * de sus estados
 */
function RecibirDanyo(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	`log("RecibirDanyo Global");
}


DefaultProperties
{
	
	m_tiempo_tick=0
}
