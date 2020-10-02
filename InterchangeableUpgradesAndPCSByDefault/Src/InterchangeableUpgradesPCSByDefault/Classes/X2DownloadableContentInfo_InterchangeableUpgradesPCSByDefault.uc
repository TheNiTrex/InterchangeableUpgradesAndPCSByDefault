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

var config bool bInterchangeable_Log; // Logging

var config bool bInterchangeableUpgrades;
var config bool bInterchangeablePCS;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame() {
	
	// Ensure Reusable Upgrades and PCSs are enabled on existing saves:
	HandleInterchangeableUpgradesPCS(none); // Pass none as an argument so a New Game State isn't defined.

}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState) {
	
	// Enable Reusables Upgrades and PCSs on campaign start:
	HandleInterchangeableUpgradesPCS(StartState);  

}

static event OnPostCreatedTemplates() {

	HideVanillaTechTemplates(); // Prevent the Reusable Attachment and PCS Breakthroughs from showing-up, since they're redundant now.
	EditNewTechTemplates(); // Hide the Reusable Attachment and PCS Breakthrough Breakthrough Bonuses if they're already researched.

}

static function HandleInterchangeableUpgradesPCS(XComGameState NewGameState) {

    local XComGameState_HeadquartersXCom XComHQ;
    local bool bSubmitLocally;

	`log("Handling Interchangeable Upgrades and PCS", default.bInterchangeable_Log , 'InterchangeableUpgradesAndPCSByDefault');

    if (NewGameState == none) { // If the StartState isn't passed (In the case of the OLSG Hook), create a new Change State to be submitted.

        bSubmitLocally = true;
        NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("PA: Forcing Lock And Load");

    }

    XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', `XCOMHQ.ObjectID));
	XComHQ.bReuseUpgrades = default.bInterchangeableUpgrades;
	`log("Interchangeable Upgrades are set to: " @ XComHQ.bReuseUpgrades, default.bInterchangeable_Log, 'InterchangeableUpgradesAndPCSByDefault');
	XComHQ.bReusePCS = default.bInterchangeablePCS;
	`log("Interchangeable PCS is set to: " @ XComHQ.bReusePCS, default.bInterchangeable_Log, 'InterchangeableUpgradesAndPCSByDefault');

    if(bSubmitLocally) { // New Game States should only be submitted if the campaign isn't being bootstrapped.
	 
        `XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

    }
}

static function HideVanillaTechTemplates() {

	local X2StrategyElementTemplateManager StratMgr;
	local array<name> arrTemplateName;
	local array<X2DataTemplate>	arrTechTemplate;
	local X2TechTemplate TechTemplate;
	local int i, j;

	// Access StrategyElement Template Manager
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	// List all Vanilla Tech Templates by names
	arrTemplateName.AddItem('BreakthroughReuseWeaponUpgrades');
	arrTemplateName.AddItem('BreakthroughReusePCS');
	
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

		}
	}
}

static function bool HideTech() {

	return false;

}

static function EditNewTechTemplates() {

	local X2StrategyElementTemplateManager StratMgr;
	local array<name> arrTemplateName;
	local array<X2DataTemplate> arrTechTemplate;
	local X2TechTemplate TechTemplate;
	local int i, j;

	// Access StrategyElement Template Manager
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	// List all New Tech Templates by names
	arrTemplateName.AddItem('GuaranteedReuseWeaponUpgrades');
	arrTemplateName.AddItem('GuaranteedReusePCS');
	
	for (i = 0; i < arrTemplateName.Length; i++) {		

		// Reset New Tech Templates for all difficulties
		arrTechTemplate.Length = 0;
		
		// Access New Tech Templates for all difficulties
		StratMgr.FindDataTemplateAllDifficulties(arrTemplateName[i], arrTechTemplate);

		for (j = 0; j < arrTechTemplate.Length; j++) {

			// Access New Tech Template
			TechTemplate = X2TechTemplate(arrTechTemplate[j]);
			
			// Hide New Tech Template if Vanilla Tech is already researched
			if (TechTemplate.DataName == 'GuaranteedReuseWeaponUpgrades') {

				TechTemplate.UnavailableIfResearched = 'BreakthroughReuseWeaponUpgrades';

			} else if (TechTemplate.DataName == 'GuaranteedReusePCS') {

				TechTemplate.UnavailableIfResearched = 'BreakthroughReusePCS';

			}
		}
	}
}