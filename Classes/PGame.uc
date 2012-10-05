/**
 * Configuración general del juego
 * */

class PGame extends GameInfo;

var const float fDecalSize;
var bool bActivateDecalsOnWalk;
var int EnemiesLeft;
var bool bEarthNotFlying;
var int creditos;
var PPlayerBase PlayerBase;
var bool NodosCreados;
var int EScoutLeft;
var int m_ticks_spawn_enemigos; //control de ticks spawneando enemigos
var int m_intervalo_spawn_enemies; //tiempo entre spawn de cualquier huevo
var bool juegofinalizadomuerte,juegofinalizadogana;

var string m_TextoPendiente;

var PGameSonidos SONIDOS_JUEGO;

struct Spawner
{
	var int id;
	var PEnemySpawner SpawnPoint;
};

struct GrupoNodos
{
	var LinearColor Col;
	var int id;
	var array<PPathNode> Nodos;
};

struct GrupoNodosMundo
{
	var int id;
	var array<PWorldPathNode> Nodos;
};

var array<GrupoNodos> GroupNodos;
var array<Spawner> EnemySpawners;
var array<GrupoNodosMundo> NodosMundo;

var bool bSpawnBoss;
var Vector  m_CentroPlaneta;
var float m_max_radiorandom; //Máxima distancia a aplicar al offset de los nodos del minion
var float m_min_radiorandom; //Mínima distancia a aplicar al offset de los nodos del minion


simulated function PostBeginPlay()
{
    local PEnemySpawner ES;
	local PPlayerBase PB;

	local Spawner SP;

	SONIDOS_JUEGO = spawn(class'PGameSonidos',,,,,,);


    foreach DynamicActors(class'PEnemySpawner', ES)
    {
		if(EnemySpawners.Find('id', ES.Group) == -1)
		{
			SP.SpawnPoint = ES;
			SP.id = ES.Group;
			EnemySpawners.AddItem(SP);
			EScoutLeft++;
		}
    }

	//_DEBUG_ ("Hay"@EnemySpawners.Length);

	CreatePathNodes();

	foreach DynamicActors(class'PPlayerBase', PB)
		PlayerBase = PB;

	CreaNodosMundo();

	if(EnemySpawners.Length != 0)
		SetTimer(1.0, false, 'ActivateSpawners');

	super.PostBeginPlay();
	CreateVegetationCollision();
}

function CreaNodosMundo()
{
	local PWorldPathNode pNodo;

	local Vector vInicial;
	local Rotator rRotacion;

	local Vector HitLocation,HitNormal;
	local int i,j;
	local int deltaAngulo;
	local int id;

	deltaAngulo = 15 * DegToUnrRot;
	vInicial = vect(0, 0, 15000);

	NodosMundo.Add(5);

	for (i = 0; i < 65535; i += deltaAngulo)
	{
		for (j = 0; j < 65535; j += deltaAngulo)
		{
			rRotacion.Yaw += deltaAngulo;
			vInicial = TransformVectorByRotation(rRotacion, vInicial);
			Trace(HitLocation, HitNormal, m_CentroPlaneta, m_CentroPlaneta + vInicial, true, vect(0, 0, 1));
			if(CanSpawnNode(HitLocation) == false)
				continue;
			//DrawDebugSphere(HitLocation,50,25,255,0,0,true);
			id = Rand(5);
			pNodo = Spawn(class'PWorldPathNode',,, HitLocation);
			//DrawDebugCylinder(m_CentroPlaneta, m_CentroPlaneta + vInicial, 25, 25, 0, 255, 0, true);

			pNodo.id = id;

			NodosMundo[pNodo.id].id = pNodo.id;
			NodosMundo[pNodo.id].Nodos.AddItem(pNodo);
		}

		rRotacion.Pitch += deltaAngulo;
		rRotacion.Yaw = 0;
	}

	NodosCreados = true;
}

function bool CanSpawnNode(Vector loc)
{
	local PNoSpawnVolume vol;
	foreach AllActors(class'PNoSpawnVolume', vol)
	{
		if(vol.ContainsPoint(loc))
			return false;
	}

	return true;
}

function array<PWorldPathNode> ObtenerNodosMundo(int id)
{
	return NodosMundo[id].Nodos;
}

