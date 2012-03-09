class PKActor extends KActorSpawnable
	placeable
	implements(PMouseInteractionInterface);

/*
 * 
 * NOTA:
 * Se ha extendido la clase KActorSpawnable y no KActor, debido a que en tiempo de ejecucion
 * no se pueden destruir los actores de la clase KActor (mediante codigo; por Kismet parece que si), ya que la variable bNoDelete es TRUE
 * 
 */

var Vector CachedMouseHitLocation;
var Vector CachedMouseHitNormal;
var Vector CachedMouseWorldOrigin;
var Vector CachedMouseWorldDirection;

var(ItemProperties) const int ItemIndex;

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

function DestroyItem()
{
	Destroy();
}


DefaultProperties
{
	SupportedEvents(5)=class'PSeqEvent_MouseInput'
	//El sprite con el que se identificara el objeto cuando lo creemos en el editor
	
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.S_Actor'
		HiddenGame=True
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Components.Add(Sprite)

	//Por defecto el indice del item es 0
	ItemIndex=0
}

