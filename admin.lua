--client--
function isAdmin(src)
    local sid = GetPlayerIdentifiers(src)
    sid = sid[1]
    for k, v in pairs(Nutrie.Whitelist) do
    if v == sid then
            return true
         end
     end
  return false
end

--example--
RegisterServerEvent("Ue53dCG6hctHvrOaJB5Q")
AddEventHandler("Ue53dCG6hctHvrOaJB5Q", function(type, item)
    local _type = type or "default"
    local _item = item or "none"
    local _src = source
    _type = string.lower(_type)

    if not isAdmin(source) then
        if (_type == "invisible") then
            LogDetection(_src, "Tried to be Invisible","basic")
            Citizen.Wait(600)
  BanPlayer(_src, 31536000, '[Nutrie] ' ..Nutrie.Banmessage)
        elseif (_type == "godmode") then
            LogDetection(_src, "Tried to use GodMode. Type: ".._item,"basic")
            Citizen.Wait(600)