/// Devuelve un id random de todos los posibles nodos
function int ObtenerIdNodosMundo()
{
	return Rand(NodosMundo.Length);
}

function DeleteWorldPathNode(int id, int i)
{
	NodosMundo[id].Nodos.Remove(i, 1);
}

function CreatePathNodes()
{
	local GrupoNodos GP;
	local PPathNode PN;
	local int i;
	foreach DynamicActors(class'PPathNode', PN)
	{
		i = GroupNodos.Find('id', PN.id);
		if(i == -1)
		{
			GP.Nodos.AddItem(PN);
			GP.id = PN.id;
			GP.Col = MakeLinearColor(Frand(), FRand(), FRand(), 1.0);

			GroupNodos.AddItem(GP);
		}
		else
		{
			GroupNodos[i].Nodos.AddItem(PN);
		}
	}
}

/************ REDUCCION TICKS ************
event Tick(float DeltaTime)
{
	local int i;
	local int j;
	local vector v0;
	local vector v1;

	//FlushPersistentDebugLines();
	if(NodosCreados)
		DrawWorldNodes();
	DrawNodes();

	for(i = 0; i < NodosMundo.Length; ++i)
	{
		for(j = 0; j < NodosMundo[i].Nodos.Length; ++j)
		{
			if(j+1 >= NodosMundo[i].Nodos.Length)
				v1 = NodosMundo[i].Nodos[0].Location;
			else
				v1 = NodosMundo[i].Nodos[j+1].Location;
	
			v0 = NodosMundo[i].Nodos[j].Location;
			//_DEBUG_DrawDebugLine(v0, v1, 255, 0, 0, false);
			//DrawDebugSphere(v0, 200, 10, 255, 0, 0, false);
		}
	}
}
**************** FIN REDUCCION TICKS ********/


function DrawWorldNodes()
{
	local int i;

	for(i = 0; i < NodosMundo.Length; i++)
	{
		//DBG DrawDebugSphere(NodosMundo[i].Location, 30, 10, 255, 0, 0, false);
	}
}

function DrawNodes()
{
	local int i, j;
	local GrupoNodos GP;
	local vector v1, v2;

	for(j = 0; j < GroupNodos.Length; j++)
	{
		GP = GroupNodos[j];
		for(i = 0; i < GP.Nodos.Length; i++)
		{
			v1 = GP.Nodos[i].Location;
			if(i >= GP.Nodos.Length-1)
				v2 = GP.Nodos[i].Location;
			else
				v2 = GP.Nodos[i+1].Location;

			//DBG DrawDebugLine(v1, v2, GP.Col.R * 255, GP.Col.G * 255, GP.Col.B * 255, false);
			//DBG DrawDebugSphere(v1, 20, 10, GP.Col.R * 255, GP.Col.G * 255, GP.Col.B * 255, false);
		}
	}
}

function AddPathNode(int id, PPathNode pNodo, optional LinearColor col)
{
	local int indice;
	local GrupoNodos GP;

	indice = GroupNodos.Find('id', id);
	if(indice == -1)
	{
		GP.Nodos.AddItem(pNodo);
		GP.id = pNodo.id;
		GP.Col = col;

		GroupNodos.AddItem(GP);
		//_DEBUG_Broadcast(none, "Creando nuevo grupo de nodos...");
	}
	else
		GroupNodos[indice].Nodos.AddItem(pNodo);
}

function PPathNode GetNextPath(int id, out int NodeIndex)
{
	local int indice;
	local int NodeIndexTmp;
	local GrupoNodos GN;
	local int len;

	NodeIndexTmp = NodeIndex +1;

	indice = GroupNodos.Find('id', id);
	if (indice == -1)
	{
		//Grave problema... significa que no hemos creado los nodos..
		//_DEBUG `log("___ERROR___ No se han creado los nodos para el grupo " @id);
		return none;
	}
	GN = GroupNodos[indice];
	len = GN.Nodos.Length;

	if(NodeIndexTmp >= len)
	{
		return none;
	}
	else
	{
		NodeIndex ++;
		return GroupNodos[indice].Nodos[NodeIndex];
	}
}

