class PTree extends PKActor;

var(Tree) SkeletalMeshComponent TreeMesh;

var SkeletalMesh skMesh0;
var PhysicsAsset physAsset0;
var SkeletalMesh skMesh1;
var PhysicsAsset physAsset1;
var SkeletalMesh skMesh2;
var PhysicsAsset physAsset2;

var MaterialInstanceConstant mat;

var int m_toques; //toques que lleva recibido de los minions
var int m_toquesToDestroy; //máximo de toques que soporta antes de destruirse

var bool m_caer; //Está el árbol cayendo?
var Quat m_QuatInicial; //Para la caída
var vector m_ejeCaida;
var float m_anguloCaida;

event Bump(Actor Other, PrimitiveComponent OtherComp,vector VectorHitNormal)
{
	local int kk;
	kk=0;
	kk=kk+1;
}

event Touch(Actor Other, PrimitiveComponent OtherComp,Vector HitLocation,Vector HitNormal)
{
	local int kk;
	kk=0;
	kk=kk+1;

}



simulated function PostBeginPlay()
{
	local int i, j;
	local SkeletalMesh sk;
	local PhysicsAsset pa;
	local array<MaterialInstanceConstant> m;

	i=Rand(3);
	switch(i)
	{
	case 0:
		sk=skMesh0;
		pa=physAsset0;
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol01_MAT_01');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol01_MAT_02');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol01_MAT_03');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol01_MAT_04');
		break;
	case 1:
		sk=skMesh1;
		pa=physAsset1;
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol03_MAT_01');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol03_MAT_02');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol03_MAT_03');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol03_MAT_04');
		break;
	case 2:
		sk=skMesh2;
		pa=physAsset2;
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol04_MAT_01');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol04_MAT_02');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol04_MAT_03');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol04_MAT_04');
		break;
	}

	TreeMesh.SetSkeletalMesh(sk);
	TreeMesh.SetPhysicsAsset(pa);

	j = Rand(m.Length);
	TreeMesh.SetMaterial(0, m[j]);
}

function Toque()
{
	m_toques ++;
	if (m_toques >= m_toquesToDestroy )
	{
		Destruccion();
	}
}

function Destruccion()
{
	//Se llama cuando se llega a los n toques de los minions, o bien cuando se la come un ogro.
	//Debemos mostrar el sistema de partículas de las hojas y dejar el troncho del árbol
	local vector rx,ry,rz;
    if (m_caer)
    {
		return;
    }

	GetAxes(self.Rotation,rx,ry,rz);
	`log("Destruccion arbol "@self.Name);

	m_QuatInicial = QuatFromRotator(self.Rotation);
	m_ejeCaida = ry;
	m_caer = true; //Para que en el tick se tire pabajo
	//self.SetCollision(false,false,false);
}

event Tick(float delta)
{
	local rotator r1,r2;
	local Quat qActual,ernion;

	if (!m_caer)
	{
		return;
	}
	Destroy();
	return;


	m_anguloCaida += delta*10;

	`log("Angulo caida " @m_anguloCaida);

	ernion =  QuatFromAxisAndAngle(m_ejeCaida,-m_anguloCaida*DegToRad); 
	qActual =  QuatProduct(ernion,m_QuatInicial);

	//DrawDebugCylinder(self.Location,self.Location+vector(QuatToRotator(qActual))*100,14,14,200,0,0,false); //origen rojo
	//DrawDebugCylinder(self.Location,self.Location+vector(r2)*100,10,10,0,0,200,true); //destino azul
		
	self.treemesh.SetRotation(QuatToRotator(qActual));
	self.SetRotation(QuatToRotator(qActual));
	
	self.TreeMesh.ForceUpdate(true);
	self.ForceUpdateComponents();

	if (m_anguloCaida > 80 )
	{
		//Ya ha llegado a la orientación final
		//DrawDebugSphere(self.Location,120,20,0,200,0,true);
		Destroy();
	}
	
}

defaultproperties
{
	Begin Object class=SkeletalMeshComponent name=tree
		SkeletalMesh=SkeletalMesh'Vegetacion.Arbol01'
		PhysicsAsset=PhysicsAsset'Vegetacion.Arbol01_Physics'
		CollideActors=true
		BlockActors=true
		BlockZeroExtent=true
		BlockNonZeroExtent=true
		BlockRigidBody=true
		bHasPhysicsAssetInstance=true
		//bUpdateKinematicBonesFromAnimation=false
		PhysicsWeight=1.0
		RBChannel=RBCC_GameplayPhysics
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE)
		LightEnvironment=MyLightEnvironment
		bSkipAllUpdateWhenPhysicsAsleep=TRUE
		bBlockFootPlacement=false
    End Object

	TreeMesh=tree
	skMesh0=SkeletalMesh'Vegetacion.Arbol01'
	physAsset0=PhysicsAsset'Vegetacion.Arbol01_Physics'
	skMesh1=SkeletalMesh'Vegetacion.Arbol03'
	physAsset1=PhysicsAsset'Vegetacion.Arbol03_Physics'
	skMesh2=SkeletalMesh'Vegetacion.Arbol04'
	physAsset2=PhysicsAsset'Vegetacion.Arbol04_Physics'

	CollisionComponent=tree
//	bCollideComplex=true 
	bCanStepUpOn=false
	BlockRigidBody=true
	bCollideActors=true
	bCollideWorld=true
	//CollisionType=COLLIDE_BlockAll
	Components.Add(tree) 
	m_toquesToDestroy = 10
	Physics=PHYS_None
}
