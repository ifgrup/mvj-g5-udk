class PTree extends PKActor;

var(Tree) SkeletalMeshComponent TreeMesh;

var SkeletalMesh skMesh0;
var PhysicsAsset physAsset0;
var SkeletalMesh skMesh1;
var PhysicsAsset physAsset1;
var SkeletalMesh skMesh2;
var PhysicsAsset physAsset2;

var StaticMesh stMesh0;
var StaticMesh stMesh1;
var StaticMesh stMesh2;
var StaticMesh meshTocon;

var MaterialInstanceConstant mat;

var int m_toques; //toques que lleva recibido de los minions
var int m_toquesToDestroy; //máximo de toques que soporta antes de destruirse

var bool m_temblar_arbol; //Está el árbol temblando?
var Quat m_QuatInicial; //Para la caída
var vector m_ejeTemblor;
var float m_anguloTemblor;
var float m_tiempoTemblor;
var array<float> m_angulos_temblor; //Array de angulos del tembleque. Debe tener 8 posiciones, una para cada medio segundo
var int m_idx_temblor; //para acceder al vector anterior
var float m_tiempoLastTemblor;
var rotator m_rotInicial;
var vector m_pos_inicial;

event Bump(Actor Other, PrimitiveComponent OtherComp,vector VectorHitNormal)
{
	self.SetLocation(m_pos_inicial);
}

event Touch(Actor Other, PrimitiveComponent OtherComp,Vector HitLocation,Vector HitNormal)
{
	self.SetLocation(m_pos_inicial);
}

event TakeDamage(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
		
	//Ha sido por disparo de Giru?
	if(PMisiles(DamageCauser) != None && PPlayerController(EventInstigator) != None)
	{
		Toque();
		return;
	}

	//Ha sido por disparo de TurretCannon?
    if(PMisiles(DamageCauser) != None && PMisiles(DamageCauser).disparador == 'PTurretCannon')
	{
		Toque();
		return;
	}

}


simulated function PostBeginPlay()
{
	local int i, j;
	local SkeletalMesh sk;
	local PhysicsAsset pa;
	local array<MaterialInstanceConstant> m;
	local vector rx,ry,rz;


	i=Rand(3);
	switch(i)
	{
	case 0:
		sk=skMesh0;
		pa=physAsset0;
		meshTocon=stMesh0;
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol01_MAT_01');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol01_MAT_02');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol01_MAT_03');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol01_MAT_04');
		break;
	case 1:
		sk=skMesh1;
		pa=physAsset1;
		meshTocon=stMesh1;
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol03_MAT_01');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol03_MAT_02');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol03_MAT_03');
		m.AddItem(MaterialInstanceConstant'Vegetacion.Materials.Arbol03_MAT_04');
		break;
	case 2:
		sk=skMesh2;
		pa=physAsset2;
		meshTocon=stMesh2;
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
	
	//Guardo la posición inicial
	m_pos_inicial = self.Location;

	m_angulos_temblor.AddItem(-4);
	m_angulos_temblor.AddItem(4);
	m_angulos_temblor.AddItem(-3);
	m_angulos_temblor.AddItem(3);
	m_angulos_temblor.AddItem(-2);
	m_angulos_temblor.AddItem(2);
	m_angulos_temblor.AddItem(-1);
	m_angulos_temblor.AddItem(1);

	//Posicion inicial. para tenerla siempre guardada
	m_QuatInicial = QuatFromRotator(self.treemesh.Rotation);
	GetAxes(self.treemesh.Rotation,rx,ry,rz);
	m_rotInicial = self.treemesh.Rotation;
	m_ejeTemblor = ry;
}

static final function vector MatrixGetScale(Matrix TM)
{
    local Vector s;
    s.x = sqrt(TM.XPlane.X**2 + TM.XPlane.Y**2 + TM.XPlane.Z**2);
    s.y = sqrt(TM.YPlane.X**2 + TM.YPlane.Y**2 + TM.YPlane.Z**2);
    s.z = sqrt(TM.ZPlane.X**2 + TM.ZPlane.Y**2 + TM.ZPlane.Z**2);
    return s;
}

