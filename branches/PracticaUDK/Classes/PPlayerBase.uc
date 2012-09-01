
/** Clase PPaintCanvas
 * Crea un objeto de tipo PPaintCanvas con las siguientes características:
 * - Modelo 3D de un cubo
 * - Permite cambiar dinámicamente el material del objeto, con las siguientes limitaciones:
 *      - El material tiene que tener como mínimo dos texturas
 *      - El material tiene que tener como mínimo un parámetro escalar llamado 'matLoading'
 */
class PPlayerBase extends Actor
    placeable;

var float CantidadColor;
var bool bumped;
var StaticMeshComponent ColorMesh;
var MaterialInstanceConstant mat;


var int life;


/** PostBeginPlay
 * Justo al crear el objeto, obtenemos el material de su Mesh.
 * Este material se le habrá asignado mediante el Editor.
 */
simulated function PostBeginPlay()
{
    mat = ColorMesh.CreateAndSetMaterialInstanceConstant(0);
}

/** ChangeTexture
 * Cambiamos el estado de la textura, de activa/tocada a inactiva
 */
function ChangeTexture()
{
	if(bumped)
	{
		bumped=false;
	}
	else
	{
		bumped=true;
	}
	
	//DBG WorldInfo.Game.Broadcast(self,Name$": bumped:" @bumped);
}

/** Tick
 * A cada tick del juego comprobamos si el material tiene que cambiar
 * y en caso de que tenga que cambiar, controlamos qué cantidad tenemos que 
 * asignarle al parámetro escalar del material.
 */
event Tick(float DeltaTime)
{
	if(bumped)
	{
		CantidadColor += 0.01;
		if(CantidadColor > 1.0)
			CantidadColor = 1.0;
	}
	else
	{
		CantidadColor -= 0.01;
		if(CantidadColor < 0.0)
			CantidadColor = 0.0;
	}
	
	// Asignamos el parámetro de cantidad al material
	mat.SetScalarParameterValue('matLoading', CantidadColor);
}



event TakeDamage(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	/*
    `log("me tan dando");
	life--;
	if(life == 0)
	{
		Destroy();
		if(PGame(WorldInfo.Game) != none)
		{
			PGame(WorldInfo.Game).basedestrozada();
		}
	}
  */
}

function pupitabase()
{
	//_DEBUG_ ("man dao augthhh");
	life--;
	if(life <= 0)
	{
		
		PGame(WorldInfo.Game).basedestrozada();
		
	}
  

}

/** DefaultProperties
 * Propiedades por defecto del objeto físico dentro del juego
 * Inicializamos variables, asignamos la iluminación y el objeto
 * físico dentro del juego.
 */
DefaultProperties
{

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true
	End Object

	LightEnvironment=MyLightEnvironment
	Components.Add(MyLightEnvironment)

	begin object class=StaticMeshComponent Name=BaseMesh
		StaticMesh=StaticMesh'Edificios.Casa01'
		LightEnvironment=MyLightEnvironment
	end object

	ColorMesh=BaseMesh
	Components.Add(BaseMesh)
	CollisionComponent=BaseMesh
//	Components.Add(CollisionComponent)

	bWorldGeometry=true
	TickGroup=TG_PreAsyncWork
	bStatic=false
	bCanBeDamaged=true
	bCollideActors=true
	bBlockActors=true
	bNoEncroachCheck=true

	CantidadColor=0
	bumped=false

	life=3
}
