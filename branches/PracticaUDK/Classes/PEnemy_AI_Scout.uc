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
var bool m_bBreakpoint;
var float oldDistNodo;
var int m_segundosQuieto;
var float m_radio_escudo; //Radio de acción del escudo de los minions
var float m_escudo; //cantidad de escudo proporcionada por los minions
var float m_DistanciaAtaqueBase; //Distancia a la que considera que ha llegado a la base

struct EscudoInfo
{
	var PEnemyPawn_Minion Pawn;
	var bool DeleteMe;
};
var array<EscudoInfo> m_escudo_info;


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

	/*Timer para gestión del escudo proporcionado por los minions*/
	SetTimer(0.3, true, 'GestionEscudo');
	
}

function GestionEscudo()
{
	local PEnemyPawn_Minion	helper;
	local GamePawn GP;
	local int escudo_actual;
	local int i,Index;
	local EscudoInfo escudo;
	local bool bira; //Hay que activar ira o no, es decir, está cerca o no el PPawn
	local LinearColor colorescudo; 
	escudo_actual = 0;
	colorescudo=MakeLinearColor(0, 0, 0, 1.0);
	bira=false;
	//Marco todos como borrables inicialmente
	for (i = 0; i < self.m_escudo_info.Length; i++)
	{
		m_escudo_info[i].DeleteMe = true;
	}

	//__DEBUG__DrawDebugSphere(self.Pawn.Location,m_radio_escudo,20,0,200,200,false);
	foreach CollidingActors(class'GamePawn', GP, m_radio_escudo,self.Pawn.Location)//,,,,, HitInfo )
	{
		if(PEnemyPawn_Minion(GP)!=none)
		{
			helper=PEnemyPawn_Minion(GP);
		
			if (Penemy_AI_Bot(helper.Owner).id == self.id)
			{
			
				helper.activarEscudoScout(PEnemyPawn_Scout(self.Pawn),m_radio_escudo);
			
				Index = m_escudo_info.Find('Pawn', helper);
				if (Index == INDEX_NONE && helper.life> 0)
				{

					escudo.Pawn = helper;
					escudo.DeleteMe = false;
					m_escudo_info.AddItem(escudo);
					/*
					i = m_escudo_info.Length;
					m_escudo_info.Length = m_escudo_info.Length + 1;
					m_escudo_info[i].Pawn = helper;
					m_escudo_info[i].DeleteMe = false;
					*/
				}
				else
				{
					m_escudo_info[Index].DeleteMe = false;
				}
			}
		}
		
		//Gestión de ira de Scout utilizando el foreach del escudo
		if(PPawn(GP)!=none)
		{
			bira=true;
		
		}
		
		

	}

	for (i=0; i< m_escudo_info.Length;i++)
	{
		if (m_escudo_info[i].DeleteMe)
		{
			if (m_escudo_info[i].Pawn != none) //Puede haber muerto
			{
				m_escudo_info[i].Pawn.desactivarEscudoScout();
			}
			m_escudo_info[i].Pawn = none; //GC
			m_escudo_info.Remove(i,1);
			i--; //ÑAAAAAAAAAPAAAAAAAAAAAAAAAAAAA!!!
		}
		else
		{
			escudo_actual ++;
		}
	}

	m_escudo = escudo_actual;
	//_DEBUG_`log("Escudo del scout "@self.Name @m_escudo);
	
	PEnemyPawn_Scout(self.Pawn).GestionIra(bira); //SI ira es true, aumentará, si es false, disminuirá

	NubeDeIraSobrePawn(); //Activar Nube encima de Giru en función del tamaño de la ira.

	if(m_escudo>0)
	{
		colorescudo.R=PEnemyPawn_Scout(self.Pawn).Col2.R;
		colorescudo.G=PEnemyPawn_Scout(self.Pawn).Col2.G;
		colorescudo.B=PEnemyPawn_Scout(self.Pawn).Col2.B;
		colorescudo.A=1*m_escudo;

		PEnemyPawn_Scout(self.Pawn).escudo.Mesh.SetScale(CLAMP(m_escudo,6,10));
		PEnemyPawn_Scout(self.Pawn).escudo.ShieldMIC.SetVectorParameterValue('Color',colorescudo);

		
	}
	else
	{
		colorescudo.R=0;
		colorescudo.G=0;
		colorescudo.B=0;
		colorescudo.A=0;
		PEnemyPawn_Scout(self.Pawn).escudo.ShieldMIC.SetVectorParameterValue('Color',colorescudo);
	
	}
	
	
}

