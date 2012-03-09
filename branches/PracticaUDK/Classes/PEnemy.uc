class PEnemy extends PActor
    abstract;

var float BumpDamage;
var Pawn Enemy;
var float MovementSpeed;
var float AttackDistance;
var Material SeekingMat, AttackingMat, FleeingMat;
var StaticMeshComponent MyMesh;
var bool bAttacking;

function GetEnemy()
{
    local PPlayerController PC;

    foreach LocalPlayerControllers(class'PPlayerController', PC)
    {
        if(PC.Pawn != none)
            Enemy = PC.Pawn;
    }
}

function EndAttack()
{
    bAttacking = false;

    if(GetStateName() == 'Seeking')
        MyMesh.SetMaterial(0, SeekingMat);
}

function RunAway()
{
}

auto state Seeking
{
    function BeginState(Name PreviousStateName)
    {
		SetPhysics(PHYS_Spider);
        if(!bAttacking)
            MyMesh.SetMaterial(0, SeekingMat);
    }

    function Tick(float DeltaTime)
    {
        local vector NewLocation;

        if(bAttacking)
            return;

        if(Enemy == none)
            GetEnemy();

        if(Enemy != none)
        {
            NewLocation = Location;
            NewLocation += normal(Enemy.Location - Location) * MovementSpeed * DeltaTime;
			//Move(NewLocation);
            SetLocation(NewLocation);
    
            if(VSize(NewLocation - Enemy.Location) < AttackDistance)
                GoToState('Attacking');
        }
    }
}

state Attacking
{
    function BeginState(Name PreviousStateName)
    {
        MyMesh.SetMaterial(0, AttackingMat);
    }

    function Tick(float DeltaTime)
    {
        bAttacking = true;

        if(Enemy == none)
            GetEnemy();
    
        if(Enemy != none)
        {
            Enemy.Bump(self, CollisionComponent, vect(0,0,0));
    
            if(VSize(Location - Enemy.Location) > AttackDistance)
                GoToState('Seeking');
        }
    }
    
    function EndState(name NextStateName)
    {
        SetTimer(1, false, 'EndAttack');
    }
}

state Fleeing
{
    ignores TakeDamage;

    function BeginState(Name PreviousStateName)
    {
        MyMesh.SetMaterial(0, FleeingMat);
    }

    function Tick(float DeltaTime)
    {
        local vector NewLocation;

        if(Enemy == none)
            GetEnemy();
    
        if(Enemy != none)
        {
            NewLocation = Location;
            NewLocation -= normal(Enemy.Location - Location) * MovementSpeed * DeltaTime;
            SetLocation(NewLocation);
        }
    }
}

defaultproperties
{
    SeekingMat=Material'EditorMaterials.WidgetMaterial_X'
    AttackingMat=Material'EditorMaterials.WidgetMaterial_Z'
    FleeingMat=Material'EditorMaterials.WidgetMaterial_Y'
    AttackDistance=96.0
    MovementSpeed=256.0
    BumpDamage=5.0
    bBlockActors=True
    bCollideActors=True

    Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
        bEnabled=TRUE
    End Object
    Components.Add(MyLightEnvironment)

    Begin Object Class=StaticMeshComponent Name=EnemyMesh
        StaticMesh=StaticMesh'UN_SimpleMeshes.TexPropCube_Dup'
        Materials(0)=Material'EditorMaterials.WidgetMaterial_X'
        LightEnvironment=MyLightEnvironment
        Scale3D=(X=0.2,Y=0.2,Z=0.2)
    End Object
    Components.Add(EnemyMesh)
    MyMesh=EnemyMesh

    Begin Object Class=CylinderComponent Name=CollisionCylinder
        CollisionRadius=32.0
        CollisionHeight=64.0
        BlockNonZeroExtent=true
        BlockZeroExtent=true
        BlockActors=true
        CollideActors=true
    End Object
    CollisionComponent=CollisionCylinder
    Components.Add(CollisionCylinder)
}
