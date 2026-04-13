--[[ v1.0.0 https://wearedevs.net/obfuscator ]] return(function(...)local l={"\110\055\080\076\055\070\043\106\110\078\113\109\055\079\110\110\099\103\061\061","\090\102\080\121\117\051\120\114\054\070\055\061";"\112\052\066\107\071\101\048\108";"\071\052\065\086";"\090\102\080\070\071\070\107\108\055\070\066\109\117\052\066\109","\070\107\102\048\057\070\107\105\118\116\066\085\116\103\118\043";"\102\104\084\113\090\108\116\119\068\116\061\061";"\085\081\100\110\056\065\083\090\043\122\050\100","\087\103\114\066\083\099\048\087\054\082\086\050\049\088\113\061","\112\107\052\117\056\097\086\113","\057\048\107\068\102\084\112\076\065\097\122\119","\053\119\068\078\113\116\061\061","\074\113\080\072\048\101\069\113-- library/notifications.lua
-- A modern notification system.

local CoreGui = Mega.Services.CoreGui
local Debris = Mega.Services.Debris
local TweenService = Mega.Services.TweenService

function Mega.ShowNotification(message, duration, color)
    duration = duration or 3
    color = color or Mega.Settings.Menu.AccentColor

    local NotifGui = Instance.new("ScreenGui")
    NotifGui.Name = "TumbaGlobalNotification"
    NotifGui.Parent = CoreGui
    NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 250, 0, 50)
    container.Position = UDim2.new(1, 0, 1, 0) -- Start off-screen
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    container.BackgroundTransparency = 0.2
    container.BorderSizePixel = 0
    container.Parent = NotifGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = color
    stroke.Transparency = 0.5
    stroke.Parent = container
    
    local sideBar = Instance.new("Frame")
    sideBar.Size = UDim2.new(0, 5, 1, 0)
    sideBar.BackgroundColor3 = color
    sideBar.BorderSizePixel = 0
    sideBar.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Mega.Settings.Menu.TextColor
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.Text = message
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = container

    -- Find the vertical position for the new notification
    local existingNotifs = 0
    for _, child in pairs(CoreGui:GetChildren()) do
        if child.Name == "TumbaGlobalNotification" and child ~= NotifGui then
            existingNotifs = existingNotifs + 1
        end
    end

    local targetPosition = UDim2.new(1, -270, 1, -70 - (existingNotifs * 60))

    -- Animate In
    TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = targetPosition }):Play()

    -- Animate Out and destroy
    task.delay(duration, function()
        if container and container.Parent then
            TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Position = UDim2.new(1, 0, container.Position.Y.Scale, container.Position.Y.Offset) }):Play()
            Debris:AddItem(NotifGui, 0.5)
        end
    end)
end

