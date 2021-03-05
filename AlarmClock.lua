--[=[
	AlarmClock by boatbomber
	3/5/2021 | Distributed under MIT License
--]=]

local RunService = game:GetService("RunService")

local AlarmClock = {
	Watchlist = table.create(10);
	DestroyConnections = table.create(10);
	SteppedConnection = nil;
}

local SLEEPING,PUSH = Vector3.new(),Vector3.new(0,-0.08,0)

local function SteppedFunction()
	-- Iterate through forbidden parts and wake any that are attempting to sleep
	for i, Part in ipairs(AlarmClock.Watchlist) do
		if Part.Velocity == SLEEPING then
			Part.Velocity = PUSH
		end
	end
end

function AlarmClock:ForbidSleep(Part)
	-- Validate
	if (typeof(Part)~="Instance") or (not Part:IsA("BasePart")) then
		warn("Attempt to ForbidSleep on invalid part")
		return
	end
	if table.find(self.Watchlist,Part) then
		warn("Attempt to forbid a part that's already forbidden")
		return
	end

	-- Add part to watchlist
	self.Watchlist[#self.Watchlist+1] = Part

	-- Start our watcher if we haven't yet
	if not self.SteppedConnection then
		self.SteppedConnection = RunService.Stepped:Connect(SteppedFunction)
	end

	-- Create a destroy watcher if one doesn't exist
	if not self.DestroyConnections[Part] then
		self.DestroyConnections[Part] = Part.AncestryChanged:Connect(function()
			if not Part:IsDescendantOf(game) then
				self:AllowSleep(Part)
			end
		end)
	end
end

function AlarmClock:AllowSleep(Part)
	-- Validate
	if (typeof(Part)~="Instance") or (not Part:IsA("BasePart")) then
		warn("Attempt to AllowSleep on invalid part")
		return
	end

	-- Find the part within our watchlist
	local PartIndex = table.find(self.Watchlist,Part)
	if not PartIndex then return end

	-- Remove the part without shifting the array via unordered removal
	if PartIndex == #self.Watchlist then
		self.Watchlist[PartIndex] = nil
	else
		self.Watchlist[PartIndex] = self.Watchlist[#self.Watchlist]
		self.Watchlist[#self.Watchlist] = nil
	end

	-- Clear our part destroy connection
	if self.DestroyConnections[Part] then
		self.DestroyConnections[Part]:Disconnect()
		self.DestroyConnections[Part] = nil
	end

	-- Stop our watcher if we no longer need it
	if #self.Watchlist < 1 and self.SteppedConnection then
		self.SteppedConnection:Disconnect()
		self.SteppedConnection = nil
	end
end

function AlarmClock:ForbidSleepForDuration(Part, Duration)
	-- Validate
	if (typeof(Part)~="Instance") or (not Part:IsA("BasePart")) then
		warn("Attempt to ForbidSleepForDuration on invalid part")
		return
	end

	Duration = type(Duration)=="number" and Duration or 1
	
	coroutine.wrap(function()
		local t = os.clock()

		self:ForbidSleep(Part)

		-- Accurate wait the specified duration before allowing sleep
		while true do
			if os.clock()-t >= Duration then
				break
			end
			RunService.Heartbeat:Wait();
		end

		self:AllowSleep(Part)
	end)()
end

function AlarmClock:AllowAllSleep()
	-- Free all watched parts
	table.clear(self.Watchlist)

	-- Stop our watcher as we no longer need it
	if self.SteppedConnection then
		self.SteppedConnection:Disconnect()
		self.SteppedConnection = nil
	end

	-- Clear destroy connections
	for Part,Connect in pairs(self.DestroyConnections) do
		Connect:Disconnect()
	end
	table.clear(self.DestroyConnections)
end

return AlarmClock
