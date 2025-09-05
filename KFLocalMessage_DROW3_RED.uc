class KFLocalMessage_DROW3_RED extends KFLocalMessage;

enum EGameMessageType
{
	GMT_BossesCantJoinTeam
};

var localized string BossesCantJoinTeamMessage;

// Returns a hex color code for the supplied message type
static function string GetHexColor(int Switch)
{
    switch ( Switch )
	{
		case GMT_BossesCantJoinTeam:
            return default.GameColor;
	}

	return "00F000";
}

static function string GetString(
    optional int Switch,
    optional bool bPRI1HUD,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
	switch ( Switch )
	{
		case GMT_BossesCantJoinTeam:
			return default.BossesCantJoinTeamMessage;
		default:
			return "";
	}
}

DefaultProperties
{
	Lifetime=10
	bIsConsoleMessage=true
 	bIsUnique=false
 	bIsSpecial=false
 	bBeep=false

	// bIsConsoleMessage=false
 	// bIsUnique=true
 	// bIsSpecial=true
 	// bBeep=true

	FontSize=20
	DrawColor=(R=255,G=0,B=0,A=255)
}