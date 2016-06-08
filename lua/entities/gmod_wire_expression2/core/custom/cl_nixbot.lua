E2Helper.Descriptions["createNB"] = "Creates a NixBot"

    
hook.Add("NIXBOT.notify.player", "1", function( msg)
  gmod.GetGamemode():AddNotify( msg, NOTIFY_ERROR, 6 )
  surface.PlaySound( "buttons/button10.wav" )
end)