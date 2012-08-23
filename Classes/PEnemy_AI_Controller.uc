class PEnemy_AI_Controller extends AIController;

var PPlayerBase theBase;    //Base objetivo de juego
var float m_tiempo_tick;    //Para control de tiempo. Actualizada en el tick global
var int id;                 //Id del spawner que lo cre�. Para identificar el scout y sus minions

var bool m_b_breakpoint; //Se pone a true al disparar con Giru, usado para poner un if y un breakpoint dentro, para
					     //poder debugar un bicho en concreto

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

	//Actualizaci�n de la rotaci�n del pawn que controlamos
	if (Pawn != None)
	{
		thePawn = PEnemy(Pawn);
		thePawn.ActualizaRotacion(DeltaTime);
		setRotation(thePawn.Rotation);
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
	`log("PEnemy_AI_Controller, recibido danyo Giru Global, DEBES SOBREESCRIBIRME!!!" @self.GetStateName());
	m_b_breakpoint = true; //Para poder poner un breakpoint en un if (m_b_breakpoint), y s�lo se parar� si
						   //has disparado a ese PEnemy
}

function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser)
{
	`log("PEnemy_AI_Controller, recibido danyo TurretCannon Global, DEBES SOBREESCRIBIRME!!!");
}

function ControlTakeDisparoTurretIce(vector HitLocation, vector Momentum, Actor DamageCauser)
{
	`log("PEnemy_AI_Controller, recibido danyo TurretIce Global, DEBES SOBREESCRIBIRME!!!");
}


function Control_BaseChangedPenemy(Actor PEnemyOtro)
{
	//`log("PEnemy_AI_Controller::Control_BaseChangedPenemy, DEBES SOBREESCRIBIRME!!!");
	
}

DefaultProperties
{
	
	m_tiempo_tick=0
}
