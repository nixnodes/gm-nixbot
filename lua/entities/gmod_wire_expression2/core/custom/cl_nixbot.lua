E2Helper.Descriptions["createNB"] = "Creates a NixBot"
E2Helper.Descriptions["getEnemy"] = "Get current enemy"
E2Helper.Descriptions["haveEnemy"] = "Returns 1 if the bot has a target, 0 otherwise"
    
hook.Add("NIXBOT.notify.player", "1", function( msg)
  gmod.GetGamemode():AddNotify( msg, NOTIFY_ERROR, 6 )
  surface.PlaySound( "buttons/button10.wav" )
end)