class PPlayerInput extends PlayerInput;

//Aqui se guarda la posicion del mouse. Se pone como private write para que las otras clases no puedan modificarlo, pero si puedan acceder a el
var IntPoint MousePosition;
//var PrivateWrite IntPoint MousePosition; 
var private bool MouseIniciado;


event PlayerInput(float DeltaTime)
{
	local PHUD pHUD;

	//Captar el mouse si no usamos Scaleform
	//Asegurarnos de que tenemos un HUD valido
	pHUD = PHUD(myHUD);
	if (pHUD != None) 
	{
		if(!pHUD.UsingScaleform)
		{
			//Posicion inicial del mouse en el centro de la pantalla
			if(!MouseIniciado)
			{
				MousePosition.X = myHUD.SizeX*0.5;
				MousePosition.Y = myHUD.SizeY*0.5;
				MouseIniciado = true;
			}

			//Sumar amouseX a la posicion del mouse y hacer clamp con el ancho del viewport (para que no se salga de la pantalla)
			MousePosition.X = Clamp(MousePosition.X + aMouseX, 0, pHUD.SizeX); 
			//Lo mismo con el Y, pero con la altura del viewport, pero hay que invertir el incremento
			MousePosition.Y = Clamp(MousePosition.Y - aMouseY, 0, pHUD.SizeY); 
		}
	}

	Super.PlayerInput(DeltaTime);
}

function SetMousePosition(int x, int y)
{
	if(myHUD != none)
	{
		MousePosition.X = Clamp(x, 0, myHUD.SizeX);
		MousePosition.Y = Clamp(y, 0, myHUD.SizeY);
	}
}

defaultproperties
{
	MouseIniciado = false
}
