integer cityLightChan = -9834922;

default
{
    touch_start(integer count)
    {
        llRegionSay(-9834922, llGetObjectDesc() + "#$WALK");
    }
}
