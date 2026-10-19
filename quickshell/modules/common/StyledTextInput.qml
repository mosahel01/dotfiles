import qs.config
import QtQuick

/**
 * Does not include visual layout, but includes the easily neglected colors.
 */
TextInput {
    renderType: Text.NativeRendering
    selectedTextColor: Config.color_foreground
    selectionColor: Config.color_blue
    font {
        family: "sans-serif"
        pixelSize: Config.font_base
        hintingPreference: Font.PreferFullHinting
    }
}