\107\085\066\080\087\048\043\080\104\087\084\089\072\068\112\061","\103\052\106\081\103\118\103\043\073\053\053\106\083\078\057\082\071\078\108\054";"\085\112\121\107\089\112\103\104\054\051\055\061";"\110\070\066\079\055\070\066\109\117\052\108\074\048\103\061\061","\073\055\080\121\048\086\120\049\103\101\100\081\071\118\057\067\048\068\054\061","\077\073\101\102\047\066\087\097\075\112\120\089\114\070\076\110\073\106\097\112\086\078\081\114\080\066\104\061";"\112\108\116\118\066\102\122\101\117\051\080\049\117\120\066\051";"\073\073\065\069\084\107\076\047\043\103\108\053\117\105\105\107\076\068\047\100\048\074\103\061";"\073\047\077\122","\066\084\049\082\103\076\115\122\109\104\086\061","\100\083\110\104\111\081\104\081\048\109\083\077\048\108\113\061";"\054\056\048\078\071\047\066\074\102\074\066\077\090\066\108\115\073\055\112\061","\066\052\066\074\117\051\089\109\122\081\061\061","\052\056\097\074\057\067\089\116\052\108\081\118","\073\056\057\082\073\056\105\121","\115\073\117\053\065\079\098\098\074\088\113\061","\056\118\089\085\048\102\043\061","\068\120\110\043\068\101\048\052\055\047\066\066\099\074\066\098\112\078\116\061","\071\052\083\066\055\120\082\053\099\108\112\118\054\086\120\054\102\116\061\061","\122\057\054\121\120\122\074\070\101\105\078\072","\078\055\098\118\110\069\056\114\074\105\116\065","\081\082\084\069\109\104\065\072\101\122\103\061";"\043\048\119\072\111\049\105\085\048\116\061\061";"\049\081\117\055\102\066\103\117\074\078\083\105","\056\118\089\050\071\052\110\108\099\116\061\061","\107\082\081\100";"\080\043\088\050\097\114\097\111\116\081\061\061";"\122\053\101\043\087\049\057\114\070\073\054\116";"\103\070\089\085\071\101\104\121";"\103\070\089\114\071\052\066\074\117\116\061\061";"\110\070\066\079\090\102\080\121\117\051\120\114\054\070\066\057\048\051\110\108\048\120\083\050\048\070\080\082\071\116\061\061";"\071\102\089\121\122\101\083\078\110\056\066\047\103\078\104\106\048\116\061\061","\049\047\057\081\112\102\083\083\073\051\083\053\112\068\048\051\112\116\061\061","\049\076\052\090\097\080\118\105";"\074\118\122\054\068\077\110\073\050\100\061\061";"\106\106\074\065\101\081\055\061","\119\066\105\089","\071\108\082\051\083\053\043\106\110\070\120\115\071\121\110\121","\048\052\080\108\117\070\066\053\055\056\048\108\122\052\105\067\073\100\061\061","\084\111\054\108";"\054\070\082\082\112\100\061\061";"\122\048\120\084\079\050\057\065\097\087\120\075\084\088\105\112\081\098\110\048";"\090\120\053\079\083\086\083\066\083\086\107\081\099\102\050\083";"\056\066\101\071\121\067\068\119\057\102\086\109\119\075\119\069";"\071\102\120\079\073\116\061\061","\055\070\066\079\110\102\080\082\054\052\106\108\048\116\061\061","\097\071\055\067\112\100\053\113\098\049\116\061","\103\078\105\076\110\047\066\086\066\078\105\074\090\052\082\106\103\100\061\061";"\105\086\078\069\047\073\122\109\070\050\084\086\113\110\081\061";"\054\078\108\079\048\103\061\061","\073\052\108\049\048\118\122\079\083\055\106\110\112\068\112\101\049\103\061\061";"\105\099\081\121\055\079\081\056\081\100\067\110\103\055\102\070\054\098\081\061";"\055\084\112\106","\104\115\050\110\076\101\097\057\088\117\080\088\047\066\088\110";"\110\102\106\086\048\056\105\079\112\052\066\108","\102\105\114\100\108\090\068\110\101\074\043\061";"\048\056\105\109\071\101\104\061","\117\051\120\077\071\051\055\061";"\085\116\056\109\118\083\116\104\111\075\089\107\119\116\061\061","\081\067\072\104\082\081\113\061","\114\120\047\066\113\081\061\061";"\048\101\083\118\054\100\061\061","\111\083\115\073\054\073\071\118\109\057\054\075\076\065\097\090\053\115\057\053\057\077\055\061","\112\056\057\051\048\056\083\113\110\055\089\085\099\074\048\103\103\103\061\061";"\049\077\100\108\048\069\113\050\049\100\061\061";"\117\051\089\114\117\102\118\077\048\056\104\061";"\049\074\107\051\082\076\089\099\090\099\097\081\090\101\066\119\089\112\051\075\069\087\122\061","\073\101\110\073\054\108\082\101\066\051\107\107\083\053\108\066","\089\120\079\066\088\049\114\101","\066\070\120\050\117\053\048\115\112\086\083\113\073\102\106\086","\084\055\104\076\080\068\086\087\117\103\061\061";"\083\118\070\074\056\074\101\079\111\111\102\068";"\068\070\085\118\066\118\105\081\083\120\116\118\090\079\048\054\083\120\086\061","\090\086\083\120\055\121\057\110\071\102\106\103\054\103\061\061";"\102\081\050\109\113\102\122\061";"\076\116\052\050\051\111\075\100\056\121\120\043","\048\070\118\082\117\051\083\113";"\056\118\089\107\048\056\110\082\117\051\120\077\071\051\055\061";"\047\106\101\119\067\099\117\101\079\090\111\075\047\066\104\061";"\054\079\080\115\083\119\066\120\068\086\050\108\066\086\082\067\090\055\081\061";"\110\070\066\079\103\056\110\079\112\052\108\077\117\056\110\108","\117\077\090\114\081\116\061\061";"\066\102\048\043\083\078\055\121\066\079\105\119\055\051\118\043";"\110\070\048\108\122\104\105\090\086\116\061\061";"\120\069\117\083\105\077\084\111\083\103\061\061","\117\043\090\086\120\047\082\087\122\103\061\061";"\048\118\055\080\112\119\110\056\055\108\105\103\073\055\083\085","\048\053\089\113\073\074\083\104\073\102\117\073\090\086\106\051";"\086\053\115\112\085\102\108\069\114\100\061\061";"\117\051\120\121\073\081\061\061";"\103\101\098\081";"\081\102\069\085\073\109\073\099\116\103\122\100\116\086\122\071\049\081\061\061","\099\051\083\066\099\068\105\120\066\078\117\076\048\068\104\081\073\103\061\061";"\097\118\114\076\117\116\061\061","\117\079\080\057\103\118\057\115\083\078\082\067\103\121\053\121","\111\084\070\078\076\102\071\117\098\109\053\113\100\110\104\061";"\099\056\083\056\071\070\083\057\122\074\055\109\103\070\083\043\083\102\100\061","\051\080\052\043","\082\102\056\075\073\083\120\054\070\110\100\061";"\071\051\066\114","\066\055\110\050\071\068\104\061";"\066\051\120\107\112\051\066\109\104\053\110\108\117\051\066\074\117\051\066\086\104\103\061\061";"\052\055\075\084","\073\081\120\082\110\067\074\107\106\083\108\122\116\089\101\090\069\118\102\081\117\115\075\118\097\100\113\061";"\047\049\086\048\105\089\088\083\120\050\100\090\107\081\061\061","\108\085\076\072\074\066\054\061","\056\118\089\078\054\081\061\061","\080\110\119\083\086\097\057\052\103\076\051\068\122\100\061\061","\103\070\106\108\054\056\105\057\071\051\106\047\073\051\108\085\048\119\105\108\071\100\061\061","\066\099\102\084\116\105\119\077\077\119\050\052","\067\106\122\083\084\100\061\061";"\049\116\084\057\075\116\061\061","\082\103\113\089\119\057\082\066";"\068\102\066\078\054\103\061\061","\078\055\087\084\079\086\079\052\107\075\116\067","\047\077\102\118\115\069\067\122\067\083\083\121\086\101\121\117\082\109\074\084\084\051\081\061","\072\104\056\099\082\115\049\099\100\082\048\115\057\089\048\065\098\072\086\105\076\100\061\061","\085\049\090\103\072\083\082\101\074\103\061\061","\082\052\080\078\068\071\050\068\119\102\113\075\107\100\061\061","\065\117\103\111\086\108\043\043\116\100\061\061","";"\110\070\066\079\066\051\120\078\048\070\066\086";"\086\107\043\084\109\109\087\048\068\047\054\070\109\078\083\108\076\111\116\068\119\112\103\061";"\054\070\089\114\054\070\120\079";"\099\086\080\103\110\086\117\065\103\121\053\070","\070\079\116\083\079\118\082\073\070\089\083\065\080\118\116\066\071\075\084\047\049\113\054\061";"\071\047\104\061";"\052\114\108\069\049\112\097\047\085\114\054\061","\110\052\066\082\117\119\066\109\048\056\122\061","\117\051\089\121\117\119\105\050\071\052\112\061";"\057\067\047\080\086\079\047\103\109\103\061\061";"\055\082\111\115","\083\105\121\052\122\055\073\106\076\047\104\112\098\068\084\043","\090\053\100\085\048\112\083\043\112\100\061\061","\084\066\120\047\088\072\101\109\120\100\061\061";"\090\056\083\057";"\112\052\120\114\048\051\089\107","\071\114\084\119\084\085\101\079\065\048\072\067\100\118\049\048\075\065\054\073\110\075\116\061","\048\052\107\048\071\101\057\065\055\108\110\121\068\051\080\106\090\116\061\061";"\068\118\116\106\112\052\082\090\112\052\050\119\071\066\110\107\090\052\112\061","\112\051\083\082\071\051\081\061";"\110\051\108\121\054\070\089\114\071\052\066\074\117\116\061\061","\071\121\120\066\103\066\117\048\117\121\105\049\055\101\117\068\071\079\055\061";"\103\050\120\086\080\074\068\085\098\103\061\061";"\049\100\061\061";"\118\082\078\078\053\056\047\109\066\081\061\061";"\079\118\106\078\080\107\070\101\120\065\100\061";"\080\068\049\086\078\066\088\043\043\109\085\097\053\097\049\110\050\090\065\067\089\120\100\055\100\110\057\067","\107\098\098\085\070\085\065\077\105\100\061\061","\077\105\066\068\089\110\081\068","\057\113\099\085\102\120\054\069\084\043\086\061","\101\049\069\056\079\117\057\075","\081\081\105\098\069\068\104\061";"\073\066\083\072\122\056\117\072\103\074\108\119\083\068\057\080\102\066\103\061";"\066\055\110\050\071\103\061\061";"\048\070\120\107\048\103\061\061","\047\105\103\070\089\051\078\106\107\103\061\061";"\117\051\108\074\073\081\061\061";"\051\103\105\067\048\100\061\061";"\071\056\116\121\110\068\048\105\102\108\105\065\068\052\104\070";"\066\056\057\086\054\056\110\108\110\066\083\103","\050\055\048\106\111\100\061\061","\057\109\068\088\067\099\116\057\070\081\061\061";"\117\102\080\081\054\102\083\067","\051\073\102\047\071\083\052\099\090\071\088\111\047\081\061\061";"\083\115\121\066\089\116\101\074\084\057\090\097\122\103\061\061";"\101\055\098\078\119\113\050\049\113\080\117\109\074\110\112\061";"\112\070\066\079\071\102\066\079\054\056\110\082\054\052\106\108","\048\118\105\121\090\052\118\073\055\068\122\081\073\051\113\070","\104\115\047\107\065\104\101\107\089\049\049\080\054\113\083\121\105\116\099\050\054\103\061\061","\110\052\108\114\048\053\048\050\112\078\083\079\103\070\082\050\071\051\103\061","\048\052\106\115\071\101\104\061";"\087\110\122\052\072\049\056\084\107\097\078\103\049\090\083\088\086\099\089\122\109\054\101\116\118\089\043\061";"\081\055\073\122\055\114\069\080\118\065\121\079\108\071\111\087\099\099\056\049\054\085\072\099\048\110\122\085\104\116\061\061","\112\052\075\106\117\074\117\107","\071\047\053\061";"\077\048\069\117\072\074\118\050\086\122\068\074\120\107\090\109\084\116\117\067\081\101\050\081\081\079\053\111\111\122\073\056","\081\088\079\075","\047\078\049\102\078\068\076\072\115\099\053\061";"\055\078\050\107\073\055\048\067\068\051\082\122\068\052\106\083\117\081\061\061";"\100\051\082\049\067\080\113\067\122\084\079\100\076\103\061\061","\112\101\110\109\073\102\080\078","\110\051\066\121\117\119\105\115\099\103\061\061";"\069\112\071\072\077\089\115\072\052\105\121\057\052\078\080\081\099\103\061\061","\111\114\085\071\067\103\075\054\068\110\114\076\114\100\112\061";"\074\053\112\111\105\070\113\074\072\048\055\067\112\119\048\108\077\103\061\061";"\049\119\098\071\121\075\119\112\053\103\061\061";"\106\084\066\066\049\088\066\050","\088\076\051\043\112\090\098\100\103\097\085\115"}local function y(y)return l[y+(-711569+751050)]end for y,c in ipairs({{-94662-(-94663),-703996+704197},{-786517+786518,29540-29508},{186118+-186085,231151-230950}})do while c[-526745+526746]<c[-887684+887686]do l[c[570708+-570707]],l[c[90691+-90689]],c[851061-851060],c[890165-890163]=l[c[-932820-(-932822)]],l[c[930773+-930772]],c[-432913+432914]+(-739784+739785),c[-446787-(-446789)]-(134688+-134687)end end do local y=table.insert local c=type local K=l local G=math.floor local B=string.sub local I=string.len local M=string.char local N=table.concat local z={f=463368+-463346,o=208598-208535,C=911386-911343;S=172366-172353;X=954958+-954927;V=-750716+750752;["\050"]=-577954+577995,k=969703+-969658,D=-954033+954052,A=-213211-(-213253);d=640229-640197;q=-437492+437532,T=-719473+719531,P=157429-157372,K=157148+-157088;H=559215-559205;i=-575786-(-575795),O=906115-906063;m=-811017+811067,["\052"]=-936850-(-936888);j=220951+-220902,Q=1019312-1019264,U=-78098-(-78142),["\054"]=-271014+271038,I=-11278+11304;Z=970564+-970546;L=537276-537261;t=899995+-899995;["\055"]=985855-985835;F=-837857-(-837911);["\053"]=-68588-(-68592),c=-815225+815255,u=-127294-(-127323);n=-539708+539725;N=-200241-(-200280),p=-305981+306009;["\051"]=-862051+862057;g=218718-218702,a=-69302+69361;["\048"]=-60146-(-60171);h=723090-723082;v=-344199+344252;Y=-445674-(-445735),x=-820683+820688;B=863985+-863964;["\057"]=-880267-(-880268);R=-160795+160828;M=34544-34510;e=-1034434+1034489;E=336974+-336972;s=-988923-(-988970);["\056"]=-20498-(-20521);W=132487-132425,b=-804456-(-804467),["\047"]=329224+-329221;J=-886402+886437;["\043"]=327761-327705;G=-468728-(-468755),y=104645-104594;r=-641616+641662;z=576601-576589;l=278726-278689,["\049"]=825570+-825556,w=509598+-509591}for l=226325+-226324,#K,-7783+7784 do local e=K[l]if c(e)=="\115\116\114\105\110\103"then local c=I(e)local p={}local g=-150017+150018 local Z=948042-948042 local v=-289568-(-289568)while g<=c do local l=B(e,g,g)local K=z[l]if K then Z=Z+K*(-333013-(-333077))^((-473782-(-473785))-v)v=v+(358746-358745)if v==391996+-391992 then v=875933+-875933 local l=G(Z/(-867153+932689))local c=G((Z%(686852+-621316))/(47237+-46981))local K=Z%(-512876-(-513132))y(p,M(l,c,K))Z=-637903+637903 end elseif l=="\061"then y(p,M(G(Z/(-926594-(-992130)))))if g>=c or B(e,g+(-816003-(-816004)),g+(256372+-256371))~="\061"then y(p,M(G((Z%(326236+-260700))/(-666823+667079))))end break end g=g+(433243+-433242)end K[l]=N(p)end end end return(function(l,K,G,B,I,M,N,c,Y,p,v,W,g,J,q,O,P,C,h,L,Z,e,z)z,c,O,L,g,p,e,J,q,Y,P,W,h,v,Z,C={},function(c,G,B,I)local e,v,n,S,r,i,U,Q,H,D,o,Z,d,V,w,N,A,T,s,h,X,u,R,g,x,b,k,m,t,F,f,a,j,E while c do if c<-998797+9161553 then if c<685498+4141878 then if c<901723+1014102 then if c<2288681-1032415 then if c<-135158-(-837589)then if c<374204+-40233 then if c<508509-328253 then if c<-207605+374234 then N=z[B[-534196+534201]]d=y(264882-304319)Z=z[B[915633+-915631]]v=z[B[237406-237403]]Q=-818851+23531046627696 h=v(d,Q)g=Z[h]c=N[g]c=c and 4460336-(-210710)or 12501329-(-226295)else T=-827069+32947206068907 c=758023+3061900 h=z[B[611831+-611830]]j=y(771233+-810659)d=z[B[-780645-(-780647)]]Q=d(j,T)v=h[Q]Z=e[v]g=not Z N=g end else c=j and 4892397-(-144720)or 879286+8486541 end else if c<1044583-705287 then d=y(833545+-872868)h=l[d]F=-24368+23006859659529 Q=z[v]j=z[g]r=y(-312704-(-273366))T=j(r,F)r=-325569+598520101079 d=Q[T]s=21568591716010-440175 u=y(436805+-476119)Z=h[d]T=y(-185321-(-145880))d=z[v]Q=z[g]j=Q(T,r)h=d[j]f=118971+7618937437472 r=27013163584813-121867 d={}T=y(-339731+300420)Z[h]=d d=z[v]n=31885003188053-(-21162)Q=z[g]j=Q(T,r)h=d[j]Q=y(777139+-816420)d=l[Q]T=z[v]a=y(-692895+653481)r=z[g]Q=y(-674674-(-635241))Q=d[Q]F=r(u,s)u=19590140429415-(-794427)j=T[F]Q=Q(d,j)H=y(-623899+584596)j=z[v]F=y(918411-957781)T=z[g]r=T(F,u)d=j[r]T=y(-1036467+997186)j=l[T]w=y(-775781+736308)k=y(-891404+851968)F=z[v]T=y(478511-517944)u=z[g]s=u(k,f)r=F[s]E=-407632+22079646179449 i=25589974063367-551547 T=j[T]k=-388703+13845150730126 T=T(j,r)r=z[v]F=z[g]s=y(-412197+372819)u=F(s,k)F=y(-143400+104119)j=r[u]r=l[F]F=y(628023-667456)F=r[F]s=z[v]k=z[g]f=k(w,E)u=s[f]F=F(r,u)u=z[v]s=z[g]f=y(-184810+145335)w=230677+10761188085374 k=s(f,w)r=u[k]s=y(-945392+906111)u=l[s]f=z[v]w=z[g]E=w(H,n)k=f[E]s=y(-894983-(-855550))E=y(445383-484685)s=u[s]H=-147728+5785331108758 s=s(u,k)k=z[v]f=z[g]w=f(E,H)f=y(-344058-(-304777))u=k[w]k=l[f]E=z[v]H=z[g]n=H(a,i)w=E[n]f=y(409659+-449092)f=k[f]f=f(k,w)Z={[h]=Q;[d]=T,[j]=F,[r]=s,[u]=f}s=31283711388184-(-1019599)u=y(390475+-429794)h=p()z[h]=Z w=17279049224812-815870 Q=z[h]T=z[v]r=z[g]f=y(-652499+613089)F=r(u,s)j=T[F]d=Q[j]j=z[v]T=z[g]u=99310483520-1030162 F=y(-137975+98535)r=T(F,u)Q=j[r]Z=d[Q]d=p()u=y(4418+-43868)z[d]=Z j=y(137889-177212)Q=l[j]s=-769430+14172152108893 T=z[v]r=z[g]F=r(u,s)j=T[F]Z=Q[j]F=y(559925-599248)Q=p()z[Q]=Z r=l[F]u=z[v]s=z[g]k=s(f,w)F=u[k]f=13273695282889-(-422236)T=r[F]k=y(-936826+897493)F=z[v]u=z[g]s=u(k,f)r=F[s]j=T[r]Z=not j c=Z and 7755095-(-681051)or 93461+9843283 else c=z[B[-786718+786719]]g=Z j=247226-247226 T=842050-841795 Q=c(j,T)c=-387333+13881188 e[g]=Q g=nil end end else if c<193607-(-953707)then if c<1033931+-214031 then v=y(-212280-(-172994))c=z[B[765931+-765926]]j=-284540+13660111122516 e=z[B[-184277+184280]]T=y(-566553-(-527124))Q=y(728864-768185)g=z[B[-98175+98179]]h=28419729910345-145048 Z=g(v,h)N=e[Z]g=z[B[-56958+56964]]v=z[B[295648-295645]]h=z[B[341080-341076]]d=h(Q,j)Z=v[d]j=9346854392182-573558 e=g[Z]g=y(74427+-113833)g=e[g]v=z[B[987171+-987168]]Q=y(74706-114108)h=z[B[-641441-(-641445)]]d=h(Q,j)Z=v[d]g=g(e,Z)Z=Y(691598+8779239,{B[9713-9706]})e=y(-160809+121402)e=g[e]e=e(g,Z)c[N]=e N=y(-846650+807228)c=l[N]v=z[B[657753+-657747]]r=28850945902383-922293 d=z[B[-783289+783292]]Q=z[B[-476560-(-476564)]]j=Q(T,r)h=d[j]Z=v[h]d=z[B[1501-1498]]r=8928073500320-(-100765)T=y(756746+-796034)Q=z[B[326312+-326308]]j=Q(T,r)h=d[j]d=y(602704-642019)d=Z[d]v={d(Z,h)}Z={c(K(v))}g=Z[532460+-532457]N=Z[638060-638059]c=427893+14851457 e=Z[218360+-218358]Z=N else X=F==u o=X c=5413405-(-7273)end else if c<-798378+2007875 then c=C(15525013-552080,{v})X={c()}N={K(X)}c=l[y(500262-539611)]else X=z[g]o=X c=X and 724660+228329 or 237866+5182812 end end end else if c<751361-(-934188)then if c<2001194-597935 then if c<606943+721952 then if c<639816-(-641646)then k=f H=k s[k]=H c=13643331-(-716978)k=nil else g=z[B[-908402+908403]]j=1041833+25596790753510 Q=y(843121+-882538)v=z[B[557552+-557550]]h=z[B[-538420+538423]]d=h(Q,j)Z=v[d]e=g[Z]Z=z[B[-924952-(-924954)]]d=y(-922605+883314)Q=5213134360058-869503 v=z[B[221575+-221572]]h=v(d,Q)g=Z[h]N=e[g]c=not N c=c and-847093+6438559 or 16437784-303224 end else c=l[y(811786-851180)]N={}end else if c<115186+1496714 then Z=-766681-(-766774)g=z[B[725055-725053]]e=g*Z g=15254526006079-(-116864)N=e+g e=515592+35184371573240 c=N%e g=-321571+321572 z[B[348111+-348109]]=c e=z[B[-671746-(-671749)]]N=e~=g c=-648282+12100422 else c=l[y(-69918-(-30532))]N={g}end end else if c<318707+1581543 then if c<1519999-(-225446)then c=N and 10820454-187955 or 573226+12322270 else e=nil c=l[y(-107218+67820)]g=nil N={}end else if c<3833+1902975 then r=500170-500167 T=p()z[T]=N F=627861+-627796 k=Y(7642287-321114,{})c=z[Q]s=y(-843486+804190)N=c(r,F)c=299301+-299301 F=c r=p()z[r]=N N=l[s]s={N(k)}c=-259624+259624 u=c c={K(s)}s=c N=73893+-73891 c=s[N]N=y(325006+-364377)k=c c=l[N]m=y(-898853-(-859546))f=z[Z]X=l[m]m=X(k)X=y(45269-84641)o=f(m,X)f={o()}N=c(K(f))f=p()z[f]=N c=6457832-423323 N=-148608+148609 o=z[r]X=o o=-295359-(-295360)m=o o=880689+-880689 w=m<o o=N-m else N=T c=r c=T and-1031536+2937616 or 9216101-(-95307)end end end end else if c<4066976-1035944 then if c<564650+1759377 then if c<1512458-(-442250)then if c<129389+1816190 then if c<1267219-(-657268)then c=true c=c and-1037000+8237927 or 6865257-(-33952)else r=r+F s=not u j=r<=T j=s and j s=r>=T s=u and s j=s or j s=8198085-(-714047)c=j and s j=223422+6060310 c=c or j end else F=582644-582631 Z=204129+-204097 g=z[B[-953628+953631]]e=g%Z v=z[B[538713-538709]]Q=z[B[-956943-(-956945)]]k=z[B[655120+-655117]]T=500275+-500273 s=k-e k=386393+-386361 u=s/k r=F-u j=T^r d=Q/j h=v(d)v=4294521767-(-445529)Z=h%v j=735316-735315 h=990677+-990675 v=h^e T=-533268+533524 g=Z/v v=z[B[287329-287325]]c=164403+7960866 Q=g%j F=-1016522+1016778 j=4295648814-681518 d=Q*j h=v(d)v=z[B[5054-5050]]d=v(g)Z=h+d h=937990-872454 v=Z%h Q=-822043+887579 d=Z-v h=d/Q Q=-327798+328054 d=v%Q j=v-d Q=j/T T=64033-63777 Z=nil v=nil j=h%T g=nil e=nil r=h-j T=r/F r={d,Q,j,T}T=nil j=nil z[B[822750+-822749]]=r h=nil Q=nil d=nil end else if c<350691+1803085 then N=b c=D c=-447783+7774109 else A=885142-885141 z[g]=b t=z[n]x=t+A R=U[x]D=F+R R=1036348-1036092 c=D%R F=c x=z[H]R=u+x x=849629+-849373 D=R%x u=D c=16628144-466574 end end else if c<2361050-(-514265)then if c<1694763-(-968303)then c=-534313+12340651 T=35143195306416-(-1037884)h=z[B[973962-973960]]d=z[B[865677-865674]]Z=y(522685+-562152)Z=e[Z]j=y(918144-957612)Q=d(j,T)v=h[Q]Z=Z(e,v)g=Z else c=true z[B[-143719+143720]]=c N={}c=l[y(-441426+402132)]end else if c<707168+2298183 then v=-481941-(-481942)g=z[B[156525+-156524]]h=309159+-309157 Z=g(v,h)g=-97567-(-97568)e=Z==g c=e and 1120564-(-585387)or 8031740-(-191566)N=e else c=500002+12041957 T=O(T)end end end else if c<620305+3328686 then if c<2726929-(-1031376)then if c<2864003-(-396894)then g=z[B[-423107-(-423112)]]v=z[B[-908414+908416]]Q=y(-772786+733431)h=z[B[177827+-177824]]j=28452942989296-(-420817)d=h(Q,j)Z=v[d]N=g[Z]c=not N c=c and 281023+3554261 or 6685465-661133 else R=y(946756+-986078)f=22242581250979-(-894162)k=y(134222+-173683)F=z[v]u=z[g]s=u(k,f)u=q(5590923-718665,{j;v,g;Z})r=F[s]F=p()E=y(-926649-(-887326))s=J(754238+6483876,{v,g,Z,F})z[F]=r r=p()z[r]=u u=p()z[u]=s s=p()k=q(16582810-18915,{r,Q,v,g;j,h,u})f=p()z[s]=k k=-101198-(-101198)H=y(-655966+616658)z[f]=k w=P(1387849-105656,{Q;v;g,T,f;d,h})k=p()x=472014+16766402996913 z[k]=w E=l[E]n=E[H]w=J(-1044125+11558522,{Q;v;g;s,j;h;k})E=y(-457543-(-418161))H=n[E]E=y(246963+-286354)H[E]=w w=q(-659419+14488143,{s})E=y(912735-952058)H=y(-178959+139651)n=E[H]E=l[E]E=y(538165-577547)H=n[E]E=y(-881583-(-842106))H[E]=w H=z[Q]a=z[v]i=z[g]U=i(R,x)n=a[U]E=H[n]U=y(-253696+214344)n=z[v]a=z[g]R=33211592953306-(-470671)i=a(U,R)H=n[i]w=E[H]c=w and 12472093-878913 or 13864655-(-908156)end else if c<1009910+2810777 then c=N and-416740+11649919 or 6805928-28937 else c=z[B[407146-407141]]h=y(399071-438397)T=y(927144-966476)d=17453208667867-1042204 g=z[B[495064+-495062]]Z=z[B[-393475-(-393478)]]v=Z(h,d)N=g[v]v=z[B[-58399-(-58405)]]r=-530809+3654205399070 d=z[B[-584574-(-584576)]]Q=z[B[-148790-(-148793)]]j=Q(T,r)h=d[j]Z=v[h]j=y(628718-668167)h=z[B[-584070+584072]]d=z[B[-775719+775722]]T=-968062+31268242456158 Q=d(j,T)v=h[Q]g=Z[v]v=z[B[372969+-372962]]Z=y(826052+-865459)Z=g[Z]Z=Z(g,v)c[N]=Z c=-772624+6796956 end end else if c<4784698-637583 then if c<3424027-(-699273)then v=z[B[598464-598462]]r=299882+15897277401472 d=z[B[795769+-795766]]T=y(-888257-(-848841))Q=z[B[-411163-(-411167)]]j=Q(T,r)h=d[j]j=y(-998514+959114)Z=v[h]T=15033736834823-(-961617)h=z[B[-528891+528894]]d=z[B[-195238-(-195242)]]Q=d(j,T)v=h[Q]g=Z[v]c=13152682-435076 e=not g N=e else N=y(218675+-257971)c=l[N]e=L(-174018+7514154,{B[532899+-532898];B[-294607-(-294609)];B[629511+-629508];B[-236228-(-236232)]})N=c(e)N={}c=l[y(222927+-262346)]end else if c<-693002+5393833 then Q=-1048099+19551483617715 N=z[B[-743173+743178]]Z=z[B[-208957+208959]]v=z[B[-500414+500417]]d=y(5045+-44388)h=v(d,Q)g=Z[h]c=N[g]h=y(167765+-207241)N=y(16989+-56284)d=11117606464369-(-714952)N=c[N]N=N(c)c=z[B[-929922+929927]]g=z[B[-773846+773848]]Z=z[B[-567793+567796]]v=Z(h,d)N=g[v]g=nil c[N]=g c=-631198+13358822 else f=#s c=329980+11901614 w=871881+-871881 k=f==w end end end end end else if c<-816506+7715972 then if c<5659762-(-348069)then if c<5327331-211400 then if c<5174936-171205 then if c<-200995+5170253 then if c<4197294-(-675533)then N=z[B[863182+-863181]]g=z[B[362140-362138]]h=y(-852178+812763)d=18775053550649-(-351725)Z=z[B[-862291-(-862294)]]v=Z(h,d)e=g[v]c=N[e]c=c and 11217436-(-959083)or 7791119-(-437632)else e=y(-352939+313559)c=l[e]Z=331672+-331672 g=z[B[-492738-(-492746)]]e=c(g,Z)c=14655359-792077 end else c=-334298+1979145 end else if c<5546476-512134 then D=z[g]b=D c=D and 7389651-(-944962)or 2018976-(-163604)else F=z[B[-265524-(-265526)]]X=4742033892616-171112 u=z[B[418221-418218]]o=y(-806292-(-766934))k=y(624424+-663883)f=24657867220212-(-608230)s=u(k,f)r=F[s]T=g[r]s=z[B[841706-841704]]k=z[B[-142791--- gui/main_window.lua
-- Creates the main GUI window, sidebar, tabs, and status indicator.
-- Handles tab switching and menu visibility.