simulated event Destroyed()
{
	local PTreeDestruido tocon;
	
	//PGame(WorldInfo.Game).Broadcast(self, Other.Name @ " me ha bumpeado!");
	tocon = Spawn(class'PTreeDestruido',,,self.Location,self.Rotation);
	tocon.SetDrawScale3D(self.DrawScale3D);
	tocon.SetStaticMesh(meshTocon);
	WorldInfo.ForceGarbageCollection();
}

function Toque()
{
	m_toques ++;
	TemblarArbol();

	if (m_toques >= m_toquesToDestroy )
	{
		Destruccion();
	}
}

function TemblarArbol()
{
	`log("Tembleque " @self.Name);

	if (m_temblar_arbol)
	{
		return; //intento de evitar toques recursivos
	}
	m_temblar_arbol = true;
	m_tiempoTemblor = 0;
	//Restauramos la posición inicial, por si llega un toque en medio de otro toque.
	self.treemesh.SetRotation(m_rotInicial);
}

function Destruccion()
{
	//Se llama cuando se llega a los n toques de los minions, o bien cuando se la come un ogro.
	//Debemos mostrar el sistema de partículas de las hojas y dejar el troncho del árbol
	self.bWorldGeometry = false;
	self.SetCollision(false,false,false);
	`log("Destruccion arbol "@self.Name);
	self.Destroy();
}

event Tick(float delta)
{
	local Quat qActual,ernion;

	if (!m_temblar_arbol)
	{
		return;
	}
	
	m_tiempoTemblor += delta;
	if (m_idx_temblor >=  m_angulos_temblor.Length)
	{
		m_tiempoTemblor = 0;
		m_tiempoLastTemblor = 0;
		m_temblar_arbol = false;
		m_idx_temblor = 0;
		//Restauramos la posición inicial porsiaca
		self.treemesh.SetRotation(m_rotInicial);
		//self.SetRotation(m_rotInicial);
		return;
	}

	if ( (m_tiempoTemblor - m_tiempoLastTemblor) > 0.1)
	{
		//tembleque cada 0.2 segundos
		m_tiempoLastTemblor = m_tiempoTemblor;
	}
	else
	{
		return;
	}

	
	m_anguloTemblor = m_angulos_temblor[m_idx_temblor];
	m_idx_temblor = m_idx_temblor +1; //Inc después para que cuente el cero
	//_DEBUG `log("angulo temblor "@m_anguloTemblor);

	ernion =  QuatFromAxisAndAngle(m_ejeTemblor,m_anguloTemblor*DegToRad); 
	qActual =  QuatProduct(ernion,m_QuatInicial);

	//DrawDebugCylinder(self.Location,self.Location+vector(QuatToRotator(qActual))*100,14,14,200,0,0,false); //origen rojo
	//DrawDebugCylinder(self.Location,self.Location+vector(r2)*100,10,10,0,0,200,true); //destino azul
		
	self.treemesh.SetRotation(QuatToRotator(qActual));
	//self.SetRotation(QuatToRotator(qActual));

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
		//RBChannel=RBCC_GameplayPhysics
		//RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE)
		LightEnvironment=MyLightEnvironment
		bSkipAllUpdateWhenPhysicsAsleep=TRUE
		bBlockFootPlacement=false
    End Object

	TreeMesh=tree
	skMesh0=SkeletalMesh'Vegetacion.Arbol01'
	stMesh0=StaticMesh'Vegetacion.Arbol01_Tocon'
	physAsset0=PhysicsAsset'Vegetacion.Arbol01_Physics'
	skMesh1=SkeletalMesh'Vegetacion.Arbol03'
	stMesh1=StaticMesh'Vegetacion.Arbol03_Tocon'
	physAsset1=PhysicsAsset'Vegetacion.Arbol03_Physics'
	skMesh2=SkeletalMesh'Vegetacion.Arbol04'
	stMesh2=StaticMesh'Vegetacion.Arbol04_Tocon'
	physAsset2=PhysicsAsset'Vegetacion.Arbol04_Physics'

	CollisionComponent=tree
//	bCollideComplex=true 
	bCanStepUpOn=false
	BlockRigidBody=true
	bCollideActors=true
	bCollideWorld=true
	CollisionType=COLLIDE_BlockAll
	Components.Add(tree) 
	m_toquesToDestroy=5
	Physics=PHYS_None
	bWorldGeometry=true
	bCanBeDamaged=true
}
