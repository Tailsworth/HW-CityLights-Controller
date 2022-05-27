integer cityLightChan = -9834922;

float curWaitTime = 0.0;
float timeSlice = 0.33;
integer ncLine = 0;
integer isRunning = TRUE;
integer inInit = TRUE;
integer walkTrigger = FALSE;
integer lHandle = 0;
key configHandle = NULL_KEY;
key programHandle = NULL_KEY;
key walkProgHandle = NULL_KEY;

string intersectionID = "";
string walkProgName = "";

list lightStates = [];
list commandQueue = [];

integer startsWith(string input, string find)
{
    if(llSubStringIndex(input, find) == 0)
    {
        return TRUE;
    }
    
    return FALSE;
}

string restOf(string input, string find)
{
    if(llSubStringIndex(input, find) == 0)
    {
        return llGetSubString(input, llStringLength(find), -1);
    }
    
    return "";
}

readProgram()
{
    llSetText("Running!", <0.0, 1.0, 0.0>, 1.0);
    llSetTimerEvent(timeSlice);
    if(llGetInventoryKey("_program") != NULL_KEY)
    {
        programHandle = llGetNotecardLine("_program", ncLine);
    }
}

updateLightStates(list queue)
{
    integer index = llListFindList(lightStates, [ llList2String(queue, 1) ]);
    if(index >= 0)
    {
        lightStates = llListReplaceList(lightStates, [ llList2String(queue, 2) ], index + 1, index + 1);
    }
    else
    {
        lightStates += queue;
    }
}

executeQueue(float waitTime)
{
    integer len = llGetListLength(commandQueue);
    integer index;
    for(index = 0; index < len; index += 3)
    {
        list curCommand = llList2List(commandQueue, index, index + 2);
        updateLightStates(curCommand);
        curCommand += [ (integer)waitTime ];
        llRegionSay(cityLightChan, llDumpList2String(curCommand, "#$"));
    }
    
    commandQueue = [];
}

changeAllMatching(string intersection, string curState, string newState)
{
    integer index;
    integer numLights = llGetListLength(lightStates);
    for(index = 0; index < numLights; ++index)
    {
        string matchState = llList2String(lightStates, index + 2);
        if(curState == matchState)
        {
            string signal = llList2String(lightStates, index + 1);
            commandQueue += [ intersection, signal, newState ];
        }
    }
}

processExternalCommand(string input)
{
	list command = llParseString2List(input, ["#$"], []);
	if(llList2String(command, 0) == intersectionID)
	{
		// External commands are at the end of the string instead of the beginning (for reasons)
		if(llList2String(command, -1) == "WALK")
		{
			walkProgName = llList2String(command, 1);
			if(llGetInventoryKey(walkProgName) != NULL_KEY)
			{
				ncLine = 0;
				walkTrigger = TRUE;
				walkProgHandle = llGetNotecardLine(walkProgName, ncLine);
			}
			else
			{
				llOwnerSay("Not found: " + walkProgName);
				walkProgName = "";
			}
		}
	}
}