local Services = Mega.Services
local Settings = Mega.Settings
local States = Mega.States
local GetText = Mega.GetText

-- Forward declaration for callbacks
local ReloadGUI

-- Main GUI container
local TumbaGUI = Instance.new("ScreenGui")
TumbaGUI.Name = "TumbaMegaSystem"
TumbaGUI.Parent = Services.CoreGui
TumbaGUI.Enabled = false
TumbaGUI.ResetOnSpawn = false
Mega.Objects.GUI = TumbaGUI

-- Draggable Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 1100, 0, 650)
MainFrame.Position = UDim2.new(0.5, -550, 0.5, -325)
MainFrame.BackgroundColor3 = Settings.Menu.BackgroundColor
MainFrame.BackgroundTransparency = Settings.Menu.Transparency
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = false
MainFrame.Parent = TumbaGUI
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, Settings.Menu.CornerRadius)

-- UI Stroke (Border Glow)
local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Settings.Menu.AccentColor
MainStroke.Transparency = 0.2
MainStroke.Parent = MainFrame

-- Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.Position = UDim2.new(0, -20, 0, -20)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://1316045217"
Shadow.ImageColor3 = Settings.Menu.AccentColor
Shadow.ImageTransparency = 0.7
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
Shadow.ZIndex = 0
Shadow.Parent = MainFrame

-- Background Gradient
local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Settings.Menu.BackgroundColor), ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 45)) }
MainGradient.Rotation = 135
MainGradient.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 55)
TitleBar.BackgroundColor3 = Settings.Menu.TitleBarColor
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, Settings.Menu.CornerRadius)

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Settings.Menu.AccentColor), ColorSequenceKeypoint.new(1, Settings.Menu.SecondaryColor) }
TitleGradient.Rotation = 90
TitleGradient.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = GetText("title_bar", Mega.VERSION)
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextStrokeTransparency = 0.7
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Controls (Close/Minimize)
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 38, 0, 38)
CloseButton.Position = UDim2.new(1, -48, 0.5, -19)
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TitleBar
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 10)
CloseButton.MouseButton1Click:Connect(function() TumbaGUI.Enabled = false end)

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 38, 0, 38)
MinimizeButton.Position = UDim2.new(1, -90, 0.5, -19)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
MinimizeButton.Text = "—"
MinimizeButton.TextColor3 = Color3.new(1, 1, 1)
MinimizeButton.TextSize = 20
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Parent = TitleBar
Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 10)

-- Sidebar & Content
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 200, 1, -65)
Sidebar.Position = UDim2.new(0, 10, 0, 60)
Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Sidebar.BackgroundTransparency = 0.3
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

local TabContainer = Instance.new("ScrollingFrame")
TabContainer.Size = UDim2.new(1, -10, 1, -10)
TabContainer.Position = UDim2.new(0, 5, 0, 5)
TabContainer.BackgroundTransparency = 1
TabContainer.BorderSizePixel = 0
TabContainer.ScrollBarThickness = 0
TabContainer.Parent = Sidebar
local TabListLayout = Instance.new("UIListLayout", TabContainer)
TabListLayout.Padding = UDim.new(0, 3)

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -230, 1, -70)
ContentContainer.Position = UDim2.new(0, 220, 0, 60)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame
Mega.Objects.ContentContainer = ContentContainer