function NubeDeIraSobrePawn()
{
	local PEnemyPawn_Scout scoutpawn;
	local PPawn giru;

	giru = PPawn( PGame(WorldInfo.Game).GetALocalPlayerController().Pawn);
	scoutpawn = PEnemyPawn_Scout(self.Pawn);
	
	giru.EstadoNubeIra(scoutpawn.ValorIra());

	//Si está en el nivel máximo, rayazo contra el giru
	if (3 == scoutpawn.NivelIra())
	{
		giru.RayazoNubeIra();
		scoutpawn.ResetIra();
	}

}


function ContraTorreta(Actor torreta, optional float dist=m_despContraTorreta)
{

	if (m_ChocandoContraTorreta)
	{
		`log("Evito Recursividad "@self.Name @torreta.Name);
		return;
	}
	m_ChocandoContraTorreta = true;

	//Se supone que llega aquí sólo si se ha comido un árbol o una torreta. Y lo que tiene que hacer en ambos
	//casos es cicutriñárselo... so..

	if(PAutoTurret(torreta)!=None)
	{
		`log("Scout se come torreta" @self.Name);
		PAutoTurret(torreta).Destruccion();
	}

	if(PTree(torreta)!=None)
	{
		`log("Scout se come arbol" @self.Name);
		PTree(torreta).Destruccion();
	}
	
	m_ChocandoContraTorreta = false;
}



function SetColor(LinearColor Col)
{
	ColorDecal = Col;
	Mat.SetVectorParameterValue('Color', ColorDecal);
}


function DrawDebugInfo()
{
	//_DEBUG_DrawDebugLine(Pawn.Location, m_CurrentDestination, 0, 255, 0, false);
	//_DEBUG_DrawDebugSphere(m_CurrentDestination, 20, 20, 0, 255, 0, false);
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
	//_DEBUG_ PGame(WorldInfo.Game).Broadcast(self, "Voy hacia el nodo "@pWNodos[j].Name);
	//DrawDebugSphere(pWNodos[j].Location, 500, 10, 0, 255, 0, true);
	m_Destination = pWNodos[j];
	m_CurrentDestination = m_Destination.Location;
	//Y lo elimino para que no podamos volver a asignarnos el mismo nodo ;)
	PGame(WorldInfo.Game).DeleteWorldPathNode(id_Path, j);
	//`log("______Nextnode "@m_Destination.Location);
}

/* --------------- ESTADO IDLE_INICIAL --------------
 * --- Empieza en este estado, y cuando el Pawn recién creado llega al suelo, pasamos al estado inicial
 */
auto state Idle_Inicial
{
	event BeginState(Name PrevName)
	{
		//_DEBUG_ ("Penemy_AI_Scout creado, estoy en Idle");
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

	function BumpContraSuelo(Actor suelo,Vector HitNormal)
	{
		PEnemy(self.Pawn).AterrizadoAfterSpawn();
	}


	event EndState(name NextStateName)
	{
		//_DEBUG_ ("Penemy_AI_Scout saliendo de idle");
	}
}/* --------------- FIN ESTADO IDLE_INICIAL --------------*/
//____________________________________________________________________________________________________________________________________


/* --------------- ESTADO MOVETODESTINATION --------------
 * --- El scout va avanzando hasta al siguiente nodo, y si se acerca lo suficiente a la base, hacia la base directo
 */
state MoveToDestination
{
	event SeePlayer(Pawn seen)
	{
		//_DEBUG `log ("Soy el scout, hE visto a este pawn "@seen.Name);

		if (PPawn(seen) != None)
		{
			if (m_disparo_posible && vsize(self.Pawn.Location - seen.Location) < m_max_dist_disparo_ppawn )
			{
				self.DisparaAPPawn(PPawn(seen));
			}
		}
	}

	event Tick(float DeltaTime)
	{
		local Pawn pDetectado;
		local PPathNode nodo;
		local float distanciaBase;
		local float distNodo;

		DrawDebugInfo();
		super.Tick(DeltaTime);

		if (pawn.Velocity == vect(0,0,0) && m_Destination == theObjective)
		{
			//`log("S'ha parao no sé por què");
			//_DEBUG_DrawDebugSphere(pawn.Location,200,20,200,0,0,false);
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
			nodo.m_direccion_nodo = self.pawn.Velocity;
			nodo.m_floor_nodo = self.pawn.floor;
			PGame(WorldInfo.Game).AddPathNode(id, nodo, ColorDecal);
			
			OldLocation = Pawn.Location;
		}


		//Control de llegada a nodo y/o Base
		if (m_tiempo_tick >= 1.0)
		{
			if (m_bBreakpoint)
			{
				`log("Parate colega!");
			}
			m_tiempo_tick -= 1.0; //reset del tiempo para el siguiente 'timer'
			
			//Hemos llegado a la base?
			distanciaBase = VSize(theObjective.Location - Pawn.Location);
			//`log("Distancia Base "@self.Name @distanciaBase);
			if (distanciaBase == distanciaBase_antes)
			{
				//`log("Ta kieto!!");
			}
			distanciaBase_antes = distanciaBase;
			if(distanciaBase < m_DistanciaAtaqueBase)
			{
				Pawn.Velocity = vect(0,0,0);
				GotoState('ArrivedDestination');
			}
			else
			{
				//Si estamos cerca de la base, no vamos al siguiente nodo, sino directamente contra la base
				if(VSize(theObjective.Location - Pawn.Location) < Step * 4)
				{
					m_Destination = theObjective;
					//`log("Voy directo para la base, velocidad "@Pawn.Velocity);
					m_CurrentDestination = m_Destination.Location;
				}
				//Si no, controlamos si estamos cerca del siguiente nodo,y si es así, 
				//vamos hacia el siguiente
				else 
				{
					distNodo = VSize(m_CurrentDestination - Pawn.Location);
					if (distNodo < DestinationOffset)
					{
						distNodo = 0;
						NextPath();
						//_DEBUG_ ("nextpath "@self.Name);
					}
					else
					{
						//Control de que se queda quieto:
						if (abs(distNodo - oldDistNodo)<0.1)
						{
							m_segundosQuieto +=1;
							if (m_segundosQuieto == 3)
							{
								//DrawDebugSphere(pawn.Location,300,80,0,0,200,true);
								m_segundosQuieto = 0;
								//_DEBUG_ ("__________LA DISTANCIA ERA "@distNodo);
								NextPath();

							}
						}
						oldDistNodo = distNodo;
					}
				}

				//Igualmente hay que decirle que se siga moviendo hacia donde iba
				GoToState ('MoveToDestination');
			}

		}//m_tiempo_tick >= 1.0
	}//Tick


	
	function ControlTakeDisparoGiru(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_SCOUT ControlTakeDisparoGiru en MoveToDestination"@self.Name);
		m_bBreakpoint = true;

	}
	
	function ControlTakeDisparoTurretCannon(vector HitLocation, vector Momentum, Actor DamageCauser)
	{
		`log("PEnemy_AI_BOT, ControlTakeDisparoGiru en MoveToDestination"@self.Name);
	}


Begin:
	//m_tiempo_tick = 1.0; //Para que en el primer tick ya evalúe, y así cuando encontramos un nuevo destino,no hace parada, sino que
						 //directamente parece que sepa a dónde va
	if (m_Destination != None)
	{
		StopLatentExecution();
		MoveToward(m_Destination,,DestinationOffset/2, false, true);
		/*
		else //No sabemos por qué, el UDK aquí si poníamos MoveToward no movía al bicho....
		{
			MoveTo(m_Destination.Location,m_Destination,100,true);
		}
		*/
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


	event Tick(float delta)
	{
		super.Tick(delta);
		self.Velocity = vect(0,0,0);
		self.Acceleration = vect(0,0,0);
		self.Pawn.Velocity = vect(0,0,0);
		self.Pawn.Acceleration = vect(0,0,0);
	}

}/* --------------- FIN ESTADO ArrivedDestination --------------*/
//____________________________________________________________________________________________________________________________________


defaultproperties
{
	Step=1000
	id_Path=0
	DestinationOffset=200
	m_radio_escudo = 800
	m_max_dist_disparo_ppawn=500
	m_timout_entre_disparos = 0.2
	m_ClaseMisil=class 'PMisilScout'
	m_DistanciaAtaqueBase=1700
}
