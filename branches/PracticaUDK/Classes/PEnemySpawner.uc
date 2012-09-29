class PEnemySpawner extends PActor
    placeable;

var MaterialInstanceConstant mat;
var StaticMeshComponent ColorMesh;
var LinearColor Col1;
var LinearColor Col2;

var(SpawnConfig) int Group;
var PEnemy EnemyScout;
var PEnemy_AI_Scout AI;

var array<PEnemy> Enemy;
var array<PEnemy_AI_Bot> AIBot;

var(SpawnConfig) int MaxEnemies;

var float m_distDelHuevoAlNacer;
var vector m_location_primer_nodo;

var int m_num_minions_por_spawn; //cuantos minions se crean cada vez

var bool m_bMuertoScout; //Indica si el ogro que se creó, ha muerto

struct OffsetNodo
{
	var vector posicion;
	var float  giro_angulo;
};

function PostBeginPlay()
{
	// Si no tenemos grupo, generamos uno
	if(Group == 0)
		Group = Rand(255);

	Col1 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	Col2 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	mat = new class'MaterialInstanceConstant';
	mat = ColorMesh.CreateAndSetMaterialInstanceConstant(0);
	mat.SetParent(Material'Props.Huevos.Huevo01_Mat');
	mat.SetVectorParameterValue('Color_Emissive01', Col1);
	mat.SetVectorParameterValue('Color_Emissive02', Col2);

	ColorMesh.SetMaterial(0, mat);
	//_DEBUG_DrawDebugCylinder(self.Location, self.location + (self.Location - (PGame(Worldinfo.Game)).m_CentroPlaneta),10,10,200,0,0,true);

	//Timer que cada 30 segundos incrementa el número de minions a salir de cada spawn
	SetTimer(30,true,'IncSpawnCount');
}

function IncSpawnCount()
{
	m_num_minions_por_spawn = clamp (m_num_minions_por_spawn+1,3,7);
	`log ("__Nuevo num de minions por scout "@m_num_minions_por_spawn);
}

/**
 * Genera enemigos. El primero de todos siempre es el Scout, que se encarga de ir generando el camino
 * */
function SpawnEnemy()
{
	//Si el scout creado en primer momento muere, no se genera nada más,  y el spawner se queda inactivo:
	if (m_bMuertoScout)
	{
		return;
	}

	//Si no hay Scout, lo creamos
    if(EnemyScout == none)
    {
        EnemyScout = spawn(class'PEnemyPawn_Scout',,,Location);
		if (EnemyScout == none)
		{
			//_DEBUG_ ("No se ha podido crear el scout");
			return;
		}
        EnemyScout.SetColor(Col2);
		EnemyScout.SetId(Group);

		AI = spawn(class'PEnemy_AI_Scout',,,Location);
		AI.SetColor(Col2);
		AI.SetID(Group);
		AI.Possess(EnemyScout, false);

		//Y ahora necesitamos que además genere una primera oleada de minions para que tenga escudo.
		//Le generamos 2 oleadas de 5 minions, en intervalos de 5 segundos:
		SetTimer( 5.0,false,'PrimeraOleada');
    }
	else //Ya hay scout, generamos minions
	{
		GeneraMinions(m_num_minions_por_spawn);
	}
}

function GeneraMinions(int cuantos)
{
	local PEnemyPawn_Minion EN;
	local Penemy_AI_Bot AIB;
	local vector vector_hacia_primer_nodo;
	local array<OffsetNodo> posiciones;
	local int i;

	if(CanSpawnEnemy())
	{
	    //Sacamos tantos como la orda que toque.
		//Simplemente guardaría en las estructuras que tenemos, el id de orda que llevamos,
		//Y vamos haciendo que incremente el número de minions por orda.
		//Ahora para probar, hacemos 3.
		if (m_location_primer_nodo == vect(0,0,0))
		{
			m_location_primer_nodo = PGame(Worldinfo.game).GetFirstNodeLocation(Group);
		}
		if (m_location_primer_nodo == vect(0,0,0))
		{
			//Aún no existe el primer nodo. Puede pasar si los minions salen enseguida después del scout y éste aún
			//no lo ha creado
			//así que le damos más tiempo, y esperamos al siguiente timer
			return;
		}

		//_DEBUG_DrawDebugCylinder(self.Location,m_location_primer_nodo,10,10,0,255,0,true);
		//_DEBUG_DrawDebugSphere(self.Location,120,20,255,0,0,true);
		vector_hacia_primer_nodo  = m_location_primer_nodo - self.Location;

		generarPosicionSpawn(vector_hacia_primer_nodo,cuantos,posiciones);
		for (i=0;i<cuantos;i++)
		{
				
			EN = spawn(class'PEnemyPawn_Minion',,, posiciones[i].posicion);
			if (EN!=None) //Proteccion Víctor
			{
				EN.SetColor(Col2);
				EN.SetID(Group);
				AIB = spawn(class'PEnemy_AI_Bot',,, posiciones[i].posicion);
				AIB.SetID(Group);
				AIB.m_AnguloOffsetInicial = posiciones[i].giro_angulo;
				Enemy.AddItem(EN);
				AIBot.AddItem(AIB);
				AIB.Possess(EN, false);
			}
		}
	}

}


function  generarPosicionSpawn(vector v_haciaprimernodo, int num_bichos, out array<OffsetNodo> posiciones)
{
	local vector vdesdecentro, p;
	//local vector parriba;
    //local vector vrandom;
	local rotator rot;
	local float deltaangulo;
	local int i,signo;
	local vector rx,ry,rz,v;
	local Quat ernion,ernion2;
	local float giro_radianes;
	local OffsetNodo o;

	vdesdecentro = self.location + (self.Location -PGame(Worldinfo.Game).GetCentroPlaneta()); //un pseudo floor
	vdesdecentro = normal (vdesdecentro);

	rot = rotator (vdesdecentro);
	getaxes(rot,rx,ry,rz);

	//Ahora debemos mover en yaw, en función del número de bichos que pidan.
	if (num_bichos == 1)
	{
		deltaangulo = 0;
	}
	else
	{
		deltaangulo = 180 / (num_bichos -1 );
	}

	for (i = 0; i < num_bichos; i++)
	{
		if (i%2 ==0)
		{
			signo = -1;
		}
		else
		{
			signo =1 ;
		}
		//el rot va de centro a huevo. Por tanto, queremos girar en rx
		giro_radianes =  ((i+1)/2) * signo * deltaangulo *DegToRad;

		v = normal(v_haciaprimernodo);
		if (giro_radianes != 0)
		{
			ernion =  QuatFromAxisAndAngle(vdesdecentro ,giro_radianes);
			ernion2 = QuatFromRotator(Rotator(normal(v_haciaprimernodo)));
			ernion =  QuatProduct(ernion,ernion2);
			v = vector(QuatToRotator(ernion));
		}

		/**********
		ernion =  QuatFromAxisAndAngle(rx,giro_radianes);
		ernion2 = QuatFromRotator(Rotator(normal(v_haciaprimernodo)));
		ernion =  QuatProduct(ernion,ernion2);
		v = vector(QuatToRotator(ernion));
		***************/
		//Y aplicamos la rotación
		p = 150 * normal(vdesdecentro) + self.Location + (v * m_distDelHuevoAlNacer);
		o.giro_angulo = giro_radianes;
		o.posicion = p;
		posiciones.AddItem(o);
		//_DEBUG_DrawDebugCylinder(self.Location,p,2,2,0,200,200,true);
		
		//posiciones[i].posicion = p;
		//posiciones[i].giro_angulo = giro_radianes ;

	}
}

function bool CanSpawnEnemy()
{
	local bool res;
	local int indice;
	res = false;

	//Si no tiene creado el grupo de nodos todavía, no puede hacer spawn
	indice =  PGame(Worldinfo.game).GroupNodos.Find('id', self.Group);
	if (indice != -1)
	{
		res = (Enemy.Length <= MaxEnemies);
	}
	else
	{
		`log("No hay nodos todavía para el grupo " @group);
	}
   
	return res;
}

