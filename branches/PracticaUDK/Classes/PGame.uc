/**
 * Configuración general del juego
 * */

class PGame extends FrameworkGame;

var const float fDecalSize;

defaultproperties
{
	PlayerControllerClass=class'PGame.PPlayerController'
	DefaultPawnClass=class'PGame.PPawn'
	HUDType=class'PGame.PHUD'
	bDelayedStart=false
	fDecalSize=128.0f	
}