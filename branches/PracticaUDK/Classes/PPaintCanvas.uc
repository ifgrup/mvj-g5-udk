
/** Clase PPaintCanvas
 * Crea un objeto de tipo PPaintCanvas con las siguientes caracter�sticas:
 * - Modelo 3D de un cubo
 * - Permite cambiar din�micamente el material del objeto, con las siguientes limitaciones:
 *      - El material tiene que tener como m�nimo dos texturas
 *      - El material tiene que tener como m�nimo un par�metro escalar llamado 'matLoading'
 */
class PPaintCanvas extends Actor
    placeable;

var float CantidadColor;
var bool bumped;
var StaticMeshComponent ColorMesh;
var MaterialInstanceConstant mat;

/** PostBeginPlay
 * Justo al crear el objeto, obtenemos el material de su Mesh.
 * Este material se le habr� asignado mediante el Editor.
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
 * y en caso de que tenga que cambiar, controlamos qu� cantidad tenemos que 
 * asignarle al par�metro escalar del material.
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
	
	// Asignamos el par�metro de cantidad al material
	mat.SetScalarParameterValue('matLoading', CantidadColor);
}

/** DefaultProperties
 * Propiedades por defecto del objeto f�sico dentro del juego
 * Inicializamos variables, asignamos la iluminaci�n y el objeto
 * f�sico dentro del juego.
 */
DefaultProperties
{

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true
	End Object

	LightEnvironment=MyLightEnvironment
	Components.Add(MyLightEnvironment)

	begin object class=StaticMeshComponent Name=BaseMesh
		StaticMesh=StaticMesh'EditorMeshes.TexPropCube'
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
}
