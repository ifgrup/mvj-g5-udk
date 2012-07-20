class PEnemyPawn_Minion extends PEnemy;

var MaterialInstanceConstant mat;
var SkeletalMeshComponent ColorMesh;
var LinearColor Col1, Col2;

var vector ViewX,ViewY,ViewxZ;


simulated function PostBeginPlay()
{
	Col1 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	Col2 = MakeLinearColor(FRand(), FRand(), FRand(), 1.0);
	mat = new class'MaterialInstanceConstant';
	mat = ColorMesh.CreateAndSetMaterialInstanceConstant(0);
	mat.SetParent(Material'Gelatinos.Walker.Gelatino_Walker_MASTER');
	mat.SetVectorParameterValue('ColorBase', Col1);
	mat.SetVectorParameterValue('DetailColor', Col2);

	ColorMesh.SetMaterial(0, mat);
}

function SetColor(LinearColor Col)
{
	Col1 = Col;
	mat.SetVectorParameterValue('ColorBase', Col1);
}

event TakeDamage(int iDamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
    life--;
	`log("vida minion" @life);
	if(life == 0)
	{
		
		Destroy();
		if(PGame(WorldInfo.Game) != none)
		{
		    PGame(WorldInfo.Game).EnemyKilled();
			PGame(WorldInfo.Game).SetCredito(PGame(WorldInfo.Game).creditos + m_puntos_al_morir);
		}
	}
}



	function ActualizaRotacion(float DeltaTime)
	{
		local rotator ViewRotation;
		local vector MyFloor, CrossDir, FwdDir, OldFwdDir, RealFloor;
		local float angulo;
		
		MyFloor = self.Floor;
		if(OldFloor == vect(0,0,1))
		{
			OldFloor = MyFloor;
			OldFloor.X += 0.0001; //para que sean diferentes y entre en el if
		}

		
		//Si estoy saltando, nada de transiciones de normales, sigo teniendo como normal la vertical del salto y punto
		/*****
		if ( MyFloor != OldFloor )
		{
			// smoothly transition between floors
			//Para colocar al bicho en la perpendicular del suelo
			RealFloor = MyFloor;
			MyFloor = Normal(6*DeltaTime * MyFloor + (1 - 6*DeltaTime) * OldFloor);
 
			if ( (RealFloor dot MyFloor) > 0.999 )
			{
				MyFloor = RealFloor;
			}
			else
			{
				// translate view direction
				CrossDir = Normal(RealFloor Cross OldFloor);
				FwdDir = CrossDir cross MyFloor; //Hacia delante, forward
				OldFwdDir = CrossDir cross OldFloor; //El hacia delante que tenía antes
				ViewX = MyFloor * (OldFloor dot ViewX) + CrossDir * (CrossDir dot ViewX) + FwdDir * (OldFwdDir dot ViewX);
				ViewX = Normal(ViewX);
				ViewZ = MyFloor * (OldFloor dot ViewZ) + CrossDir * (CrossDir dot ViewZ) + FwdDir * (OldFwdDir dot ViewZ);
				ViewZ = Normal(ViewZ);
				OldFloor = MyFloor;
				ViewY = Normal(MyFloor cross ViewX);
				//Pawn.mesh.SetRotation(OrthoRotation(ViewX,ViewY,ViewZ));
			}
		}
        *************/

		
		/*Ajustamos el Yaw en función del ángulo formado por el vector velocidad, y el ViewX, para que el 
		 * bicho realmente tenga como ViewX su velocidad. Pero no lo asignamos directamente,sino que dejamos los cálculos
		 * para que la rotación se calcule igual que con el pawn, y luego lo giramos rotando por yaw*/
		//ViewZ = Normal(5*DeltaTime * MyFloor + (1 - 5*DeltaTime) * OldFloor);
		
		
		FloorActual = vinterpto(FloorActual,self.Floor,deltatime,1);
		ViewZ = FloorActual;
		DrawDebugCylinder(self.Location,self.Location+Floor*130,4,10,100,100,50,false);
		DrawDebugCylinder(self.Location,self.Location+FloorActual*130,4,10,100,10,255,false);
		
		ViewX = Normal(5*DeltaTime * Normal(self.velocity) + (1 - 5*DeltaTime) * ViewX);
		ViewY = Normal (ViewZ cross ViewX);
		ViewRotation = OrthoRotation(ViewX,ViewY,ViewZ);
		
		SetRotation(ViewRotation);
		self.SetViewRotation(ViewRotation);
		//self.Mesh.SetRotation(ViewRotation);
		//self.SetViewRotation(ViewRotation);
		
		//Dibujamos cilindro para la direccion de su orientacion, y para su movimiento
		//FlushPersistentDebugLines();
		DrawDebugCylinder(self.Location,self.Location+ViewX*100,5,5,255,0,0,false);
		DrawDebugCylinder(self.Location,self.Location+normal(self.Velocity)*100,5,5,0,0,255,false);
		DrawDebugCylinder(self.Location,self.Location+ViewZ*100,5,5,0,255,0,false);

		GetAxes(self.Rotation,viewx,viewy,viewz);
		DrawDebugCylinder(self.Location,self.Location+ViewX*125,5,5,255,255,255,false);


	}



defaultproperties
{


	//Begin Object Class=SkeletalMeshComponent Name=WPawnSkeletalMeshComponent
	Begin Object Name=WPawnSkeletalMeshComponent
		/*SkeletalMesh=SkeletalMesh'Gelatinos.Walker.GelatinoBipedoEsqueleto'
		Translation=(Z=-70.0)
		Scale=0.7*/
		//demo
		SkeletalMesh=SkeletalMesh'CH_LIAM_Cathode.Mesh.SK_CH_LIAM_Cathode'
		AnimTreeTemplate=AnimTree'CH_AnimHuman_Tree.AT_CH_Human'
		PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
		AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
		
		Scale=3
		//Translation=(Z=-1670.0)
		//demo
	End Object


	ColorMesh=WPawnSkeletalMeshComponent


		

	GroundSpeed=50.0
	m_puntos_al_morir = 100
}
