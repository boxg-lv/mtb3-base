/*
This code was supposed to be under Apache 2.0 license,
but due to complexity of licensing when multiple packages are involved,
this code (and anything else that does not have a specific license) has the "IDFCALJUIFA" license.
Also known as the "I DON'T FUCKING CARE ABOUT LICENSES, JUST USE IT FOR ANYTHING" license.

Check README.md for details on how to use this code.
*/

//CUSTOMIZABLE_START------------------------------------------------------------------------------------
#define TOURNAMENT_NAME "MTB Race 3"
#define MAX_TPOINTS 10
#define MAX_TVEHICLES 10
#define WAITING_WEAPON1 WEAPON_CHAINSAW
#define WAITING_AMMO1 1
#define WAITING_WEAPON2 WEAPON_GRENADE
#define WAITING_AMMO2 2
#define WAITING_WEAPON3 WEAPON_SHOTGSPA
#define WAITING_AMMO3 10
#define TOURNAMENT_WEAPON WEAPON_TEC9
#define TOURNAMENT_AMMO 0
#define TOURNAMENT_WEATHER 0
#define TOURNAMENT_TIME 12
#define TOURNAMENT_GRAVITY 0.008
#define MAX_POIS 1
#define DEFAULT_VEHICLE_MODEL INVALID_VEHICLE_MODEL

//CUSTOMIZABLE_END--------------------------------------------------------------------------------------

#include <open.mp>
#undef MAX_PLAYERS
#define MAX_PLAYERS 50
#include <fixes>
#include <YSI_Visual/y_commands>
#include <YSI_Data/y_iterate>
#include <streamer>
#include <sscanf2>
#include <logger>
#include <progress2>
#include <colandreas>

enum e_TRace {
	T_Type,
	Float:T_X,
	Float:T_Y,
	Float:T_Z,
    Float:T_Size,
	T_Model,
	T_Interior,
	bool:T_ShowDirection,
    T_BStart,
    T_BEnd,
    T_VLast,
    bool:T_Vehreq,
    T_SpawnOverride,
    bool:SpawnInVehicle,
    bool:T_NextORenable,
    Float:T_NextORX,
    Float:T_NextORY,
    Float:T_NextORZ
}

enum e_TSpawn {
    Float:T_SX,
    Float:T_SY,
    Float:T_SZ,
    Float:T_SA,
    Float:T_SArea
}

enum e_TVehicleSpawn {
    T_VModel,
    Float:T_VX,
    Float:T_VY,
    Float:T_VZ,
    Float:T_VA,
    T_VC1,
    T_VC2,
    T_VPID
}

enum e_PTD {
    PlayerText:TD_ID,
    TD_Timer
}

#define WORLD_XMAX 20000
#define WORLD_XMIN -20000
#define WORLD_YMAX 20000
#define WORLD_YMIN -20000
#define CP_GROUND 0
#define CP_AIR 3
#define CP_STANDARD 9
#define CP_PICKUP 10
#define NO_INTERIOR 0
#define NO_DIRECTION false
#define INVALID_PICKUP_ID -1
#define INVALID_POINT_ID -1
#define INVALID_VEHICLE_MODEL -1
#define INVALID_SPAWN_ID -1
#define SHOW_DIRECTION true
#define MAX_QUERY 256
#define MAX_TMPSTR 128
#define VEHICLE_REQUIRED true
#define VEHICLE_OPTIONAL false
#define SPAWN_VEHICLE true
#define SPAWN_FOOT false
#define HOLDING(%0) ((newkeys & (%0)) == (%0))
#define RELEASED(%0) (((newkeys & (%0)) != (%0)) && ((oldkeys & (%0)) == (%0)))
#define DIALOG_HELP 1
#define INVALID_TIMER 0
#define POIICON_ID 1

new T_RaceData[MAX_TPOINTS][e_TRace];
new T_RealTPointsCount = 0;
new T_RealTVehicleCount = 0;
new T_RealTPOICount = 0;
new bool:TournamentStarted = false;
new bool:PickupHistory[MAX_PLAYERS][MAX_TPOINTS];
new PickupidToPointid[MAX_PLAYERS][MAX_PICKUPS];
new PointidToPickupid[MAX_PLAYERS][MAX_TPOINTS];
new Iterator:CreatedPickups[MAX_PLAYERS]<MAX_PICKUPS>;
new Iterator:DirectionalPickups[MAX_PLAYERS]<MAX_PICKUPS>;
new Iterator:PointVehicles[MAX_TPOINTS]<MAX_VEHICLES>;
new Iterator:FreePointVehicles<MAX_VEHICLES>;
new Iterator:CreatedVehicles<MAX_VEHICLES>;
new static DB:TournamentDB;
new bool:FirstSpawn[MAX_PLAYERS];
new const ValidSkins[] = {
    1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,
    24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,
    44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,
    64,65,66,67,68,69,70,71,72,73,75,76,77,78,79,80,81,82,83,84,
    85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,
    104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,
    119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,
    134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,
    150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,
    165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,
    180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,
    195,196,197,198,199,200,201,202,203,204,205,206,207,209,210,
    211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,
    226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,
    241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,
    256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,
    271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,
    286,287,288,289,290,291,292,293,294,295,296,297,298,299
};
new SpawnCenter[e_TSpawn];
new TournamentVehicleSpawns[MAX_TVEHICLES][e_TVehicleSpawn];
new VehicleIDToSpawnID[MAX_VEHICLES];
new bool:UnlockedVehicles[MAX_VEHICLES][MAX_PLAYERS];
new Iterator:PointsWithVehicles<MAX_TPOINTS>;
new VehicleRespawnTimers[MAX_VEHICLES];
new PlayerVehicleModel[MAX_PLAYERS];
new PlayerVehicleID[MAX_PLAYERS];
new VehicleIDToPlayerid[MAX_VEHICLES];
new PlayerVehicleColour[MAX_PLAYERS][2];
new TournamentCountdown = 0;
new CountdownTimer = 0;
new Iterator:SpawnedPlayers<MAX_PLAYERS>;
new bool:IsPlayerSpawn[MAX_PLAYERS];
new PlayerTooltipTD[MAX_PLAYERS][e_PTD];
new PlayerObjectiveTD[MAX_PLAYERS][e_PTD];
new PlayerScreenTD[MAX_PLAYERS][e_PTD];
new PlayerText:PlayerTDPosBorder[MAX_PLAYERS];
new PlayerText:PlayerTDPosWhite[MAX_PLAYERS];
new PlayerText:PlayerTDPosInner[MAX_PLAYERS];
new PlayerText:PlayerTDPosProgress[MAX_PLAYERS];
new PlayerText:PlayerTDPosTxt[MAX_PLAYERS];
new PlayerText:PlayerTDPosNum[MAX_PLAYERS];
new PlayerText:PlayerTDPosTotal[MAX_PLAYERS];
new PlayerText:PlayerTDFinishBox[MAX_PLAYERS];
new PlayerText:PlayerTDFinishTxt[MAX_PLAYERS];
new PlayerText:PlayerTDFinishPos[MAX_PLAYERS];
new PlayerText:PlayerTDFinishTime[MAX_PLAYERS];
new PlayerText:PlayerTDSignalText[MAX_PLAYERS];
new FinishedPlayers = 0;
new FinishedPos[MAX_PLAYERS];
new StartingTime;
new SummonTimer[MAX_PLAYERS];
new UnfreezeTimer[MAX_PLAYERS];
new CarSpawnTimer[MAX_PLAYERS];
new DeathTimer[MAX_PLAYERS];
new SoundTimer[MAX_PLAYERS];
new DirectionTimer[MAX_PLAYERS];
new FinishTDTimer[MAX_PLAYERS];
new Iterator:SpectatedBy[MAX_PLAYERS]<MAX_PLAYERS>;
new SpectatingPlayer[MAX_PLAYERS];
new PreviousPos[MAX_PLAYERS];
new PreviousInterior[MAX_PLAYERS];
new Iterator:BlockedCarSpawns<MAX_TPOINTS>;
new PlayerBar:PlayerTDSignal[MAX_PLAYERS];
new STREAMER_TAG_AREA:BombField = INVALID_STREAMER_ID;
new BombingTimers[MAX_PLAYERS][2];
new BombOjectToPlayerid[10240]; //Lets hope this is enough
new Float:LastPlayerSpeed[MAX_PLAYERS][4];
new Float:POIs[MAX_POIS][3];
new POIcounter[MAX_PLAYERS];

main() {
    printf("----------\n%s loaded.\n----------", TOURNAMENT_NAME);
}

stock SetupTournamentSpawn() {
    //CUSTOMIZABLE_START------------------------------------------------------------------------------------
    
    //X,Y,Z,angle,spawn_radius
    SetSpawnPoint(0.0,0.0,0.0,0.0, 32.0);
    
    //CUSTOMIZABLE_END--------------------------------------------------------------------------------------
    return true;
}

stock SetupTournamentPoints() {
    //CUSTOMIZABLE_START------------------------------------------------------------------------------------


    //type,X,Y,Z,cp_size
    AddRacePoint(CP_GROUND, 1.0, 2.0, 3.0, 4.0);

    //X,Y,Z,cp_size,interior,vehicle_required?
    AddCheckPoint(1.0, 2.0, 3.0, 4.0, NO_INTERIOR, VEHICLE_REQUIRED);
    AddCheckPoint(1.0, 2.0, 3.0, 4.0, NO_INTERIOR);
    AddCheckPoint(1.0, 2.0, 3.0, 4.0);

    //model,X,Y,Z,show_direction?
    AddPickupPoint(1580, 1.0, 2.0, 3.0, SHOW_DIRECTION);
    AddPickupPoint(1580, 1.0, 2.0, 3.0);

    //type,X,Y,Z,cp_size,interior?,vehicle_required?,spawn_in_vehicle?
    AddRacePoint(CP_GROUND, 1.0, 2.0, 3.0, 4.0, NO_INTERIOR, VEHICLE_REQUIRED, SPAWN_VEHICLE);
    AddRacePoint(CP_AIR, 1.0, 2.0, 3.0, 4.0, NO_INTERIOR, VEHICLE_REQUIRED, SPAWN_VEHICLE);

    //CUSTOMIZABLE_END--------------------------------------------------------------------------------------
    return true;
}

stock AdditionalPointConfig() {
    //CUSTOMIZABLE_START------------------------------------------------------------------------------------

    //CUSTOMIZABLE_END--------------------------------------------------------------------------------------
    return true;
}

stock SetupTournamentVehicles() {
    //CUSTOMIZABLE_START------------------------------------------------------------------------------------
    
    //moidel,X,Y,Z,angle,color1,color2,unlock_at_point_id
    AddTournamentVehicle(451,1.0, 2.0, 3.0, 4.0,-1,-1, 2); 

    //CUSTOMIZABLE_END--------------------------------------------------------------------------------------
    return true;
}

stock AdditionalTournamentCalls(playerid, playerscore, bool:justspawned) {
    Logger_Dbg("tournament", "AdditionalTournamentCalls", Logger_I("playerid", playerid), Logger_I("playerscore", playerscore), Logger_B("justspawned", justspawned));
    //CUSTOMIZABLE_START------------------------------------------------------------------------------------
    //A giant function that is called whenever player progresses the tournament, useful to add messages or set vehicles
 
    //CUSTOMIZABLE_END--------------------------------------------------------------------------------------
    return true;
}

stock SetupTournamentExtras() {
    //CUSTOMIZABLE_START------------------------------------------------------------------------------------
    
  
    //CUSTOMIZABLE_END--------------------------------------------------------------------------------------
    return true;
}

public OnGameModeInit() {
    DisableCrashDetectLongCall(); //Longcalls broken in OMP
    if(!CA_Init()) {
        Logger_Fatal("Could not load ColAndreas map, ensure you have generated ColAndreas.cadb using the Wizard!");
        SendRconCommand("exit");
        return false;
    }

    SetGameModeText(TOURNAMENT_NAME);
    EnableStuntBonusForAll(false);
    UsePlayerPedAnims(); //For players to run like CJ
    ShowNameTags(true);
    SetGravity(TOURNAMENT_GRAVITY);
    SetWeather(TOURNAMENT_WEATHER);
    SetWorldTime(TOURNAMENT_TIME);
    AllowAdminTeleport(true);
    Logger_ToggleDebug("tournament", false); //Set this to true to habe a lot of logging, a lot

    SetupTournamentSpawn(); //Sets up the spawn
    SetupTournamentPoints(); //Sets up all the CPs and pickups

    Iter_Init(PointVehicles);
    Iter_Init(CreatedVehicles);
    Iter_Init(PointsWithVehicles);
    Iter_Init(FreePointVehicles);
    Iter_Init(SpawnedPlayers);
    Iter_Init(BlockedCarSpawns);

    SetupTournamentVehicles(); //Sets up all tournament vehicles
    SetupTournamentExtras(); //Sets up misc stuff to make tournament fancier
    PopulatePickupBatches(); //Creates starting and end points of pickup batches
    PopulateVehicleBatches(); //Creates last batch ids for vehicles

    //Generate all valid skins are classes
    for(new i = 0; i<sizeof(ValidSkins); i++) {
        AddPlayerClass(ValidSkins[i], SpawnCenter[T_SX], SpawnCenter[T_SY], SpawnCenter[T_SZ], 0.1, WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0);
    }

    Iter_Init(CreatedPickups);
    Iter_Init(DirectionalPickups);
    Iter_Init(SpectatedBy);

    for(new i = 0; i<MAX_PLAYERS; i++) {
        PlayerVehicleID[i] = INVALID_VEHICLE_ID;
        PlayerVehicleModel[i] = DEFAULT_VEHICLE_MODEL;
    }

    for(new i = 0; i<MAX_VEHICLES; i++) {
        VehicleIDToPlayerid[i] = INVALID_PLAYER_ID;
    }

    InitTournamentDB();

    AdditionalPointConfig(); //Override some specific values for a pointid
    DoMemoryOptimizationChecks(); //Some checks that can make your code run 0.00001% faster
    return true;
}

public OnGameModeExit() {
    DB_Close(TournamentDB);
    return true;
}

public OnDynamicActorStreamIn(actorid, forplayerid) {
    Logger_Dbg("tournament", "OnDynamicActorStreamIn", Logger_I("actorid", actorid), Logger_I("forplayerid", forplayerid));
    return true;
}

public OnPlayerEnterRaceCheckpoint(playerid) {
    Logger_Log("OnPlayerEnterRaceCheckpoint", Logger_I("playerid", playerid));
    if(!TournamentStarted) return false; //Not possible, but why not
    new playerscore = GetPlayerScore(playerid);
    if(T_RaceData[playerscore][T_Vehreq] == true && GetPlayerState(playerid) != PLAYER_STATE_DRIVER) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be in a vehicle!");
        return false; //Vehicle is required
    }
    DisablePlayerRaceCheckpoint(playerid);
    PlayerPlaySound(playerid, 1138, 0.0, 0.0, 0.0);
    playerscore = IncreasePlayerScore(playerid);
    UpdateTournamentPos(false);
    TDB_SavePlayerScore(playerid, playerscore);
    SavePlayerLastSpeed(playerid, true);
    AdditionalTournamentCalls(playerid, playerscore, false);
    ProgressTournamentForPlayer(playerid, playerscore);
    UpdatePlayerSpawnInfo(playerid, playerscore); //Improves spawning experience
    return true;
}

public OnPlayerEnterCheckpoint(playerid) {
    Logger_Log("OnPlayerEnterCheckpoint", Logger_I("playerid", playerid));
    if(!TournamentStarted) return false; //Not possible, but why not
    new playerscore = GetPlayerScore(playerid);
    if(T_RaceData[playerscore][T_Vehreq] == true && GetPlayerState(playerid) != PLAYER_STATE_DRIVER) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be in a vehicle!");
        return false; //Vehicle is required
    }
    DisablePlayerCheckpoint(playerid);
    PlayerPlaySound(playerid, 1138, 0.0, 0.0, 0.0);
    playerscore = IncreasePlayerScore(playerid);
    UpdateTournamentPos(false);
    TDB_SavePlayerScore(playerid, playerscore);
    SavePlayerLastSpeed(playerid, false);
    AdditionalTournamentCalls(playerid, playerscore, false);
    ProgressTournamentForPlayer(playerid, playerscore);
    UpdatePlayerSpawnInfo(playerid, playerscore); //Improves spawning experience
    return true;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ) {
    Logger_Dbg("tournament", "OnPlayerClickMap", Logger_I("playerid", playerid), Logger_F("fX", fX), Logger_F("fY", fY), Logger_F("fZ", fZ));
    RemovePlayerMapIcon(playerid, POIICON_ID);
    return false;
}

public OnPlayerPickUpPlayerPickup(playerid, pickupid) {
    Logger_Log("OnPlayerPickUpPlayerPickup", Logger_I("playerid", playerid), Logger_I("pickupid", pickupid));
    if(!TournamentStarted) return false; //Not possible, but why not. If this does happen, player will need to wait for the pickup to respawn
    if(PickupidToPointid[playerid][pickupid] == INVALID_POINT_ID) return false; //Special case where a stale pickup is picked up
    if(PickupHistory[playerid][PickupidToPointid[playerid][pickupid]] == false) {
        PickupHistory[playerid][PickupidToPointid[playerid][pickupid]] = true;
        TDB_SavePickupHistory(playerid, PickupidToPointid[playerid][pickupid]);
        new playerscore = IncreasePlayerScore(playerid);
        if(Iter_Contains(DirectionalPickups[playerid], PickupidToPointid[playerid][pickupid])) {
            if(Iter_Count(DirectionalPickups[playerid]) == 1) {
                if(playerscore < T_RealTPointsCount) {
                    if(T_RaceData[playerscore][T_Type] == CP_PICKUP) {
                        //If there is just one directional pickup left and we just picked it up and the next pointid is also a pickup, then that must mean that we ran out of directional pickups
                        //Only non-directional pickups are left, so send a message to the player to find them on their own
                        HidePlayerProgressBar(playerid, PlayerTDSignal[playerid]);
                        PlayerTextDrawHide(playerid, PlayerTDSignalText[playerid]);
                        ShowPlayerObjective(playerid, "Find all the ~r~Packages ~w~in the area");
                    }
                }
            }
            Iter_Remove(DirectionalPickups[playerid], PickupidToPointid[playerid][pickupid]);
            //Remove the pointid that the player just picked up, this will allow ShowPickupDirection to start pointing towards the next pickup
        }
        PointidToPickupid[playerid][PickupidToPointid[playerid][pickupid]] = INVALID_PICKUP_ID;
        PickupidToPointid[playerid][pickupid] = INVALID_POINT_ID;
        DestroyPlayerPickup(playerid, pickupid);
        PlayerPlaySound(playerid, 1138, 0.0, 0.0, 0.0);
        UpdateTournamentPos(false);
        TDB_SavePlayerScore(playerid, playerscore);
        SavePlayerLastSpeed(playerid, false);
        AdditionalTournamentCalls(playerid, playerscore, false);
        ProgressTournamentForPlayer(playerid, playerscore);
    } //else: should not be possible since we are supposed to destroy the pickup
    return true;
}

public OnPlayerConnect(playerid) {
    Logger_Log("OnPlayerConnect", Logger_I("playerid", playerid));
    FirstSpawn[playerid] = true;
    SetPlayerTeam(playerid, NO_TEAM);
    new playername[MAX_PLAYER_NAME];
    new playerscore = 0;
    GetPlayerName(playerid, playername, MAX_PLAYER_NAME);
    //We want to reset all data before we set score or pickup history from DB
    CleanupPlayerData(playerid);
    PlayerVehicleID[playerid] = INVALID_VEHICLE_ID;
    PlayerVehicleModel[playerid] = DEFAULT_VEHICLE_MODEL;
    FinishedPos[playerid] = 0;
    POIcounter[playerid] = 0;
    playerscore = TDB_GetPlayerScore(playername);
    TDB_GetPlayerVehicle(playername, PlayerVehicleModel[playerid], PlayerVehicleColour[playerid][0], PlayerVehicleColour[playerid][1]);
    TDB_GetPlayerSpeed(playername, LastPlayerSpeed[playerid][0], LastPlayerSpeed[playerid][1], LastPlayerSpeed[playerid][2], LastPlayerSpeed[playerid][3]);
    TDB_GetPlayerPickupHistory(playerid, playername);
    FinishedPos[playerid] = TDB_GetPlayerFinishPos(playername);
    SetPlayerScore(playerid, playerscore);
    CreatePlayerTextDraws(playerid);
    SendDeathMessage(INVALID_PLAYER_ID, playerid, REASON_CONNECT);
    SendClientMessage(playerid, -1, "Welcome to {FFFF00}%s{FFFFFF}! Use {FFFF00}/info{FFFFFF} to get started!", TOURNAMENT_NAME);
    return true;
}

public OnPlayerRequestClass(playerid, classid) {
    Logger_Log("OnPlayerRequestClass", Logger_I("playerid", playerid), Logger_I("classid", classid));
    SetPlayerPos(playerid, 1664.1835, -2286.6123, -1.2335);
    SetPlayerFacingAngle(playerid, 0);
    SetPlayerCameraPos(playerid, 1665, -2283, 0);
    SetPlayerCameraLookAt(playerid, 1664.1835, -2286.6123, -1.2335);
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 100+playerid);
    SetRandomAnimation(playerid);
    PlayerTextDrawHide(playerid, PlayerScreenTD[playerid][TD_ID]); //We need this when player changes class after death
    return true;
}

public OnPlayerSpawn(playerid) {
    Logger_Log("OnPlayerSpawn", Logger_I("playerid", playerid));
    TogglePlayerControllable(playerid, false); //Sometimes this prevents player from falling through floors
    new playerscore = GetPlayerScore(playerid);
    IsPlayerSpawn[playerid] = true;
    Iter_Add(SpawnedPlayers, playerid);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerWeather(playerid, TOURNAMENT_WEATHER);
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, 69); //Nice
    SetPlayerColor(playerid, 0xFFFF00FF);
    new pointid = DetermineSpawnPoint(playerscore, playerid);

    if(FirstSpawn[playerid]) {
        if(TournamentStarted) {
            InitTVehicleLocks(playerid);
            if(TournamentCountdown == 0) {
                if(PlayerVehicleModel[playerid] != INVALID_VEHICLE_MODEL) {
                    //Inform the player on first spawn when tournament has started that the player has a vehicle
                    ShowPlayerTooltip(playerid, "You can summon your vehicle by holding ~k~~CONVERSATION_YES~ or using /car");
                }
            }
        }
        UpdateTournamentPos(false); //This executes update for more players than actually needed, this is much siompler, but room for improvement
        UpdatePlayerSpawnInfo(playerid, playerscore);
        FirstSpawn[playerid] = false;
    }

    SetPlayerTournamentSpawn(playerid, playerscore, true);
    HidePlayerTextDraws(playerid, false);
    if(TournamentCountdown < 4) {
        ProgressTournamentForPlayer(playerid, playerscore);
        if(TournamentCountdown > 0) { //During countdown 3-1
            GivePlayerWeapon(playerid, WEAPON:TOURNAMENT_WEAPON, TOURNAMENT_AMMO);
            TogglePlayerControllable(playerid, false);
        } else { //= 0
            if(TournamentStarted) {
                //Fully started tournament
                GivePlayerWeapon(playerid, WEAPON:TOURNAMENT_WEAPON, TOURNAMENT_AMMO);
                AdditionalTournamentCalls(playerid, playerscore, true);
                if(UnfreezeTimer[playerid] != INVALID_TIMER) {
                    KillTimer(UnfreezeTimer[playerid]);
                }
                UnfreezeTimer[playerid] = SetTimerEx("UnfreezePlayer", 500, false, "i", playerid); //Sometimes prevents players from being spawned inside a floor
            } else {
                //If tournament is not started and countdown is 0, then lets have fun
                GivePlayerWeapon(playerid, WEAPON:WAITING_WEAPON1, WAITING_AMMO1);
                GivePlayerWeapon(playerid, WEAPON:WAITING_WEAPON2, WAITING_AMMO2);
                GivePlayerWeapon(playerid, WEAPON:WAITING_WEAPON3, WAITING_AMMO3);
                if(DoesPointSpawnInVehicle(pointid)) {
                    TogglePlayerControllable(playerid, false); //We want the player to stand still when spawning in vehicle is required to prevent the player from falling in air
                } else {
                    if(UnfreezeTimer[playerid] != INVALID_TIMER) {
                        KillTimer(UnfreezeTimer[playerid]);
                    }
                    UnfreezeTimer[playerid] = SetTimerEx("UnfreezePlayer", 500, false, "i", playerid); //Sometimes prevents players from being spawned inside a floor
                }
            }
        }

        //Tournament is started and countdown is in progress below 4
        if(TournamentStarted) {
            ShowPlayerProgress(playerid, playerscore);
            if(playerscore < T_RealTPointsCount && T_RaceData[playerscore][T_Type] == CP_PICKUP) {
                //This function is not called when player has picked up a pickup, lets force it on countdown end
                if(T_RaceData[playerscore][T_BStart] != playerscore) {
                    CreatePlayerPickupBatch(playerid, playerscore);
                }
            }
            if(TournamentCountdown == 0) {
                ShowPlayerCurrentObjective(playerid, playerscore);
            }
        }
    } else { //10-4 countdown
        if(DoesPointSpawnInVehicle(pointid)) {
            TogglePlayerControllable(playerid, false); //We want the player to stand still when spawning in vehicle is required to prevent the player from falling in air
        } else {
                if(UnfreezeTimer[playerid] != INVALID_TIMER) {
                    KillTimer(UnfreezeTimer[playerid]);
                }
                UnfreezeTimer[playerid] = SetTimerEx("UnfreezePlayer", 500, false, "i", playerid); //Sometimes prevents players from being spawned inside a floor
        }
    }

    SetCameraBehindPlayer(playerid);
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
    ClearAnimations(playerid);
    FadeInPlayerScreen(playerid);
    return true;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid) {
    Logger_Dbg("tournament", "OnPlayerInteriorChange", Logger_I("playerid", playerid), Logger_I("newinteriorid", newinteriorid), Logger_I("oldinteriorid", oldinteriorid));
    if(Iter_Count(SpectatedBy[playerid]) > 0) {
        //If player changes interior, we need to set the same interior for spectators
        foreach(new i : SpectatedBy[playerid]) {
            SetPlayerInterior(i, newinteriorid);
        }
    }
    return true;
}

