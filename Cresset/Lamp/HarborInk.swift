import SwiftUI

/// Role: Lamp. Named colours and SF Pro. Hex lives only here: #FAF7F5 #FEFEFD #392818 #CC6D19 #816C5A.
enum HarborInk {
    static let face = "SF Pro"

    enum Hex {
        static let background = "#FAF7F5"
        static let surface = "#FEFEFD"
        static let ink = "#392818"
        static let accent = "#CC6D19"
        static let muted = "#816C5A"
    }

    enum Palette {
        static let background = Color("background")
        static let surface = Color("surface")
        static let ink = Color("ink")
        static let accent = Color("harborAccent")
        static let muted = Color("muted")
    }
}
