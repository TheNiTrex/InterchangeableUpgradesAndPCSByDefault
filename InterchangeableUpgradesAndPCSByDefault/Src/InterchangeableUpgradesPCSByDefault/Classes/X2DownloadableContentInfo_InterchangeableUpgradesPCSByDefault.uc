//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_InterchangeableUpgradesPCSByDefault.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_InterchangeableUpgradesPCSByDefault extends X2DownloadableContentInfo;

var config bool bIUAPBD_Log; // Logging

var config bool bInterchangeableUpgrades;
var config bool bInterchangeablePCS;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame() {
	
	// Ensure Reusable Upgrades and PCSs are enabled on existing saves:
	if(default.bInterchangeableUpgrades || default.bInterchangeablePCS) HandleInterchangeableUpgradesPCS(none); // Pass none as an argument so a New Game State isn't defined.

}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState) {
	
	// Enable Reusable Upgrades and PCSs on campaign start:
	if(default.bInterchangeableUpgrades || default.bInterchangeablePCS) HandleInterchangeableUpgradesPCS(StartState);  

}

static event OnPostTemplatesCreated() {

	if(default.bInterchangeableUpgrades || default.bInterchangeablePCS) HandleVanillaTechTemplates(); // Prevent the Reusable Attachment and PCS Breakthroughs from showing-up, since they're redundant now.

}

static function HandleInterchangeableUpgradesPCS(XComGameState NewGameState) {

    local XComGameState_HeadquartersXCom XComHQ;
    local bool bSubmitLocally;

	`log("Handling Interchangeable Upgrades and PCS", default.bIUAPBD_Log , 'InterchangeableUpgradesAndPCSByDefault');

    if (NewGameState == none) { // If the StartState isn't passed (In the case of the OLSG Hook), create a new Change State to be submitted.

        bSubmitLocally = true;
        NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("IUAPBD: Handling Interchangeable Upgrades And PCS");

    }

    XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', `XCOMHQ.ObjectID));
	if(default.bInterchangeableUpgrades) XComHQ.bReuseUpgrades = true;
	`log("Interchangeable Upgrades are set to: " @ XComHQ.bReuseUpgrades, default.bIUAPBD_Log, 'InterchangeableUpgradesAndPCSByDefault');
	if(default.bInterchangeablePCS) XComHQ.bReusePCS = true;
	`log("Interchangeable PCS is set to: " @ XComHQ.bReusePCS, default.bIUAPBD_Log, 'InterchangeableUpgradesAndPCSByDefault');

    if(bSubmitLocally) { // New Game States should only be submitted if the campaign isn't being bootstrapped.
	 
        `XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

    }
}

static function HandleVanillaTechTemplates() {

	local X2StrategyElementTemplateManager StratMgr;
	local array<name> arrTemplateName;
	local array<X2DataTemplate>	arrTechTemplate;
	local X2TechTemplate TechTemplate;
	local int i, j;

	`log("Handling Vanilla Tech Templates", default.bIUAPBD_Log ,'InterchangeableUpgradesAndPCSByDefault');

	// Access StrategyElement Template Manager
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	// List all Vanilla Tech Templates by names
	if(default.bInterchangeableUpgrades) arrTemplateName.AddItem('BreakthroughReuseWeaponUpgrades');
	if(default.bInterchangeablePCS) arrTemplateName.AddItem('BreakthroughReusePCS');

	for (i = 0; i < arrTemplateName.Length; i++) {		

		// Reset Vanilla Tech Templates for all difficulties
		arrTechTemplate.Length = 0;
		
		// Access Vanilla Tech Templates for all difficulties
		StratMgr.FindDataTemplateAllDifficulties(arrTemplateName[i], arrTechTemplate);

		for (j = 0; j < arrTechTemplate.Length; j++) {

			// Access Vanilla Tech Template
			TechTemplate = X2TechTemplate(arrTechTemplate[j]);
		
			// Delete Alternate Requirements
			TechTemplate.AlternateRequirements.Length = 0;

			// Hide Vanilla Tech Template
			TechTemplate.Requirements.SpecialRequirementsFn = HideTech;
			`log("Hid: " @ arrTechTemplate[j], default.bIUAPBD_Log ,'InterchangeableUpgradesAndPCSByDefault');

		}
	}
}

static function bool HideTech() {

	return false;

}