public OnPlayerDeath(playerid, killerid, WEAPON:reason) {
    Logger_Log("OnPlayerDeath", Logger_I("playerid", playerid), Logger_I("killerid", killerid), Logger_I("reason", reason));
    FadeOutPlayerScreen(playerid);
    GameTextForPlayer(playerid, "Wasted", 3500, 2);
    Iter_Remove(SpawnedPlayers, playerid);
    IsPlayerSpawn[playerid] = false;
    HidePlayerTextDraws(playerid, false);

    if(DeathTimer[playerid] != INVALID_TIMER) { //In case player is kill in the middle of kill animation
        KillTimer(DeathTimer[playerid]);
        DeathTimer[playerid] = INVALID_TIMER;
    }

    StopPlayerBombField(playerid);

    if(FinishTDTimer[playerid] != INVALID_TIMER) {
        KillTimer(FinishTDTimer[playerid]);
        FinishTDTimer[playerid] = INVALID_TIMER;
    }
    return true;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, CLICK_SOURCE:source) {
    Logger_Log("OnPlayerClickPlayer", Logger_I("playerid", playerid), Logger_I("clickedplayerid", clickedplayerid), Logger_I("source", source));
    if(playerid == clickedplayerid) {
        //If you click yourself, then exit spectate
        StopSpectating(playerid);
        return true;
    } else {
        StartSpectating(playerid, clickedplayerid);
    }
    return false;
}

public OnPlayerCommandText(playerid, cmdtext[]) {
    Logger_Log("OnPlayerCommandText", Logger_I("playerid", playerid), Logger_S("cmdtext", cmdtext));
    return false;
}

public OnPlayerDisconnect(playerid, reason) {
    Logger_Log("OnPlayerDisconnect", Logger_I("playerid", playerid), Logger_I("reason", reason));
    if(IsCreatedVehicleValid(PlayerVehicleID[playerid])) {
        DestroyVehicle(PlayerVehicleID[playerid]);
        Iter_Remove(CreatedVehicles, PlayerVehicleID[playerid]);
        VehicleIDToPlayerid[PlayerVehicleID[playerid]] = INVALID_PLAYER_ID;
        PlayerVehicleID[playerid] = INVALID_VEHICLE_ID;
    }
    Iter_Remove(SpawnedPlayers, playerid);
    IsPlayerSpawn[playerid] = false;

    //If anyone is spectating, then stop spectating on disconnect
    foreach(new i : SpectatedBy[playerid]) {
        if(SpectatingPlayer[i] == playerid) {
            TogglePlayerSpectating(i, false);
        }
    }
    Iter_Clear(SpectatedBy[playerid]);

    if(SpectatingPlayer[playerid] != INVALID_PLAYER_ID) {
        Iter_Remove(SpectatedBy[SpectatingPlayer[playerid]], playerid);
        SpectatingPlayer[playerid] = INVALID_PLAYER_ID;
    }

    HidePlayerTextDraws(playerid, true);

    PlayerTooltipTD[playerid][TD_ID] = INVALID_PLAYER_TEXT_DRAW;
    PlayerObjectiveTD[playerid][TD_ID] = INVALID_PLAYER_TEXT_DRAW;
    PlayerScreenTD[playerid][TD_ID] = INVALID_PLAYER_TEXT_DRAW;
    PlayerTDPosBorder[playerid] = INVALID_PLAYER_TEXT_DRAW;
    PlayerTDPosWhite[playerid] = INVALID_PLAYER_TEXT_DRAW;
    PlayerTDPosInner[playerid] = INVALID_PLAYER_TEXT_DRAW;
    PlayerTDPosProgress[playerid] = INVALID_PLAYER_TEXT_DRAW;
    PlayerTDPosTxt[playerid] = INVALID_PLAYER_TEXT_DRAW;
    PlayerTDPosNum[playerid] = INVALID_PLAYER_TEXT_DRAW;
    PlayerTDPosTotal[playerid] = INVALID_PLAYER_TEXT_DRAW;
    PlayerTDFinishBox[playerid] = INVALID_PLAYER_TEXT_DRAW;
    PlayerTDFinishTxt[playerid] = INVALID_PLAYER_TEXT_DRAW;
    PlayerTDFinishPos[playerid] = INVALID_PLAYER_TEXT_DRAW;
    PlayerTDFinishTime[playerid] = INVALID_PLAYER_TEXT_DRAW;
    
    if(SummonTimer[playerid] != INVALID_TIMER) {
        KillTimer(SummonTimer[playerid]);
        SummonTimer[playerid] = INVALID_TIMER;
    }
    if(CarSpawnTimer[playerid] != INVALID_TIMER) {
        KillTimer(CarSpawnTimer[playerid]);
        CarSpawnTimer[playerid] = INVALID_TIMER;
    }
    if(DeathTimer[playerid] != INVALID_TIMER) {
        KillTimer(DeathTimer[playerid]);
        DeathTimer[playerid] = INVALID_TIMER;
    }
    if(FinishTDTimer[playerid] != INVALID_TIMER) {
        KillTimer(FinishTDTimer[playerid]);
        FinishTDTimer[playerid] = INVALID_TIMER;
    }
    if(UnfreezeTimer[playerid] != INVALID_TIMER) {
        KillTimer(UnfreezeTimer[playerid]);
        UnfreezeTimer[playerid] = INVALID_TIMER;
    }

    StopPlayerBombField(playerid);
    SetTimerEx("UpdateTournamentPos", 1000, false, "b", false);

    if(SoundTimer[playerid] != INVALID_TIMER) {
        KillTimer(SoundTimer[playerid]);
        SoundTimer[playerid] = INVALID_TIMER;
    }
    if(DirectionTimer[playerid] != INVALID_TIMER) {
        KillTimer(DirectionTimer[playerid]);
        DirectionTimer[playerid] = INVALID_TIMER;
    }

    if(PlayerScreenTD[playerid][TD_Timer] != INVALID_TIMER) {
        KillTimer(PlayerScreenTD[playerid][TD_Timer]);
        PlayerScreenTD[playerid][TD_Timer] = INVALID_TIMER;
    }
    
    SendDeathMessage(INVALID_PLAYER_ID, playerid, REASON_DISCONNECT);
    return true;
}

public OnPlayerKeyStateChange(playerid, KEY:newkeys, KEY:oldkeys) {
    Logger_Dbg("tournament", "OnPlayerKeyStateChange", Logger_I("playerid", playerid), Logger_I("newkeys", newkeys), Logger_I("oldkeys", oldkeys));
    if(HOLDING(KEY_YES)) {
        //When player presses the special button, it starts the timer
        CheckSummoningVehicle(playerid, true);
    } else if(RELEASED(KEY_YES)) {
        //If player releases special button, then reset the timer
        if(SummonTimer[playerid] != INVALID_TIMER) {
            KillTimer(SummonTimer[playerid]);
            SummonTimer[playerid] = INVALID_TIMER;
        }
    }
}

public OnVehicleStreamIn(vehicleid, forplayerid) {
    Logger_Dbg("tournament", "OnVehicleStreamIn", Logger_I("vehicleid", vehicleid), Logger_I("forplayerid", forplayerid));
    if(UnlockedVehicles[vehicleid][forplayerid] == false) {
        SetVehicleParamsForPlayer(vehicleid, forplayerid, false, true);
    } else {
        SetVehicleParamsForPlayer(vehicleid, forplayerid, false, false); 
    }
    return true;
}

public OnVehicleDeath(vehicleid, killerid) {
    Logger_Log("OnVehicleDeath", Logger_I("vehicleid", vehicleid), Logger_I("killerid", killerid));
    if(VehicleIDToPlayerid[vehicleid] != INVALID_PLAYER_ID) {
        if(Iter_Count(SpectatedBy[VehicleIDToPlayerid[vehicleid]]) > 0) {
            //Seems like an OpenMP bug, player gets spawned when spectating a vehicle and it dies
            foreach(new i : SpectatedBy[VehicleIDToPlayerid[vehicleid]]) {
                PlayerSpectatePlayer(i, VehicleIDToPlayerid[vehicleid], SPECTATE_MODE_NORMAL);
            }
        }

        //Destroy player vehicle on death
        DestroyVehicle(vehicleid);
        Iter_Remove(CreatedVehicles, vehicleid);
        PlayerVehicleID[VehicleIDToPlayerid[vehicleid]] = INVALID_VEHICLE_ID;
        VehicleIDToPlayerid[vehicleid] = INVALID_PLAYER_ID;
    }
    return true;
}

public OnPlayerStateChange(playerid, PLAYER_STATE:newstate, PLAYER_STATE:oldstate) {
    Logger_Dbg("tournament", "OnPlayerStateChange", Logger_I("playerid", playerid), Logger_I("newstate", newstate), Logger_I("oldstate", oldstate));
    if(Iter_Count(SpectatedBy[playerid]) > 0) {
        
        if((newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER)) {
            new vehicleid = GetPlayerVehicleID(playerid);
            foreach(new i : SpectatedBy[playerid]) {
                if(SpectatingPlayer[i] != playerid) {
                    //Not sure if this can happen, but just to be sure to remove dangling playerid if the dandling playerid is not even spectating the player
                    Iter_Remove(SpectatedBy[playerid], i);
                } else {
                    if(IsCreatedVehicleValid(vehicleid)) {
                        PlayerSpectateVehicle(i, vehicleid);
                    } else {
                        PlayerSpectatePlayer(i, playerid, SPECTATE_MODE_NORMAL); //Probably impossible, but in case vehicleid is 0
                    }
                }
            }
        } else if(newstate == PLAYER_STATE_ONFOOT) {
            foreach(new i : SpectatedBy[playerid]) {
                if(SpectatingPlayer[i] != playerid) {
                    //Not sure if this can happen, but just to be sure to remove dangling playerid if the dangling playerid is not even spectating the player
                    Iter_Remove(SpectatedBy[playerid], i);
                } else {
                    PlayerSpectatePlayer(i, playerid, SPECTATE_MODE_NORMAL);
                }
            }
        } //else: nothing? lets just wait for a more interesting state
    }

    if(!TournamentStarted) return true; //If somehow it happens, just let it be
    if(oldstate == PLAYER_STATE_ONFOOT && newstate == PLAYER_STATE_DRIVER) {
        //If player takes a vehicle from spawn, then recreate the vehicle after 10 seconds
        new vehicleid = GetPlayerVehicleID(playerid);
        if(IsCreatedVehicleValid(vehicleid) && VehicleIDToSpawnID[vehicleid] != INVALID_SPAWN_ID) {
            VehicleRespawnTimers[vehicleid] = SetTimerEx("RespawnTournamentVehicle", 10000, false, "ii", VehicleIDToSpawnID[vehicleid], vehicleid);
            if(TournamentVehicleSpawns[VehicleIDToSpawnID[vehicleid]][T_VPID] != INVALID_POINT_ID) {
                Iter_Remove(PointVehicles[TournamentVehicleSpawns[VehicleIDToSpawnID[vehicleid]][T_VPID]], vehicleid);
            } else {
                Iter_Remove(FreePointVehicles, vehicleid);
            }
            VehicleIDToSpawnID[vehicleid] = INVALID_SPAWN_ID;
            if(IsCreatedVehicleValid(PlayerVehicleID[playerid])) {
                DestroyVehicle(PlayerVehicleID[playerid]);
                PlayerVehicleID[playerid] = INVALID_VEHICLE_ID;
                Iter_Remove(CreatedVehicles, PlayerVehicleID[playerid]);
            }
            PlayerVehicleID[playerid] = vehicleid;
            VehicleIDToPlayerid[vehicleid] = playerid;
            new model = GetVehicleModel(vehicleid);
            if(model > 0) { //In some odd cases this can be 0 and will cause the car not to be saved
                new Float:spawnX, Float:spawnY, Float:spawnZ, Float:angle, colour1, colour2;
                GetVehicleSpawnInfo(vehicleid, spawnX, spawnY, spawnZ, angle, colour1, colour2);
                GetVehicleColours(vehicleid, PlayerVehicleColour[playerid][0], PlayerVehicleColour[playerid][1]);
                SetVehicleSpawnInfo(vehicleid, model, spawnX, spawnY, spawnZ, angle, colour1, colour2, -1); //Prevent the current car from respawning

                PlayerVehicleModel[playerid] = model;
                TDB_SavePlayerVehicle(playerid, PlayerVehicleModel[playerid], PlayerVehicleColour[playerid][0], PlayerVehicleColour[playerid][1]);
                foreach(new i : Player) {
                    SetVehicleParamsForPlayer(vehicleid, i, false, true);
                    UnlockedVehicles[vehicleid][i] = false;
                }
                SetVehicleParamsForPlayer(vehicleid, playerid, false, false);
                UnlockedVehicles[vehicleid][playerid] = true;
            } else {
                //Something went wrong, just warn the player
                SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Failed to update vehicle. {FFFF00}Try exiting and entering the vehicle again!");
            }
        }
    }
    return true;
}

public OnPlayerEnterDynamicArea(playerid, areaid) {
    Logger_Dbg("tournament", "OnPlayerEnterDynamicArea", Logger_I("playerid", playerid), Logger_I("areaid", areaid));
    if(areaid == BombField) {
        if(!TournamentStarted) return false;
        //WARNING: Bomb field will be started regardless of score! This means a player can randomly cross a mine field
        StartPlayerBombField(playerid);
    }
    return true;
}

public OnPlayerLeaveDynamicArea(playerid, areaid) {
    Logger_Dbg("tournament", "OnPlayerLeaveDynamicArea", Logger_I("playerid", playerid), Logger_I("areaid", areaid));
    if(areaid == BombField) {
        StopPlayerBombField(playerid);
    }
    return true;
}

public OnDynamicObjectMoved(objectid) {
    Logger_Dbg("tournament", "OnDynamicObjectMoved", Logger_I("objectid", objectid));
    //When bomb touches the ground, make a sounds and later create explosion
    if(BombOjectToPlayerid[objectid] != INVALID_PLAYER_ID) {
        SetTimerEx("DestroyBomb", 500, false, "ii", objectid, BombOjectToPlayerid[objectid]);
        new Float:TempX, Float:TempY, Float:TempZ;
        GetDynamicObjectPos(objectid, TempX, TempY, TempZ);
        PlayerPlaySound(BombOjectToPlayerid[objectid], 16200, TempX, TempY, TempZ);
    }
    return true;
}

stock InitTournamentDB() {
    TournamentDB = DB_Open("Tournament.db");
    if(TournamentDB == DB:0) {
        Logger_Fatal("Could not open tournament.db, must exit");
        SendRconCommand("exit");
        return false;
    }
    if(!DB_FreeResultSet(DB_ExecuteQuery(TournamentDB,
        "CREATE TABLE IF NOT EXISTS `score` (`id` INTEGER PRIMARY KEY AUTOINCREMENT,`PlayerName` VARCHAR(24) NOT NULL,`PlayerScore` INTEGER NOT NULL)"))) {
        Logger_Fatal("Could not create DB score table, must exit");
        SendRconCommand("exit");
        return false;
    }

    if(!DB_FreeResultSet(DB_ExecuteQuery(TournamentDB,
        "CREATE TABLE IF NOT EXISTS `speed` (`id` INTEGER PRIMARY KEY AUTOINCREMENT,`PlayerName` VARCHAR(24) NOT NULL,`SpeedX` FLOAT(13,8),`SpeedY` FLOAT(13,8),`SpeedZ` FLOAT(13,8),`SpeedR` FLOAT(13,8))"))) {
        Logger_Fatal("Could not create DB speed table, must exit");
        SendRconCommand("exit");
        return false;
    }

    if(!DB_FreeResultSet(DB_ExecuteQuery(TournamentDB,
        "CREATE TABLE IF NOT EXISTS `pickuphistory` (`id` INTEGER PRIMARY KEY AUTOINCREMENT,`PlayerName` VARCHAR(24) NOT NULL,`PointID` INTEGER NOT NULL)"))) {
        Logger_Fatal("Could not create DB pickup history table, must exit");
        SendRconCommand("exit");
        return false;
    }

    if(!DB_FreeResultSet(DB_ExecuteQuery(TournamentDB,
        "CREATE TABLE IF NOT EXISTS `vehicles` (`id` INTEGER PRIMARY KEY AUTOINCREMENT,`PlayerName` VARCHAR(24) NOT NULL,`model` INTEGER NOT NULL,`colour1` INTEGER NOT NULL,`colour2` INTEGER NOT NULL)"))) {
        Logger_Fatal("Could not create DB vehicle table, must exit");
        SendRconCommand("exit");
        return false;
    }

    if(!DB_FreeResultSet(DB_ExecuteQuery(TournamentDB,
        "CREATE TABLE IF NOT EXISTS `finish` (`id` INTEGER PRIMARY KEY AUTOINCREMENT,`PlayerName` VARCHAR(24) NOT NULL,`PlayerTime` INTEGER NOT NULL,`PlayerPos` INTEGER NOT NULL)"))) {
        Logger_Fatal("Could not create DB finish table, must exit");
        SendRconCommand("exit");
        return false;
    }
    return true;
}

stock DoMemoryOptimizationChecks() {
    if(T_RealTPointsCount > MAX_TPOINTS) {
        Logger_Fatal("Real point count exceeds MAX_TPOINTS, increase it!", Logger_I("T_RealTPointsCount", T_RealTPointsCount));
        SendRconCommand("exit");
        return false;
    }

    if(T_RealTPointsCount < MAX_TPOINTS) {
        Logger_Log("Real point count is smaller than MAX_TPOINTS, decrease MAX_TPOINTS it in your .pwn file to improve performance", Logger_I("T_RealTPointsCount", T_RealTPointsCount));
    }

    if(T_RealTVehicleCount > MAX_TVEHICLES) {
        Logger_Fatal("Real vehicle count exceeds MAX_TVEHICLES, increase it in your .pwn file", Logger_I("T_RealTVehicleCount", T_RealTVehicleCount));
        SendRconCommand("exit");
        return false;
    }

    if(T_RealTVehicleCount < MAX_TVEHICLES) {
        Logger_Log("Real vehicle count is smaller than MAX_TVEHICLES, decrease MAX_TVEHICLES it in your .pwn file to improve performance", Logger_I("T_RealTVehicleCount", T_RealTVehicleCount));
    }

    if(T_RealTPOICount > MAX_POIS) {
        Logger_Fatal("Real POI count exceeds MAX_POIS, increase it in your .pwn file", Logger_I("MAX_POIS", MAX_POIS));
        SendRconCommand("exit");
        return false;
    }

    if(T_RealTPOICount < MAX_POIS) {
        Logger_Log("Real POI count is smaller than MAX_POIS, decrease MAX_POIS it in your .pwn file to improve performance", Logger_I("T_RealTPOICount", T_RealTPOICount));
    }
    return true;
}

stock AddPOI(Float:pX, Float:pY, Float:pZ, const label[]) {
    Logger_Dbg("tournament", "AddPOI", Logger_F("pX", pX), Logger_F("pY", pY), Logger_F("pZ", pZ), Logger_S("label", label));
    POIs[T_RealTPOICount][0] = pX;
    POIs[T_RealTPOICount][1] = pY;
    POIs[T_RealTPOICount][2] = pZ;
    Create3DTextLabel(label, 0xFFFFFFFF, pX, pY, pZ, 40.0, 0, true);
    T_RealTPOICount++;
    return true;
}

stock SetSpawnPoint(Float:SpawnX, Float:SpawnY, Float:SpawnZ, Float:SpawnAngle, Float:SpawnArea) {
    Logger_Dbg("tournament", "SetSpawnPoint", Logger_F("SpawnX", SpawnX), Logger_F("SpawnY", SpawnY),
    Logger_F("SpawnZ", SpawnZ), Logger_F("SpawnAngle", SpawnAngle), Logger_F("SpawnArea", SpawnArea));
    SpawnCenter[T_SX] = SpawnX;
    SpawnCenter[T_SY] = SpawnY;
    SpawnCenter[T_SZ] = SpawnZ;
    SpawnCenter[T_SA] = SpawnAngle;
    SpawnCenter[T_SArea] = SpawnArea;
}

stock AddTournamentVehicle(modelid, Float:spawnX, Float:spawnY, Float:spawnZ, Float:angle, colour1, colour2, pointid) {
    Logger_Dbg("tournament", "AddTournamentVehicle", Logger_F("spawnX", spawnX),
    Logger_F("spawnY", spawnY), Logger_F("spawnZ", spawnZ), Logger_F("angle", angle),
    Logger_I("colour1", colour1), Logger_I("colour2", colour2), Logger_I("pointid", pointid));
    TournamentVehicleSpawns[T_RealTVehicleCount][T_VModel] = modelid;
    TournamentVehicleSpawns[T_RealTVehicleCount][T_VX] = spawnX;
    TournamentVehicleSpawns[T_RealTVehicleCount][T_VY] = spawnY;
    TournamentVehicleSpawns[T_RealTVehicleCount][T_VZ] = spawnZ;
    TournamentVehicleSpawns[T_RealTVehicleCount][T_VA] = angle;
    TournamentVehicleSpawns[T_RealTVehicleCount][T_VC1] = colour1;
    TournamentVehicleSpawns[T_RealTVehicleCount][T_VC2] = colour2;
    TournamentVehicleSpawns[T_RealTVehicleCount][T_VPID] = pointid;
    if(pointid != INVALID_POINT_ID) {
        if(!Iter_Contains(PointsWithVehicles, pointid)) {
            Iter_Add(PointsWithVehicles, pointid);
        }
    }
    T_RealTVehicleCount++;
}

stock OverrideNextCPForPointID(pointid, Float:NextX, Float:NextY, Float:NextZ) {
    if(pointid >= T_RealTPointsCount) {
        Logger_Fatal("Tried to ovveride next CP non existing pointid", Logger_I("pointid", pointid));
        SendRconCommand("exit");
        return false;
    }

    T_RaceData[pointid][T_NextORenable] = true;
    T_RaceData[pointid][T_NextORX] = NextX;
    T_RaceData[pointid][T_NextORY] = NextY;
    T_RaceData[pointid][T_NextORZ] = NextZ;
    return true;
}

stock OverrideSpawnForPointID(pointid, overridetopointid) {
    if(pointid >= T_RealTPointsCount) {
        Logger_Fatal("Tried to override non existing pointid spawn", Logger_I("pointid", pointid), Logger_I("overridetopointid", overridetopointid));
        SendRconCommand("exit");
        return false;
    }
    if(overridetopointid >= T_RealTPointsCount) {
        Logger_Fatal("Tried to override pointid spawn with non existing pointid", Logger_I("pointid", pointid), Logger_I("overridetopointid", overridetopointid));
        SendRconCommand("exit");
        return false;
    }

    T_RaceData[pointid][T_SpawnOverride] = overridetopointid;
    return true;
}

