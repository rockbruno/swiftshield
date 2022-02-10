public protocol TransactionUseCase {

    func getUserDepositAccount(
    completion: @escaping (Result<String?, Error>) -> Void
    )

    func getTransactions(
        request: String,
        completion: @escaping (Result<String, Error>) -> Void
    )

    func getCalendarActivity(
    completion: @escaping (Result<String, Error>) -> Void
    )
}

public final class DBTransactionUseCase: TransactionUseCase {

    public init() {}

    deinit {}

    public func getUserDepositAccount(
    completion: @escaping (Result<String?, Error>) -> Void
    ) {}

    public func getTransactions(
        request: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {}

    @discardableResult
    public func getCalendarActivity(
        completion: @escaping (Result<String, Error>) -> Void
    ) {}
}