function PrimeraOleada()
{
	GeneraMinions(5); //Genera 5 enemigos , y a los 5 segundos, otros 5. Con el mismo timer me daba problemas...
	//Puede ser que el ogro aún no haya generado un primer nodo, por lo que los minions no sabrían dónde ir, y no se
	//pueden generar. Así que si no los ha podido generar, relanzamos el timer un segundo más tarde
	if (Enemy.Length ==0)
	{
		`log ("Primera Oleada, reintento en 1 s "@self.name);
		SetTimer(1.0,false,'PrimeraOleada');
		return;
	}
	else
	{
		`log ("Primera Oleada creada "@self.name);
		SetTimer(5.0,false,'SegundaOleada');
		return;
	}
}

function SegundaOleada()
{
	`log ("Segunda Oleada "@self.name);
	GeneraMinions(5); //Genera 5 enemigos , y a los 5 segundos, otros 5. Con el mismo timer me daba problemas...
}


//Elimina un minion del array Enemy, para que pueda seguir spawneando
function EliminaMinion(PEnemyPawn_Minion minion)
{
	local int index;
	
	index = self.Enemy.Find(minion);
	if (index == -1)
	{
		`log ("Shit happens...");
	}
	else
	{
		Enemy.Remove(index,1);
	}

}

defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true
	End Object

    LightEnvironment=MyLightEnvironment
	Components.Add(MyLightEnvironment)
	
	Begin Object class=StaticMeshComponent Name=BaseMesh
		StaticMesh=StaticMesh'Props.Huevos.Huevo01'
		LightEnvironment=MyLightEnvironment
		Scale=2
    End Object

	ColorMesh=BaseMesh
	Components.Add(BaseMesh)

	MaxEnemies=80;
	m_distDelHuevoAlNacer=300
	m_num_minions_por_spawn=2 //Inicialmente, que sólo genere 2 cada vez.
	m_bMuertoScout=false
}