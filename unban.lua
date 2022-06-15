--client.lua-- 

RegisterCommand('unban', function(source, args)
    local data = GetResourceKvpString(string.format('vac_ban_%s', args[1]))
    local reason = 'No reason specified'
  
    if (data) then
      -- check if a reason was provided
      if (args[2]) then
        table.remove(args, 1)
        reason = table.concat(args, " ")
      end
  
      DeleteResourceKvp(string.format('vac_ban_%s', args[1]))
      
      print('Sucsesfully deleted Ban Id:',args[1])
    else
      print('Unable to find Ban Id: %s are you sure this is a valid ban?', args[1])
    end
  
    TriggerEvent('__vac_internal:playerUnbanned')
  end, true)
