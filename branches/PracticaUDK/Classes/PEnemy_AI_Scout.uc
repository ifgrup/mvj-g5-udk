class PEnemy_AI_Scout extends PEnemy_AI_Controller;

var Actor thePlayer;
var Actor theObjective;
var vector OldLocation;
var vector OldDecalLocation;


var int OffX, OffY;
var int OffsetX, OffsetY;
var int Step;
var array<PWorldPathNode> ListaNodosRecorridos;
var DecalMaterial Decal;
var MaterialInstanceConstant Mat;
var LinearColor ColorDecal;

var int id_Path;
var float DestinationOffset;

var Actor m_Destination; //Siguiente nodo destino al que nos dirijimos
var vector m_CurrentDestination; //Posición de m_Destination
var float distanciaBase_antes;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	theObjective = PGame(WorldInfo.Game).PlayerBase;
	
	ColorDecal = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);

	Mat = new class'MaterialInstanceConstant';
	Mat.SetParent(MaterialInstanceConstant'Materiales.Decals.DecalSuelo1_INST');
	Mat.SetVectorParameterValue('Color', ColorDecal);
	/*Mat.SetScalarParameterValue('R', ColorDecal.R);
	Mat.SetScalarParameterValue('G', ColorDecal.G);
	Mat.SetScalarParameterValue('B', ColorDecal.B);*/

	/*Nos asignamos uno de los caminos posibles*/
	id_Path = PGame(WorldInfo.Game).ObtenerIdNodosMundo();

	//SetTimer(1, false, 'BrainTimer');
}

function SetColor(LinearColor Col)
{
	ColorDecal = Col;
	Mat.SetVectorParameterValue('Color', ColorDecal);
}


function DrawDebugInfo()
{
	DrawDebugLine(Pawn.Location, m_CurrentDestination, 0, 255, 0, false);
	DrawDebugSphere(m_CurrentDestination, 20, 20, 0, 255, 0, false);
}

function  NextPath()
{
	local array<PWorldPathNode> pWNodos;
	local int i;
	local int j;
	local float distancia, tmp;

	// busco el más cercano
	pWNodos = PGame(WorldInfo.Game).ObtenerNodosMundo(id_Path);
	
	j = 0;
	distancia = 100000;

	for(i = 0; i < pWNodos.Length; ++i)
	{
		tmp = VSize(pWNodos[i].Location - Pawn.Location);
		if(distancia > tmp && pWNodos[i].id == id_Path)
		{
			distancia = tmp;
			j = i;
		}
	}

	// me lo asigno
	PGame(WorldInfo.Game).Broadcast(self, "Voy hacia el nodo "@pWNodos[j].Name);
	DrawDebugSphere(pWNodos[j].Location, 500, 10, 0, 255, 0, true);
	m_Destination = pWNodos[j];
	m_CurrentDestination = m_Destination.Location;
	//Y lo elimino para que no podamos volver a asignarnos el mismo nodo ;)
	PGame(WorldInfo.Game).DeleteWorldPathNode(id_Path, j);
}

/* --------------- ESTADO IDLE_INICIAL --------------
 * --- Empieza en este estado, y cuando el Pawn recién creado llega al suelo, pasamos al estado inicial
 */
