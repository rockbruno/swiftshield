import Foundation

func exit(error: Bool = false) -> Never {
    //Sleep shortly to prevent the terminal from eating the last log
    sleep(1)
    exit(error ? -1 : 0)
}
