class PActorInteractuable extends PActor
	implements(PMouseInteractionInterface);


var Vector CachedMouseHitLocation;
var Vector CachedMouseHitNormal;
var Vector CachedMouseWorldOrigin;
var Vector CachedMouseWorldDirection;



//  ===
//  Implementacion de TITMouseInteractionInterface 
//  ===

function MouseLeftPressed(Vector MouseWorldOrigin, Vector MouseWorldDirection, Vector HitLocation, Vector HitNormal)
{
	CachedMouseWorldOrigin = MouseWorldOrigin;
	CachedMouseWorldDirection = MouseWorldDirection;
	CachedMouseHitLocation = HitLocation;
	CachedMouseHitNormal = HitNormal;
	//El ultimo parametro de la funcion indica el indice de salida del evento
	TriggerEventClass(class'PSeqEvent_MouseInput', self, 0);
}

function MouseLeftReleased(Vector MouseWorldOrigin, Vector MouseWorldDirection)
{
	CachedMouseWorldOrigin = MouseWorldOrigin;
	CachedMouseWorldDirection = MouseWorldDirection;
	CachedMouseHitLocation = Vect(0.f, 0.f, 0.f);
	CachedMouseHitNormal = Vect(0.f, 0.f, 0.f);
	TriggerEventClass(class'PSeqEvent_MouseInput', self, 1);
}

function MouseRightPressed(Vector MouseWorldOrigin, Vector MouseWorldDirection, Vector HitLocation, Vector HitNormal)
{
	CachedMouseWorldOrigin = MouseWorldOrigin;
	CachedMouseWorldDirection = MouseWorldDirection;
	CachedMouseHitLocation = HitLocation;
	CachedMouseHitNormal = HitNormal;
	TriggerEventClass(class'PSeqEvent_MouseInput', Self, 2);
}

function MouseRightReleased(Vector MouseWorldOrigin, Vector MouseWorldDirection)
{
	CachedMouseWorldOrigin = MouseWorldOrigin;
	CachedMouseWorldDirection = MouseWorldDirection;
	CachedMouseHitLocation = Vect(0.f, 0.f, 0.f);
	CachedMouseHitNormal = Vect(0.f, 0.f, 0.f);
	TriggerEventClass(class'PSeqEvent_MouseInput', Self, 3);
}

function MouseMiddlePressed(Vector MouseWorldOrigin, Vector MouseWorldDirection, Vector HitLocation, Vector HitNormal)
{
	CachedMouseWorldOrigin = MouseWorldOrigin;
	CachedMouseWorldDirection = MouseWorldDirection;
	CachedMouseHitLocation = HitLocation;
	CachedMouseHitNormal = HitNormal;
	TriggerEventClass(class'PSeqEvent_MouseInput', Self, 4);
}

function MouseMiddleReleased(Vector MouseWorldOrigin, Vector MouseWorldDirection)
{
	CachedMouseWorldOrigin = MouseWorldOrigin;
	CachedMouseWorldDirection = MouseWorldDirection;
	CachedMouseHitLocation = Vect(0.f, 0.f, 0.f);
	CachedMouseHitNormal = Vect(0.f, 0.f, 0.f);
	TriggerEventClass(class'PSeqEvent_MouseInput', Self, 5);
}

function MouseScrollUp(Vector MouseWorldOrigin, Vector MouseWorldDirection)
{
	CachedMouseWorldOrigin = MouseWorldOrigin;
	CachedMouseWorldDirection = MouseWorldDirection;
	CachedMouseHitLocation = Vect(0.f, 0.f, 0.f);
	CachedMouseHitNormal = Vect(0.f, 0.f, 0.f);
	TriggerEventClass(class'PSeqEvent_MouseInput', Self, 6);
}

function MouseScrollDown(Vector MouseWorldOrigin, Vector MouseWorldDirection)
{
	CachedMouseWorldOrigin = MouseWorldOrigin;
	CachedMouseWorldDirection = MouseWorldDirection;
	CachedMouseHitLocation = Vect(0.f, 0.f, 0.f);
	CachedMouseHitNormal = Vect(0.f, 0.f, 0.f);
	TriggerEventClass(class'PSeqEvent_MouseInput', Self, 7);
}

function MouseOver(Vector MouseWorldOrigin, Vector MouseWorldDirection)
{
	CachedMouseWorldOrigin = MouseWorldOrigin;
	CachedMouseWorldDirection = MouseWorldDirection;
	CachedMouseHitLocation = Vect(0.f, 0.f, 0.f);
	CachedMouseHitNormal = Vect(0.f, 0.f, 0.f);
	TriggerEventClass(class'PSeqEvent_MouseInput', Self, 8);
}

function MouseOut(Vector MouseWorldOrigin, Vector MouseWorldDirection)
{
	CachedMouseWorldOrigin = MouseWorldOrigin;
	CachedMouseWorldDirection = MouseWorldDirection;
	CachedMouseHitLocation = Vect(0.f, 0.f, 0.f);
	CachedMouseHitNormal = Vect(0.f, 0.f, 0.f);
	TriggerEventClass(class'PSeqEvent_MouseInput', Self, 9);
}

function Vector GetHitLocation()
{
	return CachedMouseHitLocation;
}

function Vector GetHitNormal()
{
	return CachedMouseHitNormal;
}

function Vector GetMouseWorldOrigin()
{
	return CachedMouseWorldOrigin;
}

function Vector GetMouseWorldDirection()
{
	return CachedMouseWorldDirection;
}


DefaultProperties
{
}
