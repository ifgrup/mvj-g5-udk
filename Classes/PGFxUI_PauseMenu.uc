class PGFxUI_PauseMenu extends UTGFxTweenableMoviePlayer;

var GFxObject RootMC, PauseMC, OverlayMC, Btn_Resume_Wrapper, Btn_Exit_Wrapper,Btn_RStart_Wrapper;
var GFxClikWidget Btn_ResumeMC, Btn_ExitMC,Btn_RStart,Btn_ffMC,Btn_f1MC,Btn_f2MC,Btn_f3MC;

// Localized strings to use as button labels
var localized string ResumeString, ExitString;

function bool Start(optional bool StartPaused = false)
{
    super.Start();
    Advance(0);

	RootMC = GetVariableObject("_root");
    PauseMC = RootMC.GetObject("pausemenu");    

	//Btn_Resume_Wrapper = PauseMC.GetObject("resume");
	//Btn_Exit_Wrapper = PauseMC.GetObject("exit");
	//Btn_RStart_Wrapper=PauseMC.GetObject("RStart",class'GFxClikWidget');
 // Btn_ResumeMC = GFxClikWidget(Btn_Resume_Wrapper.GetObject("btn", class'GFxClikWidget'));
  // Btn_ExitMC = GFxClikWidget(Btn_Exit_Wrapper.GetObject("btn", class'GFxClikWidget'));
	//Btn_RStart= GFxClikWidget(Btn_RStart_Wrapper);
	
	//Btn_ExitMC.SetString("label", "Saliir");
	//Btn_ResumeMC.SetString("label", "Continuar");
	//Btn_RStart.SetString("label", "pako");
	//Btn_ExitMC.AddEventListener('CLIK_press', OnPressExitButton);
	//Btn_ResumeMC.AddEventListener('CLIK_press', OnPressResumeButton);
	//Btn_RStart.AddEventListener('CLIK_press', OnPressExitButton);
	//AddCaptureKey('XboxTypeS_A');
	//AddCaptureKey('XboxTypeS_Start');
	//AddCaptureKey('Enter');

    return TRUE;
}

event bool WidgetInitialized(name WN,name WP, GFxObject w)
{
	
	switch(WN)
	{
		case ('ff'):
			Btn_ffMC=GFxClikWidget(w);
			
		Btn_ffMC.SetString("label", "Resumen");
			Btn_ffMC.AddEventListener('CLIK_press',OnPressResumeButton);
			break;

			case ('f1'):
			Btn_f1MC=GFxClikWidget(w);
			
		Btn_f1MC.SetString("label", "Reiniciar Mapa");
		Btn_f1MC.AddEventListener('CLIK_press',OnPressRStartButton);
			break;

			case ('f2'):
			Btn_f2MC=GFxClikWidget(w);
			
			Btn_f2MC.SetString("label", "Salir");
			Btn_f2MC.AddEventListener('CLIK_press',OnPressExitButton);
			break;
			case ('f3'):
			Btn_f3MC=GFxClikWidget(w);
			
			Btn_f3MC.SetString("label", "Menú");
			Btn_f3MC.AddEventListener('CLIK_press',OnPressMenuButton);
			break;

		default:
			break;

	}
	return true;
}



function OnPressResumeButton(GFxClikWidget.EventData ev)
{
    PlayCloseAnimation();
}

function OnPressExitButton(GFxClikWidget.EventData ev)
{
	//UTPlayerController(GetPC()).QuitToMainMenu();	
	ConsoleCommand("exit");
}
function OnPressRStartButton(GFxClikWidget.EventData ev)
{
	//UTPlayerController(GetPC()).QuitToMainMenu();	
	ConsoleCommand("Open PGamePlanet01");
}
function OnPressMenuButton(GFxClikWidget.EventData ev)
{
	//UTPlayerController(GetPC()).QuitToMainMenu();	
	ConsoleCommand("Open PGameMenu");
}
function PlayOpenAnimation()
{
//RootMC.GotoAndPlay("open");
   PauseMC.GotoAndPlay("open");
}

function PlayCloseAnimation()
{
//RootMC.GotoAndPlay("close");
    PauseMC.GotoAndPlay("close");
}

function OnPlayAnimationComplete()
{
    //
}

function OnCloseAnimationComplete()
{
    PHUD(GetPC().MyHUD).CompletePauseMenuClose();
}

/*
    Launch a console command using the PlayerOwner.
    Will fail if PlayerOwner is undefined.
*/
/*final function UT_ConsoleCommand(string Cmd, optional bool bWriteToLog)
{
    GetPC().Player.Actor.ConsoleCommand(Cmd, bWriteToLog);
}
*/
defaultproperties
{
    bEnableGammaCorrection=FALSE
	bPauseGameWhileActive=TRUE
	bCaptureInput=true
	WidgetBindings.Add((WidgetName="ff",WidgetClass=class'GfxClikWidget'));
	WidgetBindings.Add((WidgetName="f1",WidgetClass=class'GfxClikWidget'));
	WidgetBindings.Add((WidgetName="f2",WidgetClass=class'GfxClikWidget'));
		WidgetBindings.Add((WidgetName="f3",WidgetClass=class'GfxClikWidget'));
	
}