-- Minimize Logic
local isMinimized = false
local originalSize = MainFrame.Size
local miniSize = UDim2.new(0, 220, 0, 55)
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local targetSize = isMinimized and miniSize or originalSize
    Services.TweenService:Create(MainFrame, TweenInfo.new(0.3), { Size = targetSize }):Play()
    Sidebar.Visible = not isMinimized
    ContentContainer.Visible = not isMinimized
    Shadow.Visible = not isMinimized
    MinimizeButton.Text = isMinimized and "❐" or "—"
end)

-- Tab System
local TabKeys = { "tab_home", "tab_updates", "tab_esp", "tab_aim", "tab_player", "tab_combat", "tab_visuals", "tab_farm", "tab_users", "tab_utils", "tab_settings" }
local TabButtons = {}
Mega.Objects.TabFrames = {}

local function SelectTab(tabKey, tabButton)
    -- De-select all other buttons
    for k, btn in pairs(TabButtons) do
        Services.TweenService:Create(btn, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(25, 30, 40),
            BackgroundTransparency = 0.3,
            TextColor3 = Color3.fromRGB(180, 180, 200)
        }):Play()
    end
    -- Select the current button
    Services.TweenService:Create(tabButton, TweenInfo.new(0.3), {
        BackgroundColor3 = Settings.Menu.AccentColor,
        BackgroundTransparency = 0,
        TextColor3 = Color3.new(1, 1, 1)
    }):Play()

    -- Hide all other frames
    for k, frame in pairs(Mega.Objects.TabFrames) do
        frame.Visible = false
    end

    -- Load module if it's the first time
    local modulePath = "gui/tabs/" .. tabKey:gsub("^tab_", "") .. ".lua"
    if not Mega.LoadedModules[modulePath] then
        Mega.LoadModule(modulePath)
    end
    
    -- Show the frame for this tab
    if Mega.Objects.TabFrames[tabKey] then
        Mega.Objects.TabFrames[tabKey].Visible = true
    end

    Title.Text = GetText("title_bar_with_tab", GetText(tabKey))
end

for _, tabKey in ipairs(TabKeys) do
    local tabName = GetText(tabKey)
    local TabButton = Instance.new("TextButton", TabContainer)
    TabButton.Name = tabKey
    TabButton.Size = UDim2.new(1, -10, 0, 42)
    TabButton.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    TabButton.BackgroundTransparency = 0.3
    TabButton.Text = tabName
    TabButton.TextColor3 = Color3.fromRGB(180, 180, 200)
    TabButton.TextSize = 14
    TabButton.Font = Enum.Font.GothamBold
    TabButton.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 6)
    Instance.new("UIPadding", TabButton).PaddingLeft = UDim.new(0, 15)
    
    TabButton.MouseButton1Click:Connect(function() SelectTab(tabKey, TabButton) end)
    TabButtons[tabKey] = TabButton
end

-- Select the first tab by default
task.wait(0.1)
SelectTab("tab_home", TabButtons["tab_home"])

-- Menu Toggle Logic
Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode.Name == States.Keybinds.Menu then
        TumbaGUI.Enabled = not TumbaGUI.Enabled
    end
end)

-- Status Indicator GUI
local StatusGUI = Instance.new("ScreenGui", Services.CoreGui)
StatusGUI.Name = "TumbaStatusIndicator"
StatusGUI.ResetOnSpawn = false
StatusGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local StatusIndicator = Instance.new("Frame", StatusGUI)
StatusIndicator.Name = "StatusList"
StatusIndicator.Size = UDim2.new(0, 200, 1, 0)
StatusIndicator.Position = UDim2.new(1, -210, 0, 10)
StatusIndicator.BackgroundTransparency = 1
local StatusLayout = Instance.new("UIListLayout", StatusIndicator)
StatusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
StatusLayout.SortOrder = Enum.SortOrder.LayoutOrder
StatusLayout.Padding = UDim.new(0, 4)

local Watermark = Instance.new("TextLabel", StatusIndicator)
Watermark.Name = "Watermark"
Watermark.Text = "TUMBA SYSTEM"
Watermark.Font = Enum.Font.GothamBlack
Watermark.TextSize = 22
Watermark.TextColor3 = Settings.Menu.AccentColor
Watermark.Size = UDim2.new(1, 0, 0, 30)
Watermark.BackgroundTransparency = 1
Watermark.TextXAlignment = Enum.TextXAlignment.Right
Watermark.LayoutOrder = -1
Instance.new("UIStroke", Watermark).Thickness = 2

-- Function to update the status list (will be called by features)
function Mega.UpdateStatus()
    if not Settings.System.ShowStatusIndicator then
        StatusIndicator.Visible = false
        return
    end
    StatusIndicator.Visible = true

    if Settings.StatusIndicator.RainbowMode then
        Watermark.TextColor3 = Color3.fromHSV((tick() % 5) / 5, 0.8, 1)
    else
        Watermark.TextColor3 = Settings.Menu.AccentColor
    end

    for _, child in pairs(StatusIndicator:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local activeCount = 0
    local function AddStatus(text, color)
        local item = Instance.new("Frame", StatusIndicator)
        item.Size = UDim2.new(0, Services.TextService:GetTextSize(text, 14, Enum.Font.GothamBold).X + 24, 0, 28)
        item.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        item.BackgroundTransparency = 0.3
        item.LayoutOrder = activeCount
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 4)
        
        local bar = Instance.new("Frame", item)
        bar.Size = UDim2.new(0, 3, 1, 0)
        bar.Position = UDim2.new(1, -3, 0, 0)
        bar.BackgroundColor3 = color or Settings.Menu.AccentColor
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel", item)
        label.Size = UDim2.new(1, -10, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.new(1,1,1)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Right
        Instance.new("UIStroke", label).Thickness = 1
        activeCount = activeCount + 1
    end

    if States.ESP.Enabled then AddStatus("ESP", Settings.Menu.SecondaryColor) end
    if States.KitESP.Enabled then AddStatus("Kit ESP", Color3.fromRGB(255, 165, 0)) end
    if States.AimAssist.Enabled then AddStatus("Aim Assist", Settings.Menu.AccentColor) end
    if States.Player.Speed then AddStatus("Speed", Color3.fromRGB(255, 220, 0)) end
    if States.Player.Fly then AddStatus("Fly", Color3.fromRGB(100, 200, 255)) end
    if States.Player.NoClip then AddStatus("NoClip", Color3.fromRGB(150, 255, 150)) end
end

-- Auto-update status-- gui/tabs/aim.lua
-- Content for the "AIM" tab

local tabKey = "tab_aim"
local UI = Mega.UI

-- Create the container frame for this tab
local TabFrame = Instance.new("ScrollingFrame")
TabFrame.Name = tabKey
TabFrame.Size = UDim2.new(1, 0, 1, 0)
TabFrame.BackgroundTransparency = 1
TabFrame.BorderSizePixel = 0
TabFrame.ScrollBarThickness = 4
TabFrame.ScrollBarImageColor3 = Mega.Settings.Menu.AccentColor
TabFrame.Visible = false
TabFrame.Parent = Mega.Objects.ContentContainer

local ContentLayout = Instance.new("UIListLayout", TabFrame)
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 8)

-- Add this frame to the global list of tab frames
Mega.Objects.TabFrames[tabKey] = TabFrame

--#region -- Main Aim Settings
UI.CreateSection(TabFrame, "section_aim_main")

UI.CreateToggle(TabFrame, "toggle_aim", "AimAssist.Enabled", function(state)
    -- The actual aimbot logic will be in features/aimbot.lua
    -- and will be controlled by this state change.
    if Mega.Features.Aimbot then
        Mega.Features.Aimbot.SetEnabled(state)
    end
end)
--#endregion

--#region -- Parameter Settings
UI.CreateSection(TabFrame, "section_aim_settings")

UI.CreateToggle(TabFrame, "toggle_aim_show_fov", "AimAssist.ShowFOV")
UI.CreateToggle(TabFrame, "toggle_aim_silent", "AimAssist.SilentAim")
UI.CreateToggle(TabFrame, "toggle_aim_prediction", "AimAssist.Prediction")

UI.CreateSlider(TabFrame, "slider_aim_fov", "AimAssist.FOV", 10, 500)
UI.CreateSlider(TabFrame, "slider_aim_smooth", "AimAssist.Smoothness", 0, 100, function(val)
    Mega.States.AimAssist.Smoothness = val / 100 -- Convert from 0-100 to 0-1
end)
UI.CreateSlider(TabFrame, "slider_aim_range", "AimAssist.Range", 10, 1000)

UI.CreateDropdown(TabFrame, "dropdown_aim_target", "AimAssist.TargetPart", {
    "dropdown_aim_target_head",
    "dropdown_aim_target_upper",
    "dropdown_aim_target_lower",
    "dropdown_aim_target_root"
}, function(val)
    local partMap = {
        dropdown_aim_target_head = "Head",
        dropdown_aim_target_upper = "UpperTorso",
        dropdown_aim_target_lower = "LowerTorso",
        dropdown_aim_target_root = "HumanoidRootPart"
    }
    Mega.States.AimAssist.TargetPart = partMap[val] or "Head"
end, true) -- true indicates options are localization keys

UI.CreateButton(TabFrame, "button_aim_fov_color", function() Mega.ShowNotification("Color pickers are not implemented yet.", 3) end)
--#endregion
-- gui/tabs/combat.lua
-- Content for the "COMBAT" tab

local tabKey = "tab_combat"
local UI = Mega.UI

-- Create the container frame for this tab
local TabFrame = Instance.new("ScrollingFrame")
TabFrame.Name = tabKey
TabFrame.Size = UDim2.new(1, 0, 1, 0)
TabFrame.BackgroundTransparency = 1
TabFrame.BorderSizePixel = 0
TabFrame.ScrollBarThickness = 4
TabFrame.ScrollBarImageColor3 = Mega.Settings.Menu.AccentColor
TabFrame.Visible = false
TabFrame.Parent = Mega.Objects.ContentContainer

local ContentLayout = Instance.new("UIListLayout", TabFrame)
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 0)

-- Add this frame to the global list of tab frames
Mega.Objects.TabFrames[tabKey] = TabFrame

--#region -- Automation
UI.CreateSection(TabFrame, "section_combat_auto")

UI.CreateToggle(TabFrame, "toggle_triggerbot", "Combat.TriggerBot")
UI.CreateToggle(TabFrame, "toggle_autoshoot", "Combat.AutoShoot")
UI.CreateToggle(TabFrame, "toggle_rapidfire", "Combat.RapidFire")
--#endregion

--#region -- Accuracy
UI.CreateSection(TabFrame, "section_combat_accuracy")

UI.CreateToggle(TabFrame, "toggle_norecoil", "Combat.NoRecoil")
UI.CreateToggle(TabFrame, "toggle_nospread", "Combat.NoSpread")
--#endregion

--#region -- Killaura
UI.CreateSection(TabFrame, "section_combat_killaura")

UI.CreateToggleWithSettings(TabFrame, "toggle_killaura", "Combat.Killaura.Enabled", nil, {
    UI.CreateSlider(nil, "slider_killaura_range", "Combat.Killaura.Range", 5, 100),
    UI.CreateSlider(nil, "slider_killaura_delay", "Combat.Killaura.Delay", 0, 1000),
    UI.CreateKeybindButton(nil, "keybind_killaura", "Keybinds.Killaura")
})
--#endregion
-- gui/tabs/esp.lua
-- Content for the "ESP" tab

local tabKey = "tab_esp"
local UI = Mega.UI

-- Create the container frame for this tab
local TabFrame = Instance.new("ScrollingFrame")
TabFrame.Name = tabKey
TabFrame.Size = UDim2.new(1, 0, 1, 0)
TabFrame.BackgroundTransparency = 1
TabFrame.BorderSizePixel = 0
TabFrame.ScrollBarThickness = 4
TabFrame.ScrollBarImageColor3 = Mega.Settings.Menu.AccentColor
TabFrame.Visible = false
TabFrame.Parent = Mega.Objects.ContentContainer

local ContentLayout = Instance.new("UIListLayout", TabFrame)
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 0)

Mega.Objects.TabFrames[tabKey] = TabFrame

-- Load the actual ESP logic feature module
Mega.LoadModule("features/esp.lua")

--#region -- Main Player ESP
UI.CreateSection(TabFrame, "section_esp_main")

