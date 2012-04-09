class PEnemy extends UTPawn
Placeable;

var PPawn P; // variable to hold the pawn we bump into
var() int DamageAmount;   //how much brain to munch
var vector DireccionCaida;

simulated function PostBeginPlay()
{
   super.PostBeginPlay();

   //Hacemos que caigan hasta el suelo. Una vez en el suelo, spider
  // GoToState('Cayendo');
   
}

auto state Cayendo
{
	event BeginState(name EstadoPrevio)
	{
		//Nada más empezar estamos en este estado, cayendo desde el EnemySpawner.
		//Nos ponemos en physics flying hasta llegar al suelo, y luego, pasamos a spider y al comportamiento normal
		local Vector vCaida;

		vCaida=PGame(WorldInfo.game).m_centroPlaneta-Location;
		Velocity=Normal(vCaida)*400; //Lo decimos la velocidad a la que volará hasta el suelo, como si estuviera cayendo
		SetPhysics(PHYS_Flying);
		DireccionCaida=Normal(vCaida);
		`log('Enemy entrando en estado CAYENDO');
		bDirectHitWall = true;
	}
	
	event Tick(float delta)
	{
		//`log("->" @self.Location @self.Velocity);
		DrawDebugCone(self.Location,Velocity,100,0.01,0.1,20,MakeColor(200,0,0));
		
	}
	// cuando llegue al suelo:
	event HitWall(Vector HitNormal,Actor Wall, PrimitiveComponent WallComp)
	{
		`log('Enemy ha llegado al suelo');
		SetBase(Wall, HitNormal);
		bDirectHitWall = false; 
		SetPhysics(PHYS_None);
		SetPhysics(PHYS_Spider); // "Glue" back to surface

		GotoState(''); //estado default
	}
   
	event EndState(Name NextState)
	{
		
		`log('Enemy sale de estado Cayebdo '@NextState);
	}

}//state Cayendo


//over-ride epics silly character stuff
simulated function SetCharacterClassFromInfo(class<UTFamilyInfo> Info)
{
	Return;
}

simulated event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
{
	Super.Bump( Other, OtherComp, HitNormal );

	if ( (Other == None) || Other.bStatic )
		return;

	P = PPawn(Other); //the pawn we might have bumped into

	if ( P != None)  //if we hit a pawn
	{
		if (PEnemy(Other) != None)  //we hit another zombie
		{
			return; //dont do owt
		}
		else
		{
			//use a timer so it just takes health once each encounter
			//theres other better ways of doing this probably
			SetTimer(0.1, false, 'EatSlow');
		}
	}
}

simulated function EatSlow()
{
	P.Health -= DamageAmount; // eat brains! mmmmm

	if (P.Health <= 0)//if the pawn has no health
	{
		P.Destroy();  //kill it
	}
}




defaultproperties
{
	Begin Object Name=WPawnSkeletalMeshComponent
		AnimTreeTemplate=AnimTree'CH_AnimHuman_Tree.AT_CH_Human'
		SkeletalMesh=SkeletalMesh'CH_IronGuard_Male.Mesh.SK_CH_IronGuard_MaleA'
		AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
		PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
	End Object

	RagdollLifespan=180.0 //how long the dead body will hang around for

	AirSpeed=200
	GroundSpeed=200

	ControllerClass=class'PEnemyBot'
	bDontPossess=false
	//bNotifyStopFalling=true --> si quisiéramos controlar el fin del falling así, se ejecutaría StoppedFalling.
	DamageAmount=10
}
