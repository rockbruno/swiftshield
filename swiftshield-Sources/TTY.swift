import Foundation

var isTTY = isatty( STDERR_FILENO ) != 0

protocol Visualiser {
    func enter()
    func present(dict: sourcekitd_variant_t, indent: String)
    func exit()
}