stock BlockCarSpawnForPointID(pointid) {
    if(pointid >= T_RealTPointsCount) {
        Logger_Fatal("Tried to block car spawns for non existing pointid", Logger_I("pointid", pointid));
        SendRconCommand("exit");
        return false;
    }

    Iter_Add(BlockedCarSpawns, pointid);
    return true;
}

stock PopulatePickupBatches() {
    Logger_Dbg("tournament", "PopulatePickupBatches");
    //First loop, determine starting points where pickup batches need to be created
    new pickupcount = 0;
    new pickupbatchstart = INVALID_POINT_ID;
    for(new i = 0; i<T_RealTPointsCount; i++) {
        if(T_RaceData[i][T_Type] == CP_PICKUP) {
            if(pickupbatchstart == INVALID_POINT_ID) {
                pickupbatchstart = i;
            }
            T_RaceData[i][T_BStart] = pickupbatchstart;
            pickupcount++;
        } else {
            pickupbatchstart = INVALID_POINT_ID;
            T_RaceData[i][T_BStart] = INVALID_POINT_ID;
        }
    }

    //Second loop, determing ending points where pickup batches need to be created
    new pickupbatchend = INVALID_POINT_ID;
    for(new i = (T_RealTPointsCount-1); i>=0; i--) {
        if(T_RaceData[i][T_Type] == CP_PICKUP) {
            if(pickupbatchend == INVALID_POINT_ID) {
                pickupbatchend = i;
            }
            T_RaceData[i][T_BEnd] = pickupbatchend;
        } else {
            pickupbatchend = INVALID_POINT_ID;
            T_RaceData[i][T_BEnd] = INVALID_POINT_ID;
        }
    }
    if(pickupcount > 4096) {
        Logger_Fatal("Pickup count is larger than 4096, some of your tournament points will not work properly!");
        SendRconCommand("exit");
        return false;
    }
    return true;
}

stock PopulateVehicleBatches() {
    Logger_Dbg("tournament", "PopulateVehicleBatches");
    new lastpointid = INVALID_POINT_ID;
    for(new i = 0; i<T_RealTPointsCount; i++) {
        if(Iter_Contains(PointsWithVehicles, i)) {
            T_RaceData[i][T_VLast] = i;
            lastpointid = i;
        } else {
            T_RaceData[i][T_VLast] = lastpointid;
        }
    }
    return true;
}

stock AddRacePoint(CP_TYPE, Float:RaceX, Float:RaceY, Float:RaceZ, Float:RaceSize, RaceInterior = NO_INTERIOR, bool:vehiclerequired = false, bool:spawninvehicle = false) {
    Logger_Dbg("tournament", "AddRacePoint", Logger_I("CP_TYPE", CP_TYPE), Logger_F("RaceX", RaceX), Logger_F("RaceY", RaceY), Logger_F("RaceZ", RaceZ),
    Logger_F("RaceSize", RaceSize), Logger_I("RaceInterior", RaceInterior), Logger_B("vehiclerequired", vehiclerequired), Logger_B("spawninvehicle", spawninvehicle));
    T_RaceData[T_RealTPointsCount][T_Type] = CP_TYPE:CP_TYPE;
    T_RaceData[T_RealTPointsCount][T_X] = RaceX;
    T_RaceData[T_RealTPointsCount][T_Y] = RaceY;
    T_RaceData[T_RealTPointsCount][T_Z] = RaceZ;
    T_RaceData[T_RealTPointsCount][T_Size] = RaceSize;
    T_RaceData[T_RealTPointsCount][T_Interior] = RaceInterior;
    T_RaceData[T_RealTPointsCount][T_Vehreq] = vehiclerequired;
    T_RaceData[T_RealTPointsCount][T_SpawnOverride] = INVALID_POINT_ID;
    T_RaceData[T_RealTPointsCount][SpawnInVehicle] = spawninvehicle;
    T_RaceData[T_RealTPointsCount][T_NextORenable] = false;
    T_RaceData[T_RealTPointsCount][T_NextORX] = 0.0;
    T_RaceData[T_RealTPointsCount][T_NextORY] = 0.0;
    T_RaceData[T_RealTPointsCount][T_NextORZ] = 0.0;
    T_RealTPointsCount++;
    return true;
}

stock AddCheckPoint(Float:RaceX, Float:RaceY, Float:RaceZ, Float:RaceSize, RaceInterior = NO_INTERIOR, bool:vehiclerequired = false) {
    Logger_Dbg("tournament", "AddCheckPoint", Logger_F("RaceX", RaceX), Logger_F("RaceY", RaceY),
    Logger_F("RaceZ", RaceZ), Logger_F("RaceSize", RaceSize), Logger_I("RaceInterior", RaceInterior),
    Logger_B("vehiclerequired", vehiclerequired));
    T_RaceData[T_RealTPointsCount][T_Type] = CP_TYPE:CP_STANDARD;
    T_RaceData[T_RealTPointsCount][T_X] = RaceX;
    T_RaceData[T_RealTPointsCount][T_Y] = RaceY;
    T_RaceData[T_RealTPointsCount][T_Z] = RaceZ;
    T_RaceData[T_RealTPointsCount][T_Size] = RaceSize;
    T_RaceData[T_RealTPointsCount][T_Interior] = RaceInterior;
    T_RaceData[T_RealTPointsCount][T_Vehreq] = vehiclerequired;
    T_RaceData[T_RealTPointsCount][T_SpawnOverride] = INVALID_POINT_ID;
    T_RealTPointsCount++;
    return true;
}

stock AddPickupPoint(PickupModel, Float:RaceX, Float:RaceY, Float:RaceZ, bool:direction = false) {
    Logger_Dbg("tournament", "AddPickupPoint", Logger_I("PickupModel", PickupModel), Logger_F("RaceX", RaceX), Logger_F("RaceY", RaceY), Logger_F("RaceZ", RaceZ), Logger_B("direction", direction));
    T_RaceData[T_RealTPointsCount][T_Type] = CP_TYPE:CP_PICKUP;
    T_RaceData[T_RealTPointsCount][T_Model] = PickupModel;
    T_RaceData[T_RealTPointsCount][T_X] = RaceX;
    T_RaceData[T_RealTPointsCount][T_Y] = RaceY;
    T_RaceData[T_RealTPointsCount][T_Z] = RaceZ;
    T_RaceData[T_RealTPointsCount][T_ShowDirection] = direction;
    T_RaceData[T_RealTPointsCount][T_Vehreq] = false;
    T_RaceData[T_RealTPointsCount][T_SpawnOverride] = INVALID_POINT_ID;
    T_RealTPointsCount++;
    return true;
}

stock Float:GetCurrentPickupDistance(playerid) {
    new Float:pickupdistance = 9999.9;
    if(Iter_Count(DirectionalPickups[playerid]) > 0) {
        new pointid = INVALID_POINT_ID;
        //We want the first pickup, then stop
        foreach(new i : DirectionalPickups[playerid]) {
            pointid = i;
            break;
        }
        if(pointid != INVALID_POINT_ID) {
            new Float:Tempx, Float:Tempy, Float:Tempz;
            GetPlayerPos(playerid, Tempx, Tempy, Tempz);
            Tempx -= T_RaceData[pointid][T_X];
            Tempy -= T_RaceData[pointid][T_Y];
            Tempz -= T_RaceData[pointid][T_Z];
            //Sadly we need to find the square root, otherwise signal bar is not going to be linear, *sad micro-optimization noises*
            pickupdistance = floatsqroot((Tempx*Tempx) + (Tempy*Tempy) + (Tempz*Tempz));
        }
    }
    return pickupdistance;
}

stock Float:CalculateDistanceProgress(Float:pickupdistance) {
    new Float:progress = 100;
    progress = 100 - pickupdistance;
    if(progress < 0) {
        progress = 0.0;
    }
    return progress;
}

stock UpdateSignalProgress(playerid, Float:progress) {
    SetPlayerProgressBarValue(playerid, PlayerTDSignal[playerid], progress);
}

stock ProgressTournamentForPlayer(playerid, playerscore) {
    Logger_Dbg("tournament", "ProgressTournamentForPlayer", Logger_I("playerid", playerid), Logger_I("playerscore", playerscore));
    if(!TournamentStarted) return false; //Not possible, but why not

    UnlockTVehiclesForPlayer(playerid, INVALID_VEHICLE_ID, playerscore);
    ShowPlayerProgress(playerid, playerscore);

    if(playerscore <= (T_RealTPointsCount-1)) {
        SetNextPointForPlayer(playerid, playerscore);
        if(TournamentCountdown == 0 && (playerscore == 0 || T_RaceData[playerscore][T_Type] != T_RaceData[playerscore-1][T_Type])) {

            //Show objective at start or when point type has changed
            //We also want to show this only when tournament countdown has ended
            ShowPlayerCurrentObjective(playerid, playerscore);
        }
    } else {
        if(FinishedPos[playerid] == 0) {
            new tmpstr[MAX_TMPSTR];
            new playerposstr[MAX_TMPSTR];
            FinishedPlayers++;
            FinishedPos[playerid] = FinishedPlayers; //Prevents from finishing twice
            format(playerposstr, MAX_TMPSTR, "%d%s", FinishedPos[playerid], NumberToPosition(FinishedPos[playerid]));
            new finishtime = GetTickCount() - StartingTime;
            TDB_SaveFinishTime(playerid, finishtime);
            GameTextForPlayer(playerid, "FINISHED!~n~~w~RESPECT+", 7000, 0);
            PlayerPlaySound(playerid, 1132, 0.0, 0.0, 0.0);
            PlayerPlaySound(playerid, 183, 0.0, 0.0, 0.0);
            SoundTimer[playerid] = SetTimerEx("StopPlayerSound", 8000, false, "i", playerid);
            ShowPlayerFinishBox(playerid, FinishedPos[playerid], finishtime);
            new playername[MAX_PLAYER_NAME];
            GetPlayerName(playerid, playername, MAX_PLAYER_NAME);
            format(tmpstr, MAX_TMPSTR, "{000099}|| {FF00BF}%s FINISHED %s {000099}||", playername, playerposstr);
            foreach(new i : Player) {
                SendClientMessage(i, -1, tmpstr);
            }
            //Lets reuse the HideTooltip timer for creating a delayed tooltip
            if(PlayerTooltipTD[playerid][TD_Timer] != INVALID_TIMER) {
                KillTimer(PlayerTooltipTD[playerid][TD_Timer]);
            }
            PlayerTextDrawHide(playerid, PlayerTooltipTD[playerid][TD_ID]); //This can hide the previous tooltip suddenly, but there should not be another tooltip when finished
            PlayerTooltipTD[playerid][TD_Timer] = SetTimerEx("ShowPlayerTooltip", 8000, false, "is", playerid, "You can now spectate others by clicking on other players or by using /spec");
        } //else: already finished, don't do anything
        SetPlayerColor(playerid, 0xC0C0C0FF);
    }
    return true;
}

stock ArraySortReverse(array[], left = 0, right = sizeof array) {
    //Code stolen then simply swapped < and > from https://github.com/Vince0789/pawn-array-util/blob/master/array_util.inc
	new i = left, j = right;
    new pivotindex = (left + right) / 2; //Gets truncated without rounding, magic
	new pivot = array[pivotindex];

	while (i <= j) {
        //Honestly, I have no idea what I am doing, but it works
		while (array[i] > pivot) { i++; }
		while (array[j] < pivot) { j--; }
        //OK, not completely no idea, but something tells me this might fail in some cases

		if (i <= j) {
			new temp = array[i];
			array[i] = array[j];
			array[j] = temp;
		  	i++;
		  	j--;
		}
	}

	if (left < j) {
		ArraySortReverse(array, left, j);
    }

	if (i < right) {
		ArraySortReverse(array, i, right);
    }
}

stock SetNextPointForPlayer(playerid, playerscore) {
    Logger_Dbg("tournament", "SetNextPointForPlayer", Logger_I("playerid", playerid), Logger_I("playerscore", playerscore));
    if(playerscore >= T_RealTPointsCount) return false; //Score should not be larger than point count
    switch(T_RaceData[playerscore][T_Type]) {
        case CP_GROUND, CP_AIR: {
            SetNextRacePointForPlayer(playerid, playerscore);
        }
        case CP_STANDARD: {
            SetPlayerCheckpoint(playerid, T_RaceData[playerscore][T_X], T_RaceData[playerscore][T_Y], T_RaceData[playerscore][T_Z], T_RaceData[playerscore][T_Size]);
        }
        case CP_PICKUP: {
            //On first spawn the player might be reconnecting and we need to recreate the batch from the starting point
            //Or if the score matches with the first pickup point, then we should also create a batch
            //Otherwise it should already be created
            if(FirstSpawn[playerid] || T_RaceData[playerscore][T_BStart] == playerscore) {
                CreatePlayerPickupBatch(playerid, playerscore);
            }
        }
        default: {
            return false; //Seems to be an unknown point type
        }
    }
    return true;
}

stock SetNextRacePointForPlayer(playerid, playerscore) {
    Logger_Dbg("tournament", "SetNextRacePointForPlayer", Logger_I("playerid", playerid), Logger_I("playerscore", playerscore));
    if(playerscore < (T_RealTPointsCount-1)) { //Regular
        if(T_RaceData[playerscore][T_NextORenable]) {
            SetPlayerRaceCheckpoint(playerid, CP_TYPE:T_RaceData[playerscore][T_Type], T_RaceData[playerscore][T_X],
            T_RaceData[playerscore][T_Y], T_RaceData[playerscore][T_Z], T_RaceData[playerscore][T_NextORX],
            T_RaceData[playerscore][T_NextORY], T_RaceData[playerscore][T_NextORZ], T_RaceData[playerscore][T_Size]);
        } else {
            SetPlayerRaceCheckpoint(playerid, CP_TYPE:T_RaceData[playerscore][T_Type], T_RaceData[playerscore][T_X],
            T_RaceData[playerscore][T_Y], T_RaceData[playerscore][T_Z], T_RaceData[playerscore+1][T_X],
            T_RaceData[playerscore+1][T_Y], T_RaceData[playerscore+1][T_Z], T_RaceData[playerscore][T_Size]);
        }
    } else { //Finish CP
        new CP_TYPE:NextTRaceType = CP_TYPE_GROUND_FINISH;
        switch(T_RaceData[playerscore][T_Type]) {
            case CP_AIR: {
                NextTRaceType = CP_TYPE_AIR_FINISH;
            }
        }
        SetPlayerRaceCheckpoint(playerid, NextTRaceType, T_RaceData[playerscore][T_X], T_RaceData[playerscore][T_Y], 
        T_RaceData[playerscore][T_Z], T_RaceData[playerscore-1][T_X], T_RaceData[playerscore-1][T_Y],
        T_RaceData[playerscore-1][T_Z], T_RaceData[playerscore][T_Size]);
    }
    return true;
}

stock SavePlayerLastSpeed(playerid, bool:racecp) {
    Logger_Dbg("tournament", "SavePlayerLastSpeed", Logger_I("playerid", playerid), Logger_B("racecp", racecp));
    if(racecp) {
        if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER) {
            new vehicleid = GetPlayerVehicleID(playerid);
            if(IsCreatedVehicleValid(vehicleid)) {
                GetVehicleVelocity(vehicleid, LastPlayerSpeed[playerid][0], LastPlayerSpeed[playerid][1], LastPlayerSpeed[playerid][2]);
                GetVehicleZAngle(vehicleid, LastPlayerSpeed[playerid][3]);
                TDB_SavePlayerSpeed(playerid, LastPlayerSpeed[playerid][0], LastPlayerSpeed[playerid][1], LastPlayerSpeed[playerid][2], LastPlayerSpeed[playerid][3]);
                return true;
            }
        }
    }
    //If Player did not enter a Race CP, then reset the speed
    TDB_SavePlayerSpeed(playerid, 0.0, 0.0, 0.0, 0.0);
    LastPlayerSpeed[playerid][0] = 0.0;
    LastPlayerSpeed[playerid][1] = 0.0;
    LastPlayerSpeed[playerid][2] = 0.0;
    LastPlayerSpeed[playerid][3] = 0.0;
    return true;
}

stock IncreasePlayerScore(playerid) {
    Logger_Dbg("tournament", "IncreasePlayerScore", Logger_I("playerid", playerid));
    new playerscore = GetPlayerScore(playerid);
    playerscore++;
    SetPlayerScore(playerid, playerscore);
    return playerscore;
}

stock IsCreatedVehicleValid(vehicleid) {
    //Both 0 and INVALID_VEHICLE_ID is not valid, not sure why anyone would care
    if(vehicleid == 0) return false;
    if(vehicleid == INVALID_VEHICLE_ID) return false;
    return true;
}

stock UpdatePlayerProgress(playerid, playerscore) {
    Logger_Dbg("tournament", "UpdatePlayerProgress", Logger_I("playerid", playerid), Logger_I("playerscore", playerscore));
    if(!TournamentStarted) return false; //If not started, then no progress
    if(playerscore == T_RealTPointsCount) return false; //No progress for finished

    new foundpoints, totalpoints;
    new tmpstr[MAX_TMPSTR];
    if(T_RaceData[playerscore][T_Type] == CP_PICKUP) {
        totalpoints = T_RaceData[playerscore][T_BEnd]-T_RaceData[playerscore][T_BStart]+1; //Return the amount of pickups in a batch as total
        foundpoints = totalpoints - (T_RaceData[playerscore][T_BEnd] - playerscore)-1;
        format(tmpstr, MAX_TMPSTR, "%d/%d", foundpoints, totalpoints);
    } else {
        foundpoints = playerscore;
        totalpoints = T_RealTPointsCount;
        format(tmpstr, MAX_TMPSTR, "%d/%d", foundpoints, totalpoints);
    }

    PlayerTextDrawSetString(playerid, PlayerTDPosProgress[playerid], tmpstr);
    return true;
}

