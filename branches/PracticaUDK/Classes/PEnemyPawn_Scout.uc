class PEnemyPawn_Scout extends PEnemy;

var MaterialInstanceConstant mat;
var MaterialInstanceConstant matBandera;

var SkeletalMeshComponent ColorMesh;
var StaticMeshComponent Bandera;
var LinearColor Col1, Col2;

var int ira, max_ira;

simulated function PostBeginPlay()
{
	local int yes;
	local StaticMeshComponent mesh;
	//super.PostBeginPlay();
	Col1 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	Col2 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	mat = new class'MaterialInstanceConstant';
	mat = ColorMesh.CreateAndSetMaterialInstanceConstant(0);
	mat.SetParent(Material'Ogro.Materials.Ogro_Mat');
	mat.SetVectorParameterValue('BaseColor', Col1);
	mat.SetVectorParameterValue('EmissiveColor', Col2);

	// Bandera
	if(ColorMesh.GetSocketByName('Espalda') != none)
	{
		Bandera = new class'StaticMeshComponent';
		Bandera.SetStaticMesh(StaticMesh'Ogro.Bandera');
		ColorMesh.AttachComponentToSocket(Bandera, 'Espalda');

		matBandera = new class'MaterialInstanceConstant';
		matBandera = Bandera.CreateAndSetMaterialInstanceConstant(0);
		matBandera.SetParent(Material'Ogro.Bandera_Mat');
		matBandera.SetVectorParameterValue('BaseColor', Col1);
		Bandera.SetMaterial(0, matBandera);
	}

	// Barriga
	yes = Rand(10);
	if(yes > 5)
	{
		if(ColorMesh.GetSocketByName('Barriga') != none)
		{
			mesh = new class'StaticMeshComponent';
			mesh.SetStaticMesh(StaticMesh'Ogro.ArmaduraBarriga');
			ColorMesh.AttachComponentToSocket(mesh, 'Barriga');
		}
	}

	// Cuernos
	yes = Rand(10);
	if(yes > 5)
	{
		if(ColorMesh.GetSocketByName('Cuernos') != none)
		{
			mesh = new class'StaticMeshComponent';
			mesh.SetStaticMesh(StaticMesh'Ogro.Cuernos');
			ColorMesh.AttachComponentToSocket(mesh, 'Cuernos');
		}
	}

	// Hombrera Derecha
	yes = Rand(10);
	if(yes > 5)
	{
		if(ColorMesh.GetSocketByName('HombroDerecho') != none)
		{
			mesh = new class'StaticMeshComponent';
			mesh.SetStaticMesh(StaticMesh'Ogro.Hombrera_Derecha');
			ColorMesh.AttachComponentToSocket(mesh, 'HombroDerecho');
		}
	}

	// Hombrera Izquierda
	yes = Rand(10);
	if(yes > 5)
	{
		if(ColorMesh.GetSocketByName('HombroIzquierdo') != none)
		{
			mesh = new class'StaticMeshComponent';
			mesh.SetStaticMesh(StaticMesh'Ogro.Hombrera_Izquierda');
			ColorMesh.AttachComponentToSocket(mesh, 'HombroIzquierdo');
		}
	}

	// Mano Derecha
	yes = Rand(10);
	if(yes > 5)
	{
		if(ColorMesh.GetSocketByName('ManoDerecha') != none)
		{
			mesh = new class'StaticMeshComponent';
			mesh.SetStaticMesh(StaticMesh'Ogro.ManoDerecha');
			ColorMesh.AttachComponentToSocket(mesh, 'ManoDerecha');
		}
	}

	// Cinturon
	yes = Rand(10);
	if(yes > 5)
	{
		if(ColorMesh.GetSocketByName('Pelvis') != none)
		{
			mesh = new class'StaticMeshComponent';
			mesh.SetStaticMesh(StaticMesh'Ogro.Cinturon');
			ColorMesh.AttachComponentToSocket(mesh, 'Pelvis');
		}
	}
}

function SetColor(LinearColor Col)
{
	Col1 = Col;
	mat.SetVectorParameterValue('ColorBase', Col1);
	matBandera.SetVectorParameterValue('ColorBase', Col1);
}

//Gestionamos la ira del Scout true para incrementar ira, flase para decrementarla
function GestionIra(bool mecabreo)
{
	//_DEBUG_ `log("--------------------------------ira"@self.ira);
	if(mecabreo)
	{    
		if(ira <= max_ira)
		{
			ira = ira + 1;
		}
	}
	else
	{
		if(ira > 0)
		{
			ira = ira - 1;
		}
	}
}

defaultproperties
{
	Begin Object Name=PEnemySkeletalMeshComponent
		SkeletalMesh=SkeletalMesh'Ogro.Ogre'
		PhysicsAsset=PhysicsAsset'Ogro.Ogre_Physics_V2'
		AnimTreeTemplate=AnimTree'Ogro.Ogro_AnimTree'
		AnimSets(0)=AnimSet'Ogro.Ogro_Anim'
		Translation=(Z=-50.0)
		Scale=3
	End Object

	ColorMesh=PEnemySkeletalMeshComponent

	GroundSpeed=100.0
	m_defaultGroundSpeed=GroundSpeed
	m_puntos_al_morir = 300
	ira=0;
	max_ira=100;
}