function vector GetFirstNodeLocation(int id)
{
	local int indice;
	local PPathNode nodo;

	indice = 0 ;
	nodo = GetNextPath(id,indice);
	if (nodo != None)
	{
		return nodo.Location;
	}
	else
	{
		return vect(0,0,0);
	}
}

function ActivateSpawners()
{
    local PPlayerController PC;

    foreach LocalPlayerControllers(class'PPlayerController', PC)
        break;

    if(PC.Pawn == none)
    {
        SetTimer(1.0, false, 'ActivateSpawners');
        return;
    }
    
    EnemySpawners[Rand(EnemySpawners.length)].SpawnPoint.SpawnEnemy();
	// Con esto controlamos que sólo haya un spawn activo a la vez y que no spawneen todos los enemigos a la vez
	m_ticks_spawn_enemigos = (m_ticks_spawn_enemigos + 1) % 10;
	if (m_ticks_spawn_enemigos == 0)
	{
		m_intervalo_spawn_enemies = fclamp (m_intervalo_spawn_enemies-1,4,10);
		//_DEBUG `log ("Nuevo intervalo spawn"@m_intervalo_spawn_enemies);
	}

    SetTimer(m_intervalo_spawn_enemies, false, 'ActivateSpawners');
}

function SetCredito(int credito)
{
	creditos=credito;
}


function EnemyKilled(PEnemy enemigoMuerto)
{
	if (PEnemyPawn_Minion(enemigoMuerto) != None)
	{
		EliminaMinionVector(PEnemyPawn_Minion(enemigoMuerto));

		//VICTOR:
		/***********
		EnemiesLeft--;
		if(EnemiesLeft <= 0)
		{
	        ClearTimer('ActivateSpawners');
			bSpawnBoss = true;
			ActivateSpawners();
		}
		***************/

	}
	else if (PEnemyPawn_Scout(enemigoMuerto) != None)
	{

		EScoutLeft--;
		if (EScoutLeft ==1)
		{
			self.m_TextoPendiente = "Only One Left!!";
		}
		else
		{
			self.m_TextoPendiente = "Well Done!! Keep on Fighting!!!";
		}

		//Como ha muerto el líder, el guía espiritual, los minions no pueden superarlo y se suicidan:
		TodosMinionsKamikaze(PEnemyPawn_Scout(enemigoMuerto).id);
		//Y hacemos que el spawner no genere más ogros ni más minions:
		InhabilitarSpawner(PEnemyPawn_Scout(enemigoMuerto).id);
		if(EScoutLeft <= 0)
		{
			MapaFinalizado();
		}
	}

	//Y ahora, control de puntos:
	SetCredito(creditos + enemigoMuerto.m_puntos_al_morir);
}




//control de Game Over
function BaseDestrozada()
{
//_DEBUG `log("Base destrozada");
	GameOver();
   // consolecommand("Open PGameMenuini");


}


function GameOver()
{
juegofinalizadomuerte=true;
//consolecommand("Open PGameMenuini");


}


function MapaFinalizado()
{

juegofinalizadogana=true;


}


function ScoreObjective(PlayerReplicationInfo Scorer, Int Score)
{
    super.ScoreObjective(Scorer, Score);
}

function Vector GetCentroPlaneta()
{
	return m_CentroPlaneta;
}

function GetVectorEnemigos(int idSpawner, out array<PEnemy> enemigos, out PEnemy_AI_Scout scout)
{
	 local Spawner ES;
	 local int index;
     local PEnemy_AI_Scout  elscout;

	 index= EnemySpawners.Find('id', idSpawner);

	 if(index == -1)
	 {
		//_DEBUG `log("KAGADA");
	 }
	 else
	 {
		ES = EnemySpawners[index];
		enemigos = ES.SpawnPoint.Enemy;
		//Obtener el scout
		foreach DynamicActors(class 'PEnemy_AI_Scout', elscout)
		{
			if (elscout.id == idSpawner)
			{
				scout = elscout;
				break;
			}
		}
	 }
}

function TodosMinionsKamikaze(int id_scout)
{
	 local Spawner ES;
	 local int index;
	 local int i;
     local  array<PEnemy> sus_minions;

	 index= EnemySpawners.Find('id', id_scout);

	 if(index == -1)
	 {
		//_DEBUG `log("KAGADA");
	 }
	 else
	 {
		ES = EnemySpawners[index];
		sus_minions = ES.SpawnPoint.Enemy;
		for (i=0;i<sus_minions.Length;i++)
		{
			sus_minions[i].Owner.GotoState('TowerAttack');
		}
	 }
}