stock SetRandomAnimation(playerid) {
    Logger_Dbg("tournament", "SetRandomAnimation", Logger_I("playerid", playerid));
    //This can be made as an array of strings, but this is simpler and uses less memory
    new rand_anim = random(26);

    switch(rand_anim) {
        case 0: ApplyAnimation(playerid, "BASEBALL", "Bat_1", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 1: ApplyAnimation(playerid, "BD_FIRE", "Playa_Kiss_03", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 2: ApplyAnimation(playerid, "PED", "WALK_DRUNK", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 3: ApplyAnimation(playerid, "benchpress", "gym_bp_celebrate", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 4: ApplyAnimation(playerid, "BLOWJOBZ", "BJ_Stand_Start_W", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 5: ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 6: ApplyAnimation(playerid, "STRIP", "PUN_LOOP", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 7: ApplyAnimation(playerid, "CASINO", "cards_win", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 8: ApplyAnimation(playerid, "CLOTHES", "CLO_Pose_Hat", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 9: ApplyAnimation(playerid, "CLOTHES", "CLO_Pose_Loop", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 10: ApplyAnimation(playerid, "CRACK", "crckdeth4", 4.1, false, true, true, true, 1, SYNC_NONE);
        case 11: ApplyAnimation(playerid, "FOOD", "EAT_Vomit_P", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 12: ApplyAnimation(playerid, "DEALER", "DEALER_DEAL", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 13: ApplyAnimation(playerid, "FAT", "FatRun", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 14: ApplyAnimation(playerid, "FIGHT_B", "FightB_3", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 15: ApplyAnimation(playerid, "KISSING", "BD_GF_Wave", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 16: ApplyAnimation(playerid, "STRIP", "STR_Loop_B", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 17: ApplyAnimation(playerid, "MISC", "bitchslap", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 18: ApplyAnimation(playerid, "MISC", "Scratchballs_01", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 19: ApplyAnimation(playerid, "MUSCULAR", "MuscleWalk", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 20: ApplyAnimation(playerid, "ped", "ARRESTgun", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 21: ApplyAnimation(playerid, "ped", "CAR_crawloutRHS", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 22: ApplyAnimation(playerid, "ped", "FightA_M", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 23: ApplyAnimation(playerid, "ped", "fucku", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 24: ApplyAnimation(playerid, "ped", "swat_run", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 25: ApplyAnimation(playerid, "RAPPING", "RAP_A_Loop", 4.1, true, true, true, true, 1, SYNC_NONE);
        case 26: ApplyAnimation(playerid, "SMOKING", "M_smklean_loop", 4.1, true, true, true, true, 1, SYNC_NONE);
    }
    return true;
}

stock Float:GetAngleBetweenPoints(Float:x1, Float:y1, Float:x2, Float:y2) {
    //Code stolen from https://github.com/oscar-broman/samp-weapon-config/blob/master/weapon-config.inc#L5246
    return -(90.0 - atan2(y1 - y2, x1 - x2));
}

stock Float:floatrand(Float:min, Float:max) {
    //stolen from Y_Less
	new imin = floatround(min);
	return floatdiv(float(random((floatround(max)-imin)*100)+(imin*100)),100.0);
}

stock Float:GetTournamentSpawnAngle(pointid, Float:newspawnx, Float:newspawny) {
    Logger_Dbg("tournament", "GetTournamentSpawnAngle", Logger_I("pointid", pointid), Logger_F("newspawnx", newspawnx), Logger_F("newspawny", newspawny));
    new Float:adjustedangle = 0;
    if(pointid != INVALID_POINT_ID) {
        adjustedangle = GetAngleBetweenPoints(T_RaceData[pointid][T_X], T_RaceData[pointid][T_Y], newspawnx, newspawny);
    } else {
        //Next point is either after finish or pickup, make it random to confuse players
        adjustedangle = floatrand(0, 360);
    }
    return adjustedangle;
}

stock SetPlayerTournamentSpawn(playerid, playerscore, bool:forceteleport) {
    Logger_Dbg("tournament", "SetPlayerTournamentSpawn", Logger_I("playerid", playerid), Logger_I("playerscore", playerscore), Logger_B("forceteleport", forceteleport));
    new Float:newspawnx, Float:newspawny, Float:newspawnz, Float:newspawnarea;
    new pointid = DetermineSpawnPoint(playerscore, playerid);
    
    if(pointid == INVALID_POINT_ID) {
        //Set the default spawn
        newspawnx = SpawnCenter[T_SX];
        newspawny = SpawnCenter[T_SY];
        newspawnz = SpawnCenter[T_SZ];
        newspawnarea = SpawnCenter[T_SArea];
        SetPlayerInterior(playerid, 0); //Change this in case you want to spawn inside an interior
    } else {
        //Set last checkpoint as spawn
        newspawnx = T_RaceData[pointid][T_X];
        newspawny = T_RaceData[pointid][T_Y];
        newspawnz = T_RaceData[pointid][T_Z];
        newspawnarea = T_RaceData[pointid][T_Size];
        SetPlayerInterior(playerid, T_RaceData[pointid][T_Interior]);
    }

    if(forceteleport) {
        //For regular spawns and /restart
        new nextpointid = DetermineNextPoint(playerscore);
        SetPlayerRandomSpawn(playerid, nextpointid, newspawnx, newspawny, newspawnz, newspawnarea, pointid);
    }
    if(TournamentCountdown > 0) {
        //During countdown, tournament is started, but we don't want them to move too much
        new Float:halfarea = (newspawnarea/2)+5;
        SetPlayerWorldBounds(playerid, newspawnx+halfarea, newspawnx-halfarea, newspawny+halfarea, newspawny-halfarea);
    } else {
        if(!TournamentStarted) {
            //Tournament has not started, but we want to limit movement
            new Float:halfarea = (newspawnarea/2)+5;
            SetPlayerWorldBounds(playerid, newspawnx+halfarea, newspawnx-halfarea, newspawny+halfarea, newspawny-halfarea);
        } else {
            //Tournament is started, countdown has ended, let them move
            SetPlayerWorldBounds(playerid, WORLD_XMAX, WORLD_XMIN, WORLD_YMAX, WORLD_YMIN);
        }
    }
    return true;
}

stock UpdatePlayerSpawnInfo(playerid, playerscore) {
    Logger_Dbg("tournament", "UpdatePlayerSpawnInfo", Logger_I("playerid", playerid), Logger_I("playerscore", playerscore));
    //Updates the spawn info when playerscore increases, this prevents an unwanted message about world bounds when tournament is not started or world bounds are small
    new pointid = DetermineSpawnPoint(playerscore, playerid);
    if(pointid != INVALID_POINT_ID) {
        new team,skin,Float:spawnX,Float:spawnY,Float:spawnZ,Float:spawnangle,WEAPON:weapon1,ammo1,WEAPON:weapon2,ammo2,WEAPON:weapon3,ammo3;
        
        GetSpawnInfo(playerid, team, skin, spawnX, spawnY, spawnZ, spawnangle, weapon1, ammo1, weapon2, ammo2, weapon3, ammo3);

        SetSpawnInfo(playerid, team, skin, T_RaceData[pointid][T_X], T_RaceData[pointid][T_Y], T_RaceData[pointid][T_Z], spawnangle, weapon1, ammo1, weapon2, ammo2, weapon3, ammo3);
    }
    return true;
}

stock DetermineNextPoint(pointid) {
    Logger_Dbg("tournament", "DetermineNextPoint", Logger_I("pointid", pointid));
    if(pointid < T_RealTPointsCount) {
        //We simply need to check if the next point is not a pickup, otherwise just return same value
        if(T_RaceData[pointid][T_Type] != CP_PICKUP) {
            return pointid;
        }
    }
    return INVALID_POINT_ID;
}

stock DetermineSpawnPoint(pointid, playerid) {
    Logger_Dbg("tournament", "DetermineSpawnPoint", Logger_I("pointid", pointid), Logger_I("playerid", playerid));

    if(pointid > 0) {
        //We want to spawn at the pointid of previous pointid
        pointid = pointid-1;
        if(T_RaceData[pointid][T_Type] == CP_PICKUP) {
            pointid = T_RaceData[pointid][T_BStart]-1;
        }
        //If there were no checkpoints, then BStart will be INVALID_POINT_ID and later we simply set the defualt spawn

        //When we have a special point that needs overriden spawn
        if(T_RaceData[pointid][T_SpawnOverride] != INVALID_POINT_ID) {
            return T_RaceData[pointid][T_SpawnOverride];
        }
        if(pointid >= 0) return pointid;
    }

    return INVALID_POINT_ID;
}

stock SetPlayerRandomSpawn(playerid, pointid, Float:newspawnx, Float:newspawny, Float:newspawnz, Float:newspawnarea, spawnpointid) {
    Logger_Dbg("tournament", "SetPlayerRandomSpawn", Logger_I("playerid", playerid), Logger_F("newspawnx", newspawnx),
        Logger_F("newspawny", newspawny), Logger_F("newspawnz", newspawnz), Logger_F("newspawnarea", newspawnarea),
        Logger_I("spawnpointid", spawnpointid));
    //When setting spawn that is a checkpoint, the player might spawn outside the checkpoint slightly.
    //This is because we are using an spawn area not radius, calculating a random radius is too resourceful
    //unless.. someone has a sound mathematical way to do it

    new Float:halfspawnarea = newspawnarea/2;
    new Float:randomx = floatrand(-halfspawnarea, halfspawnarea)+newspawnx;
    new Float:randomy = floatrand(-halfspawnarea, halfspawnarea)+newspawny;
    new Float:randomz = floatrand(0.0, 0.5)+newspawnz;
    Streamer_UpdateEx(playerid, randomx, randomy, randomz);
    SetPlayerPos(playerid, randomx, randomy, randomz);
    new Float:newspawnangle = GetTournamentSpawnAngle(pointid, newspawnx, newspawny);
    SetPlayerFacingAngle(playerid, newspawnangle);
    SpawnPlayerInVehicle(playerid, randomx, randomy, randomz, spawnpointid);
    return true;
}

stock SpawnPlayerInVehicle(playerid, Float:vX, Float:vY, Float:vZ, playerscore) {
    Logger_Dbg("tournament", "SpawnPlayerInVehicle", Logger_F("vX", vX), Logger_F("vY", vY), Logger_F("vZ", vZ), Logger_I("playerscore", playerscore));
    if(!TournamentStarted) return false;
    if(TournamentCountdown != 0) return false;
    if(PlayerVehicleModel[playerid] == INVALID_VEHICLE_MODEL) return false;
    if(playerscore >= T_RealTPointsCount) return false; //Prevents OOB
    if(playerscore == INVALID_POINT_ID) return false;
    if(!T_RaceData[playerscore][SpawnInVehicle]) return false;

    if(CarSpawnTimer[playerid] != INVALID_TIMER) {
        KillTimer(CarSpawnTimer[playerid]);
    }
    //Create a small delay to allow the player to adjust
    CarSpawnTimer[playerid] = SetTimerEx("PutPlayerInTournamentVehicle", 500, false, "iffffb", playerid, vX, vY, vZ, LastPlayerSpeed[playerid][3], true);
    return true;
}

stock CreatePlayerPickupBatch(playerid, playerscore) {
    Logger_Dbg("tournament", "CreatePlayerPickupBatch", Logger_I("playerid", playerid), Logger_I("playerscore", playerscore));
    new pickupid = INVALID_PICKUP_ID;
    if(T_RaceData[playerscore][T_BStart] == INVALID_POINT_ID) return false; //safety check, do not create pickups if BStart is invalid

    //We always need to start with T_BStart since the player might have picked up a pickup in a random order, we can check if the pickup is already picked up later
    for(new i = T_RaceData[playerscore][T_BStart]; i<=T_RaceData[playerscore][T_BEnd]; i++) {
        if(PickupHistory[playerid][i] == false) {
            if(PointidToPickupid[playerid][i] == INVALID_PICKUP_ID) {
                pickupid = CreatePlayerPickup(playerid, T_RaceData[i][T_Model], 19, T_RaceData[i][T_X], T_RaceData[i][T_Y], T_RaceData[i][T_Z], 0);
                if(pickupid != INVALID_PICKUP_ID) {
                    PickupidToPointid[playerid][pickupid] = i;
                    PointidToPickupid[playerid][i] = pickupid;
                    Iter_Add(CreatedPickups[playerid], pickupid);
                    if(T_RaceData[i][T_ShowDirection] == true) {
                        //We want an iter of all pickups that require direction
                        //In case there is a mix of directional and non-directional pickups, then simply add them all in the same batch
                        //This way we can not worry that a player randomly finds a pickup from a different pointid
                        Iter_Add(DirectionalPickups[playerid], i);
                    }
                } else {
                    Logger_Err("Unable to create a pickup for pointid", Logger_I("pointid", i));
                }
            } //else: do not create pickup, it should be already created
        } //else: do nothing since the pickup is already picked up
    }
    return true;
}

stock DoesPointSpawnInVehicle(pointid) {
    Logger_Dbg("tournament", "DoesPointSpawnInVehicle", Logger_I("pointid", pointid));
    if(pointid == INVALID_POINT_ID || pointid == 0) return false; //Spawning inside a vehicle on default spawn is not supported, deal with it!
    if(pointid >= T_RealTPointsCount) return false; //Spawning in a vehicle on finish also not supported, deal with it!
    if(T_RaceData[pointid][SpawnInVehicle] == true) {
        //Probably more checks can be added here later
        return true;
    }
    return false;
}

stock InitTVehicleLocks(playerid) {
    Logger_Dbg("tournament", "InitTVehicleLocks", Logger_I("playerid", playerid));
    //It is possible that some created vehicles can be unlocked for a playerid, to prevent this we can lock all vehicles on first spawn and later unlock needed ones
    foreach(new i : CreatedVehicles) {
        UnlockedVehicles[i][playerid] = false;
        SetVehicleParamsForPlayer(i, playerid, false, true);
    }

    //We can unlock all vehicles without a point id
    foreach(new i : FreePointVehicles) {
        UnlockedVehicles[i][playerid] = true;
        SetVehicleParamsForPlayer(i, playerid, false, false);
    }
    return true;
}

stock bool:InArray(needle, const haystack[], &index = -1, size = sizeof haystack) {	
    //Code stolen from https://github.com/Vince0789/pawn-array-util/blob/master/array_util.inc
	while(++index < size) {
		if(haystack[index] == needle)
			return true;
	}
    return false;
}

stock InSortedArrayNextMatch(const haystack[], needle, index, size) {
    //Requires a sorted array
    new testindex = index+1; //Imagine, creating a variable for just +1, huge optimiziation!
    if((testindex) >= size) return false; //Prevents invalid index

    //In sorted arrays the duplicate values will be adjacent
    //InArray will return the lowest index. If the same value is on the next index, then we have duplicate values
    if(haystack[testindex] == needle) return true;
    return false;
}

stock CreatePlayerTextDraws(playerid) {
    Logger_Dbg("tournament", "CreatePlayerTextDraws", Logger_I("playerid", playerid));

    //Single player style tooltip box
    PlayerTooltipTD[playerid][TD_ID] = CreatePlayerTextDraw(playerid, 10, 90, "");
    PlayerTextDrawUseBox(playerid, PlayerTooltipTD[playerid][TD_ID], true);
    PlayerTextDrawBoxColour(playerid, PlayerTooltipTD[playerid][TD_ID], 255);
    PlayerTextDrawSetShadow(playerid, PlayerTooltipTD[playerid][TD_ID], 0);
    PlayerTextDrawColour(playerid, PlayerTooltipTD[playerid][TD_ID], 0xFFFFFF96),
    PlayerTextDrawBackgroundColour(playerid, PlayerTooltipTD[playerid][TD_ID], 0x000000AA),
    PlayerTextDrawLetterSize(playerid, PlayerTooltipTD[playerid][TD_ID], 0.45, 2.0);
    PlayerTextDrawTextSize(playerid, PlayerTooltipTD[playerid][TD_ID], 150.0, 0.0);
    PlayerTextDrawFont(playerid, PlayerTooltipTD[playerid][TD_ID], TEXT_DRAW_FONT_1);
    PlayerTextDrawSetProportional(playerid, PlayerTooltipTD[playerid][TD_ID], true);

    //Single player style objective text at bottom
    PlayerObjectiveTD[playerid][TD_ID] = CreatePlayerTextDraw(playerid, 320, 342, "");
    PlayerTextDrawAlignment(playerid, PlayerObjectiveTD[playerid][TD_ID], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawLetterSize(playerid, PlayerObjectiveTD[playerid][TD_ID], 0.45, 2.00);
    PlayerTextDrawTextSize(playerid, PlayerObjectiveTD[playerid][TD_ID], 0.0, 500.0);
    PlayerTextDrawSetOutline(playerid, PlayerObjectiveTD[playerid][TD_ID], true);

    //Fade screen to black
    PlayerScreenTD[playerid][TD_ID] = CreatePlayerTextDraw(playerid, -20.000000, 0.000000, "_" ); 
    PlayerTextDrawUseBox(playerid, PlayerScreenTD[playerid][TD_ID], true);
    PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x000000FF);
    PlayerTextDrawAlignment(playerid, PlayerScreenTD[playerid][TD_ID], TEXT_DRAW_ALIGN:0);
    PlayerTextDrawBackgroundColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x000000FF);
    PlayerTextDrawFont(playerid, PlayerScreenTD[playerid][TD_ID], TEXT_DRAW_FONT_3);
    PlayerTextDrawLetterSize(playerid, PlayerScreenTD[playerid][TD_ID], 1.000000, 52.200000 );
    PlayerTextDrawColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x000000FF);

    //Single player style signal bar for fiding Mike
    PlayerTDSignalText[playerid] = CreatePlayerTextDraw(playerid, 549.000000, 98.000000, "SIGNAL");
    PlayerTextDrawFont(playerid, PlayerTDSignalText[playerid], TEXT_DRAW_FONT_3);
    PlayerTextDrawLetterSize(playerid, PlayerTDSignalText[playerid], 0.304166, 1.600000);
    PlayerTextDrawTextSize(playerid, PlayerTDSignalText[playerid], 400.000000, 0.000000);
    PlayerTextDrawSetOutline(playerid, PlayerTDSignalText[playerid], true);
    PlayerTextDrawSetShadow(playerid, PlayerTDSignalText[playerid], false);
    PlayerTextDrawAlignment(playerid, PlayerTDSignalText[playerid], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, PlayerTDSignalText[playerid], 2094792959);
    PlayerTextDrawBackgroundColour(playerid, PlayerTDSignalText[playerid], 255);
    PlayerTextDrawBoxColour(playerid, PlayerTDSignalText[playerid], 50);
    PlayerTextDrawUseBox(playerid, PlayerTDSignalText[playerid], false);
    PlayerTextDrawSetProportional(playerid, PlayerTDSignalText[playerid], true);
    PlayerTextDrawSetSelectable(playerid, PlayerTDSignalText[playerid], false);

    //Actual signal bar
    PlayerTDSignal[playerid] = CreatePlayerProgressBar(playerid, 587.000000, 102.000000, 39.500000, 9.000000, 2094792959, 100.000000, BAR_DIRECTION_RIGHT);

    CreatePlayerPosTextDraws(playerid);
    CreatePlayerFinishTextDraws(playerid);
    return true;
}

stock CreatePlayerFinishTextDraws(playerid) {
    Logger_Dbg("tournament", "CreatePlayerFinishTextDraws", Logger_I("playerid", playerid));

    //Signle player style finish box with time and position and winner text
    PlayerTDFinishBox[playerid] = CreatePlayerTextDraw(playerid, 320.000000, 324.000000, "_");
    PlayerTextDrawFont(playerid, PlayerTDFinishBox[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, PlayerTDFinishBox[playerid], 0.600000, 6.799989);
    PlayerTextDrawTextSize(playerid, PlayerTDFinishBox[playerid], 312.000000, 119.000000);
    PlayerTextDrawSetOutline(playerid, PlayerTDFinishBox[playerid], true);
    PlayerTextDrawSetShadow(playerid, PlayerTDFinishBox[playerid], false);
    PlayerTextDrawAlignment(playerid, PlayerTDFinishBox[playerid], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, PlayerTDFinishBox[playerid], -1);
    PlayerTextDrawBackgroundColour(playerid, PlayerTDFinishBox[playerid], 255);
    PlayerTextDrawBoxColour(playerid, PlayerTDFinishBox[playerid], 255);
    PlayerTextDrawUseBox(playerid, PlayerTDFinishBox[playerid], true);
    PlayerTextDrawSetProportional(playerid, PlayerTDFinishBox[playerid], true);
    PlayerTextDrawSetSelectable(playerid, PlayerTDFinishBox[playerid], false);

    //Single player finish text
    PlayerTDFinishTxt[playerid] = CreatePlayerTextDraw(playerid, 264.000000, 312.000000, "Finished!");
    PlayerTextDrawFont(playerid, PlayerTDFinishTxt[playerid], TEXT_DRAW_FONT:0);
    PlayerTextDrawLetterSize(playerid, PlayerTDFinishTxt[playerid], 0.400000, 1.750000);
    PlayerTextDrawTextSize(playerid, PlayerTDFinishTxt[playerid], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, PlayerTDFinishTxt[playerid], true);
    PlayerTextDrawSetShadow(playerid, PlayerTDFinishTxt[playerid], false);
    PlayerTextDrawAlignment(playerid, PlayerTDFinishTxt[playerid], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawColour(playerid, PlayerTDFinishTxt[playerid], -1);
    PlayerTextDrawBackgroundColour(playerid, PlayerTDFinishTxt[playerid], 255);
    PlayerTextDrawBoxColour(playerid, PlayerTDFinishTxt[playerid], 50);
    PlayerTextDrawUseBox(playerid, PlayerTDFinishTxt[playerid], false);
    PlayerTextDrawSetProportional(playerid, PlayerTDFinishTxt[playerid], true);
    PlayerTextDrawSetSelectable(playerid, PlayerTDFinishTxt[playerid], false);

    //Single player style finish time
    PlayerTDFinishTime[playerid] = CreatePlayerTextDraw(playerid, 271.000000, 360.000000, "");
    PlayerTextDrawFont(playerid, PlayerTDFinishTime[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, PlayerTDFinishTime[playerid], 0.350000, 1.899999);
    PlayerTextDrawTextSize(playerid, PlayerTDFinishTime[playerid], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, PlayerTDFinishTime[playerid], true);
    PlayerTextDrawSetShadow(playerid, PlayerTDFinishTime[playerid], false);
    PlayerTextDrawAlignment(playerid, PlayerTDFinishTime[playerid], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawBackgroundColour(playerid, PlayerTDFinishTime[playerid], 255);
    PlayerTextDrawBoxColour(playerid, PlayerTDFinishTime[playerid], 50);
    PlayerTextDrawUseBox(playerid, PlayerTDFinishTime[playerid], false);
    PlayerTextDrawSetProportional(playerid, PlayerTDFinishTime[playerid], true);
    PlayerTextDrawSetSelectable(playerid, PlayerTDFinishTime[playerid], false);

    //Single player style finish position
    PlayerTDFinishPos[playerid] = CreatePlayerTextDraw(playerid, 272.000000, 336.000000, "");
    PlayerTextDrawFont(playerid, PlayerTDFinishPos[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, PlayerTDFinishPos[playerid], 0.400000, 1.900000);
    PlayerTextDrawTextSize(playerid, PlayerTDFinishPos[playerid], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, PlayerTDFinishPos[playerid], true);
    PlayerTextDrawSetShadow(playerid, PlayerTDFinishPos[playerid], false);
    PlayerTextDrawAlignment(playerid, PlayerTDFinishPos[playerid], TEXT_DRAW_ALIGN_LEFT);
    PlayerTextDrawBackgroundColour(playerid, PlayerTDFinishPos[playerid], 255);
    PlayerTextDrawBoxColour(playerid, PlayerTDFinishPos[playerid], 50);
    PlayerTextDrawUseBox(playerid, PlayerTDFinishPos[playerid], false);
    PlayerTextDrawSetProportional(playerid, PlayerTDFinishPos[playerid], true);
    PlayerTextDrawSetSelectable(playerid, PlayerTDFinishPos[playerid], false);
    return true;
}

stock CreatePlayerPosTextDraws(playerid) {
    Logger_Dbg("tournament", "CreatePlayerPosTextDraws", Logger_I("playerid", playerid));

    //Single player style current position box
    PlayerTDPosBorder[playerid] = CreatePlayerTextDraw(playerid, 548.000000, 311.000000, "_");
    PlayerTextDrawFont(playerid, PlayerTDPosBorder[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, PlayerTDPosBorder[playerid], 0.600000, 6.499988);
    PlayerTextDrawTextSize(playerid, PlayerTDPosBorder[playerid], 288.000000, 37.000000);
    PlayerTextDrawSetOutline(playerid, PlayerTDPosBorder[playerid], true);
    PlayerTextDrawSetShadow(playerid, PlayerTDPosBorder[playerid], false);
    PlayerTextDrawAlignment(playerid, PlayerTDPosBorder[playerid], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, PlayerTDPosBorder[playerid], -1);
    PlayerTextDrawBackgroundColour(playerid, PlayerTDPosBorder[playerid], 1296911871);
    PlayerTextDrawBoxColour(playerid, PlayerTDPosBorder[playerid], 255);
    PlayerTextDrawUseBox(playerid, PlayerTDPosBorder[playerid], true);
    PlayerTextDrawSetProportional(playerid, PlayerTDPosBorder[playerid], true);
    PlayerTextDrawSetSelectable(playerid, PlayerTDPosBorder[playerid], false);

    //Single player style current position box
    PlayerTDPosWhite[playerid] = CreatePlayerTextDraw(playerid, 548.000000, 312.000000, "_");
    PlayerTextDrawFont(playerid, PlayerTDPosWhite[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, PlayerTDPosWhite[playerid], 0.600000, 6.249987);
    PlayerTextDrawTextSize(playerid, PlayerTDPosWhite[playerid], 294.000000, 35.500000);
    PlayerTextDrawSetOutline(playerid, PlayerTDPosWhite[playerid], true);
    PlayerTextDrawSetShadow(playerid, PlayerTDPosWhite[playerid], false);
    PlayerTextDrawAlignment(playerid, PlayerTDPosWhite[playerid], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, PlayerTDPosWhite[playerid], -1);
    PlayerTextDrawBackgroundColour(playerid, PlayerTDPosWhite[playerid], 255);
    PlayerTextDrawBoxColour(playerid, PlayerTDPosWhite[playerid], -421070081);
    PlayerTextDrawUseBox(playerid, PlayerTDPosWhite[playerid], true);
    PlayerTextDrawSetProportional(playerid, PlayerTDPosWhite[playerid], true);
    PlayerTextDrawSetSelectable(playerid, PlayerTDPosWhite[playerid], false);

    //Single player style current position box
    PlayerTDPosInner[playerid] = CreatePlayerTextDraw(playerid, 548.000000, 314.000000, "_");
    PlayerTextDrawFont(playerid, PlayerTDPosInner[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, PlayerTDPosInner[playerid], 0.600000, 5.799984);
    PlayerTextDrawTextSize(playerid, PlayerTDPosInner[playerid], 294.500000, 33.500000);
    PlayerTextDrawSetOutline(playerid, PlayerTDPosInner[playerid], true);
    PlayerTextDrawSetShadow(playerid, PlayerTDPosInner[playerid], false);
    PlayerTextDrawAlignment(playerid, PlayerTDPosInner[playerid], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, PlayerTDPosInner[playerid], -1);
    PlayerTextDrawBackgroundColour(playerid, PlayerTDPosInner[playerid], 255);
    PlayerTextDrawBoxColour(playerid, PlayerTDPosInner[playerid], 255);
    PlayerTextDrawUseBox(playerid, PlayerTDPosInner[playerid], true);
    PlayerTextDrawSetProportional(playerid, PlayerTDPosInner[playerid], true);
    PlayerTextDrawSetSelectable(playerid, PlayerTDPosInner[playerid], false);

    //Single player style current position box
    PlayerTDPosProgress[playerid] = CreatePlayerTextDraw(playerid, 549.000000, 353.000000, "");
    PlayerTextDrawFont(playerid, PlayerTDPosProgress[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, PlayerTDPosProgress[playerid], 0.20000, 1.5);
    PlayerTextDrawTextSize(playerid, PlayerTDPosProgress[playerid], 0.000000, 0.50000);
    PlayerTextDrawSetOutline(playerid, PlayerTDPosProgress[playerid], true);
    PlayerTextDrawSetShadow(playerid, PlayerTDPosProgress[playerid], false);
    PlayerTextDrawAlignment(playerid, PlayerTDPosProgress[playerid], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, PlayerTDPosProgress[playerid], -421070081);
    PlayerTextDrawBackgroundColour(playerid, PlayerTDPosProgress[playerid], 255);
    PlayerTextDrawBoxColour(playerid, PlayerTDPosProgress[playerid], 50);
    PlayerTextDrawUseBox(playerid, PlayerTDPosProgress[playerid], true);
    PlayerTextDrawSetProportional(playerid, PlayerTDPosProgress[playerid], true);
    PlayerTextDrawSetSelectable(playerid, PlayerTDPosProgress[playerid], false);

    //We set this to 10 to trigger textdraw update later
    PreviousPos[playerid] = 10;

    //Single player style current position's point count
    PlayerTDPosTxt[playerid] = CreatePlayerTextDraw(playerid, 558.000000, 315.000000, "");
    PlayerTextDrawFont(playerid, PlayerTDPosTxt[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, PlayerTDPosTxt[playerid], 0.262500, 2.749998);
    PlayerTextDrawTextSize(playerid, PlayerTDPosTxt[playerid], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, PlayerTDPosTxt[playerid], true);
    PlayerTextDrawSetShadow(playerid, PlayerTDPosTxt[playerid], false);
    PlayerTextDrawAlignment(playerid, PlayerTDPosTxt[playerid], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, PlayerTDPosTxt[playerid], -421070081);
    PlayerTextDrawBackgroundColour(playerid, PlayerTDPosTxt[playerid], 255);
    PlayerTextDrawBoxColour(playerid, PlayerTDPosTxt[playerid], 50);
    PlayerTextDrawUseBox(playerid, PlayerTDPosTxt[playerid], false);
    PlayerTextDrawSetProportional(playerid, PlayerTDPosTxt[playerid], true);
    PlayerTextDrawSetSelectable(playerid, PlayerTDPosTxt[playerid], false);

    //Single player style current position number
    PlayerTDPosNum[playerid] = CreatePlayerTextDraw(playerid, 541.000000, 309.000000, "");
    PlayerTextDrawFont(playerid, PlayerTDPosNum[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, PlayerTDPosNum[playerid], 0.550000, 5.550004);
    PlayerTextDrawTextSize(playerid, PlayerTDPosNum[playerid], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, PlayerTDPosNum[playerid], true);
    PlayerTextDrawSetShadow(playerid, PlayerTDPosNum[playerid], false);
    PlayerTextDrawAlignment(playerid, PlayerTDPosNum[playerid], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, PlayerTDPosNum[playerid], -421070081);
    PlayerTextDrawBackgroundColour(playerid, PlayerTDPosNum[playerid], 255);
    PlayerTextDrawBoxColour(playerid, PlayerTDPosNum[playerid], 50);
    PlayerTextDrawUseBox(playerid, PlayerTDPosNum[playerid], false);
    PlayerTextDrawSetProportional(playerid, PlayerTDPosNum[playerid], false);
    PlayerTextDrawSetSelectable(playerid, PlayerTDPosNum[playerid], false);

    //Single player style current position total players
    PlayerTDPosTotal[playerid] = CreatePlayerTextDraw(playerid, 558.000000, 336.000000, "");
    PlayerTextDrawFont(playerid, PlayerTDPosTotal[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, PlayerTDPosTotal[playerid], 0.4000, 1.700000);
    PlayerTextDrawTextSize(playerid, PlayerTDPosTotal[playerid], 400.000000, 17.000000);
    PlayerTextDrawSetOutline(playerid, PlayerTDPosTotal[playerid], true);
    PlayerTextDrawSetShadow(playerid, PlayerTDPosTotal[playerid], false);
    PlayerTextDrawAlignment(playerid, PlayerTDPosTotal[playerid], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawColour(playerid, PlayerTDPosTotal[playerid], -421070081);
    PlayerTextDrawBackgroundColour(playerid, PlayerTDPosTotal[playerid], 255);
    PlayerTextDrawBoxColour(playerid, PlayerTDPosTotal[playerid], 50);
    PlayerTextDrawUseBox(playerid, PlayerTDPosTotal[playerid], false);
    PlayerTextDrawSetProportional(playerid, PlayerTDPosTotal[playerid], true);
    PlayerTextDrawSetSelectable(playerid, PlayerTDPosTotal[playerid], false);
    return true;
}

stock ShowPlayerObjective(playerid, const text[]) {
    Logger_Dbg("tournament", "ShowPlayerObjective", Logger_I("playerid", playerid), Logger_S("text", text));
    if(PlayerObjectiveTD[playerid][TD_Timer] != INVALID_TIMER) {
        KillTimer(PlayerObjectiveTD[playerid][TD_Timer]);
    }
    PlayerTextDrawSetString(playerid, PlayerObjectiveTD[playerid][TD_ID], text);
    PlayerTextDrawShow(playerid, PlayerObjectiveTD[playerid][TD_ID]);
    PlayerObjectiveTD[playerid][TD_Timer] = SetTimerEx("HidePlayerObjective", 8000, false, "i", playerid);
    return true;
}

stock ShowPlayerCurrentObjective(playerid, playerscore) {
    Logger_Dbg("tournament", "ShowPlayerCurrentObjective", Logger_I("playerid", playerid), Logger_I("playerscore", playerscore));
    if(playerscore >= T_RealTPointsCount) return false;

    if(T_RaceData[playerscore][T_Type] == CP_PICKUP) {
        if(Iter_Count(DirectionalPickups[playerid]) > 0) {
            new Float:pickupdistance = GetCurrentPickupDistance(playerid);
            UpdateSignalProgress(playerid, CalculateDistanceProgress(pickupdistance));
            ShowPlayerProgressBar(playerid, PlayerTDSignal[playerid]);
            PlayerTextDrawShow(playerid, PlayerTDSignalText[playerid]);
            ShowPlayerObjective(playerid, "Use the ~g~signal ~w~to find all the ~r~Packages ~w~in the area");
            if(DirectionTimer[playerid] != INVALID_TIMER) {
                KillTimer(DirectionTimer[playerid]);
                DirectionTimer[playerid] = INVALID_TIMER;
            }
            DirectionTimer[playerid] = SetTimerEx("ShowPickupDirection", 1000, false, "i", playerid);
        } else {
            if(DirectionTimer[playerid] != INVALID_TIMER) {
                KillTimer(DirectionTimer[playerid]);
                DirectionTimer[playerid] = INVALID_TIMER;
            }
            HidePlayerProgressBar(playerid, PlayerTDSignal[playerid]);
            PlayerTextDrawHide(playerid, PlayerTDSignalText[playerid]);
            ShowPlayerObjective(playerid, "Find all the ~r~Packages ~w~in the area");
        }
    } else {
        if(DirectionTimer[playerid] != INVALID_TIMER) {
            KillTimer(DirectionTimer[playerid]);
            DirectionTimer[playerid] = INVALID_TIMER;
        }
        HidePlayerProgressBar(playerid, PlayerTDSignal[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDSignalText[playerid]);
        ShowPlayerObjective(playerid, "Go to the next ~r~Checkpoint");
    }
    return true;
}

stock ShowPlayerFinishBox(playerid, finishpos, finishtime) {
    Logger_Dbg("tournament", "ShowPlayerFinishBox", Logger_I("playerid", playerid), Logger_I("finishpos", finishpos), Logger_I("finishtime", finishtime));
    if(FinishTDTimer[playerid] != INVALID_TIMER) {
        KillTimer(FinishTDTimer[playerid]);
    }
    new tmpstr[MAX_TMPSTR];
    format(tmpstr, MAX_TMPSTR, "~b~~h~~h~~h~Position: ~w~%d%s", finishpos, NumberToPosition(finishpos));
    PlayerTextDrawSetString(playerid, PlayerTDFinishPos[playerid], tmpstr);
    format(tmpstr, MAX_TMPSTR, "~b~~h~~h~~h~Time: ~w~%s", TimeConvert(finishtime));
    PlayerTextDrawSetString(playerid, PlayerTDFinishTime[playerid], tmpstr);
    PlayerTextDrawShow(playerid, PlayerTDFinishBox[playerid]);
    PlayerTextDrawShow(playerid, PlayerTDFinishTxt[playerid]);
    PlayerTextDrawShow(playerid, PlayerTDFinishPos[playerid]);
    PlayerTextDrawShow(playerid, PlayerTDFinishTime[playerid]);
    FinishTDTimer[playerid] = SetTimerEx("HidePlayerFinishBox", 10000, false, "i", playerid);
    return true;
}

stock FadeOutPlayerScreen(playerid) {
    Logger_Dbg("tournament", "FadeOutPlayerScreen", Logger_I("playerid", playerid));
    if(PlayerScreenTD[playerid][TD_Timer] != INVALID_TIMER) {
        KillTimer(PlayerScreenTD[playerid][TD_Timer]);
        PlayerScreenTD[playerid][TD_Timer] = INVALID_TIMER;
    }
    PlayerScreenTD[playerid][TD_Timer] = SetTimerEx("FadeScreen", 2500, false, "iib", playerid, 15, false);
}

stock FadeInPlayerScreen(playerid) {
    Logger_Dbg("tournament", "FadeInPlayerScreen", Logger_I("playerid", playerid));
    if(PlayerScreenTD[playerid][TD_Timer] != INVALID_TIMER) {
        KillTimer(PlayerScreenTD[playerid][TD_Timer]);
        PlayerScreenTD[playerid][TD_Timer] = INVALID_TIMER;
    }
    FadeScreen(playerid, 1, true); //We want to start fading in instantly, but fade out with a delay to simulate singleplayer
}

stock TimeConvert(time) {
    time = floatround(time/1000); //Convert to seconds
    //Code stolen from a random Discord user "Envy", then rewritten to add missing zeros
    new day = time / 86400; time %= 86400;
    new hour = time / 3600; time %= 3600;
    new minute = time / 60; time %= 60;
    new second = time;
    new tmpstr[MAX_TMPSTR];
    if(day > 0) {
        //Days take too much space, lets just remove seconds since those are irrelevent when tournament is days long
        //Seriously, days?
        //Sure, why not, don't care, have fun
        format(tmpstr, MAX_TMPSTR, "%s%dd ", tmpstr, day);

        if(hour < 9) {
            format(tmpstr, MAX_TMPSTR, "%s0%d:", tmpstr, hour);
        } else {
            format(tmpstr, MAX_TMPSTR, "%s%d:", tmpstr, hour);
        }
        if(minute < 9) {
            format(tmpstr, MAX_TMPSTR, "%s0%d", tmpstr, minute);
        } else {
            format(tmpstr, MAX_TMPSTR, "%s%d", tmpstr, minute);
        }
    } else {
        if(hour < 9) {
            format(tmpstr, MAX_TMPSTR, "%s0%d:", tmpstr, hour);
        } else {
            format(tmpstr, MAX_TMPSTR, "%s%d:", tmpstr, hour);
        }
        if(minute < 9) {
            format(tmpstr, MAX_TMPSTR, "%s0%d:", tmpstr, minute);
        } else {
            format(tmpstr, MAX_TMPSTR, "%s%d:", tmpstr, minute);
        }
        if(second < 9) {
            format(tmpstr, MAX_TMPSTR, "%s0%d", tmpstr, second);
        } else {
            format(tmpstr, MAX_TMPSTR, "%s%d", tmpstr, second);
        }
    }
    return tmpstr;
}

stock StartSpectatingChecks(playerid, targetplayerid) {
    Logger_Dbg("tournament", "StartSpectatingChecks", Logger_I("playerid", playerid), Logger_I("targetplayerid", targetplayerid));
    if(GetPlayerScore(playerid) < T_RealTPointsCount && !IsPlayerAdmin(playerid)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are not allowed to use this command!");
        return false;
    }

    if(!IsPlayerSpawn[playerid] && GetPlayerState(playerid) != PLAYER_STATE_SPECTATING) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be spawned!");
        return false;
    }

    if(!IsPlayerSpawn[targetplayerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Player has not spawned!");
        return false;
    }

    //In case someone is spectating the player, stop spectating since the player is spectating someone else
    if(Iter_Count(SpectatedBy[playerid]) > 0) {
        foreach(new i : SpectatedBy[playerid]) {
            StopSpectating(i);
        }
    }

    return true;
}

stock StartSpectating(playerid, targetplayerid) {
    Logger_Dbg("tournament", "StartSpectating", Logger_I("playerid", playerid), Logger_I("targetplayerid", targetplayerid));
    if(!StartSpectatingChecks(playerid, targetplayerid)) return false; //If failed check, skip

    if(SpectatingPlayer[playerid] != INVALID_PLAYER_ID) {
        //In case user starts spectating a new player, remove the playerid from old player's iter
        Iter_Remove(SpectatedBy[targetplayerid], playerid);
    }

    //Destroy player vehicle before starting to spectate, otherwise a rogue vehicle is spawned
    if(IsCreatedVehicleValid(PlayerVehicleID[playerid])) {
        DestroyVehicle(PlayerVehicleID[playerid]);
        Iter_Remove(CreatedVehicles, PlayerVehicleID[playerid]);
        VehicleIDToPlayerid[PlayerVehicleID[playerid]] = INVALID_PLAYER_ID;
        PlayerVehicleID[playerid] = INVALID_VEHICLE_ID;
    }

    HidePlayerTextDraws(playerid, false);
    PreviousInterior[playerid] = GetPlayerInterior(playerid);
    TogglePlayerSpectating(playerid, true);
    IsPlayerSpawn[playerid] = false; //We want this to prevent random functions from being executed on a spectator
    Iter_Remove(SpawnedPlayers, playerid);
    new vehicleid = GetPlayerVehicleID(targetplayerid);
	if(IsCreatedVehicleValid(vehicleid)) {
		PlayerSpectateVehicle(playerid, vehicleid);
	} else {
		PlayerSpectatePlayer(playerid, targetplayerid, SPECTATE_MODE_NORMAL);
	}
    SetPlayerInterior(playerid, GetPlayerInterior(targetplayerid));
    Iter_Add(SpectatedBy[targetplayerid], playerid);
    SpectatingPlayer[playerid] = targetplayerid;
    return true;
}

stock StopSpectating(playerid) {
    Logger_Dbg("tournament", "StopSpectating", Logger_I("playerid", playerid));
    if(SpectatingPlayer[playerid] != INVALID_PLAYER_ID) {
        Iter_Remove(SpectatedBy[SpectatingPlayer[playerid]], playerid);
    }
    TogglePlayerSpectating(playerid, false);
    IsPlayerSpawn[playerid] = true;
    Iter_Add(SpawnedPlayers, playerid);
    SetPlayerInterior(playerid, PreviousInterior[playerid]);
    SpectatingPlayer[playerid] = INVALID_PLAYER_ID;
}

stock ShowPlayerProgress(playerid, playerscore) {
    Logger_Dbg("tournament", "ShowPlayerProgress", Logger_I("playerid", playerid), Logger_I("playerscore", playerscore));
    if(UpdatePlayerProgress(playerid, playerscore)) { //Only show if function returns true
        PlayerTextDrawShow(playerid, PlayerTDPosBorder[playerid]);
        PlayerTextDrawShow(playerid, PlayerTDPosWhite[playerid]);
        PlayerTextDrawShow(playerid, PlayerTDPosInner[playerid]);
        PlayerTextDrawShow(playerid, PlayerTDPosProgress[playerid]);
        PlayerTextDrawShow(playerid, PlayerTDPosTxt[playerid]);
        PlayerTextDrawShow(playerid, PlayerTDPosNum[playerid]);
        PlayerTextDrawShow(playerid, PlayerTDPosTotal[playerid]);
    } else {
        PlayerTextDrawHide(playerid, PlayerTDPosBorder[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDPosWhite[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDPosInner[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDPosProgress[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDPosTxt[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDPosNum[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDPosTotal[playerid]);
    }
    return true;
}

stock HidePlayerTextDraws(playerid, bool:ondisconnect) {
    Logger_Dbg("tournament", "HidePlayerTextDraws", Logger_I("playerid", playerid), Logger_B("ondisconnect", ondisconnect));
    //PlayerScreenTD is not here on purpose, we want that to be shown during spawn/death
    if(!ondisconnect) {
        PlayerTextDrawHide(playerid, PlayerTooltipTD[playerid][TD_ID]);
        PlayerTextDrawHide(playerid, PlayerObjectiveTD[playerid][TD_ID]);
        PlayerTextDrawHide(playerid, PlayerTDPosBorder[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDPosWhite[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDPosInner[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDPosProgress[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDPosTxt[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDPosNum[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDPosTotal[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDFinishBox[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDFinishTxt[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDFinishPos[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDFinishTime[playerid]);
        PlayerTextDrawHide(playerid, PlayerTDSignalText[playerid]);
        HidePlayerProgressBar(playerid, PlayerTDSignal[playerid]);
    }

    if(PlayerTooltipTD[playerid][TD_Timer] != INVALID_TIMER) {
        KillTimer(PlayerTooltipTD[playerid][TD_Timer]);
        PlayerTooltipTD[playerid][TD_Timer] = INVALID_TIMER;
    }
    if(PlayerObjectiveTD[playerid][TD_Timer] != INVALID_TIMER) {
        KillTimer(PlayerObjectiveTD[playerid][TD_Timer]);
        PlayerObjectiveTD[playerid][TD_Timer] = INVALID_TIMER;
    }
    if(FinishTDTimer[playerid] != INVALID_TIMER) {
        KillTimer(FinishTDTimer[playerid]);
        FinishTDTimer[playerid] = INVALID_TIMER;
    }

    return true;
}

stock IsTournamentStarted() {
    if(!TournamentStarted) return false;
    if(TournamentCountdown != 0) return false;
    return true;
}

stock CheckSummoningVehicle(playerid, bool:keypress) {
    Logger_Dbg("tournament", "CheckSummoningVehicle", Logger_I("playerid", playerid), Logger_B("keypress", keypress));
    if(!IsTournamentStarted()) {
        if(!keypress) {
            SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Tournament has not been started yet!");
        }
        return true;
    }

    if(!IsPlayerSpawn[playerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be spawned!");
        return true;
    }

    if(PlayerVehicleModel[playerid] == INVALID_VEHICLE_MODEL) {
        if(!keypress) {
            SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You don't have a vehicle, find one first!");
        }
        return true;
    }

    //There isn't a good way to prevent a player not climbing to CPs on foot when vehicle is required.
    //Instead we limit how close to the CPs you can summon vehicles
    new pointid = GetPlayerCurrentCP(playerid);
    if(pointid != INVALID_POINT_ID) {
        if(IsPlayerInRangeOfPoint(playerid, 50.0, T_RaceData[pointid][T_X], T_RaceData[pointid][T_Y], T_RaceData[pointid][T_Z])) {
            if(!keypress) {
                SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are too close to the checkpoint for summoning your vehicle!");
            }
            return true;
        }
    }

    if(SummonTimer[playerid] != INVALID_TIMER) {
        if(!keypress) {
            SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Vehicle already summoned, please wait!");
        }
        return true;
    }

    //This sort of prevents flipping the vehicle
    if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT) {
        if(!keypress) {
            SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You must be on foot!");
        }
        return true;
    }

    if(Iter_Contains(BlockedCarSpawns, GetPlayerScore(playerid))) {
        if(!keypress) {
            SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Vehicles are not allowed to be summoned here!");
        }
        return true;
    }

    new Float:Tempx1;
    new Float:Tempy1;
    new Float:Tempz1;
    GetPlayerPos(playerid, Tempx1, Tempy1, Tempz1);
    if(!keypress) {
        SendClientMessage(playerid, -1, "{00FF00}- Summoning vehicle... please wait {FFFF00}and stand still!");
    }
    SummonTimer[playerid] = SetTimerEx("SummonTournamentVehicle", 3000, false, "ifff", playerid, Tempx1, Tempy1, Tempz1);
    return true;
}



stock GetPlayerCurrentCP(playerid) {
    Logger_Dbg("tournament", "GetPlayerCurrentCP", Logger_I("playerid", playerid));
    new playerscore = GetPlayerScore(playerid);
    if(playerscore < T_RealTPointsCount) {
        if(T_RaceData[playerscore][T_Vehreq] == true) { //Only limit vehicle summoning if vehicle is required
            return playerscore;
        }
    }
    return INVALID_POINT_ID;
}

stock NumberToPosition(position) {
    Logger_Dbg("tournament", "NumberToPosition", Logger_I("position", position));
    new lastdigit = position % 10;
    new tmpstr[MAX_TMPSTR];
    switch(lastdigit) {
        case 1: {
            format(tmpstr, MAX_TMPSTR, "ST");
        }
        case 2: {
            format(tmpstr, MAX_TMPSTR, "ND");
        }
        case 3: {
            format(tmpstr, MAX_TMPSTR, "RD");
        }
        default: {
            format(tmpstr, MAX_TMPSTR, "TH");
        }
    }
    return tmpstr;
}

stock ResetTournamentVehicles() {
    Logger_Dbg("tournament", "ResetTournamentVehicles");
    foreach (new vehicleid : CreatedVehicles) {
        DestroyVehicle(vehicleid);
        if(VehicleRespawnTimers[vehicleid] != INVALID_TIMER) {
            KillTimer(VehicleRespawnTimers[vehicleid]);
            VehicleRespawnTimers[vehicleid] = INVALID_TIMER;
        }
    }
    Iter_Clear(CreatedVehicles);
    Iter_Clear(FreePointVehicles);

    for(new i = 0; i<MAX_VEHICLES; i++) {
        VehicleIDToSpawnID[i] = INVALID_SPAWN_ID;
        for(new j = 0; j<MAX_PLAYERS; j++) {
            UnlockedVehicles[i][j] = false;
        }
    }

    foreach(new pointid : PointsWithVehicles) {
        Iter_Clear(PointVehicles[pointid]);
    }

    new vehicleid = INVALID_VEHICLE_ID;
    for(new i = 0; i<T_RealTVehicleCount; i++) {
        vehicleid = CreateVehicle(TournamentVehicleSpawns[i][T_VModel], TournamentVehicleSpawns[i][T_VX],
        TournamentVehicleSpawns[i][T_VY], TournamentVehicleSpawns[i][T_VZ], TournamentVehicleSpawns[i][T_VA],
        TournamentVehicleSpawns[i][T_VC1], TournamentVehicleSpawns[i][T_VC2], 300);
        if(!IsCreatedVehicleValid(vehicleid)) {
            Logger_Err("Failed to respawn vehicle for restart", Logger_I("vehicleid", vehicleid));
            continue;
        }
        Iter_Add(CreatedVehicles, vehicleid);
        if(TournamentVehicleSpawns[i][T_VPID] != INVALID_POINT_ID) {
            
            Iter_Add(PointVehicles[TournamentVehicleSpawns[i][T_VPID]], vehicleid);
            foreach(new j : Player) {
                //We lock all vehicles on reset
                SetVehicleParamsForPlayer(vehicleid, j, false, true);
                UnlockedVehicles[vehicleid][j] = false;

            }
        } else {
            Iter_Add(FreePointVehicles, vehicleid);
            foreach(new j : Player) {
                //Vehicle is unlocked on all stages, so lets unlock it now
                SetVehicleParamsForPlayer(vehicleid, j, false, false);
                UnlockedVehicles[vehicleid][j] = true;
            }
        }

        VehicleIDToSpawnID[vehicleid] = i;
    }
    return true;
}

stock UnlockTVehiclesForPlayer(playerid, targetvehicleid, score, vehiclespawnid = INVALID_SPAWN_ID) {
    Logger_Dbg("tournament", "UnlockTVehiclesForPlayer", Logger_I("playerid", playerid), Logger_I("targetvehicleid", targetvehicleid), Logger_I("score", score));
    if(!IsCreatedVehicleValid(targetvehicleid)) { //When targetvehicleid is not specified, used for unlocking batches
        if(score == T_RealTPointsCount) score--; //Special case for finished players, lets just assume the last pointid to unlock last batch vehicles
        if(T_RaceData[score][T_VLast] != INVALID_POINT_ID) {
            //If last vehicle batch pointid is set, then we can lock all cars that were previously unlocked
            foreach(new pointid : PointsWithVehicles) {
                if(pointid < T_RaceData[score][T_VLast]) { //We should only process lower pointid since higher numbers should be locked
                    foreach(new vehicleid : PointVehicles[pointid]) {
                        UnlockedVehicles[vehicleid][playerid] = false;
                        SetVehicleParamsForPlayer(vehicleid, playerid, false, true);
                    }
                }
            }
            //Unlock vehicles at the last batch
            foreach(new vehicleid : PointVehicles[T_RaceData[score][T_VLast]]) {
                UnlockedVehicles[vehicleid][playerid] = true;
                SetVehicleParamsForPlayer(vehicleid, playerid, false, false);
            }
        }
    } else {
        if(vehiclespawnid != INVALID_SPAWN_ID) {
            //Get the pointid of the target vehicle
            if(TournamentVehicleSpawns[vehiclespawnid][T_VPID] != INVALID_POINT_ID) {
                if(score == T_RealTPointsCount) score--; //Special case for finished players, lets just assume the last pointid to unlock last batch vehicles
                if(TournamentVehicleSpawns[vehiclespawnid][T_VPID] == T_RaceData[score][T_VLast]) {
                    //If target vehicle last batch matches with the score, the unlock it
                    UnlockedVehicles[targetvehicleid][playerid] = true;
                    SetVehicleParamsForPlayer(targetvehicleid, playerid, false, false);
                } else {
                    //Vehicle is outside player's last vehicle batch, lock it
                    UnlockedVehicles[targetvehicleid][playerid] = false;
                    SetVehicleParamsForPlayer(targetvehicleid, playerid, false, true);
                }
            }
        }
    }
    return true;
}

stock ResetPlayerTournament(playerid) {
    Logger_Dbg("tournament", "ResetPlayerTournament", Logger_I("playerid", playerid));
    if(IsPlayerConnected(playerid)) { //Not sure if needed
        DisablePlayerRaceCheckpoint(playerid);
        DisablePlayerCheckpoint(playerid);
        foreach (new pickupid : CreatedPickups[playerid]) {
            DestroyPlayerPickup(playerid, pickupid);
        }
        if(DeathTimer[playerid] != INVALID_TIMER) {
            KillTimer(DeathTimer[playerid]);
            DeathTimer[playerid] = INVALID_TIMER;
        }

        if(SummonTimer[playerid] != INVALID_TIMER) {
            KillTimer(SummonTimer[playerid]);
            SummonTimer[playerid] = INVALID_TIMER;
        }
        if(UnfreezeTimer[playerid] != INVALID_TIMER) {
            KillTimer(UnfreezeTimer[playerid]);
            UnfreezeTimer[playerid] = INVALID_TIMER;
        }

        SetPlayerDrunkLevel(playerid, 0);
        SetPlayerWeather(playerid, TOURNAMENT_WEATHER);
        StopPlayerBombField(playerid);
        ClearAnimations(playerid);
    }
    return true;
}

stock CleanupPlayerData(playerid) {
    Logger_Dbg("tournament", "CleanupPlayerData", Logger_I("playerid", playerid));
    //Some functions are still not added here, rather they are added to specific calls
    for(new i = 0; i<MAX_PICKUPS; i++) {
        PickupidToPointid[playerid][i] = INVALID_POINT_ID;
    }
    
    for(new i = 0; i<MAX_TPOINTS; i++) {
        PointidToPickupid[playerid][i] = INVALID_POINT_ID;
        PickupHistory[playerid][i] = false;
    }
    Iter_Clear(SpectatedBy[playerid]);
    Iter_Clear(CreatedPickups[playerid]);
    Iter_Clear(DirectionalPickups[playerid]);
    if(IsCreatedVehicleValid(PlayerVehicleID[playerid])) {
        DestroyVehicle(PlayerVehicleID[playerid]);
        Iter_Remove(CreatedVehicles, PlayerVehicleID[playerid]);
        VehicleIDToPlayerid[PlayerVehicleID[playerid]] = INVALID_PLAYER_ID;
        PlayerVehicleID[playerid] = INVALID_VEHICLE_ID;
    }
    SpectatingPlayer[playerid] = INVALID_PLAYER_ID;
}

stock TDB_SavePickupHistory(playerid, pointid) {
    Logger_Dbg("tournament", "TDB_SavePickupHistory", Logger_I("playerid", playerid), Logger_I("pointid", pointid));
    //Updates database that player has picked up a pickup
    new playername[MAX_PLAYER_NAME];
    new DBResult:db_result;
    new query[MAX_QUERY];
    GetPlayerName(playerid, playername, MAX_PLAYER_NAME);
    format(query, MAX_QUERY, "INSERT INTO `pickuphistory` (`PlayerName`,`PointID`) VALUES ('%s', %d)", playername, pointid);
    db_result = DB_ExecuteQuery(TournamentDB, query);
    if(db_result == DBResult:0) {
        Logger_Err("Failed to insert pickup history for player", Logger_S("playername", playername));
        return false;
    }
    
    DB_FreeResultSet(db_result);
    return true;
}

stock TDB_SavePlayerScore(playerid, playerscore) {
    Logger_Dbg("tournament", "TDB_SavePlayerScore", Logger_I("playerid", playerid), Logger_I("playerscore", playerscore));
    //Updates player score in DB in general
    new playername[MAX_PLAYER_NAME];
    new DBResult:db_result;
    new query[MAX_QUERY];
    GetPlayerName(playerid, playername, MAX_PLAYER_NAME);
    format(query, MAX_QUERY, "UPDATE `score` SET `PlayerScore`='%d' WHERE PlayerName='%s'", playerscore, playername);
    db_result = DB_ExecuteQuery(TournamentDB, query);
    if(db_result == DBResult:0) {
        Logger_Err("Failed to update score for player", Logger_S("playername", playername));
        return false;
    }
    
    DB_FreeResultSet(db_result);
    return true;
}

stock TDB_SavePlayerSpeed(playerid, Float:SpeedX, Float:SpeedY, Float:SpeedZ, Float:SpeedR) {
    Logger_Dbg("tournament", "TDB_SavePlayerSpeed", Logger_I("playerid", playerid),
    Logger_F("SpeedX", SpeedX), Logger_F("SpeedY", SpeedY), Logger_F("SpeedZ", SpeedZ), Logger_F("SpeedR", SpeedR));
    //Saves the last vehicle speed for player to re-create MTA race experience
    new playername[MAX_PLAYER_NAME];
    new DBResult:db_result;
    new query[MAX_QUERY];
    GetPlayerName(playerid, playername, MAX_PLAYER_NAME);
    format(query, MAX_QUERY, "UPDATE `speed` SET `SpeedX`='%f', `SpeedY`='%f', `SpeedZ`='%f', `SpeedR`='%f' WHERE PlayerName='%s'", SpeedX, SpeedY, SpeedZ, SpeedR, playername);
    db_result = DB_ExecuteQuery(TournamentDB, query);
    if(db_result == DBResult:0) {
        Logger_Err("Failed to update speed for player", Logger_S("playername", playername));
        return false;
    }
    
    DB_FreeResultSet(db_result);
    return true;
}

stock TDB_SavePlayerVehicle(playerid, model, colour1, colour2) {
    Logger_Dbg("tournament", "TDB_SavePlayerVehicle", Logger_I("playerid", playerid), Logger_I("model", model), Logger_I("colour1", colour1), Logger_I("colour2", colour2));
    //Saves the vehicle player has found
    new playername[MAX_PLAYER_NAME];
    new DBResult:db_result;
    new query[MAX_QUERY];
    GetPlayerName(playerid, playername, MAX_PLAYER_NAME);
    format(query, MAX_QUERY, "UPDATE `vehicles` SET `model`='%d', `colour1`='%d', `colour2`='%d' WHERE PlayerName='%s'", model, colour1, colour2, playername);
    db_result = DB_ExecuteQuery(TournamentDB, query);
    if(db_result == DBResult:0) {
        Logger_Err("Failed to update vehicle for player", Logger_S("playername", playername));
        return false;
    }
    
    DB_FreeResultSet(db_result);
    return true;
}

stock TDB_ResetPickupHistory() {
    Logger_Dbg("tournament", "TDB_ResetPickupHistory");
    //For /restart
    new DBResult:db_result;
    new query[MAX_QUERY];
    format(query, MAX_QUERY, "DELETE FROM `pickuphistory`");
    db_result = DB_ExecuteQuery(TournamentDB, query);
    if(db_result == DBResult:0) {
        Logger_Err("Failed to reset pickup history");
        return false;
    }
    
    DB_FreeResultSet(db_result);
    return true;
}

stock TDB_ResetScoreHistory() {
    Logger_Dbg("tournament", "TDB_ResetScoreHistory");
    //For /restart
    new DBResult:db_result;
    new query[MAX_QUERY];
    format(query, MAX_QUERY, "UPDATE `score` SET `PlayerScore`='0'");
    db_result = DB_ExecuteQuery(TournamentDB, query);
    if(db_result == DBResult:0) {
        Logger_Err("Failed to reset score history for players");
        return false;
    }
    DB_FreeResultSet(db_result);
    return true;
}

stock TDB_ResetSpeedHistory() {
    Logger_Dbg("tournament", "TDB_ResetSpeedHistory");
    //For /restart
    new DBResult:db_result;
    new query[MAX_QUERY];
    format(query, MAX_QUERY, "UPDATE `speed` SET `SpeedX`='0', `SpeedY`='0', `SpeedZ`='0', `SpeedR`='0'");
    db_result = DB_ExecuteQuery(TournamentDB, query);
    if(db_result == DBResult:0) {
        Logger_Err("Failed to reset speed history for players");
        return false;
    }
    DB_FreeResultSet(db_result);
    return true;
}

stock TDB_ResetVehicleHistory() {
    Logger_Dbg("tournament", "TDB_ResetVehicleHistory");
    //For /restart
    new DBResult:db_result;
    new query[MAX_QUERY];
    format(query, MAX_QUERY, "UPDATE `vehicles` SET `model`='%d'", INVALID_VEHICLE_MODEL);
    db_result = DB_ExecuteQuery(TournamentDB, query);
    if(db_result == DBResult:0) {
        Logger_Err("Failed to reset speed history for players");
        return false;
    }
    DB_FreeResultSet(db_result);
    return true;
}


stock TDB_ResetFinishHistory() {
    Logger_Dbg("tournament", "TDB_ResetFinishHistory");
    //For /restart
    new DBResult:db_result;
    new query[MAX_QUERY];
    format(query, MAX_QUERY, "DELETE FROM `finish`");
    db_result = DB_ExecuteQuery(TournamentDB, query);
    if(db_result == DBResult:0) {
        Logger_Err("Failed to reset finish history for players");
        return false;
    }
    
    DB_FreeResultSet(db_result);
    return true;
}

stock TDB_SaveFinishTime(playerid, finishtime) {
    Logger_Dbg("tournament", "TDB_SaveFinishTime", Logger_I("playerid", playerid), Logger_I("finishtime", finishtime));
    //For /results
    new playername[MAX_PLAYER_NAME];
    new DBResult:db_result;
    new query[MAX_QUERY];
    GetPlayerName(playerid, playername, MAX_PLAYER_NAME);
    format(query, MAX_QUERY, "SELECT `PlayerTime` FROM `finish` WHERE `PlayerName`='%s'", playername);
	db_result = DB_ExecuteQuery(TournamentDB, query);
	if(!DB_GetRowCount(db_result)) {
        format(query, MAX_QUERY, "INSERT INTO `finish` (`PlayerName`,`PlayerPos`,`PlayerTime`) VALUES ('%s', %d, %d)", playername, FinishedPos[playerid], finishtime);
        db_result = DB_ExecuteQuery(TournamentDB, query);
        if(db_result == DBResult:0) {
            Logger_Err("Failed to insert finish time for player", Logger_S("playername", playername));
            return false;
        }
        DB_FreeResultSet(db_result);
    } else {
        DB_FreeResultSet(db_result);
        Logger_Err("Failed to insert finish time for player, it already exists", Logger_S("playername", playername));
        return false;
    }
    return true;
}

stock TDB_GetPlayerPickupHistory(playerid, playername[]) {
    Logger_Dbg("tournament", "TDB_GetPlayerPickupHistory", Logger_I("playerid", playerid), Logger_S("playername", playername));
    //Load player progress
    new query[MAX_QUERY];
    new DBResult:db_result;
    new pointid = INVALID_POINT_ID;
	format(query, MAX_QUERY, "SELECT `PointID` FROM `pickuphistory` WHERE `PlayerName`='%s'", playername);
	db_result = DB_ExecuteQuery(TournamentDB, query);
	if(DB_GetRowCount(db_result)) {
		do {
            pointid = DB_GetFieldInt(db_result, 0);
            if(pointid >= 0 && pointid < MAX_TPOINTS) {
                PickupHistory[playerid][pointid] = true;
            } else {
                Logger_Err("Player loaded invalid point id from database", Logger_S("playername", playername), Logger_I("pointid", pointid));
            }
        } while(DB_SelectNextRow(db_result));

        DB_FreeResultSet(db_result);
	} else {
        return false;
    }
    return true;
}

stock TDB_GetPlayerScore(playername[]) {
    Logger_Dbg("tournament", "TDB_GetPlayerScore", Logger_S("playername", playername));
    //Load player progress
    new query[MAX_QUERY];
    new DBResult:db_result;
    new playerscore = 0;
	format(query, MAX_QUERY, "SELECT `PlayerScore` FROM `score` WHERE `PlayerName`='%s'", playername);
	db_result = DB_ExecuteQuery(TournamentDB, query);
	if(DB_GetRowCount(db_result)) {
		playerscore = DB_GetFieldInt(db_result, 0);
        if(playerscore > T_RealTPointsCount) playerscore = 0; //Reset the score if it is higher than tournament point count, fixes bunch of weird situations
        DB_FreeResultSet(db_result);
	} else {
        DB_FreeResultSet(db_result);
        format(query, MAX_QUERY, "INSERT INTO `score` (`PlayerName`,`PlayerScore`) VALUES ('%s', 0)", playername);
        new DBResult:db_result_insert;
        db_result_insert = DB_ExecuteQuery(TournamentDB, query);
        if(db_result_insert == DBResult:0) {
            Logger_Err("Failed to insert score for player", Logger_S("playername", playername));
            return 0;
        }
        DB_FreeResultSet(db_result_insert);
    }
    return playerscore;
}

stock TDB_GetPlayerFinishPos(playername[]) {
    Logger_Dbg("tournament", "TDB_GetPlayerFinishPos", Logger_S("playername", playername));
    //Load player progress. prevents finishing twice
    new query[MAX_QUERY];
    new DBResult:db_result;
    new playerpos = 0;
	format(query, MAX_QUERY, "SELECT `PlayerPos` FROM `finish` WHERE `PlayerName`='%s'", playername);
	db_result = DB_ExecuteQuery(TournamentDB, query);
	if(DB_GetRowCount(db_result)) {
		playerpos = DB_GetFieldInt(db_result, 0);
        DB_FreeResultSet(db_result);
	}
    return playerpos;
}

stock TDB_GetFinishedCount() {
    Logger_Dbg("tournament", "TDB_GetFinishedCount");
    //Load player progress
    new DBResult:db_result;
    new finishedcount = 0;
	db_result = DB_ExecuteQuery(TournamentDB, "SELECT `PlayerPos` FROM `finish`");
	finishedcount = DB_GetRowCount(db_result);
    DB_FreeResultSet(db_result);
    return finishedcount;
}

stock TDB_GetPlayerVehicle(playername[], &model, &colour1, &colour2) {
    Logger_Dbg("tournament", "TDB_GetPlayerVehicle", Logger_S("playername", playername));
    //Load player progress
    new query[MAX_QUERY];
    new DBResult:db_result;
	format(query, MAX_QUERY, "SELECT `model`,`colour1`,`colour2` FROM `vehicles` WHERE `PlayerName`='%s'", playername);
	db_result = DB_ExecuteQuery(TournamentDB, query);
	if(DB_GetRowCount(db_result)) {
		model = DB_GetFieldInt(db_result, 0);
        colour1 = DB_GetFieldInt(db_result, 1);
        colour2 = DB_GetFieldInt(db_result, 2);
        DB_FreeResultSet(db_result);
	} else {
        DB_FreeResultSet(db_result);
        model = INVALID_VEHICLE_MODEL;
        colour1 = -1;
        colour2 = -1;
        format(query, MAX_QUERY, "INSERT INTO `vehicles` (`PlayerName`,`model`,`colour1`,`colour2`) VALUES ('%s', '%d', '%d', '%d')", playername, model, colour1, colour2);
        new DBResult:db_result_insert;
        db_result_insert = DB_ExecuteQuery(TournamentDB, query);
        if(db_result_insert == DBResult:0) {
            Logger_Err("Failed to insert vehicle for player", Logger_S("playername", playername));
            return 0;
        }
        DB_FreeResultSet(db_result_insert);
    }
    return true;
}

stock TDB_GetPlayerSpeed(playername[], &Float:SpeedX, &Float:SpeedY, &Float:SpeedZ, &Float:SpeedR) {
    Logger_Dbg("tournament", "TDB_GetPlayerSpeed", Logger_S("playername", playername));
    //Load player progress
    new query[MAX_QUERY];
    new DBResult:db_result;
	format(query, MAX_QUERY, "SELECT `SpeedX`,`SpeedY`,`SpeedZ`, `SpeedR` FROM `speed` WHERE `PlayerName`='%s'", playername);
	db_result = DB_ExecuteQuery(TournamentDB, query);
	if(DB_GetRowCount(db_result)) {
		SpeedX = DB_GetFieldFloat(db_result, 0);
        SpeedY = DB_GetFieldFloat(db_result, 1);
        SpeedZ = DB_GetFieldFloat(db_result, 2);
        SpeedR = DB_GetFieldFloat(db_result, 3);
        DB_FreeResultSet(db_result);
	} else {
        DB_FreeResultSet(db_result);
        SpeedX = 0.0;
        SpeedY = 0.0;
        SpeedZ = 0.0;
        SpeedR = 0.0;
        format(query, MAX_QUERY, "INSERT INTO `speed` (`PlayerName`,`SpeedX`,`SpeedY`,`SpeedZ`,`SpeedR`) VALUES ('%s', '%f', '%f', '%f', '%f')", playername, SpeedX, SpeedY, SpeedZ, SpeedR);
        new DBResult:db_result_insert;
        db_result_insert = DB_ExecuteQuery(TournamentDB, query);
        if(db_result_insert == DBResult:0) {
            Logger_Err("Failed to insert speed for player", Logger_S("playername", playername));
            return 0;
        }
        DB_FreeResultSet(db_result_insert);
    }
    return true;
}

stock TDB_GetFinishResults(playerid) {
    Logger_Dbg("tournament", "TDB_GetFinishResults", Logger_I("playerid", playerid));
    //For /results
    new DBResult:db_result;
    new tmpstr[MAX_TMPSTR];
	db_result = DB_ExecuteQuery(TournamentDB, "SELECT `PlayerName`,`PlayerPos`,`PlayerTime` FROM `finish` ORDER BY PlayerPos ASC");
	if(DB_GetRowCount(db_result)) {
		do {
            DB_GetFieldString(db_result, 0, tmpstr);
            SendClientMessage(playerid, -1, "> {FFFF00}#%d{FFFFFF}: %s (%s)", DB_GetFieldInt(db_result, 1), tmpstr, TimeConvert(DB_GetFieldInt(db_result, 2)));
        } while(DB_SelectNextRow(db_result));

        DB_FreeResultSet(db_result);
	} else {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: No finished players yet!");
        return false;
    }
    return true;
}

stock CreateMineField(Float:MinX, Float:MinY, Float:MinZ, Float:MaxX, Float:MaxY, Float:MaxZ) {
    Logger_Dbg("tournament", "CreateMineField", Logger_F("MinX", MinX), Logger_F("MinY", MinY), Logger_F("MinZ", MinZ), Logger_F("MaxX", MaxX), Logger_F("MaxY", MaxY), Logger_F("MaxZ", MaxZ));
    //Over the years I have had dumb crazy ideas, not sure if this is crazy dumb idea
    for(new Float:i = MinX; i<MaxX+2; i+=2.5) {
        for(new Float:j = MinY; j<MaxY+2; j+=2.5) {
            new random_slot = random(4);
            if(random_slot == 3) { //25% chance that a mine is spawned
                new Float:FoundX, Float:FoundY, Float:FoundZ;
                CA_RayCastLine(i, j, MaxZ, i, j, MinZ, FoundX, FoundY, FoundZ);
                //Little bit into the ground so players can't push the mines
                CreateDynamicObject(1225, i, j, FoundZ+0.15, 0, 0, 0, -1, -1, -1, 15.0);
            }
        }
    }
    return true;
}

stock StartPlayerBombField(playerid) {
    if(!IsPlayerInDynamicArea(playerid, BombField)) {
        //In case player is not inside a the area, stop it
        StopPlayerBombField(playerid);
        return false;
    }
    Logger_Dbg("tournament", "StartPlayerBombField", Logger_I("playerid", playerid));
    if(BombingTimers[playerid][0] != INVALID_TIMER) {
        KillTimer(BombingTimers[playerid][0]);
    }
    BombingTimers[playerid][0] = SetTimerEx("DropPlayerBomb", 1000, true, "i", playerid);
    if(BombingTimers[playerid][1] != INVALID_TIMER) {
        KillTimer(BombingTimers[playerid][1]);
    }
    BombingTimers[playerid][1] = SetTimerEx("DropPlayerBomb", 1500, true, "i", playerid);
    return true;
}

stock StopPlayerBombField(playerid) {
    Logger_Dbg("tournament", "StopPlayerBombField", Logger_I("playerid", playerid));
    if(BombingTimers[playerid][0] != INVALID_TIMER) {
        KillTimer(BombingTimers[playerid][0]);
        BombingTimers[playerid][0] = INVALID_TIMER;
    }
    if(BombingTimers[playerid][1] != INVALID_TIMER) {
        KillTimer(BombingTimers[playerid][1]);
        BombingTimers[playerid][1] = INVALID_TIMER;
    }
}

stock Float:GetVehicleDrivingAngle(vehicleid, Float:SpeedX, Float:SpeedY, &Float:vehiclespeed) {
    //Prevent player from drifting around and avoiding bombs
    new Float:TempA;
    vehiclespeed = 10*floatsqroot(SpeedX*SpeedX+SpeedY*SpeedY);
    new Float:SpeedDirection = 0;
    GetVehicleZAngle(vehicleid, TempA);
    if(vehiclespeed > 0) {
        if (SpeedX < 0) {
            if(SpeedY > 0) { 
                SpeedDirection = atan(floatabs(SpeedX)/SpeedY);
            } else if (SpeedY <= 0) { 
                SpeedDirection = atan(SpeedY/SpeedX) + 90;
            }
        } else if (SpeedX > 0) {
            if(SpeedY < 0) { 
                SpeedDirection = atan(SpeedX/floatabs(SpeedY)) + 180;
            } else if (SpeedY >= 0) {
                SpeedDirection = atan(SpeedY/SpeedX) + 270;
            }
        } else if (SpeedX == 0) {
            if (SpeedY > 0) { 
                SpeedDirection = 0;
            } else if (SpeedY < 0) {
                SpeedDirection = 180;
            }
        }
        new Float:DriftFriction = 1;
        if(floatabs(SpeedDirection-TempA) < 160) { //Player is drifting, not driving backwards
            DriftFriction = 1+4*floatabs(SpeedDirection-TempA)/180; //Some tuning can be made here, 4 works fine
        }
        vehiclespeed = vehiclespeed/DriftFriction; //If a player is drifting, they will lose speed much faster, predicts the future speed a bit better
    } else {
        SpeedDirection = 0;
    }
	return SpeedDirection;
}

//----------------------------------------------------------------------------------------------------------

@cmd() kill(playerid, params[], help) {
    if(help) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /kill | Commits suicide when standing still on your foot.");

    new PLAYER_STATE:playerstate = GetPlayerState(playerid);
    if(playerstate == PLAYER_STATE_WASTED) {
        //In some rare cases a player can be stuck in a weird state, just spawn the player again
        if(PlayerScreenTD[playerid][TD_Timer] != INVALID_TIMER) {
            KillTimer(PlayerScreenTD[playerid][TD_Timer]);
            PlayerScreenTD[playerid][TD_Timer] = INVALID_TIMER;
        }
        PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x00000000);
        PlayerTextDrawHide(playerid, PlayerScreenTD[playerid][TD_ID]);
        PlayerTextDrawShow(playerid, PlayerScreenTD[playerid][TD_ID]);
        SpawnPlayer(playerid);
        return true;
    }

    if(!IsPlayerSpawn[playerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be spawned!");
        return true;
    }

    //Only on foot so the animations work properly
    if(playerstate != PLAYER_STATE_ONFOOT) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You must be on foot!");
        return true;
    }

    //Another option could be to reset the time, but this makes more sense
    if(DeathTimer[playerid] != INVALID_TIMER) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are already killing yourself, please wait!");
        return true;
    }
    
    if(UnfreezeTimer[playerid] != INVALID_TIMER) {
        //If player wrote /kill right on spawn, then the player would be able to move, unless if we kill the timer
        KillTimer(UnfreezeTimer[playerid]);
        UnfreezeTimer[playerid] = INVALID_TIMER;
    }

    new animindex = GetPlayerAnimationIndex(playerid);
    if(animindex) {
        new animationLibrary[32], animationName[32];
        GetAnimationName(animindex, animationLibrary, 32, animationName, 32);
        if(strcmp(animationLibrary, "PED") != 0) {
            SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to stand still!");
            return true;
        }

        if(strcmp(animationName, "FALL_LAND", true) != 0 && strcmp(animationName, "IDLE_armed", true) != 0 &&
        strcmp(animationName, "IDLE_chat", true) != 0 && strcmp(animationName, "IDLE_csaw", true) != 0 &&
        strcmp(animationName, "Idle_Gang1", true) != 0 && strcmp(animationName, "IDLE_HBHB", true) != 0 &&
        strcmp(animationName, "IDLE_ROCKET", true) != 0 && strcmp(animationName, "IDLE_stance", true) != 0 &&
        strcmp(animationName, "IDLE_taxi", true) != 0 && strcmp(animationName, "IDLE_tired", true) != 0 &&
        strcmp(animationName, "Jetpack_Idle", true) != 0 && strcmp(animationName, "Idlestance_fat", true) != 0 &&
        strcmp(animationName, "idlestance_old", true) != 0 && strcmp(animationName, "woman_idlestance", true) != 0) { 
            //Detects if not falling or swimming, without this the death animations are not working
            SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to stand still!");
            return true;
        }
    } //else: no animation is applied, this usually happens when no movements have been made, but consider as standing still

    //Set camera in front of the player and watch how the character drinks a molotov
    new Float:Tempx, Float:Tempy, Float:Tempz, Float:Tempa;
    GetPlayerPos(playerid, Tempx, Tempy, Tempz);
    GetPlayerFacingAngle(playerid, Tempa);
    SetPlayerCameraPos(playerid, Tempx + 3*floatcos(90+Tempa, degrees), Tempy+ 3*floatsin(90-Tempa, degrees), Tempz+1.5);
    SetPlayerCameraLookAt(playerid, Tempx, Tempy, Tempz);
    TogglePlayerControllable(playerid, false);
    GivePlayerWeapon(playerid, WEAPON_MOLTOV, 1);
    SetPlayerArmedWeapon(playerid, WEAPON_MOLTOV);
    DeathTimer[playerid] = SetTimerEx("KillStage", 4000, false, "ii", playerid, 0);
    ApplyAnimation(playerid, "BAR", "dnk_stndM_loop", 4.1, false, true, true, true, 1, SYNC_NONE);
    return true;
}

@cmd() results(playerid, params[], help) {
    if(help) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /results | Prints out finished player results.");

    if(!TournamentStarted) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Tournament has not been started yet!");
        return true;
    }

    TDB_GetFinishResults(playerid);
    return true;
}

@cmd() poi(playerid, params[], help) {
    if(help) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /poi | Set a waypoint to a POI.");

    if(!TournamentStarted) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Tournament has not been started yet!");
        return true;
    }

    if(!IsPlayerSpawn[playerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be spawned!");
        return true;
    }

    if(POIcounter[playerid] == T_RealTPOICount) POIcounter[playerid] = 0; //Reset current POI if max is reached

    SetPlayerMapIcon(playerid, POIICON_ID, POIs[POIcounter[playerid]][0], POIs[POIcounter[playerid]][1], POIs[POIcounter[playerid]][2], 41, 0, MAPICON_GLOBAL);
    POIcounter[playerid]++;
    return true;
}

@cmd() get(playerid, params[], help) {
    if(!IsPlayerAdmin(playerid)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are not allowed to use this command!");
        return true;
    }

    new targetplayerid = INVALID_PLAYER_ID;
    if(help || sscanf(params, "u", targetplayerid)) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /get [playerid] | Teleport a player to you.");

    if(!IsPlayerSpawn[playerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be spawned!");
        return true;
    }

    if(targetplayerid == INVALID_PLAYER_ID) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Invalid palyer!");
        return true;
    }

    if(!IsPlayerSpawn[targetplayerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Player has not spawned!");
        return true;
    }

    new Float:Tempx1;
    new Float:Tempy1;
    new Float:Tempz1;
    new Float:Tempa1;
    new vehicleid = INVALID_VEHICLE_ID;
    if(IsPlayerInAnyVehicle(playerid)) {
        vehicleid = GetPlayerVehicleID(playerid);
        if(!IsCreatedVehicleValid(vehicleid)) {
            SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Invalid vehicle, try again later!");
            return true;
        }
        GetVehiclePos(vehicleid, Tempx1, Tempy1, Tempz1);
        GetVehicleZAngle(vehicleid, Tempa1);
    } else {
        GetPlayerPos(playerid, Tempx1, Tempy1, Tempz1);
        GetPlayerFacingAngle(playerid, Tempa1);
    }

    new interior = GetPlayerInterior(playerid);
    if(GetPlayerState(targetplayerid) == PLAYER_STATE_DRIVER) {
        vehicleid = GetPlayerVehicleID(targetplayerid);
        if(!IsCreatedVehicleValid(vehicleid)) {
            SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Invalid vehicle, try again later!");
            return true;
        }
        SetVehiclePos(vehicleid, Tempx1, Tempy1, Tempz1+2);
        SetVehicleZAngle(vehicleid, Tempa1);
        LinkVehicleToInterior(targetplayerid, interior);
    } else {
        Streamer_UpdateEx(targetplayerid, Tempx1, Tempy1, Tempz1+2);
        SetPlayerPos(targetplayerid, Tempx1, Tempy1, Tempz1+2);
        SetPlayerFacingAngle(targetplayerid, Tempa1);
    }
    SetPlayerInterior(targetplayerid, interior);
    SendClientMessage(playerid, -1, "{00FF00}SUCCESS{FFFFFF}: Teleported player to you!");
    return true;
}

@cmd() gravity(playerid, params[], help) {
    if(!IsPlayerAdmin(playerid)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are not allowed to use this command!");
        return true;
    }

    new targetplayerid = INVALID_PLAYER_ID;
    new Float:gravity = 0.008;
    if(help || sscanf(params, "uf", targetplayerid, gravity)) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /gravity [playerid] [amount] | Sets player gravity.");

    if(!IsPlayerSpawn[playerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be spawned!");
        return true;
    }

    if(targetplayerid == INVALID_PLAYER_ID) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Invalid palyer!");
        return true;
    }

    if(!IsPlayerSpawn[targetplayerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Player has not spawned!");
        return true;
    }

    SetPlayerGravity(targetplayerid, gravity);
    SendClientMessage(playerid, -1, "{00FF00}SUCCESS{FFFFFF}: Gravity is set!");
    return true;
}

@cmd() announce(playerid, params[], help) {
    if(!IsPlayerAdmin(playerid)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are not allowed to use this command!");
        return true;
    }

    new tempstr[MAX_TMPSTR];
    if(help || sscanf(params, "s[128]", tempstr)) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /announce [text] | Announce a text to all players.");

	foreach(new i : Player) {
        SendClientMessage(i, 0xFFA500FF, tempstr);
    }
    return true;
}

@cmd() kick(playerid, params[], help) {
    if(!IsPlayerAdmin(playerid)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are not allowed to use this command!");
        return true;
    }

    new targetplayerid = INVALID_PLAYER_ID;
    if(help || sscanf(params, "u", targetplayerid)) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /kick [playerid] | Kicks a player.");

    if(targetplayerid == INVALID_PLAYER_ID) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Invalid palyer!");
        return true;
    }

	Kick(targetplayerid);
    return true;
}

@cmd() ban(playerid, params[], help) {
    if(!IsPlayerAdmin(playerid)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are not allowed to use this command!");
        return true;
    }

    new targetplayerid = INVALID_PLAYER_ID;
    if(help || sscanf(params, "u", targetplayerid)) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /ban [playerid] | Bans a player.");

    if(targetplayerid == INVALID_PLAYER_ID) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Invalid palyer!");
        return true;
    }

	Ban(targetplayerid);
    return true;
}

@cmd() goto(playerid, params[], help) {
    if(!IsPlayerAdmin(playerid)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are not allowed to use this command!");
        return true;
    }

    new targetplayerid = INVALID_PLAYER_ID;
    if(help || sscanf(params, "u", targetplayerid)) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /goto [playerid] | Teleport to a player.");

    if(!IsPlayerSpawn[playerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be spawned!");
        return true;
    }

    if(targetplayerid == INVALID_PLAYER_ID) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Invalid palyer!");
        return true;
    }

    if(!IsPlayerSpawn[targetplayerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Player has not spawned!");
        return true;
    }

    new Float:Tempx1;
    new Float:Tempy1;
    new Float:Tempz1;
    new Float:Tempa1;
    new vehicleid = INVALID_VEHICLE_ID;
    new interior = GetPlayerInterior(targetplayerid); //Teleport the vehicle inside an interior, whats the worst that can happen

    if(IsPlayerInAnyVehicle(targetplayerid)) {
        vehicleid = GetPlayerVehicleID(targetplayerid);
        if(!IsCreatedVehicleValid(vehicleid)) {
            SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Could not get player's vehicle id, try again!");
            return true;
        }
        GetVehiclePos(vehicleid, Tempx1, Tempy1, Tempz1);
        GetVehicleZAngle(vehicleid, Tempa1);
    } else {
        GetPlayerPos(targetplayerid, Tempx1, Tempy1, Tempz1);
        GetPlayerFacingAngle(targetplayerid, Tempa1);
    }

    if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER) {
        vehicleid = GetPlayerVehicleID(playerid);
        if(!IsCreatedVehicleValid(vehicleid)) {
            SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Could not get player's vehicle id, try again!");
            return true;
        }
        SetVehiclePos(vehicleid, Tempx1, Tempy1, Tempz1+2);
        SetVehicleZAngle(vehicleid, Tempa1);
        LinkVehicleToInterior(vehicleid, interior);
    } else {
        Streamer_UpdateEx(playerid, Tempx1, Tempy1, Tempz1+2);
        SetPlayerPos(playerid, Tempx1, Tempy1, Tempz1+2);
        SetPlayerFacingAngle(playerid, Tempa1);
    }
    SetPlayerInterior(playerid, interior);
    SendClientMessage(playerid, -1, "{00FF00}SUCCESS{FFFFFF}: Teleported to player!");
    return true;
}

@cmd() spec(playerid, params[], help) {
    new targetplayerid = INVALID_PLAYER_ID;
    new PLAYER_STATE:playerstate = GetPlayerState(playerid);
    if(help || (isnull(params) && playerstate != PLAYER_STATE_SPECTATING) ||
    (sscanf(params, "u", targetplayerid) && playerstate != PLAYER_STATE_SPECTATING)) 
        return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /spec [playerid] | Spectate a player.");

    if(isnull(params)) {
        if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING) {
            StopSpectating(playerid);
            return true;
	    }
    }

    if(targetplayerid == INVALID_PLAYER_ID) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Invalid palyer!");
        return true;
    }

    if(targetplayerid == playerid) {
        if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING) {
            StopSpectating(playerid);
        } else {
            SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are not spectating anyone!");
        }
        return true;
    }

    if(StartSpectating(playerid, targetplayerid)) {
        SendClientMessage(playerid, -1, "{00FF00}SUCCESS{FFFFFF}: Started spectating!");
    }
    return true;
}

@cmd() unlockall(playerid, params[], help) {
    if(!IsPlayerAdmin(playerid)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are not allowed to use this command!");
        return true;
    }

    if(help) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /unlockall | For debugging purposes, unlock all vehicles in gamemode for yourself.");

    if(!IsPlayerSpawn[playerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be spawned!");
        return true;
    }

    foreach(new i : CreatedVehicles) {
        UnlockedVehicles[i][playerid] = true;
        SetVehicleParamsForPlayer(i, playerid, false, false);
    }

    SendClientMessage(playerid, -1, "{00FF00}SUCCESS{FFFFFF}: Unlocked all vehicles!");
    return true;
}

@cmd() unlock(playerid, params[], help) {
    if(!IsPlayerAdmin(playerid)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are not allowed to use this command!");
        return true;
    }

    new targetplayerid = INVALID_PLAYER_ID;
    if(help || sscanf(params, "u", targetplayerid)) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /unlock [playerid] | Unlock your current vehicle for a player.");

    if(!IsPlayerSpawn[playerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be spawned!");
        return true;
    }

    if(targetplayerid == INVALID_PLAYER_ID) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Invalid palyer!");
        return true;
    }

    if(!IsPlayerSpawn[targetplayerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Player has not spawned!");
        return true;
    }

    if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be a driver in a vehicle!");
        return true;
    }

    new vehicleid = GetPlayerVehicleID(playerid);
    if(!IsCreatedVehicleValid(vehicleid)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Invalid vehicle!");
        return true;
    }

    UnlockedVehicles[vehicleid][targetplayerid] = true;
    SetVehicleParamsForPlayer(vehicleid, targetplayerid, false, false);
    SendClientMessage(playerid, -1, "{00FF00}SUCCESS{FFFFFF}: Unlocked vehicle for player!");
    return true;
}

//todo setscore 36, then drive to 37, take a car, but vehicle is unlocked???

@cmd() setscore(playerid, params[], help) {
    if(!IsPlayerAdmin(playerid)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are not allowed to use this command!");
        return true;
    }

    new playerscore = 0;
    if(help || sscanf(params, "d", playerscore)) SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /setscore [score] | For debugging purposes, set your score to a specific value.");

    if(!TournamentStarted) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Tournament has not been started yet!");
        return true;
    }   

    if(TournamentCountdown != 0) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Tournament has not been started yet!");
        return true;
    }   

    if(!IsPlayerSpawn[playerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be spawned!");
        return true;
    }

    if(playerscore < 0 || playerscore > T_RealTPointsCount) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Invalid score!");
        return true;
    }

    //Just reset all pickup history, otherwise we can have a situation where pickups are not created because they were picked up beforehand
    foreach (new pickupid : CreatedPickups[playerid]) {
        DestroyPlayerPickup(playerid, pickupid);
    }
    CleanupPlayerData(playerid);
    StopPlayerBombField(playerid);
    if(DirectionTimer[playerid] != INVALID_TIMER) {
        KillTimer(DirectionTimer[playerid]);
        DirectionTimer[playerid] = INVALID_TIMER;
    }
    HidePlayerProgressBar(playerid, PlayerTDSignal[playerid]);
    PlayerTextDrawHide(playerid, PlayerTDSignalText[playerid]);

    //This command will not do anything to pickup history, but setting a score and picking up one will trigger the callback
    if(playerscore < T_RealTPointsCount) { //Equal is for finish, but array is not that large, needs to be index-1
        if(T_RaceData[playerscore][T_Type] == CP_PICKUP) {
            //This will create the correct pickups in case player sets the score in middle of a pickup batch
            CreatePlayerPickupBatch(playerid, playerscore);
        }
    }
    FinishedPos[playerid] = 0;
    //This is needed to reset that the player has finished, this will allow the player to finish more than once, but that is expected for debugging reasons, /results will still show a single entry
    DisablePlayerCheckpoint(playerid);
    DisablePlayerRaceCheckpoint(playerid);
    SetPlayerWeather(playerid, TOURNAMENT_WEATHER);
    SetPlayerDrunkLevel(playerid, 0);
    SetPlayerColor(playerid, 0xFFFF00FF);
    SetPlayerScore(playerid, playerscore);
    TogglePlayerControllable(playerid, false);
    SetPlayerTournamentSpawn(playerid, playerscore, true);
    if(UnfreezeTimer[playerid] != INVALID_TIMER) {
        KillTimer(UnfreezeTimer[playerid]);
    }
    UnfreezeTimer[playerid] = SetTimerEx("UnfreezePlayer", 500, false, "i", playerid); //Sometimes prevents players from being spawned inside a floor
    UpdateTournamentPos(false);
    TDB_SavePlayerScore(playerid, playerscore);
    AdditionalTournamentCalls(playerid, playerscore, false);
    ProgressTournamentForPlayer(playerid, playerscore);
    ShowPlayerCurrentObjective(playerid, playerscore); //Not always called, just call it anyways
    TDB_SavePlayerSpeed(playerid, 0.0, 0.0, 0.0, 0.0);
    LastPlayerSpeed[playerid][0] = 0.0;
    LastPlayerSpeed[playerid][1] = 0.0;
    LastPlayerSpeed[playerid][2] = 0.0;
    LastPlayerSpeed[playerid][3] = 0.0;
    SendClientMessage(playerid, -1, "{00FF00}SUCCESS{FFFFFF}: Score has been set!");
    return true;
}

@cmd() info(playerid, params[], help) {
    if(!IsPlayerSpawn[playerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be spawned!");
        return true;
    }

    if(help) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /info | Print out basic information about the tournament.");

    new tmpstr[2048]; //For longer texts you might even need to increase this
    format(tmpstr, 2048, "{E60000}======================[ {FFFFFF}Goals{E60000} ]=====================\n");
    format(tmpstr, 2048, "%s{FFFFFF}Your objective is simple: Be the fastest one to reach the last point.\n", tmpstr);
    format(tmpstr, 2048, "%sDuring the tournament, you may find various vehicles.\n", tmpstr);
    format(tmpstr, 2048, "%sUse them to reach your next point faster,\n", tmpstr);
    format(tmpstr, 2048, "%sbut sometimes a certain vehicle is better for the job than the other, choose wisely.\n", tmpstr);
    format(tmpstr, 2048, "%sSome points will require creative ways to reach them,\n", tmpstr);
    format(tmpstr, 2048, "%suse your surroundings and vehicle!\n\n", tmpstr);
    format(tmpstr, 2048, "%s{E60000}======================[ {FFFFFF}Rules{E60000} ]=====================\n", tmpstr);
    format(tmpstr, 2048, "%s- {E60000}No cheats!{FFFFFF}\n", tmpstr);
    format(tmpstr, 2048, "%s- {E60000}No mods!{FFFFFF}\n", tmpstr);
    format(tmpstr, 2048, "%s- {00D200}If it is in the original game, then it is allowed!\n\n", tmpstr);
    format(tmpstr, 2048, "%s{E60000}======================[ {FFFFFF}Commands{E60000} ]=====================\n", tmpstr);
    format(tmpstr, 2048, "%s{00D200}/help{FFFFFF} - View command's help section.\n", tmpstr);
    format(tmpstr, 2048, "%s{00D200}/car, /veh, /bike, /plane, /boat{FFFFFF} - Summon your vehicle.\n", tmpstr);
    format(tmpstr, 2048, "%s{00D200}/kill{FFFFFF} - Make a suicide and respawn.\n");
    format(tmpstr, 2048, "%s{00D200}/results{FFFFFF} - View finishing times.\n", tmpstr);
    format(tmpstr, 2048, "%s{00D200}/spec{FFFFFF} - Spectate a player (after you have finished)\n", tmpstr);
    format(tmpstr, 2048, "%s{00D200}/poi{FFFFFF} - Set a waypoint to a POI.", tmpstr);

    if(IsPlayerAdmin(playerid)) {
        format(tmpstr, 2048, "%s\n\n{E60000}======================[ {FFFFFF}Admin{E60000} ]=====================\n", tmpstr);
        format(tmpstr, 2048, "%s{00D200}/start{FFFFFF} - Start the tournament while preserving player scores and positions.\n", tmpstr);
        format(tmpstr, 2048, "%s{00D200}/restart{FFFFFF} - Restart the tournament, teleports players to start and resets the score.\n", tmpstr);
        format(tmpstr, 2048, "%s{00D200}/goto{FFFFFF} - Teleport to a player.\n", tmpstr);
        format(tmpstr, 2048, "%s{00D200}/get{FFFFFF} - Teleport a player to you.\n", tmpstr);
        format(tmpstr, 2048, "%s{00D200}/unlockall{FFFFFF} - Unlocks all vehicles for you.\n", tmpstr);
        format(tmpstr, 2048, "%s{00D200}/unlock{FFFFFF} - Unlock your current vehicle for a player.\n", tmpstr);
        format(tmpstr, 2048, "%s{00D200}/setscore{FFFFFF} - Set your current score to a specific value.\n", tmpstr);
        format(tmpstr, 2048, "%s{00D200}/kick{FFFFFF} - Kicks a player.\n", tmpstr);
        format(tmpstr, 2048, "%s{00D200}/ban{FFFFFF} - Bans a player.\n", tmpstr);
        format(tmpstr, 2048, "%s{00D200}/spec{FFFFFF} - Spectate a player.\n", tmpstr);
        format(tmpstr, 2048, "%s{00D200}/respawnvehicles{FFFFFF} - Respawn batch of vehicles.", tmpstr);
    }
    ShowPlayerDialog(playerid, DIALOG_HELP, DIALOG_STYLE_MSGBOX, "Help", tmpstr, "Close", "");
    return true;
}

@cmd() help(playerid, params[], help) {
	if(help || IsNull(params)) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /help [command] | Display command's help section.");

    Command_ReProcess(playerid, params, true);
	return true;
}

@cmd() start(playerid, params[], help) {
    if(!IsPlayerAdmin(playerid)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are not allowed to use this command!");
        return true;
    }

    if(help) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /start | Start the tournament without resetting any data.");

    if(!IsPlayerSpawn[playerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be spawned!");
        return true;
    }

    if(TournamentStarted) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Tournament is already started!");
        return true;
    }

    TournamentCountdown = 10;
    TournamentStarted = true;
    FinishedPlayers = TDB_GetFinishedCount();
    UpdateTournamentPos(true);
    if(CountdownTimer != INVALID_TIMER) {
        KillTimer(CountdownTimer);
    }
    CountdownTimer = SetTimer("CountdownTournament", 1000, false);
    ResetTournamentVehicles();

    new playerscore = 0;
    foreach(new i : Player) {
        ResetPlayerTournament(i);
        CleanupPlayerData(i);
        if(IsPlayerSpawn[i]) {
            HidePlayerTextDraws(i, false);
            TogglePlayerSpectating(i, false); //I don't get paid enough to create a proper spectate during countdown, who even is paying me for any of this?
            playerscore = GetPlayerScore(i);
            SetPlayerTournamentSpawn(i, playerscore, false); //On start, we hope everyone is in their place and set world bounds
            PlayerPlaySound(i, 3200, 0.0, 0.0, 0.0);
	        GameTextForPlayer(i, "~r~GET READY", 4000, 3);
        }
    }
    return true;
}

@cmd() restart(playerid, params[], help) {
    if(!IsPlayerAdmin(playerid)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are not allowed to use this command!");
        return true;
    }

    if(help) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /restart | Start the tournament and reset all progress.");

    if(!IsPlayerSpawn[playerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be spawned!");
        return true;
    }

    TournamentCountdown = 10;
    TournamentStarted = true;
    FinishedPlayers = 0;
    if(CountdownTimer != INVALID_TIMER) {
        KillTimer(CountdownTimer);
    }
    CountdownTimer = SetTimer("CountdownTournament", 1000, false);
    TDB_ResetPickupHistory();
    TDB_ResetFinishHistory();
    TDB_ResetScoreHistory();
    TDB_ResetVehicleHistory();
    TDB_ResetSpeedHistory();
    ResetTournamentVehicles();
    
    foreach(new i : Player) {
        ResetPlayerTournament(i);
        SetPlayerScore(i, 0);
        TDB_SavePlayerScore(i, 0);
        TDB_SavePlayerVehicle(i, DEFAULT_VEHICLE_MODEL, -1, -1);
        TDB_SavePlayerSpeed(i, 0.0, 0.0, 0.0, 0.0);
        CleanupPlayerData(i);
        LastPlayerSpeed[i][0] = LastPlayerSpeed[i][1] = LastPlayerSpeed[i][2] = LastPlayerSpeed[i][3] = 0.0;
        PlayerVehicleID[i] = INVALID_VEHICLE_ID;
        PlayerVehicleModel[i] = DEFAULT_VEHICLE_MODEL;
        FinishedPos[i] = 0;
        if(IsPlayerSpawn[i]) {
            HidePlayerTextDraws(i, false);
            TogglePlayerControllable(i, true); //Needed because some players might join when tournament is not started and score has spawn in vehicle
            TogglePlayerSpectating(i, false); //I don't get paid enough to create a proper spectate during countdown, who even is paying me for any of this?
            SetPlayerTournamentSpawn(i, 0, true); //On restart, we teleport everyone to spawn
            PlayerPlaySound(i, 3200, 0.0, 0.0, 0.0);
	        GameTextForPlayer(i, "~r~GET READY", 4000, 3);
            
        }
    }
    UpdateTournamentPos(true);
    return true;
}

@cmd() respawnvehicles(playerid, params[], help) {
    //Command is useful when players are assholes and moves spawned vehicles around
    if(!IsPlayerAdmin(playerid)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You are not allowed to use this command!");
        return true;
    }

    new pointid = 0;
    if(help || sscanf(params, "d", pointid)) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /respawnvehicles [pointid] | Respawns all vehicles that are spawned on a point ID.");

    if(!TournamentStarted) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Tournament has not been started yet!");
        return true;
    }   

    if(pointid < 0 || pointid > T_RealTPointsCount) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Invalid point iD!");
        return true;
    }

    if(Iter_Count(PointVehicles[pointid]) == 0) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Point ID does not have any vehicles!");
        return true;
    }

    //Destroy the vehicles and use the respawn function used for picking up spawn cars
    foreach(new vehicleid : PointVehicles[pointid]) {
        DestroyVehicle(vehicleid);
        VehicleRespawnTimers[vehicleid] = SetTimerEx("RespawnTournamentVehicle", 1000, false, "ii", VehicleIDToSpawnID[vehicleid], vehicleid);
        Iter_Remove(PointVehicles[pointid], vehicleid);
        Iter_Remove(CreatedVehicles, vehicleid);
    }
    SendClientMessage(playerid, -1, "{00FF00}SUCCESS{FFFFFF}: Vehicles have been respawned!");
    return true;
}

@cmd() car(playerid, params[], help) {
    if(help) return SendClientMessage(playerid, -1, "{FFFF00}>HELP:{FFFFFF} /car | Summons your vehicle to you.");

    CheckSummoningVehicle(playerid, false);
    return true;
}

YCMD:veh(playerid, params[], help) = car;
YCMD:bike(playerid, params[], help) = car;
YCMD:plane(playerid, params[], help) = car;
YCMD:boat(playerid, params[], help) = car;

//----------------------------------------------------------------------------------------------------------

forward DropPlayerBomb(playerid);
public DropPlayerBomb(playerid) {
    Logger_Dbg("tournament", "DropPlayerBomb", Logger_I("playerid", playerid));
    if(!TournamentStarted) return false;
    if(TournamentCountdown != 0) return false;
    if(!IsPlayerSpawn[playerid]) return false;

    new Float:FoundX, Float:FoundY, Float:FoundZ;
    new Float:TempX, Float:TempY, Float:TempZ, Float:TempA;
    new vehicleid = INVALID_VEHICLE_ID;
    new Float:SpeedX, Float:SpeedY, Float:SpeedZ;
    new Float:playerspeed = 0;
    if(IsPlayerInAnyVehicle(playerid)) {
        vehicleid = GetPlayerVehicleID(playerid);
        if(IsCreatedVehicleValid(vehicleid)) {
            GetVehiclePos(vehicleid, TempX, TempY, TempZ);
            GetVehicleVelocity(vehicleid, SpeedX, SpeedY, SpeedZ);
            TempA = GetVehicleDrivingAngle(vehicleid, SpeedX, SpeedY, playerspeed);
        } //else do nothing, it is better to not drop a bomb than drop it at random location
    } else {
        GetPlayerPos(playerid, TempX, TempY, TempZ);
        GetPlayerFacingAngle(playerid, TempA);
        GetPlayerVelocity(playerid, SpeedX, SpeedY, SpeedZ);
        playerspeed = 10*floatsqroot(SpeedX*SpeedX + SpeedY*SpeedY);
    }

    new Float:bombdistance = 15*playerspeed;
    TempX += floatrand(-2, 2)+bombdistance*floatsin(-TempA, degrees);
    TempY += floatrand(-2, 2)+bombdistance*floatcos(-TempA, degrees);
    TempZ += 50;
    CA_RayCastLine(TempX, TempY, TempZ, TempX, TempY, 0, FoundX, FoundY, FoundZ);
    new STREAMER_TAG_OBJECT:objectid = CreateDynamicObject(2918, FoundX, FoundY, TempZ, 0, 0, 0, -1, -1, playerid, 100.0);
    if(objectid == INVALID_OBJECT_ID) return false;
    BombOjectToPlayerid[objectid] = playerid;
    MoveDynamicObject(objectid, FoundX, FoundY, FoundZ+1, 20.0);
    Streamer_Update(playerid);
    return true;
}

forward DestroyBomb(objectid, playerid);
public DestroyBomb(objectid, playerid) {
    Logger_Dbg("tournament", "DestroyBomb", Logger_I("objectid", objectid), Logger_I("playerid", playerid));
    BombOjectToPlayerid[objectid] = INVALID_PLAYER_ID;
    new Float:TempX, Float:TempY, Float:TempZ;
    GetDynamicObjectPos(objectid, TempX, TempY, TempZ);
    if(IsPlayerSpawn[playerid]) {
        CreateExplosionForPlayer(playerid, TempX, TempY, TempZ, 0, 2.0); //We could make it a global explosion, but if multiple players are in the same area, it becomes way too difficult to avoid bombs
    }
    DestroyDynamicObject(objectid);
}

forward UpdateTournamentPos(bool:duringstart);
public UpdateTournamentPos(bool:duringstart) {
    if(!TournamentStarted) return false;
    new PlayerScores[MAX_PLAYERS] = {-1, ...};
    new OriginalPlayerScores[MAX_PLAYERS];
    new totalplayers = 0;
    foreach(new i : Player) {
        new playerscore = GetPlayerScore(i);
        if(playerscore == T_RealTPointsCount) continue; //Skip finished players, we have a different variable for them
        PlayerScores[i] = playerscore;
        OriginalPlayerScores[i] = playerscore; //We use this to later get player score a bit faster and this even isn't the dumbest optimization in this code
        totalplayers++;
    }

    ArraySortReverse(PlayerScores, 0 , MAX_PLAYERS-1); //Always needs to be -1, for some reasons crash-detect does not even catch out of bounds

    //Index is not the playerid anymore, because sort, duh!
    new tmpstr[MAX_TMPSTR];
    foreach(new i : SpawnedPlayers) {
        new index = -1;
        new playerscore = OriginalPlayerScores[i];
        if(playerscore == T_RealTPointsCount) continue; //We skipped finished players before, now we must skip them too
        if(InArray(playerscore, PlayerScores, index, MAX_PLAYERS)) {
            new playerpos = index+1+FinishedPlayers;
            new totalwfinishedpayers = totalplayers+FinishedPlayers;
            
            if(InSortedArrayNextMatch(PlayerScores, playerscore, index, MAX_PLAYERS) && totalplayers > 1) {
                //If the next index also contains the same value, then the position is a split
                //When testing with a single player add a special check to remove split sign
                format(tmpstr, MAX_TMPSTR, "~b~~h~~h~~h~%d", playerpos);
            } else {
                format(tmpstr, MAX_TMPSTR, "%d", playerpos);
            }
            
            if(playerpos > 9) {
                PlayerTextDrawSetPos(i, PlayerTDPosNum[i], 541.0, 309.0);
                PlayerTextDrawSetPos(i, PlayerTDPosTxt[i], 558.0, 315.0);
                PlayerTextDrawSetPos(i, PlayerTDPosTotal[i], 558.0, 336.0);
            } else {
                //Single digit pos does not take too much space, but as a result wthe whole text draw is aligned too much to right, use different coordinates on screen
                PlayerTextDrawSetPos(i, PlayerTDPosNum[i], 538.0, 309.0);
                PlayerTextDrawSetPos(i, PlayerTDPosTxt[i], 554.0, 315.0);
                PlayerTextDrawSetPos(i, PlayerTDPosTotal[i], 553.0, 336.0);
            }
            if(!duringstart) {
                //For some reasons if we change the pos for textdraws, they are not updated
                //We only re-show them when the player is not at start to prevent a flicker or textdraws

                if((PreviousPos[i] <= 9 && playerpos > 9) || (PreviousPos[i] > 9 && playerpos <= 9)) {
                    //Trigger only textdraw re-show if textdraw pos has changed
                    PlayerTextDrawHide(i, PlayerTDPosNum[i]);
                    PlayerTextDrawHide(i, PlayerTDPosTxt[i]);
                    PlayerTextDrawHide(i, PlayerTDPosTotal[i]);
                    PlayerTextDrawShow(i, PlayerTDPosNum[i]);
                    PlayerTextDrawShow(i, PlayerTDPosTxt[i]);
                    PlayerTextDrawShow(i, PlayerTDPosTotal[i]);
                }
            }
            PlayerTextDrawSetString(i, PlayerTDPosNum[i], tmpstr);
            PlayerTextDrawSetString(i, PlayerTDPosTxt[i], NumberToPosition(playerpos));
            format(tmpstr, MAX_TMPSTR, "/%d", totalwfinishedpayers);
            PlayerTextDrawSetString(i, PlayerTDPosTotal[i], tmpstr);
            PreviousPos[i] = playerpos;
        } //else: I mean... how?
    }
    return true;
}

forward StopPlayerSound(playerid);
public StopPlayerSound(playerid) {
    Logger_Dbg("tournament", "StopPlayerSound", Logger_I("playerid", playerid));
    PlayerPlaySound(playerid, 0, 0.0, 0.0, 0.0);
    return true;
}

forward FadeScreen(playerid, counter, bool:fadein);
public FadeScreen(playerid, counter, bool:fadein) {
    Logger_Dbg("tournament", "FadeScreen", Logger_I("playerid", playerid), Logger_I("counter", counter), Logger_B("fadein", fadein));
    //Code stolen from https://sampforum.blast.hk/showthread.php?tid=389280, rewritten "a bit"
    switch(counter) {
        case 1:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x000000EE);
        case 2:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x000000DD);
        case 3:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x000000CC);
        case 4:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x000000BB);
        case 5:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x000000AA);
        case 6:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x00000099);
        case 7:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x00000088);
        case 8:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x00000077);
        case 9:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x00000066);
        case 10:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x00000055);
        case 11:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x00000044);
        case 12:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x00000033);
        case 13:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x00000022);
        case 14:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x00000011);
        case 15:
            PlayerTextDrawBoxColour(playerid, PlayerScreenTD[playerid][TD_ID], 0x00000000);
    }

    PlayerTextDrawHide(playerid, PlayerScreenTD[playerid][TD_ID]);
    PlayerTextDrawShow(playerid, PlayerScreenTD[playerid][TD_ID]);

    if(fadein) {
        counter++;
    } else {
        counter--;
    }

    //Finishing counters
    if(fadein && counter == 15) return true;
    if(!fadein && counter == 1) return true;

    PlayerScreenTD[playerid][TD_Timer] = SetTimerEx("FadeScreen", 50, false, "iib", playerid, counter, fadein);
    return true;
}

forward UnfreezePlayer(playerid);
public UnfreezePlayer(playerid) {
    TogglePlayerControllable(playerid, true);
    return true;
}

forward ShowPlayerTooltip(playerid, const text[]);
public ShowPlayerTooltip(playerid, const text[]) {
    Logger_Dbg("tournament", "ShowPlayerTooltip", Logger_I("playerid", playerid), Logger_S("text", text));
    if(PlayerTooltipTD[playerid][TD_Timer] != INVALID_TIMER) {
        KillTimer(PlayerTooltipTD[playerid][TD_Timer]);
    }
    PlayerPlaySound(playerid, 1150, 0.0, 0.0, 0.0);
    PlayerTextDrawSetString(playerid, PlayerTooltipTD[playerid][TD_ID], text);
    PlayerTextDrawShow(playerid, PlayerTooltipTD[playerid][TD_ID]);
    PlayerTooltipTD[playerid][TD_Timer] = SetTimerEx("HidePlayerTooltip", 8000, false, "i", playerid);
    return true;
}

forward HidePlayerTooltip(playerid);
public HidePlayerTooltip(playerid) {
    Logger_Dbg("tournament", "HidePlayerTooltip", Logger_I("playerid", playerid));
    PlayerTextDrawHide(playerid, PlayerTooltipTD[playerid][TD_ID]);
    PlayerTooltipTD[playerid][TD_Timer] = INVALID_TIMER;
    return true;
}

forward HidePlayerObjective(playerid);
public HidePlayerObjective(playerid) {
    Logger_Dbg("tournament", "HidePlayerObjective", Logger_I("playerid", playerid));
    PlayerTextDrawHide(playerid, PlayerObjectiveTD[playerid][TD_ID]);
    PlayerObjectiveTD[playerid][TD_Timer] = 0;
    return true;
}

forward HidePlayerFinishBox(playerid);
public HidePlayerFinishBox(playerid) {
    Logger_Dbg("tournament", "HidePlayerFinishBox", Logger_I("playerid", playerid));
    PlayerTextDrawHide(playerid, PlayerTDFinishBox[playerid]);
    PlayerTextDrawHide(playerid, PlayerTDFinishTxt[playerid]);
    PlayerTextDrawHide(playerid, PlayerTDFinishPos[playerid]);
    PlayerTextDrawHide(playerid, PlayerTDFinishTime[playerid]);
    FinishTDTimer[playerid] = 0;
    return true;
}

forward KillStage(playerid, stage);
public KillStage(playerid, stage) {
    Logger_Dbg("tournament", "KillStage", Logger_I("playerid", playerid), Logger_I("stage", stage));
    switch(stage) {
        case 0: {
            PlayerPlaySound(playerid, 30803, 0.0, 0.0, 0.0);
            SetPlayerDrunkLevel (playerid, 8000);
            SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
            DeathTimer[playerid] = SetTimerEx("KillStage", 2000, false, "ii", playerid, 1);
        }
        case 1: {
            SetCameraBehindPlayer(playerid);
            SetPlayerArmedWeapon(playerid, WEAPON_FIST);
            ApplyAnimation(playerid, "ped", "KO_shot_face", 4.1, false, true, true, true, 1, SYNC_NONE);
            DeathTimer[playerid] = SetTimerEx("KillStage", 2000, false, "ii", playerid, 2);
        }
        case 2: {
            SetPlayerHealth(playerid, 0);
        }
    }
    return true;
}

forward CountdownTournament();
public CountdownTournament() {
    Logger_Dbg("tournament", "CountdownTournament");
    if(TournamentCountdown > 3) {
        //nothing
    } else if(TournamentCountdown == 3) {
        new tempstring[128];
        format(tempstring, 128, "%d", TournamentCountdown);
        new playerscore = 0;
        new Float:Tempx, Float:Tempy, Float:Tempz;
        new Float:adjustedangle;
        new pointid = INVALID_POINT_ID;
        foreach(new i : SpawnedPlayers) {
            RemovePlayerWeapon(i, WEAPON:WAITING_WEAPON1);
            RemovePlayerWeapon(i, WEAPON:WAITING_WEAPON2);
            RemovePlayerWeapon(i, WEAPON:WAITING_WEAPON3);
            RemovePlayerWeapon(i, WEAPON:TOURNAMENT_WEAPON); //To reset ammo
            GivePlayerWeapon(i, WEAPON:TOURNAMENT_WEAPON, TOURNAMENT_AMMO);
            GameTextForPlayer(i, tempstring, 750, 3);
            PlayerPlaySound(i, 1056, 0.0, 0.0, 0.0);
            TogglePlayerControllable(i, false);
            if(TournamentCountdown == 3) {
                playerscore = GetPlayerScore(i);
                GetPlayerPos(i, Tempx, Tempy, Tempz);
                pointid = DetermineNextPoint(playerscore);
                if(pointid != INVALID_POINT_ID) {
                    adjustedangle = GetAngleBetweenPoints(T_RaceData[pointid][T_X], T_RaceData[pointid][T_Y], Tempx, Tempy);
                } else {
                    //Next point is either after finish or pickup, make it random to confuse players
                    adjustedangle = floatrand(0, 360);
                }
                SetPlayerFacingAngle(i, adjustedangle);
                SetCameraBehindPlayer(i);
                ProgressTournamentForPlayer(i, playerscore);
                HidePlayerTextDraws(i, false);
                ShowPlayerProgress(i, playerscore);
                if(playerscore < T_RealTPointsCount && T_RaceData[playerscore][T_Type] == CP_PICKUP) {
                    //This function is not called when player has picked up a pickup, lets force it on countdown end
                    if(T_RaceData[playerscore][T_BStart] != playerscore) {
                        CreatePlayerPickupBatch(i, playerscore);
                    }
                }
            }
        }
    } else if(TournamentCountdown > 0 && TournamentCountdown < 3) {
        new tempstring[128];
        format(tempstring, 128, "%d", TournamentCountdown);
        foreach(new i : SpawnedPlayers) {
            GameTextForPlayer(i, tempstring, 750, 3);
            PlayerPlaySound(i, 1056, 0.0, 0.0, 0.0);
        }
    } else if(TournamentCountdown == 0) {
        foreach(new i : SpawnedPlayers) {
            PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
	        GameTextForPlayer(i, "GO!", 2000, 3);
            new playerscore = GetPlayerScore(i);
            AdditionalTournamentCalls(i, playerscore, false);
            ShowPlayerCurrentObjective(i, playerscore); //Needs to be called because ProgressTournamentForPlayer() is called on 3, but we want to show thew objective when countdown has ended
            new pointid = DetermineSpawnPoint(playerscore, i);
            if(DoesPointSpawnInVehicle(pointid)) {
                new Float:vX, Float:vY, Float:vZ, Float:vR;
                GetPlayerPos(i, vX, vY, vZ);
                GetPlayerFacingAngle(i, vR);
                PutPlayerInTournamentVehicle(i, vX, vY, vZ, vR, true); //When countdown is 0, spawn the vehicle and set last speed
            }
            TogglePlayerControllable(i, true);
            SetPlayerHealth(i, 100);
            SetPlayerWorldBounds(i, WORLD_XMAX, WORLD_XMIN, WORLD_YMAX, WORLD_YMIN);
        }
        StartingTime = GetTickCount();
        //If tournament is started again, this will reset how long the tournament is running.
        //This could be solved by tracking "uptime", but at this point it is not worth it. Minor bug
        return true; //This is needed to prevent counter going negative
    }
    TournamentCountdown--;
    if(TournamentCountdown >= 0) {
        CountdownTimer = SetTimer("CountdownTournament", 1000, false);
    }
    return true;
}

forward ShowPickupDirection(playerid);
public ShowPickupDirection(playerid) {
    if(!IsPlayerSpawn[playerid]) return false; //If not spawned, then don't process anything
    PlayerPlaySound(playerid, 40404, 0.0, 0.0, 0.0);
    new Float:pickupdistance = GetCurrentPickupDistance(playerid);
    UpdateSignalProgress(playerid, CalculateDistanceProgress(pickupdistance));

    //A cheap way to make a beep faster, it does come at a cost that floating points are calculated more frequently, but the progress bar updates more smoothly when closer
    new frequency = 1000;
    if(pickupdistance <= 30 && pickupdistance > 20) {
        frequency = 500;
    } else if(pickupdistance <= 20 && pickupdistance > 10) {
        frequency = 250;
    } else if(pickupdistance <= 10) {
        frequency = 100;
    }

    DirectionTimer[playerid] = SetTimerEx("ShowPickupDirection", frequency, false, "i", playerid);
    return true;
}

forward PutPlayerInTournamentVehicle(playerid, Float:vX, Float:vY, Float:vZ, Float:vR, bool:onspawn);
public PutPlayerInTournamentVehicle(playerid, Float:vX, Float:vY, Float:vZ, Float:vR, bool:onspawn) {
    Logger_Dbg("tournament", "PutPlayerInTournamentVehicle", Logger_I("playerid", playerid), Logger_F("vX", vX), Logger_F("vY", vY), Logger_F("vZ", vZ), Logger_F("vR", vR), Logger_B("onspawn", onspawn));
    CarSpawnTimer[playerid] = INVALID_TIMER;

    if(SpectatingPlayer[playerid] != INVALID_PLAYER_ID) return false; //Prevents a vehicle being spawned when the player vehicle dies, OpenMP bug, does not happen when spectating a player

    new vehicleid = INVALID_VEHICLE_ID;
    if(!IsCreatedVehicleValid(PlayerVehicleID[playerid])) {
        if(PlayerVehicleModel[playerid] == INVALID_VEHICLE_MODEL) return false;
        vehicleid = CreateVehicle(PlayerVehicleModel[playerid], vX, vY, vZ, vR, PlayerVehicleColour[playerid][0], PlayerVehicleColour[playerid][1], -1);
        if(!IsCreatedVehicleValid(vehicleid)) {
            Logger_Err("Failed to create vehicle on point spawn", Logger_I("playerid", playerid));
            return false;
        }
        foreach(new i : Player) {
            SetVehicleParamsForPlayer(vehicleid, i, false, true);
            UnlockedVehicles[vehicleid][i] = false;
        }
        SetVehicleParamsForPlayer(vehicleid, playerid, false, false);
        UnlockedVehicles[vehicleid][playerid] = true;
        PlayerVehicleID[playerid] = vehicleid;
        VehicleIDToPlayerid[vehicleid] = playerid;
    } else {
        vehicleid = PlayerVehicleID[playerid];
        SetVehiclePos(vehicleid, vX, vY, vZ);
        SetVehicleZAngle(vehicleid, vR);
    }
    PutPlayerInVehicle(playerid, vehicleid, 0);
    new interior = GetPlayerInterior(playerid); //Teleport the vehicle inside an interior, whats the worst that can happen
    LinkVehicleToInterior(vehicleid, interior);
    Iter_Add(CreatedVehicles, vehicleid);
    if(onspawn) {
        new playerscore = GetPlayerScore(playerid);
        if(playerscore < T_RealTPointsCount) {
            if(T_RaceData[playerscore][T_SpawnOverride] != INVALID_POINT_ID) {
                //We want to reset player speed otherwise player can have an incorrect angle and speed
                TDB_SavePlayerSpeed(playerid, 0.0, 0.0, 0.0, 0.0);
                LastPlayerSpeed[playerid][0] = 0.0;
                LastPlayerSpeed[playerid][1] = 0.0;
                LastPlayerSpeed[playerid][2] = 0.0;
                LastPlayerSpeed[playerid][3] = 0.0;
            }
        }
        SetVehicleVelocity(PlayerVehicleID[playerid], LastPlayerSpeed[playerid][0], LastPlayerSpeed[playerid][1], LastPlayerSpeed[playerid][2]);
        SetVehicleZAngle(PlayerVehicleID[playerid], LastPlayerSpeed[playerid][3]);
    }
    return true;
}

forward SummonTournamentVehicle(playerid, Float:pX, Float:pY, Float:pZ);
public SummonTournamentVehicle(playerid, Float:pX, Float:pY, Float:pZ) {
    Logger_Dbg("tournament", "SummonTournamentVehicle", Logger_I("playerid", playerid), Logger_F("pX", pX), Logger_F("pY", pY), Logger_F("pZ", pZ));
    SummonTimer[playerid] = INVALID_TIMER;
    if(!IsTournamentStarted()) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Tournament has not been started yet!");
        return true;
    }

    if(!IsPlayerSpawn[playerid]) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You need to be spawned!");
        return true;
    }

    if(PlayerVehicleModel[playerid] == INVALID_VEHICLE_MODEL) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You don't have a vehicle, find one first!");
        return true;
    }

    if(!IsPlayerInRangeOfPoint(playerid, 2.0, pX, pY, pZ)) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You did not stand still, try again!");
        return true;
    }

    if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: You must be on foot!");
        return true;
    }

    if(Iter_Contains(BlockedCarSpawns, GetPlayerScore(playerid))) {
        SendClientMessage(playerid, -1, "{FF0000}ERROR{FFFFFF}: Vehicles are not allowed to be summoned here!");
        return true;
    }

    new Float:Tempx1;
    new Float:Tempy1;
    new Float:Tempz1;
    new Float:Tempr;
    GetPlayerPos(playerid, Tempx1, Tempy1, Tempz1);
	GetPlayerFacingAngle(playerid, Tempr); 
    PutPlayerInTournamentVehicle(playerid, Tempx1, Tempy1, Tempz1, Tempr, false);
    return true;
}

forward RespawnTournamentVehicle(vehiclespawnid, oldvehicleid);
public RespawnTournamentVehicle(vehiclespawnid, oldvehicleid) {
    Logger_Dbg("tournament", "RespawnTournamentVehicle", Logger_I("vehiclespawnid", vehiclespawnid), Logger_I("oldvehicleid", oldvehicleid));
    if(VehicleRespawnTimers[oldvehicleid] == INVALID_TIMER) return false; //Something canceled the timer

    //The vehicle is not created when nobody is online. Since this is only an issue during testing, then a proper fix is not implemented. Issue is caused by OpenMP
    new newvehicleid = CreateVehicle(TournamentVehicleSpawns[vehiclespawnid][T_VModel],
    TournamentVehicleSpawns[vehiclespawnid][T_VX], TournamentVehicleSpawns[vehiclespawnid][T_VY],
    TournamentVehicleSpawns[vehiclespawnid][T_VZ], TournamentVehicleSpawns[vehiclespawnid][T_VA],
    TournamentVehicleSpawns[vehiclespawnid][T_VC1], TournamentVehicleSpawns[vehiclespawnid][T_VC2], 300);
    Iter_Add(CreatedVehicles, newvehicleid);
    if(!IsCreatedVehicleValid(newvehicleid)) {
        Logger_Err("Failed to respawn vehicle for spawn", Logger_I("vehiclespawnid", vehiclespawnid));
        return false;
    }
    if(TournamentVehicleSpawns[vehiclespawnid][T_VPID] != INVALID_POINT_ID) {
        new score = 0;
        Iter_Add(PointVehicles[TournamentVehicleSpawns[vehiclespawnid][T_VPID]], newvehicleid);
        foreach(new i : Player) {
            score = GetPlayerScore(i);
            UnlockTVehiclesForPlayer(i, newvehicleid, score, vehiclespawnid);
        }
    } else {
        Iter_Add(FreePointVehicles, newvehicleid);
        foreach(new i : Player) {
            //Vehicle is unlocked on all stages, so lets unlock it now
            SetVehicleParamsForPlayer(newvehicleid, i, false, false);
            UnlockedVehicles[newvehicleid][i] = true;
        }
    }

    VehicleIDToSpawnID[newvehicleid] = vehiclespawnid;
    VehicleRespawnTimers[oldvehicleid] = 0;
    return true;
}