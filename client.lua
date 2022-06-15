
local Charset = {}
for i = 65, 90 do
    table.insert(Charset, string.char(i))
end
for i = 97, 122 do
    table.insert(Charset, string.char(i))
end

RandomLetter = function(length)
    if length > 0 then
        return RandomLetter(length - 1) .. Charset[math.random(1, #Charset)]
    end
    return ""
end


local _CACHE = {
    identifiers = {},
    bans = {}
  }
  local is_cacheUpdated = false
  
  -- Get a list of all current bans on the server
  -- @return table
  local function fetchBans()
    if (not is_cacheUpdated) then
      local handle = StartFindKvp('vac_ban_')
      local bans = {}
      local key
  
      repeat
        key = FindKvp(handle)
  
        if (key) then
          bans[key] = json.decode(GetResourceKvpString(key))
        end
      until not key
      EndFindKvp(handle)
  
      _CACHE.bans = bans
      is_cacheUpdated = true
    end
    return _CACHE.bans
  end
  
  -- https://gist.github.com/jrus/3197011
  local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
      local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
      return string.format('%x', v)
    end)
  end
  
  -- @param netId | string | player source
  -- @param temp | bool | is player fully connected
  -- @return table | player identifiers 
  local function getIdentifiers(netId, temp)
    local t = {}
  
    if (tonumber(netId) >= 1 and not _CACHE.identifiers[netId]) then
      for _, v in pairs(GetPlayerIdentifiers(netId)) do
        local idx, value = v:match("^([^:]+):(.+)$")
  
        -- high variance/unreliable
        -- also prevents abuse by bad actors
        if (idx ~= 'ip') then
          t[idx] = value
        end
      end
  
      for _, v in pairs(GetPlayerTokens(netId)) do
        local idx, value = v:match("^([^:]+):(.+)$")
  
        -- unreliable multiple users can have the same first and second token
        if (idx ~= '0' and idx ~= '1') then
          t[idx] = value
        end
      end
  
      -- if the player doesn't have a permanent netId
      -- don't populate the cache table as they might be dropped in connection
      if (not temp) then
        _CACHE.identifiers[netId] = t
      end
  
      return t
    end
  
    -- ensure the player is in our cache table before returning data
    -- otherwise return an empty table
    return (_CACHE.identifiers[netId] and _CACHE.identifiers[netId] or {})
  end
  

  
  function BanPlayer(netId, duration, reason, extra)
    if (GetPlayerEndpoint(netId)) then
      local uuid = uuid()
      local ban = {
        id = uuid,
        -- if no time is passed default to one year 
        duration = (duration and duration + os.time() or 31536000 + os.time()),
        identifiers = getIdentifiers(netId, false),
        reason = reason or 'No reason specified'
      }
  
      SetResourceKvp(string.format('vac_ban_%s', uuid), json.encode(ban))
  
      if (not GetResourceKvpString(string.format('vac_ban_%s', uuid))) then
        log.error('Unable to ban ' ..GetPlayerName(netId).. ' this is a fatal error, please report this to the developers.')
        log.error(json.encode(ban))
        log.error('Dropping player with no reason specified')
  
        DropPlayer(netId, 'No reason specified')
        return
      end
  
      DropPlayer(netId, string.format('You have been banned\nBan Id:%s\nExpires: %s\nReason: %s', uuid, os.date('%c', ban.duration), ban.reason))
  
      is_cacheUpdated = false
    end
    
  end
  
  local filter_username = false
  local filter_text = {}
  
  local function onPlayerConnecting(name, skr, d)
    local source = source
  
    if (filter_username and #filter_text ~= 0) then
      local name = name:lower()
      local hits = {}
  
      for i = 1, #filter_text do
        if (name:find(filter_text[i]:lower())) then
          hits[i] = filter_text[i]
        end
      end
  
      if (#hits ~= 0) then
        -- TODO: Better way to format each hit
        skr(('Your username contains blocked text:  \n' ..json.encode(hits).. '\nremove these items then reconnect'))
      end
    end
  
    d.defer()
  
    Wait(0)
  
    d.update('Fetching ban data')
  
    local banlist = fetchBans()
    local identifiers = getIdentifiers(source, true)
  
    d.update('Got ban data, checking if you are banned')
  
    Wait(0)
  
    for banId, data in pairs(banlist) do
      -- clean up expired bans
      if (data.duration - os.time() <= 0) then
        DeleteResourceKvp(banId)
        goto continue
      end
  
      for _, id in pairs(data.identifiers) do
        if (json.encode(identifiers):find(id)) then
          d.done(string.format('You have been banned\nBan Id:%s\nExpires: %s\nReason: %s', data.id, os.date('%c', data.duration), data.reason))
          break
        end
      end
  
      ::continue::
    end
  
    d.done()
  end
  AddEventHandler('playerConnecting', onPlayerConnecting)
  
  AddEventHandler('__vac_internal:playerUnbanned', function()
    is_cacheUpdated = false
  end)