function InhabilitarSpawner(int idSpawner)
{
	 local Spawner ES;
	 local int index;

	 index = EnemySpawners.Find('id', idSpawner);
	 if(index == -1)
	 {
		//_DEBUG `log("KAGADA");
	 }
	 else
	 {
		ES = EnemySpawners[index];
		ES.SpawnPoint.m_bMuertoScout = true;
	 }
}

//EliminaMinionVector
//Dado un minion, lo elimina del vector Enemy del PEnemySpawner que lo creó
function EliminaMinionVector(PEnemyPawn_Minion minion)
{
	 local Spawner ES;
	 local int index;

	 index= EnemySpawners.Find('id', minion.id);

	 if(index == -1)
	 {
		//_DEBUG `log("KAGADA EliminaMinionVector");
	 }
	 else
	 {
		ES = EnemySpawners[index];
		ES.SpawnPoint.EliminaMinion(minion);
	 }
}


exec function ponerpasta(int p)
{
SetCredito(p);
}

function bool EsPlaneta(Actor a)
{
	//versión hasta ahora:
	/****
	return (a.Name == 'StaticMeshActor_1');
	***/
	
	//versión planeta troceado
	return a.Tag == 'Planeta';
}

static final function vector MatrixGetScale(Matrix TM)
{
    local Vector s;
    s.x = sqrt(TM.XPlane.X**2 + TM.XPlane.Y**2 + TM.XPlane.Z**2);
    s.y = sqrt(TM.YPlane.X**2 + TM.YPlane.Y**2 + TM.YPlane.Z**2);
    s.z = sqrt(TM.ZPlane.X**2 + TM.ZPlane.Y**2 + TM.ZPlane.Z**2);
    return s;
}

function CreateVegetationCollision()
{
	local InstancedFoliageActor ac;
	local InstancedStaticMeshComponent comp;
	local vector loc, scale;
	local Rotator rot;
	local PTree Tree;
	local int i, j;
	
	foreach AllActors(class'InstancedFoliageActor', ac)
	{
		if(ac.Layer == 'Vegetacion')
		{
			for(i = 0; i < ac.InstancedStaticMeshComponents.Length; ++i)
			{
				comp = ac.InstancedStaticMeshComponents[i];
				if(comp.StaticMesh == StaticMesh'Miscelanea.caja')
				{
					ac.InstancedStaticMeshComponents[i].SetHidden(true);
					j = comp.PerInstanceSMData.Length;
					for(j = 0; j < comp.PerInstanceSMData.Length; ++j)
					{
						loc = MatrixGetOrigin(comp.PerInstanceSMData[j].Transform);
						rot = MatrixGetRotator(comp.PerInstanceSMData[j].Transform);
						scale = MatrixGetScale(comp.PerInstanceSMData[j].Transform);
	
						Tree = Spawn(class'PTree',,,loc,rot);
						if (Tree.Location == vect (0,0,0))
						{
							//Porque UDK lo ha decidido así...
							Tree.Destroy();
							continue;
						}
						Tree.SetDrawScale3D(scale);
					}
				}
			}
		}
	}
}

defaultproperties
{
	PlayerControllerClass=class'PGame.PPlayerController'
	DefaultPawnClass=class'PGame.PPawn'
	HUDType=class'PGame.PHUD'
    	EnemiesLeft=10
    	bScoreDeaths=false
	fDecalSize=256.0f
	bActivateDecalsOnWalk=false
	creditos=100000
	bEarthNotFlying=true
	bDelayedStart=false
	//m_CentroPlaneta=(X=528,Y=144,Z=8752)
	m_CentroPlaneta=(X=0.000000,Y=0.000000,Z=0.000000)
	NodosCreados=false
	m_max_radiorandom=100;
	m_min_radiorandom=400;
	m_intervalo_spawn_enemies = 10 //Iniciamente, cada 10 segundos
	juegofinalizadomuerte=false;
	juegofinalizadogana=false;
}