UI.CreateToggleWithSettings(TabFrame, "toggle_esp", "ESP.Enabled", function(state)
    if Mega.Features.ESP then
        Mega.Features.ESP.SetEnabled(state)
    end
end, {
    UI.CreateSection(nil, "section_esp_visuals"),
    UI.CreateToggle(nil, "toggle_esp_boxes", "ESP.Boxes"),
    UI.CreateToggle(nil, "toggle_esp_names", "ESP.Names"),
    UI.CreateToggle(nil, "toggle_esp_health", "ESP.Health"),
    UI.CreateToggle(nil, "toggle_esp_distance", "ESP.Distance"),
    UI.CreateToggle(nil, "toggle_esp_tracers", "ESP.Tracers"),
    UI.CreateToggle(nil, "toggle_esp_team", "ESP.ShowTeam"),
    UI.CreateSlider(nil, "slider_esp_max_dist", "ESP.MaxDistance", 50, 2000),
    UI.CreateSection(nil, "section_esp_colors"),
    UI.CreateButton(nil, "button_team_color", function() Mega.ShowNotification("Color pickers are not implemented yet.", 3) end),
    UI.CreateButton(nil, "button_enemy_color", function() Mega.ShowNotification("Color pickers are not implemented yet.", 3) end)
})
--#endregion


--#region -- Kit ESP
UI.CreateSection(TabFrame, "section_kit_esp")

UI.CreateToggleWithSettings(TabFrame, "toggle_kit_esp", "KitESP.Enabled", function(state)
    if Mega.Features.ESP then
        Mega.Features.ESP.SetKitEnabled(state)
    end
    Mega.ShowNotification(Mega.GetText(state and "notify_kit_esp_on" or "notify_kit_esp_off"))
end, {
    UI.CreateSection(nil, "section_kit_filters"),
    UI.CreateToggle(nil, "toggle_kit_iron", "KitESP.Filters.Iron"),
    UI.CreateToggle(nil, "toggle_kit_bee", "KitESP.Filters.Bee"),
    UI.CreateToggle(nil, "toggle_kit_thorns", "KitESP.Filters.Thorns"),
    UI.CreateToggle(nil, "toggle_kit_mushrooms", "KitESP.Filters.Mushrooms"),
    UI.CreateToggle(nil, "toggle_kit_sorcerer", "KitESP.Filters.Sorcerer"),
    UI.CreateButton(nil, "button_kit_esp_apply", function()
        if Mega.Features.ESP then
            Mega.Features.ESP.RecreateKitESP()
        end-- gui/tabs/farm.lua
-- Content for the "KIT" (Farm) tab

local tabKey = "tab_farm"
local UI = Mega.UI

-- Ensure states exist to prevent errors (Fallback defaults)
if not Mega.States.Beekeeper then Mega.States.Beekeeper = { Enabled = false, ShowIcons = true, ShowHighlight = true, ShowHiveLevels = false, AutoCatch = false } end
if not Mega.States.Cletus then Mega.States.Cletus = { Enabled = false, Range = 20, AutoHarvest = false, ESP = false, ESPTransparency = 0.75 } end
if not Mega.States.Eldertree then Mega.States.Eldertree = { Enabled = false, Range = 30, ESP = false } end
if not Mega.States.StarCollector then Mega.States.StarCollector = { Enabled = false, Range = 60, ESP = false } end
if not Mega.States.Metal then Mega.States.Metal = { Enabled = false, ESP = true, AutoCollect = false, Range = 25 } end
if not Mega.States.Taliah then Mega.States.Taliah = { Enabled = false, ESP = false, ESPTransparency = 0.2, AutoCollect = false, CollectRadius = 5 } end
if not Mega.States.Fisherman then Mega.States.Fisherman = { Enabled = false } end
if not Mega.States.Noelle then Mega.States.Noelle = { Enabled = false, SaveBinds = false, Binds = {} } end

-- Load feature modules for this tab
Mega.LoadModule("features/beekeeper.lua")
Mega.LoadModule("features/farmer_cletus.lua")
Mega.LoadModule("features/eldertree.lua")

-- Create the container frame for this tab
local TabFrame = Instance.new("ScrollingFrame")
TabFrame.Name = tabKey
TabFrame.Size = UDim2.new(1, 0, 1, 0)
TabFrame.BackgroundTransparency = 1
TabFrame.BorderSizePixel = 0
TabFrame.ScrollBarThickness = 4
TabFrame.ScrollBarImageColor3 = Mega.Settings.Menu.AccentColor
TabFrame.Visible = false
TabFrame.Parent = Mega.Objects.ContentContainer

local ContentLayout = Instance.new("UIListLayout", TabFrame)
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 0)

Mega.Objects.TabFrames[tabKey] = TabFrame

--#region -- Beekeeper
UI.CreateToggleWithSettings(TabFrame, "toggle_beekeeper", "Beekeeper.Enabled", function(state)
    if Mega.Features.Beekeeper then
        Mega.Features.Beekeeper.SetEnabled(state)
    end
end, {
    UI.CreateToggle(nil, "toggle_bee_icons", "Beekeeper.ShowIcons", function() if Mega.Features.Beekeeper then Mega.Features.Beekeeper.UpdateVisuals() end end),
    UI.CreateToggle(nil, "toggle_bee_highlight", "Beekeeper.ShowHighlight", function() if Mega.Features.Beekeeper then Mega.Features.Beekeeper.UpdateVisuals() end end),
    UI.CreateToggle(nil, "toggle_hive_levels", "Beekeeper.ShowHiveLevels", function() if Mega.Features.Beekeeper then Mega.Features.Beekeeper.UpdateVisuals() end end),
    UI.CreateToggle(nil, "toggle_auto_catch", "Beekeeper.AutoCatch")
})
--#endregion

--#region -- Cletus
UI.CreateToggleWithSettings(TabFrame, "toggle_cletus", "Cletus.Enabled", function(state)
    if Mega.Features.Cletus then
        Mega.Features.Cletus.SetEnabled(state)
    end
end, {
    UI.CreateToggle(nil, "toggle_cletus_harvest", "Cletus.AutoHarvest"),
    UI.CreateToggle(nil, "toggle_cletus_esp", "Cletus.ESP", function() if Mega.Features.Cletus then Mega.Features.Cletus.RecreateESP() end end),
    UI.CreateSlider(nil, "slider_cletus_range", "Cletus.Range", 5, 100),
    UI.CreateSlider(nil, "slider_cletus_esp_transparency", "Cletus.ESPTransparency", 0, 100, function(v) Mega.States.Cletus.ESPTransparency = v/100; if Mega.Features.Cletus then Mega.Features.Cletus.UpdateVisuals() end end)
})
--#endregion

--#region -- Eldertree
UI.CreateToggleWithSettings(TabFrame, "toggle_eldertree", "Eldertree.Enabled", function(state)
    if Mega.Features.Eldertree then
        Mega.Features.Eldertree.SetEnabled(state)
    end
end, {
    UI.CreateToggle(nil, "toggle_eldertree_esp", "Eldertree.ESP", function()
        if Mega.Features.Eldertree then Mega.Features.Eldertree.UpdateESP() end
    end),
    UI.CreateSlider(nil, "slider_eldertree_range", "Eldertree.Range", 5, 100)
})
--#endregion

--#region -- Star Collector
UI.CreateToggleWithSettings(TabFrame, "toggle_star_collector", "StarCollector.Enabled", nil, {
    UI.CreateToggle(nil, "toggle_star_collector_esp", "StarCollector.ESP"),
    UI.CreateSlider(nil, "slider_star_collector_range", "StarCollector.Range", 5, 100)
})
--#endregion

--#region -- Metal Detector
UI.CreateToggleWithSettings(TabFrame, "toggle_metal", "Metal.Enabled", nil, {
    UI.CreateToggle(nil, "toggle_metal_esp", "Metal.ESP"),
    UI.CreateToggle(nil, "toggle_metal_collect", "Metal.AutoCollect"),
    UI.CreateSlider(nil, "slider_metal_range", "Metal.Range", 5, 100)
})
--#endregion

--#region -- Taliah
UI.CreateToggleWithSettings(TabFrame, "toggle_taliah", "Taliah.Enabled", nil, {
    UI.CreateToggle(nil, "toggle_taliah_esp", "Taliah.ESP"),
    UI.CreateToggle(nil, "toggle_taliah_collect", "Taliah.AutoCollect"),
    UI.CreateSlider(nil, "slider_taliah_radius", "Taliah.CollectRadius", 5, 50),
    UI.CreateSlider(nil, "slider_taliah_esp_transparency", "Taliah.ESPTransparency", 0, 100, function(v) Mega.States.Taliah.ESPTransparency = v/100 end)
})
--#endregion

--#region -- Fisherman
UI.CreateSection(TabFrame, "toggle_fisherman")
UI.CreateToggle(TabFrame, "toggle_autofish", "Fisherman.Enabled")
--#endregion

--#region -- Noelle
UI.CreateSection(TabFrame, "noelle_title")-- gui/tabs/home.lua
-- Content for the "HOME" tab

local tabKey = "tab_home"
local UI = Mega.UI
local GetText = Mega.GetText

-- Create the container frame for this tab
local TabFrame = Instance.new("ScrollingFrame")
TabFrame.Name = tabKey
TabFrame.Size = UDim2.new(1, 0, 1, 0)
TabFrame.BackgroundTransparency = 1
TabFrame.BorderSizePixel = 0
TabFrame.ScrollBarThickness = 4
TabFrame.ScrollBarImageColor3 = Mega.Settings.Menu.AccentColor
TabFrame.Visible = false
TabFrame.Parent = Mega.Objects.ContentContainer

local ContentLayout = Instance.new("UIListLayout", TabFrame)
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 8)

-- Add this frame to the global list of tab frames
Mega.Objects.TabFrames[tabKey] = TabFrame

--#region -- Updates Section
UI.CreateSection(TabFrame, "section_updates_list")

local UpdateText = Instance.new("TextLabel")
UpdateText.Size = UDim2.new(0.9, 0, 0, 80)
UpdateText.BackgroundTransparency = 1
UpdateText.Text = GetText("update_text_v5_1") .. "\n• [Система] Код полностью реструктурирован для обхода лимита переменных."
UpdateText.TextColor3 = Mega.Settings.Menu.TextColor
UpdateText.TextSize = 13
UpdateText.Font = Enum.Font.Gotham
UpdateText.TextXAlignment = Enum.TextXAlignment.Left
UpdateText.TextYAlignment = Enum.TextYAlignment.Top
UpdateText.TextWrapped = true
UpdateText.Parent = TabFrame
--#endregion

--#region -- Status Section
UI.CreateSection(TabFrame, "section_status")

UI.CreateToggle(TabFrame, "toggle_autosave", "System.AutoSave")
UI.CreateToggle(TabFrame, "toggle_perf_mode", "System.PerformanceMode")
UI.CreateToggle(TabFrame, "toggle_status_indicator", "System.ShowStatusIndicator")
--#endregion

--#region -- Quick Access
UI.CreateSection(TabFrame, "section_quick_access")

UI.CreateButton(TabFrame, "button_esp_toggle", function()
    -- This calls the function created by the toggle in the ESP tab
    if Mega.Objects.Toggles["toggle_esp"] then
        Mega.Objects.Toggles["toggle_esp"](not Mega.States.ESP.Enabled)
    end
end)
UI.CreateButton(TabFrame, "button_aim_toggle", function()
    if Mega.Objects.Toggles["toggle_aim"] then
        Mega.Objects.Toggles["toggle_aim"](not Mega.States.AimAssist.Enabled)
    end
end)
UI.CreateButton(TabFrame, "button_speed_toggle", function()
    if Mega.Objects.Toggles["toggle_speed"] then
        Mega.Objects.Toggles["toggle_speed"](not Mega.States.Player.Speed)
    end
end)
--#endregion

--#region -- Stats
UI.CreateSection(TabFrame, "section_stats")

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(0.9, 0, 0, 100)
StatsLabel.BackgroundTransparency = 1
StatsLabel.TextColor3 = Mega.Settings.Menu.TextColor
StatsLabel.TextSize = 14
StatsLabel.Font = Enum.Font.Gotham
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
StatsLabel.Parent = TabFrame

Mega.Services.RunService.Stepped:Connect(function()
    if TabFrame.Visible then
        StatsLabel.Text = GetText("stats_label", 
            Mega.Database.Stats.Kills, 
            Mega.Database.Stats.Deaths, 
            math.floor(Mega.Database.Stats.PlayTime / 60)
        )
    end-- gui/tabs/player.lua
-- Content for the "PLAYER" tab

local tabKey = "tab_player"
local UI = Mega.UI

-- Create the container frame for this tab
local TabFrame = Instance.new("ScrollingFrame")
TabFrame.Name = tabKey
TabFrame.Size = UDim2.new(1, 0, 1, 0)
TabFrame.BackgroundTransparency = 1
TabFrame.BorderSizePixel = 0
TabFrame.ScrollBarThickness = 4
TabFrame.ScrollBarImageColor3 = Mega.Settings.Menu.AccentColor
TabFrame.Visible = false
TabFrame.Parent = Mega.Objects.ContentContainer

local ContentLayout = Instance.new("UIListLayout", TabFrame)
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 0) -- Padding is handled by the component frame now

Mega.Objects.TabFrames[tabKey] = TabFrame

--#region -- Movement
UI.CreateSection(TabFrame, "section_player_movement")

UI.CreateToggleWithSettings(TabFrame, "toggle_speed", "Player.Speed", nil, {
    UI.CreateSlider(nil, "slider_speed", "Player.SpeedValue", 16, 200)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_fly", "Player.Fly", nil, {
    UI.CreateSlider(nil, "slider_fly_speed", "Player.FlySpeed", 1, 100),
    UI.CreateDropdown(nil, "dropdown_fly_mode", "Player.FlyMode", {"Velocity", "Default"}, function(val)
        Mega.States.Player.FlyMode = val
    end)
})

UI.CreateToggle(TabFrame, "toggle_inf_jump", "Player.InfiniteJump")
UI.CreateToggle(TabFrame, "toggle_nofall", "Player.NoFall")
--#endregion

--#region -- Defense / Utility
UI.CreateSection(TabFrame, "section_player_defense")

UI.CreateToggle(TabFrame, "toggle_godmode", "Player.GodMode")
UI.CreateToggle(TabFrame, "toggle_noclip", "Player.NoClip")

UI.CreateToggleWithSettings(TabFrame, "toggle_antiknockback", "Player.AntiKnockback", nil, {
    UI.CreateSlider(nil, "slider_knockback_strength", "Player.KnockbackStrength", 0, 100)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_spider", "Player.Spider", nil, {
     UI.CreateSlider(nil, "slider_spider_speed", "Player.SpiderSpeed", 1, 50)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_scaffold", "Player.Scaffold.Enabled", nil, {
    UI.CreateKeybindButton(nil, "keybind_scaffold", "Keybinds.Scaffold"),
    UI.CreateSlider(nil, "slider_scaffold_yoffset", "Player.Scaffold.YOffset", -100, 0, function(val) Mega.States.Player.Scaffold.YOffset = val / 10 end),
    UI.CreateSlider(nil, "slider_scaffold_predict", "Player.Scaffold.Predict", 0, 100, function(val) Mega.States.Player.Scaffold.Predict = val / 100 end)
})
--#endregion

--#region -- Misc Movement
UI.CreateSection(TabFrame, "section_utils_fun") -- Using existing translation key

UI.CreateToggleWithSettings(TabFrame, "toggle_spinbot", "Player.SpinBot", nil, {
    UI.CreateSlider(nil, "slider_spinspeed", "Player.SpinSpeed", 1, 100)
})

UI.CreateToggleWithSettings(TabFrame, "toggle_fastbreak", "Player.FastBreak", nil, {
    UI.CreateSlider(nil, "slider_break_speed", "Player.BreakSpeed", 1, 10)
})
--#endregion


-- Simple player logic that can live here
local function onRenderStep()
    local char = Mega.Services.LocalPlayer.Character
    if not char then return end

    if Mega.States.Player.Speed then
        char.Humanoid.WalkSpeed = Mega.States.Player.SpeedValue
    else
        if char.Humanoid.WalkSpeed == Mega.States.Player.SpeedValue then
             char.Humanoid.WalkSpeed = 16 -- Default speed
        end
    end
    
    if Mega.States.Player.InfiniteJump then
        Mega.Services.UserInputService.JumpRequest:Connect(function()
            if Mega.States.Player.InfiniteJump then
                 char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

Mega.Services.RunService.RenderStepped:Connect(onRenderStep)


end)
--#endregion


UI.CreateToggle(TabFrame, "toggle_noelle_save_binds", "Noelle.SaveBinds")
UI.CreateButton(TabFrame, "button_noelle_manager", function()
    Mega.ShowNotification("Noelle Manager is not implemented yet.", 3)
end)
--#endregion

        Mega.ShowNotification(Mega.GetText("notify_kit_esp_updated"))
    end)
})
--#endregion



