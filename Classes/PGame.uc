/**
 * Configuraci�n general del juego
 * */

class PGame extends FrameworkGame;

defaultproperties
{
   PlayerControllerClass=class'PGame.PPlayerController'
   DefaultPawnClass=class'PGame.PPawn'
   HUDType=class'PGame.PHUD'
   bDelayedStart=false
}