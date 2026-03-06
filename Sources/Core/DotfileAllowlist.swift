import Foundation

public struct DotfileAllowlist: Sendable {
    public var paths: [String]

    public init(paths: [String] = DotfileAllowlist.defaultPaths) {
        self.paths = paths
    }

    public static let defaultPaths: [String] = [
        "~/.zshrc",
        "~/.zprofile",
        "~/.bashrc",
        "~/.bash_profile",
        "~/.p10k.zsh",
        "~/.gitignore_global",
        "~/.config/starship.toml"
    ]
}
