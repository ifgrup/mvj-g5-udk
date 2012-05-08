class PShield extends KActorSpawnable
	placeable;

var () MeshComponent Mesh;
var () MaterialInstanceConstant ShieldMICPreset;
var () MaterialInstanceConstant ShieldImpactMICPreset;

var MaterialInstanceConstant ShieldMIC;
var array<StaticMeshComponent> Impacts;
var array<MaterialInstanceConstant> ImpactMICs;
var () LinearColor ShieldColor;
var () Vector2D Tiling;
var () Float EdgeSharpness;
var () Float ImpactRadius;
var () Float ImpactDissolveSpeed;
var () Name StaticMeshClass;

simulated event PostBeginPlay()
{
	local LinearColor tmpTiling;
	Super.PostBeginPlay();
	ShieldMIC = new(None) Class'MaterialInstanceConstant';
	ShieldMIC.SetParent(ShieldMICPreset);
//	ShieldMIC.SetScalarParameterValue('ImpactRadius',ImpactRadius);
	ShieldMIC.SetScalarParameterValue('EdgeSharpness',EdgeSharpness);
	ShieldMIC.SetVectorParameterValue('Color',ShieldColor);
	tmpTiling = MakeLinearColor(Tiling.X,Tiling.Y,0,0);
	ShieldMIC.SetVectorParameterValue('Tiling',tmpTiling);

	Mesh.SetMaterial(0,ShieldMIC);
}

event RigidBodyCollision (PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent, const out CollisionImpactData RigidCollisionData, int ContactIndex)
{
	TakeDamage(1,None,RigidCollisionData.ContactInfos[ContactIndex].ContactPosition,vect(0,0,0),None);
}

simulated function TakeRadiusDamage (Controller InstigatedBy, float BaseDamage, float DamageRadius, class<DamageType> DamageType, float Momentum, Object.Vector HurtOrigin, bool bFullDamage, Actor DamageCauser, optional float DamageFalloffExponent)
{
	TakeDamage(BaseDamage,InstigatedBy,HurtOrigin,vect(0,0,0),DamageType);
}

event TakeDamage (int DamageAmount, Controller EventInstigator, Object.Vector HitLocation, Object.Vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local MaterialInstanceConstant tmpMIC;
	local StaticMeshComponent tmp;
	local LinearColor tmpHitLoc, tmpTiling;
	
	tmp = new () class'StaticMeshComponent';
	tmp.SetStaticMesh(StaticMesh'Shield.ShieldMesh');
//	tmp.SetStaticMesh(StaticMeshComponent(Mesh).StaticMesh);
//	tmp.;
//	tmp.bAcceptsDynamicDecals=false;

	tmpMIC = new(None) Class'MaterialInstanceConstant';
	tmpMIC.SetParent(ShieldImpactMICPreset);
	tmpHitLoc=MakeLinearColor(HitLocation.X-Location.X-tmp.Translation.X,HitLocation.Y-Location.Y-tmp.Translation.Y,HitLocation.Z-Location.Z-tmp.Translation.Z,1);
	tmpMIC.SetVectorParameterValue('ImpactPosition',tmpHitLoc);
	tmpMIC.SetScalarParameterValue('ImpactTime',0);
	tmpMIC.SetScalarParameterValue('ImpactRadius',ImpactRadius);
	tmpMIC.SetScalarParameterValue('EdgeSharpness',EdgeSharpness);
	tmpMIC.SetVectorParameterValue('Color',ShieldColor);
	tmpTiling = MakeLinearColor(Tiling.X,Tiling.Y,0,0);
	tmpMIC.SetVectorParameterValue('Tiling',tmpTiling);

	tmp.SetMaterial(0,tmpMIC);
//	tmp.SetScale3D(vect(10,10,10));
    AttachComponent(tmp);
	Impacts.AddItem(tmp);
	ImpactMICs.AddItem(tmpMIC);
}

simulated function Tick(Float Delta)
{
	local int i;
	local float ImpactTime;
	Super.Tick(Delta);
	For(i=0;i<ImpactMICs.Length;i++)
	{
		if(ImpactMICs[i].GetScalarParameterValue('ImpactTime',ImpactTime))
		{
			ImpactTime+=Delta*ImpactDissolveSpeed;
			ImpactMICs[i].SetScalarParameterValue('ImpactTime',ImpactTime);
			if(ImpactTime>1)
			{
				DetachComponent(Impacts[i]);
				Impacts.RemoveItem(Impacts[i]);
				ImpactMICs.RemoveItem(ImpactMICs[i]);
				i--;	//Kinda ugly :D
			}
		}
	}
}

defaultproperties
{
	Begin Object Name=StaticMeshComponent0
		LightEnvironment=MyLightEnvironment
		StaticMesh=StaticMesh'Shield.ShieldMesh'
		bNotifyRigidBodyCollision=true
		ScriptRigidBodyCollisionThreshold=0.001
		
		bAcceptsDecals=false
		bAcceptsStaticDecals=false
		bAcceptsDynamicDecals=false
	End Object

	Components.Add(StaticMeshComponent0);
	Mesh=StaticMeshComponent0
	
	ShieldColor=(R=0,G=0.5,B=1,A=1)
	Tiling=(X=10,Y=5)
	EdgeSharpness=0
	ImpactRadius=150
	ImpactDissolveSpeed=0.5
	ShieldMICPreset=MaterialInstanceConstant'Shield.ShieldMat_INST'
	ShieldImpactMICPreset=MaterialInstanceConstant'Shield.ImpactMat_INST'
	Physics=PHYS_None
}