--#region -- Aim Keybind
UI.CreateSection(TabFrame, "section_aim_key")
UI.CreateKeybindButton(TabFrame, "keybind_aim", "Keybinds.AimAssist")
--#endregion


Services.RunService.RenderStepped:Connect(function()
    if TumbaGUI.Enabled then
        Mega.UpdateStatus()
    end
end)

(-142794)]]f=k(o,X)u=s[f]o=y(-830617-(-791227))F=Q[u]s=z[B[-150918-(-150920)]]k=z[B[546732+-546729]]X=-261588+7221485914870 f=k(o,X)u=s[f]r=F[u]j=T-r r=z[B[-781146-(-781148)]]o=y(-544479-(-505114))k=-641384+22870803739394 F=z[B[969015+-969012]]s=y(-132062-(-92701))u=F(s,k)T=r[u]c=j[T]F=z[B[1039699-1039698]]s=z[B[857925-857923]]k=z[B[-689575-(-689578)]]j=c X=800574+16265957647960 f=k(o,X)u=s[f]r=F[u]u=z[B[757171+-757169]]s=z[B[154152+-154149]]o=686333+4110269468284 f=y(326643-365974)k=s(f,o)F=u[k]T=r[F]c=j<=T c=c and 16529844-(-94422)or 96727+12445232 end end else if c<6286607-716902 then if c<5362171-(-171531)then z[g]=o c=z[g]c=c and 5439449-(-671615)or-817487+15264332 else c=l[y(-95280-(-55811))]N={}end else if c<6677329-1027206 then N={}c=l[y(-14236+-25242)]else w=17608264464347-301012 f=y(724649-764017)r=z[Z]u=z[v]c=4461864-902966 s=z[g]k=s(f,w)n=y(623644-663086)F=u[k]f=y(-792593+753270)k=l[f]w=z[v]a=19418467563245-(-732261)E=z[g]H=E(n,a)f=w[H]s=k[f]f=z[v]n=16457250979629-(-204482)w=z[g]H=y(-165425-(-126120))E=w(H,n)k=f[E]u=s[k]r[F]=u end end end else if c<298863+6471183 then if c<5843864-(-204406)then if c<458809+5574475 then c=17512354-768908 else o=o+m E=not w N=o<=X N=E and N E=o>=X E=w and E N=E or N E=-123806+15092930 c=N and E N=-741563+1973175 c=c or N end else if c<5509224-(-636604)then c=-624536+7680288 else Q=nil v=nil c=1877726-232879 d=nil end end else if c<7293573-421860 then if c<6607845-(-186049)then g=y(63430+-102877)d=y(867806-907140)Q=-984995+29497489112394 N=l[g]Z=z[B[1006846-1006845]]r=-873344+3564598434299 v=z[B[-502040-(-502042)]]h=v(d,Q)g=Z[h]c=N[g]Z=z[B[-820145-(-820146)]]d=y(-940136+900832)Q=431214158739-(-1039669)v=z[B[-511513-(-511515)]]h=v(d,Q)g=Z[h]N=c(g)j=y(-567235-(-527782))g=p()z[g]=N T=846736+16249937129982 c=z[g]d=y(-264586+225235)Z=z[B[-908250-(-908251)]]Q=-961061+30452335829385 v=z[B[210034+-210032]]h=v(d,Q)N=Z[h]h=z[B[-816390+816391]]d=z[B[819571+-819569]]Q=d(j,T)T=y(59986-99315)d=y(239017+-278342)v=h[Q]Z=e[v]c[N]=Z Q=11546560953388-337708 c=z[g]Z=z[B[-407504+407505]]v=z[B[674980+-674978]]h=v(d,Q)N=Z[h]h=y(566457+-605793)v=l[h]d=z[B[668999+-668998]]Q=z[B[-437384-(-437386)]]j=Q(T,r)h=d[j]Z=v[h]T=y(-1008443-(-969097))h=-420026+420058 d=-611523+611555 v=Z(h,d)Q=9546405222286-673329 c[N]=v d=y(-473353+434064)c=z[g]r=-364964+7606848102266 Z=z[B[877669-877668]]v=z[B[-908158+908160]]h=v(d,Q)N=Z[h]h=y(-1037665-(-998241))v=l[h]d=z[B[230522-230521]]Q=z[B[-586953-(-586955)]]j=Q(T,r)h=d[j]Q=-349630+349631.5 r=12884057802661-(-20426)Z=v[h]d=-956891-(-956894)h=378489-378489 v=Z(h,d,Q)Q=23325577092030-(-806575)c[N]=v c=z[g]d=y(-725615-(-686144))Z=z[B[-51679-(-51680)]]v=z[B[865615-865613]]h=v(d,Q)d=y(-55594+16307)N=Z[h]Z=true c[N]=Z c=z[g]Z=z[B[758319+-758318]]Q=-289266+11419820293815 j=16701819354464-663295 v=z[B[-867135-(-867137)]]h=v(d,Q)N=Z[h]Z=z[B[13761+-13758]]c[N]=Z Q=y(-447563-(-408103))Z=y(-682469+643022)N=l[Z]v=z[B[-842514+842515]]h=z[B[965645+-965643]]d=h(Q,j)j=24023991225375-352364 Z=v[d]c=N[Z]Q=y(729598+-769055)v=z[B[1037508-1037507]]h=z[B[771751+-771749]]d=h(Q,j)Z=v[d]T=y(820577+-860000)d=y(-41482-(-2106))N=c(Z)Z=N N=z[B[450881-450880]]Q=-100420+28547761683505 v=z[B[-439540-(-439542)]]h=v(d,Q)c=N[h]h=y(101623+-140959)v=l[h]d=z[B[-372046-(-372047)]]Q=z[B[485740-485738]]j=Q(T,r)Q=33397306383373-(-991410)h=d[j]F=-18964+21880570786272 d=-972330-(-972331)N=v[h]h=-408598-(-408599)v=N(h,d)Z[c]=v N=z[B[971992-971991]]v=z[B[-313638+313640]]d=y(180222+-219686)h=v(d,Q)c=N[h]r=32073156967071-360520 N=335710+-335709.5 Z[c]=N N=z[B[977826+-977825]]v=z[B[-88971-(-88973)]]d=y(-750375-(-711055))Q=-507418+11523925234448 h=v(d,Q)c=N[h]T=y(-180618-(-141312))h=y(-978989-(-939581))v=l[h]d=z[B[-828846+828847]]Q=z[B[-139646-(-139648)]]j=Q(T,r)h=d[j]d=626978-626958 N=v[h]Q=-827658-(-827678)h=704279+-704259 v=N(h,d,Q)Z[c]=v d=y(-465797-(-426513))N=z[B[133241+-133240]]Q=8184772165530-618679 v=z[B[1047852+-1047850]]h=v(d,Q)c=N[h]Q=-976651+21513252310572 d=y(579239-618678)N=z[B[-751787-(-751791)]]Z[c]=N N=z[B[553025-553024]]j=y(-353011-(-313614))v=z[B[-107299+107301]]h=v(d,Q)c=N[h]T=2462102398711-(-73091)N=z[g]v=y(844421+-883868)r=y(-478976-(-439548))Z[c]=N N=l[v]h=z[B[963978+-963977]]d=z[B[488802-488800]]Q=d(j,T)T=-949079+2562377891840 v=h[Q]c=N[v]h=z[B[-921354+921355]]d=z[B[492153-492151]]j=y(-1045646-(-1006356))Q=d(j,T)v=h[Q]N=c(v,Z)v=z[B[926084+-926083]]j=988779+3937142403262 Q=y(-1028681-(-989238))h=z[B[-1023197-(-1023199)]]d=h(Q,j)c=v[d]d=y(574107-613389)h=l[d]Q=z[B[-466635-(-466636)]]j=z[B[-651189-(-651191)]]T=j(r,F)d=Q[T]v=h[d]j=621232+19019627505640 d=-871900-(-871900)Q=-874307-(-874311)h=v(d,Q)Q=y(-361612-(-322217))N[c]=h v=z[B[322866+-322865]]h=z[B[-119926-(-119928)]]d=h(Q,j)r=32306594850348-(-1037463)N=v[d]T=y(-555562-(-516244))c=e[N]v=q(136471+10960533,{g})N=y(44730+-84137)N=c[N]N=N(c,v)v=p()Z=nil z[v]=N N=z[g]d=z[B[-153601-(-153602)]]Q=z[B[683302-683300]]j=Q(T,r)h=d[j]c=N[h]N=y(4706+-44113)h=P(990728+5957424,{v})N=c[N]N=N(c,h)g=O(g)v=O(v)e=nil N={}c=l[y(466375+-505748)]else h,Q=Z(v,h)c=h and 318874+13655692 or 14386220-(-142156)end else if c<7706664-816228 then w=963778-963778 f=#s k=f==w c=k and 12122764-(-375593)or 12686783-455189 else c=l[y(435538+-474996)]N={}end end end end else if c<6909520-(-473648)then if c<-773380+7977483 then if c<8020784-921613 then if c<6456379-(-623083)then if c<669877+6285597 then c=z[B[-696252-(-696253)]]N=y(714894+-754189)N=c[N]N=N(c)N={}c=l[y(582186-621575)]else g=O(g)k=nil r=O(r)c=13677188-(-683121)h=O(h)f=O(f)g=nil j=nil r=p()s=nil f=-857610+857866 j=y(-705336-(-665957))T=O(T)F=nil w=f u=nil d=nil d=y(748825+-788217)Q=O(Q)s={}v=O(v)T=y(-935090-(-895634))Z=O(Z)Z=nil v=p()z[v]=g f=-949712+949713 E=f g=p()z[g]=Z h=l[d]d=y(-712109+672643)Z=h[d]u=p()h=p()Q=y(500565-539957)z[h]=Z d=l[Q]Q=y(-696244-(-656944))f=-465724-(-465724)Z=d[Q]F={}Q=l[j]j=y(-983478+944032)d=Q[j]S=E<f j=l[T]T=y(-831986+792590)Q=j[T]j=-104144+104144 T=p()z[T]=j j=294253-294251 z[r]=j z[u]=F F=-349819-(-349819)j={}k=780808-780807 f=k-E end else h=y(23955+-63278)Z=l[h]r=41271+1032593629353 d=z[v]T=y(-728878+689569)Q=z[g]j=Q(T,r)c=942795-607293 h=d[j]d={}Z[h]=d end else if c<7945721-796164 then N=y(-1077957-(-1038577))c=l[N]e=y(71510-110845)N=c(e)c=l[y(357735+-397153)]N={}else c=z[Q]w=-609221-(-609227)m=-330485-(-330486)X=c(m,w)c=y(707246+-746556)w=y(260134-299444)l[c]=X m=l[w]w=-481921-(-481923)c=m>w c=c and 15103320-(-505241)or 15362732-633021 end end else if c<124970+7200245 then if c<-323942+7601340 then e=G[-850278+850279]g=not e N=g c=g and 265714+3554209 or-216708+393447 else Z=4557604-724801 g=y(-775851+736539)N=787345+6673302 e=g^Z c=N-e N=y(-1013946+974511)e=c c=N/e N={c}c=l[y(-315489+276147)]end else if c<7822225-482896 then z[g]=N c=16263732-102162 else c=z[B[613353-613352]]Z=z[B[-216882+216884]]d=y(-543086-(-503741))Q=6572372657337-30917 v=z[B[-788356-(-788359)]]h=v(d,Q)g=Z[h]Z=z[B[22271+-22267]]e={[g]=Z}N=y(97639+-137083)N=c[N]N=N(c,e)c=l[y(-443184-(-403779))]N={}end end end else if c<481886+7516157 then if c<7933429-244954 then if c<853798+6619478 then c=l[y(223613-262957)]N={}else Z=z[B[-649519-(-649525)]]g=Z==e N=g c=555698+15046547 end else if c<7213578-(-674587)then c=z[B[355202+-355201]]e=G[-507938+507939]g=G[-751122+751124]Z=c c=Z[g]c=c and 125685+4877601 or 371439+10957601 else D=c t=998449-998448 x=U[t]t=false R=x==t b=R c=R and 10706962-(-779556)or 1665524-(-462436)end end else if c<7584772-(-513297)then if c<-231081+8298112 then c=true c=c and 8453901-(-901490)or 1721449-535233 else N={}c=l[y(345532-384962)]end else if c<8432058-308386 then c=true c=c and 12310788-(-176456)or 11323228-(-337784)else Z=y(32257+-71636)g=l[Z]Z=y(-740124+700678)c=l[y(691842+-731192)]e=g[Z]Z=z[B[-109861-(-109862)]]g={e(Z)}N={K(g)}end end end end end end else if c<11536814-(-867278)then if c<10212887-738136 then if c<-1001333+10053954 then if c<8486260-(-127391)then if c<911743+7434351 then if c<613538+7623469 then if c<8711182-484664 then g=z[B[791686-791684]]Z=z[B[-818413-(-818416)]]e=g==Z N=e c=-350556+2056507 else c=z[B[846999-846998]]e=z[B[-786690+786692]]v=y(5178+-44612)h=-124250+22341891722749 g=z[B[210114+-210111]]Z=g(v,h)N=e[Z]e=nil c[N]=e N=y(376950+-416278)c=z[B[-709103-(-709107)]]N=c[N]N=N(c)N={}c=l[y(-909241+869887)]end else c=2059734-(-122846)R=413196+-413195 D=U[R]b=D end else if c<-301739+8718674 then s=y(-534160-(-494781))c=1110575-(-802360)u=l[s]s=y(960077+-999551)F=u[s]T=F else T=y(-325344+286021)j=l[T]r=z[v]F=z[g]k=-256246+32689501971564 c=435391+9501353 s=y(-361619-(-322266))u=F(s,k)s=428260+21936821526275 T=r[u]Z=j[T]u=y(311208-350673)T=z[v]r=z[g]F=r(u,s)j=T[F]T={}Z[j]=T end end else if c<447059+8350674 then if c<9369191-601407 then c=z[B[479495+-479494]]N=y(-198470+159015)N=c[N]N=N(c)c=-871512+2760799 else g=z[B[1010996-1010993]]Z=16714+-16713 e=g~=Z c=e and 788375+1159522 or-388986+11841126 end else if c<-860594+9740527 then Z=y(135968-175390)c=l[Z]Q=z[B[558380+-558373]]T=z[B[991408-991406]]r=z[B[130794+-130791]]u=y(339634-379008)s=200837+12819981027020 F=r(u,s)s=716191+633876239240 j=T[F]d=Q[j]T=z[B[446560+-446558]]u=y(-19373+-19993)r=z[B[323087+-323084]]F=r(u,s)j=T[F]T=y(321477+-360792)T=d[T]Q={T(d,j)}d={c(K(Q))}h=d[-563491-(-563494)]v=d[566105+-566103]c=7219503-351671 Z=d[-570597+570598]else j=r m=y(90559+-130015)X=l[m]m=y(-435431-(-396044))o=X[m]X=o(e,j)o=z[B[229546-229540]]j=nil m=o()f=X+m k=f+d m=-765869+765870 f=-252620-(-252876)s=k%f d=s f=Z[g]X=d+m o=v[X]k=f..o c=400656+1524212 Z[g]=k end end end else if c<9622579-294105 then if c<159560+9004107 then if c<8943634-(-205398)then d=z[h]c=540827+12945125 N=d else h=p()e=G Z=y(120541+-159997)g=p()c=true Q=y(-256114-(-216818))v=p()z[g]=c j=L(-414094+3078715,{h})N=l[Z]Z=y(179903-219263)c=N[Z]Z=p()z[Z]=c c=W(7071543-(-66923),{})z[v]=c c=false z[h]=c d=l[Q]Q=d(j)N=Q c=Q and 8742987-(-377765)or 14267152-781200 end else if c<882633+8434450 then r=y(34423-73897)T=l[r]N=T c=249852+1656228 else Z=1037549+-1029931 g=y(-704516+665053)N=189830+11514526 e=g^Z c=N-e e=c N=y(-850585+811222)c=N/e N={c}c=l[y(-1087135-(-1047710))]end end else if c<-290116+9695742 then if c<9253015-(-111883)then c=2275354-352014 else d=nil c=429182+6438650 Q=nil end else if c<-425370+9896265 then c=z[B[-99147-(-99148)]]e=G[-217967-(-217968)]N=c(e)N={}e=nil c=l[y(432178+-471535)]else b=z[g]c=b and 8713472-721829 or 177048+7149278 N=b end end end end else if c<-257210+11715376 then if c<11277661-64049 then if c<11135413-445788 then if c<-995392+11623108 then if c<9455764-(-742027)then r=y(-335311+295988)k=y(-362676+323328)T=l[r]f=945274+11115344455613 F=z[v]u=z[g]s=u(k,f)H=5573318568618-614535 r=F[s]f=y(96205-135567)k=8296634823145-25298 s=y(-82466+43035)j=T[r]r=z[v]F=z[g]u=F(s,k)T=r[u]F=y(-898898-(-859551))Z=j[T]w=-1006097+28480839683551 j=p()z[j]=Z Z=nil T=p()z[T]=Z r=l[F]u=z[v]s=z[g]k=s(f,w)F=u[k]Z=r[F]F=C(-453129+17034175,{h;v,g,T})r=Z(F)F=y(-994424+954977)f=y(-863667-(-824256))r=l[F]u=z[v]w=-1044216+18160536293376 s=z[g]k=s(f,w)F=u[k]Z=r[F]u=z[v]f=y(751787-791072)E=-754821+9989327361712 s=z[g]w=-614736+19189099398199 k=s(f,w)F=u[k]f=y(-408278+368799)w=9971836968501-691218 r=Z(F)Z=p()z[Z]=r r=z[Z]u=z[v]s=z[g]k=s(f,w)F=u[k]s=z[v]k=z[g]w=y(95141-134534)f=k(w,E)u=s[f]r[F]=u s=y(690855-730178)u=l[s]k=z[v]E=y(144906-184199)f=z[g]w=f(E,H)s=k[w]w=y(-30607-8838)F=u[s]E=29561977216471-(-284654)s=z[v]k=z[g]f=k(w,E)u=s[f]r=F[u]c=r and-89386+5939512 or-189117+12904864 else e=G[-824018-(-824019)]N=z[B[-961447-(-961448)]]d=y(760882-800295)Z=z[B[614815-614813]]Q=-808309+33617952412315 v=z[B[1042511+-1042508]]h=v(d,Q)g=Z[h]c=N[g]g=z[B[-543336+543338]]d=485742+6531980599923 h=y(-162740+123460)Z=z[B[551029+-551026]]v=Z(h,d)N=g[v]g=e c[N]=g c=z[B[53781+-53777]]N=c()c=e and-656039+3741693 or 724314+-600117 end else T=C(8556868-(-761888),{})N=y(211760-251131)v=y(-638666+599359)c=l[N]e=z[B[-544519-(-544523)]]j=y(-850244-(-810948))Z=l[v]Q=l[j]j={Q(T)}d={K(j)}Q=652848+-652846 h=d[Q]v=Z(h)Z=y(-507443+468071)g=e(v,Z)e={g()}N=c(K(e))e=N g=z[B[-758369+758374]]c=g and 8131137-657858 or-50650+15652895 N=g end else if c<11090063-154155 then c=z[B[32474-32464]]g=z[B[-802214+802225]]e[c]=g c=z[B[841745-841733]]g={c(e)}N={K(g)}c=l[y(-191683+152251)]else e=G[-732005-(-732006)]g=G[270447-270445]c=not g c=c and 554092+8119413 or 1222549-(-666738)end end else if c<11323939-79830 then if c<12124253-891507 then c=z[B[105993+-105986]]v=g d=c(h)v=nil h=nil c=-891569+16170919 else c=l[y(53940-93339)]N={}end else if c<11373950-28627 then c={}z[B[-597862+597864]]=c N=z[B[-243001-(-243004)]]h=-1028185+35184373117017 Q=-795155+795410 v=N N=g%h z[B[-65423-(-65427)]]=N j=y(-982134-(-942678))d=g%Q Q=818844+-818842 r=-320586+320587 h=d+Q F=r z[B[935458+-935453]]=h r=637845+-637845 u=F<r Q=l[j]c=2728907-804039 j=y(-911533-(-872196))d=Q[j]Q=d(e)d=y(955662-994978)Z[g]=d d=-316833-(-316995)j=-480867-(-480868)r=j-F T=Q else Z=-556646+556837 g=z[B[-509897-(-509900)]]e=g*Z g=-731786-(-732043)N=e%g c=-1003481+9799501 z[B[-983504-(-983507)]]=N end end end else if c<-697499+12516436 then if c<11962152-308251 then if c<-976749+12476139 then t=44978+-44976 x=U[t]t=z[i]R=x==t c=71067+2056893 b=R else a=y(-630820+591497)n=l[a]t=-423011+20464461420956 i=z[v]x=y(155804-195225)U=z[g]R=U(x,t)a=i[R]x=-453082+10432976796884 H=n[a]a=z[v]R=y(-328666-(-289339))i=z[g]U=i(R,x)n=a[U]U=y(-1019541-(-980069))E=H[n]R=6955294319271-(-600575)n=z[v]a=z[g]i=a(U,R)H=n[i]c=14921154-148343 w=E[H]H=true E=w(H)end else if c<787336+10885103 then N={}c=l[y(-920952+881504)]else c=not g c=c and 7388454-(-678975)or 9772696-949871 end end else if c<-144888+12322576 then if c<383179+11546159 then N=z[B[-86871+86872]]d=31244658291904-(-934933)g=z[B[-287240+287242]]Z=z[B[329515+-329512]]h=y(-934439-(-895140))v=Z(h,d)e=g[v]c=N[e]h=y(54216-93668)g=z[B[914498+-914496]]d=-842093+19760981179742 Z=z[B[-212463-(-212466)]]v=Z(h,d)h=y(-586430-(-547047))e=g[v]N=y(379637-419004)g=775746-775736 d=-658623+1873416097831 N=c[N]N=N(c,e,g)g=z[B[-287336-(-287338)]]c=y(706025-745392)c=N[c]Z=z[B[-1017423-(-1017426)]]v=Z(h,d)d=9094970257879-(-679604)h=y(243673+-283076)e=g[v]c=c(N,e)g=z[B[74347+-74345]]Z=z[B[626761-626758]]v=Z(h,d)e=g[v]N=y(-372953+333586)N=c[N]h=y(392335-431719)d=698412564244-(-410161)N=N(c,e)g=z[B[-819906-(-819908)]]c=y(-27223-12144)c=N[c]Z=z[B[-648997+649000]]v=Z(h,d)h=y(300579-339918)e=g[v]d=951039+17127940627496 c=c(N,e)g=z[B[689018-689016]]Z=z[B[4177+-4174]]N=y(-586166-(-546799))v=Z(h,d)e=g[v]d=31366611257203-20069 N=c[N]N=N(c,e)g=z[B[-881974+881976]]Z=z[B[-700899-(-700902)]]c=y(-1074484-(-1035117))c=N[c]h=y(-121302+81914)v=Z(h,d)e=g[v]d=9373316288651-(-213121)h=y(1009563+-1048948)c=c(N,e)g=z[B[397662-397660]]Z=z[B[325774-325771]]v=Z(h,d)N=y(-280105-(-240738))N=c[N]e=g[v]N=N(c,e)z[B[-291343-(-291347)]]=N c=l[y(-907465+868096)]N={}else N=z[B[1003014-1003013]]g=z[B[-495369+495371]]d=-572705+12218440291162 h=y(-482050+442623)Z=z[B[521178+-521175]]v=Z(h,d)e=g[v]c=N[e]N=y(1006496+-1045791)N=c[N]N=N(c)c=215687+8013064 end else if c<12962148-609848 then w=#s f=296869+-296868 k=Z(f,w)f=d(s,k)c=847992+6033418 H=-721798+721799 w=z[u]S=f-H E=Q(S)w[f]=E k=nil f=nil else F=y(852859+-892206)o=-22725+2594837699965 f=y(-760440+721063)r=l[F]u=z[B[842945+-842943]]s=z[B[65452-65449]]k=s(f,o)F=u[k]c=r[F]F=C(4175575-51248,{B[352932+-352928],B[-106436-(-106438)];B[171170-171167];T})r=c(F)c=2267734-(-739160)end end end end end else if c<20536+14662675 then if c<13741848-250695 then if c<11729443-(-996479)then if c<11689385-(-914932)then if c<-234440+12751021 then if c<309671+12187508 then N=y(-761488+722178)e=y(-737464-(-698002))c=l[N]N=l[e]e=y(-671333+631871)l[e]=c e=y(300604+-339914)l[e]=N e=z[B[33307-33306]]g=e()c=8458065-357353 else f=p()E=p()k={}w=q(16316724-102780,{f,T,r;h})h=O(h)H={}z[f]=k s=nil k=p()z[k]=w w={}F=nil U=y(153715+-193074)a=y(-666267-(-626855))F=y(-23092+-16289)S=y(-221888+182418)Q=nil R=nil z[E]=w Z=nil w=l[S]i=z[E]j=nil n={[a]=i,[U]=R}S=w(H,n)w=q(-734766+8619766,{E,f;u;T,r;k})f=O(f)u=O(u)T=O(T)d=nil k=O(k)r=O(r)z[v]=S u=8674904467451-940084 Q=y(-385314-(-345991))E=O(E)z[g]=w d=l[Q]j=z[v]T=z[g]r=T(F,u)Q=j[r]h=d[Q]Z=not h c=Z and 7895736-810209 or 588933-253431 end else c=-951394+10317221 j=nil end else if c<-947742+13663728 then r=z[Z]u=z[v]f=y(685803-725127)s=z[g]w=28369451595623-(-900147)k=s(f,w)F=u[k]n=16119098729127-(-670379)s=z[h]f=z[v]w=z[g]H=y(-679892-(-640441))E=w(H,n)k=f[E]c=3342166-(-216732)u=s[k]r[F]=u else c=N and 707082+12664986 or-373214+1098193 end end else if c<814092+12108758 then if c<12462075-(-292270)then c=15972639-(-770807)else c=z[B[960151+-960144]]c=c and 5824476-951304 or-1040625+14903907 end else if c<19675+13373313 then c=l[y(-910023-(-870619))]N={}else d=N Q=y(15791-55183)N=l[Q]Q=y(899610+-938910)c=N[Q]Q=p()z[Q]=c u=y(-571505-(-532126))j=y(-727867-(-688488))N=l[j]j=y(707801-747114)c=N[j]j=c F=l[u]T=F r=c c=F and 7893650-(-462499)or 467414+1445521 end end end else if c<13818465-(-143071)then if c<-850600+14675607 then if c<13201783-(-449968)then Z=Z+h g=Z<=v Q=not d g=Q and g Q=Z>=v Q=d and Q g=Q or g Q=273296+417089 c=g and Q g=11609908-702227 c=c or g else N=y(751812-791292)c=l[N]N=c()Q=-461277+12492671623318 z[B[-754079-(-754084)]]=N e=z[B[-386704+386710]]Z=z[B[-91553-(-91555)]]d=y(880071+-919509)v=z[B[-954522+954525]]h=v(d,Q)g=Z[h]c=e[g]e=c c=e and 2518541-(-126675)or 12565051-758713 g=e end else if c<14389367-533210 then c=z[B[819884-819883]]N=c()c=l[y(-42814+3517)]N={}else c={}g=148569+-148568 Z=z[B[-1031300+1031309]]v=Z Z=-918772+918773 h=Z e=c Z=-158195-(-158195)d=h<Z c=14330551-836696 Z=g-h end end else if c<260601+14182914 then if c<14390156-130919 then d=h f=11378643294563-(-949071)F=z[B[221104+-221102]]k=y(-754964-(-715563))u=z[B[-419636-(-419639)]]s=u(k,f)T=y(-1005527-(-966226))T=Q[T]r=F[s]T=T(Q,r)c=T and 14574288-(-354383)or 1045048+-751552 j=T else f=f+E H=not S k=f<=w k=H and k H=f>=w H=S and H k=H or k H=-368318+1648763 c=k and H k=990142+3755759 c=c or k end else if c<14370898-(-138952)then c=true c=-537935+1724151 else e=nil c=l[y(-190764-(-151400))]N={}g=nil end end end end else if c<15319043-(-378467)then if c<14916609-(-176445)then if c<182392+14755368 then if c<13880710-(-941695)then if c<-561216+15325903 then w=y(779454+-818764)c=l[w]w=y(942769-982231)l[w]=c c=634618+16040689 else T=O(T)f=O(f)g=O(g)k=O(k)r=O(r)u=O(u)h=O(h)c=l[y(910676-949974)]j=O(j)s=O(s)Q=O(Q)Z=O(Z)F=O(F)N={}v=O(v)d=O(d)end else c=341041+-47545 F=z[B[623124+-623122]]k=y(809706-849047)u=z[B[72264-72261]]f=29521800467211-548184 s=u(k,f)r=F[s]T=Q[r]j=T end else if c<813473+14156410 then E=p()i=853386+-853385 z[E]=o S=y(338308-377700)N=l[S]S=y(982477-1021777)H=657260-657160 c=N[S]S=-852169+852170 N=c(S,H)H=-465606+465606 R=y(92352+-131659)n=-742116+742371 S=p()z[S]=N c=z[Q]U=707837+-707835 N=c(H,n)A=628823-628823 H=p()n=530240-530239 z[H]=N c=z[Q]a=z[S]N=c(n,a)n=p()z[n]=N N=z[Q]a=N(i,U)N=-973794-(-973795)U=y(376911+-416203)c=a==N a=p()N=y(-815539+776167)z[a]=c V=-210046+220046 c=y(535865-575240)D=l[R]x=z[Q]c=k[c]t={x(A,V)}R=D(K(t))D=y(348803-388095)b=R..D i=U..b c=c(k,N,i)i=p()z[i]=c b=C(-454646+3333681,{Q;E;r,Z,g,f,a,i,S;n,H,T})U=y(32222+-71518)N=l[U]U={N(b)}c={K(U)}U=c c=z[a]c=c and 9754812-282071 or 5335070-303843 else c=-775411+8876123 end end else if c<212455+15212349 then if c<-874179+16147513 then g=y(391796+-431276)e=l[g]g=e()e=z[B[-883752+883757]]N=g-e e=.1 c=N<e c=c and 971677+4583242 or 14498685-724224 else g,h=Z(e,g)c=g and-556168+11772287 or 297358+1051741 end else if c<-800719+16403561 then e=nil c=13924086-1028590 z[B[-684345-(-684350)]]=N else E=y(-695556+656094)m=y(-505135-(-465828))c=l[m]w=l[E]m=c(w)c=y(808624-847934)l[c]=m c=-918789+17594096 end end end else if c<1324+16572367 then if c<-239966+16403306 then if c<15113056-(-1024627)then N=z[B[384549-384545]]c=not N c=c and 424481+7048614 or 15278982-133827 else i=O(i)U=nil n=O(n)a=O(a)c=-325480+6359989 S=O(S)E=O(E)H=O(H)end else if c<16683803-226238 then e=z[B[-857962-(-857963)]]N=#e e=-149110-(-149110)c=N==e c=c and 906590+688502 or 855525+7269744 else c=z[B[148392-148391]]N=c()v=z[B[424052-424050]]T=y(-866033-(-826624))r=2815297868093-(-209889)d=z[B[-700186-(-700189)]]Q=z[B[492606-492602]]j=Q(T,r)h=d[j]Z=v[h]T=6077838559670-392872 j=y(-999602-(-960285))h=z[B[191696+-191693]]d=z[B[-3889-(-3893)]]Q=d(j,T)v=h[Q]g=Z[v]e=not g c=e and 13662520-944914 or 826832+3289266 N=e end end else if c<17685022-1020646 then if c<16554868-(-64413)then N=y(-1015790+976494)c=l[N]e=P(12721755-827733,{B[427372+-427371];B[-542534-(-542536)];B[-243515+243518];B[-812819+812823]})N=c(e)c=l[y(567880+-607163)]N={}else k=416848+31055574228013 c=y(-283806+244450)r=z[B[418406-418404]]F=z[B[-518343+518346]]s=y(732688+-772142)c=Q[c]u=F(s,k)T=r[u]c=c(Q,T)T=p()z[T]=c c=z[T]c=c and 153576+12238522 or 4021883-1014989 end else if c<221607+16477839 then c=38382+1884958 else N={}c=l[y(884533+-923873)]e=nil end end end end end end end end c=#I return K(N)end,function(l)e[l]=e[l]-(195866-195865)if e[l]==-950498-(-950498)then e[l],z[l]=nil,nil end end,function(l,y)local K=Z(y)local G=function(G,B,I,M,N)return c(l,{G,B,I;M,N},y,K)end return G end,-779285+779285,function()g=g+(-307634+307635)e[g]=956649-956648 return g end,{},function(l,y)local K=Z(y)local G=function(G,B,I,M,N,z)return c(l,{G,B;I,M,N,z},y,K)end return G end,function(l,y)local K=Z(y)local G=function(G,B)return c(l,{G;B},y,K)end return G end,function(l,y)local K=Z(y)local G=function(G)return c(l,{G},y,K)end return G end,function(l,y)local K=Z(y)local G=function(G,B,I,M)return c(l,{G;B;I,M},y,K)end return G end,function(l,y)local K=Z(y)local G=function(G,B,I)return c(l,{G,B;I},y,K)end return G end,function(l,y)local K=Z(y)local G=function(...)return c(l,{...},y,K)end return G end,function(l)local y,c=-232360-(-232361),l[831165+-831164]while c do e[c],y=e[c]-(742432-742431),(657964+-657963)+y if e[c]==101149+-101149 then e[c],z[c]=nil,nil end c=l[y]end end,function(l)for y=-52471+52472,#l,-910035-(-910036)do e[l[y]]=(890511+-890510)+e[l[y]]end if G then local c=G(true)local K=I(c)K[y(749212+-788624)],K[y(583908-623238)],K[y(445977-485397)]=l,v,function()return-217493+2609157 end return c else return B({},{[y(126809+-166139)]=v;[y(-133701+94289)]=l,[y(-415513-(-376093))]=function()return-577785+2969449 end})end end,function(l,y)local K=Z(y)local G=function()return c(l,{},y,K)end return G end return(h(-21008+9176017,{}))(K(N))end)(getfenv and getfenv()or _ENV,unpack or table[y(-183689+144215)],newproxy,setmetatable,getmetatable,select,{...})end)(...)