class PEnemyBot extends GameAIController;

var Pawn thePlayer; //variable to hold the target pawn

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	
}


event SeePlayer(Pawn SeenPlayer) //bot sees player
{
	if (PEnemy(self.Pawn).GetStateName()=='Cayendo')
	{
		`log("Ignoro1, cayendo entoavía");
		return;
	}

	if (thePlayer ==none) //if we didnt already see a player
    {
		thePlayer = SeenPlayer; //make the pawn the target
		GoToState('Follow'); // trigger the movement code
    }
	
}

state Follow
{

Begin:

		if (thePlayer != None)  // If we seen a player
		{
		
			if (PEnemy(self.Pawn).GetStateName()=='Cayendo')
			{
				`log("Ignoro2, cayendo entoavía");
			}
			else
			{
				MoveTo(thePlayer.Location); // Move directly to the players location
				GoToState('Looking'); //when we get there
			}
		}

}

state Looking
{
Begin:
    if (thePlayer != None)  // If we seen a player
	{
		if (PEnemy(self.Pawn).GetStateName()=='Cayendo')
		{

			`log("Ignoro3, cayendo entoavía");
		}
		else
		{
			MoveTo(thePlayer.Location); // Move directly to the players location
            GoToState('Follow');  // when we get there
		}
	}
}

defaultproperties
{

}
