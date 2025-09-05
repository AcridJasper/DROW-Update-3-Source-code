class KFAIController_FleshFriend extends KFAIController_ZedFleshpoundKing;

/** Don't create a benchmarking PRI for the test Hans */
function InitPlayerReplicationInfo(){}

/** Make sure test Hans is on the human team */
simulated event byte ScriptGetTeamNum()
{
	return 0;
}

DefaultProperties
{
    bAllowScriptTeamCheck=true

    ChestBeamMinPhase=0
}