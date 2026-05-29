export type TumbaHubSlider = {
    Value: any,
    Object: Frame
}
export type TumbaHubDropdown = TumbaHubSlider

export type TumbaHubToggle = {
    Enabled: boolean,
    Toggle: (self: TumbaHubToggle, ...any) -> (),
    Object: Frame,
    Clean: (self: TumbaHubToggle, any) -> RBXScriptConnection
}

export type TumbaHubModule = TumbaHubToggle & {
    CreateSlider: (...any) -> TumbaHubSlider, 
    CreateToggle: (...any) -> TumbaHubToggle,
    CreateDropdown: (...any) -> TumbaHubDropdown,
    CreateButton: (...any) -> ()
}

export type TumbaHubCategory = {
    CreateModule: (self: TumbaHubCategory, any) -> TumbaHubModule
}