auto state Idle_Inicial
{
	event BeginState(Name PrevName)
	{
		`log("Penemy_AI_Scout creado, estoy en Idle");
		m_tiempo_tick = 0;
	}

	event Tick(float Deltatime)
	{
		//Debemos permanecer en este estado mientras el pawn esté cayendo,
		//y no tengamos nodo del path a seguir.
		//Lo comprobamos cada segundo
		super.Tick(Deltatime);
		if (m_tiempo_tick >= 1.0)
		{
			m_tiempo_tick -= 1.0; //para el siguiente 'timer'
			if (!Penemy(Pawn).IsInState('Cayendo'))
			{
				//ya ha llegado al suelo
				NextPath(); //Busca el nodo más cercano, lo guarda en m_Destination,
							//y lo borra de la lista de nodos para no volver a dirigirse a él
			
				//Y nos vamos al estado que nos dirije a ese nodo m_Destination
				GotoState('MoveToDestination');
				
			}
		}//if >1 segundo
	}//Tick

	function RecibirDanyo(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
	{
		`log("SCOUT::RecibirDanyo en estado IdleInicial");
	}

	event EndState(name NextStateName)
	{
		`log("Penemy_AI_Scout saliendo de idle");
	}
}/* --------------- FIN ESTADO IDLE_INICIAL --------------*/
//____________________________________________________________________________________________________________________________________


/* --------------- ESTADO MOVETODESTINATION --------------
 * --- El scout va avanzando hasta al siguiente nodo, y si se acerca lo suficiente a la base, hacia la base directo
 */
state MoveToDestination
{
	event Tick(float DeltaTime)
	{
		local Pawn pDetectado;
		local PPathNode nodo;
		local float distanciaBase;


		DrawDebugInfo();
		super.Tick(DeltaTime);

		if (pawn.Velocity == vect(0,0,0) && m_Destination == theObjective)
		{
			//`log("S'ha parao no sé por què");
			DrawDebugSphere(pawn.Location,200,20,200,0,0,false);
		}

		//Cada fDecalSize distancia, dejamos un decal
		if(VSize(OldDecalLocation - Pawn.Location) > (PGame(WorldInfo.Game).fDecalSize))
		{
			OldDecalLocation = Pawn.Location;
			WorldInfo.MyDecalManager.SpawnDecal
			(
				Mat,
				Pawn.Location,
				rotator(-Pawn.Floor),
				PGame(WorldInfo.Game).fDecalSize, PGame(WorldInfo.Game).fDecalSize,
				PGame(WorldInfo.Game).fDecalSize,
				true,
				0,,,,,,,100000
			);
		}
		
		/*******************************************************
		 * ***************************************************** 
		 * P E N D I E N T E   C O N F I R M A R   L U I S 
		 * ********************************************************
		foreach Pawn.OverlappingActors(class'Pawn', pDetectado, 200,,true)
		{
			// Me aseguro que no me estoy detectando a mi mismo
			if(pDetectado != Pawn)
			{
				//DBG WorldInfo.Game.Broadcast(self, Name@"Ha chocado con"@pDetectado.Name);
				//DBG DrawDebugSphere(pDetectado.Location, 200, 10, 255, 0, 0, false);
				GotoState('MoveToDestination');
			}
		}
		**************************************************************
		* ************************************************************/

		//Vamos guardando los puntos por donde vamos pasando con AddPathNode
		if(VSize(OldLocation - Pawn.Location) > (Step/4))
		{
			nodo = spawn(class'PPathNode',,,Pawn.Location);
			nodo.id = id;
			PGame(WorldInfo.Game).AddPathNode(id, nodo, ColorDecal);
			
			OldLocation = Pawn.Location;
		}

		//Control de llegada a nodo y/o Base
		if (m_tiempo_tick >= 1.0)
		{
			m_tiempo_tick -= 1.0; //reset del tiempo para el siguiente 'timer'
			
			//Hemos llegado a la base?
			distanciaBase = VSize(theObjective.Location - Pawn.Location);
			`log("Distancia Base "@self.Name @distanciaBase);
			if (distanciaBase == distanciaBase_antes)
			{
				`log("Ta kieto!!");
			}
			distanciaBase_antes = distanciaBase;
			if(distanciaBase < Step)
			{
				Pawn.Velocity = vect(0,0,0);
				GotoState('ArrivedDestination');
			}
			//Si estamos cerca de la base, no vamos al siguiente nodo, sino directamente contra la base
			else if(VSize(theObjective.Location - Pawn.Location) < Step * 4)
			{
				//Si no está yendo ya hacia el objetivo...
				if (m_Destination != theObjective)
				{
					m_Destination = theObjective;
					`log("Voy directo para la base, velocidad "@Pawn.Velocity);
					m_CurrentDestination = m_Destination.Location;
					GoToState ('MoveToDestination');
				}
			}
			//Si no, controlamos si estamos cerca del siguiente nodo,y si es así, 
			//vamos hacia el siguiente
			else if(VSize(m_CurrentDestination - Pawn.Location) < DestinationOffset)
			{
				NextPath();
				GoToState ('MoveToDestination');
			}
		}//m_tiempo_tick >= 1.0
	}//Tick

Begin:
	m_tiempo_tick = 1.0; //Para que en el primer tick ya evalúe, y así cuando encontramos un nuevo destino,no hace parada, sino que
						 //directamente parece que sepa a dónde va
	if (m_Destination != None)
	{
		if (m_Destination != theObjective)
		{
			MoveToward(m_Destination,,DestinationOffset/2, false, true);
		}
		else //No sabemos por qué, el UDK aquí si poníamos MoveToward no movía al bicho....
		{
			MoveTo(m_Destination.Location,m_Destination,100,true);
		}
	}
}/* --------------- FIN ESTADO MOVETODESTINATION --------------*/
//____________________________________________________________________________________________________________________________________

/* --------------- ESTADO ArrivedDestination --------------
 * --- El scout ha llegado a la BASE, y puede empezar el ataque
 */
state ArrivedDestination
{
	event BeginState(name PreviousStateName)
	{
		PGame(WorldInfo.Game).PlayerBase.pupitabase();
		`log("SCOUT LLEGADO A BASE!!!   vida de la base" @PGame(WorldInfo.Game).PlayerBase.life);
		//DBG WorldInfo.Game.Broadcast(self, Name@" ha llegado a destino");
		Pawn.Acceleration = vect(0,0,0);
		Pawn.Velocity = vect(0,0,0);
		StopLatentExecution();
	}
}/* --------------- FIN ESTADO ArrivedDestination --------------*/
//____________________________________________________________________________________________________________________________________


defaultproperties
{
	Step=1000
	id_Path=0
	DestinationOffset=200;
}