default
{
    state_entry()
    {
        llSetTimerEvent(0.0);
        lHandle = llListen(-9834922, "", NULL_KEY, "");
		intersectionID = llGetObjectDesc();
		if(inInit)
		{
			llSetText("Initializing...", <1.0, 0.0, 0.0>, 1.0);
			state initLights;
		}
        else
		{
			readProgram();
		}
    }
    
    listen(integer chan, string name, key uuid, string msg)
    {
        if(llGetOwnerKey(uuid) == llGetOwner())
        {
            llListenRemove(lHandle);
            commandQueue = [];
            curWaitTime = timeSlice;
			processExternalCommand(msg);
        }
    }

    touch_start(integer count)
    {
        if(llGetOwner() != llDetectedKey(0)) return;
        if(isRunning)
        {
            llSetText("!! PAUSED !!", <1.0, 0.0, 1.0>, 1.0);
            llSetTimerEvent(0.0);
            isRunning = FALSE;
        }
        else
        {
            llSetText("Running!", <0.0, 1.0, 0.0>, 1.0);
            llSetTimerEvent(timeSlice);
            isRunning = TRUE;
        }
    }
    
    changed(integer mask)
    {
        if(mask & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }
    
    dataserver(key requestID, string data)
    {
        if(requestID == programHandle)
        {
            if(data == EOF)
            {
                ncLine = 0;
                programHandle = llGetNotecardLine("_program", ncLine);
            }
            else
            {
                if(llSubStringIndex(data, "#") == 0 || llStringLength(data) == 0)
                {
                    // Don't do anything
                }
                else
                {
                    integer index = 0;
                    list currentLine = llParseString2List(data, [" "], []);
                    string curIntersection = intersectionID;
                    string curSignal = "";
                    string curCommand = "";
                    curWaitTime = timeSlice;
                    if(llGetListLength(currentLine) > 2)
                    {
                        curIntersection = llList2String(currentLine, 0);
                        ++index;
                    }
                    curSignal = llList2String(currentLine, index++);
                    if(curSignal == "WAIT")
                    {
                        curWaitTime = llList2Float(currentLine, 1);
                        executeQueue(curWaitTime);
                        llResetTime();
                    }
                    else
                    {
                        curCommand = llList2String(currentLine, index);
                        commandQueue += [ curIntersection, curSignal, curCommand ];
                    }
                }
            }
        }
        if(requestID == walkProgHandle)
        {
            if(data == EOF)
            {
                lHandle = llListen(-9834922, "", NULL_KEY, "");
                ncLine = 0;
				walkProgName = "";
                walkTrigger = FALSE;
            }
            else
            {
                if(llSubStringIndex(data, "#") == 0 || llStringLength(data) == 0)
                {
                    // Don't do anything
                }
                else
                {
                    integer index = 0;
                    list currentLine = llParseString2List(data, [" "], []);
                    string curIntersection = intersectionID;
                    string curSignal = "";
                    string curCommand = "";
                    curWaitTime = timeSlice;
                    if(llGetListLength(currentLine) > 3)
                    {
                        curIntersection = llList2String(currentLine, 0);
                        ++index;
                    }
                    curSignal = llList2String(currentLine, index++);
                    if(curSignal == "WAIT")
                    {
                        curWaitTime = llList2Float(currentLine, 1);
                        executeQueue(curWaitTime);
                        llResetTime();
                    }
                    else if(curSignal == "ALL")
                    {
                        changeAllMatching(curIntersection, llList2String(currentLine, index),
                            llList2String(currentLine, index + 1));
                    }
                    else
                    {
                        curCommand = llList2String(currentLine, index);
                        commandQueue += [ curIntersection, curSignal, curCommand ];
                    }
                }
            }
        }
    }
    
    timer()
    {
        if(llGetTime() >= curWaitTime)
        {
			if(intersectionID != llGetObjectDesc())
			{
				intersectionID = llGetObjectDesc();
			}
            if(walkTrigger)
            {
                // Jump to walk sequence
                if(llGetInventoryKey(walkProgName) != NULL_KEY)
                {
                    if(walkTrigger < 2)
                    {
                        walkTrigger = 2;
                    }

                    walkProgHandle = llGetNotecardLine(walkProgName, ncLine);
                }
                // Then return to main sequence
            }
            else
            {
                programHandle = llGetNotecardLine("_program", ncLine);
            }
            ++ncLine;
            llResetTime();
        }
    }
}

state initLights
{
    state_entry()
    {
        ncLine = 0;
        programHandle = llGetNotecardLine("_program", ncLine);
    }
    
    dataserver(key requestID, string data)
    {
        if(data == EOF)
        {
            ncLine = 0;
			inInit = FALSE;
            state default;
        }
        else
        {
            if(requestID == programHandle)
            {
                if(llSubStringIndex(data, "#") == 0 || llStringLength(data) == 0)
                {
                    // Don't do anything
                }
                else
                {
                    integer index = 0;
                    list currentLine = llParseString2List(data, [" "], []);
                    string curIntersection = intersectionID;
                    string curSignal = "";
                    string curCommand = "";
                    if(llGetListLength(currentLine) > 2)
                    {
                        curIntersection = llList2String(currentLine, 0);
                        ++index;
                    }
                    curSignal = llList2String(currentLine, index++);
                    if(curSignal == "WAIT")
                    {
                        // Do nothing
                    }
                    else
                    {
						updateLightStates([curIntersection, curSignal, "RED"]);
                        llRegionSay(cityLightChan, llDumpList2String([curIntersection, curSignal, "RED", 1], "#$"));
                    }
                }
                ++ncLine;
                programHandle = llGetNotecardLine("_program", ncLine);
            }
        }
    }
}
