class PInvisiblePlanet extends PActor
	placeable;

DefaultProperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true
	End Object

	LightEnvironment=MyLightEnvironment
	Components.Add(MyLightEnvironment)

	begin object class=StaticMeshComponent Name=BaseMesh
		StaticMesh=StaticMesh'Niveles.Planeta01_Agua'
		LightEnvironment=MyLightEnvironment
	end object

	ColorMesh=BaseMesh
	Components.Add(BaseMesh)
	CollisionComponent=BaseMesh

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