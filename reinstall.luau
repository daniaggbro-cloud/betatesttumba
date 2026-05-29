local cloneref = cloneref or function(ref: any)
    return ref
end

if isfolder('tumbascript') then
    delfolder('tumbascript')
end

cloneref(game:GetService('StarterGui')):SetCore('SendNotification', {
    Title = 'Cat TumbaHub',
    Text = 'Successfully reinstalled Cat TumbaHub, Please rejoin ur game to take effect',
    Duration = 20
})