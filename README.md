# AlarmClock

## The Problem

The Roblox physics engine will try to intelligently put parts to "sleep" whenever possible, meaning they aren't being physically simulated. The is obviously a very important optimization, since otherwise you'd be simulating thousands of parts at all times.

However, sometimes it gets it wrong, as seen in @BanTech's bowling game. The pins are sitting still, so the engine puts them to sleep- then a speeding ball hits them and they don't move at all.

In a project of mine, players can move boxes around, and putting the box onto an elevator would put it to sleep and the elevator would leave it behind!

Roblox hasn't (yet?) given us any API to manually flag parts as active, so I came up with a clever trick to keep parts awake and then wrote a module that wraps it up neatly and efficiently.

You should definitely go support this feature request so that we can get this feature added first party with less overhead.
https://devforum.roblox.com/t/duration-based-part-awakening/1085506

--------

## The Solution

To keep parts awake at minimal performance cost, I determined that the best way is to softly push the object towards the ground. We only push it when the Velocity is 0,0,0 as any other velocity means it must already be awake. We push it gently down, because if it's asleep then it must be resting on something so a downward velocity has almost no risk of actually causing the part to move- just wakes it up. This method is used in production environments by BanTech, EgoMoose, Firebrand1, and more, so I know it works well and has been battle tested.

--------

## The API

```Lua
function AlarmClock:ForbidSleep(Part)
```
Keeps the given Part awake at all times.

```Lua
function AlarmClock:ForbidSleepForDuration(Part, Duration)
```
Keeps the given Part awake for the given Duration.

```Lua
function AlarmClock:AllowSleep(Part)
```
Allows the given Part to fall asleep (aka removing it from our forbidden list).

```Lua
function AlarmClock:AllowAllSleep()
```
Allows all our currently forbidden parts to fall asleep (aka clearing our forbidden list).
