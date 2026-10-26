pragma Singleton
import QtQuick
import QtQuick.Controls.Material

Item {
    // Material resolves System to the current platform theme and tracks changes.
    property int systemTheme: Material.System
    Material.theme: systemTheme
    readonly property bool dark: Material.theme === Material.Dark

    readonly property color background: dark ? "#080E19" : "#F7F8FF"
    readonly property color backgroundTop: dark ? "#10182B" : "#FDFDFF"
    readonly property color surface: dark ? "#141E2F" : "#FFFFFF"
    readonly property color card: dark ? "#141E2F" : "#F0F1FC"
    readonly property color field: dark ? "#182236" : "#FAFAFF"
    readonly property color border: dark ? "#293650" : "#DEE2F6"
    readonly property color text: dark ? "#F4F5FF" : "#151B48"
    readonly property color muted: dark ? "#BAC4DE" : "#626D99"
    readonly property color accent: dark ? "#A6B6FF" : "#2949E8"
    readonly property color purple: dark ? "#B99AFF" : "#7441DA"
    readonly property color secondary: dark ? "#202C45" : "#E6E9FC"
    readonly property color secondaryPressed: dark ? "#2D3C5B" : "#D7DDF9"
    readonly property color route: dark ? "#344CD1" : "#DFE5FF"
    readonly property color routePressed: dark ? "#425FE4" : "#CCD6FF"
    readonly property color danger: dark ? "#FFB4BA" : "#B32640"
    readonly property color dangerSurface: dark ? "#3B2433" : "#FCEBF0"
    readonly property color dangerPressed: dark ? "#523043" : "#F5D9E2"
    readonly property color disabled: dark ? "#1C263B" : "#E7EAF3"
    readonly property color toast: dark ? "#293750" : "#202B54"
    readonly property color accentText: "#FFFFFF"
}
