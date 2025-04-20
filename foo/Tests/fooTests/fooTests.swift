import Testing
@testable import foo

@Test func example() async throws {
    let sut = FooAPIClient.create()
    sut.apiKey = "0602UmYyQqztIfPV"
    try await sut.loginWithSMS(
        with: "223345999",
        prefix: "+34",
        countryCode: "ES"
    )
    let response = try await sut.checkConfirmationSMSCode(
        with: "223345999",
        prefix: "+34",
        confirmationCode: "123456",
        countryCode: "ES"
    )
    sut.authToken = response.accessToken
    try await sut.logOut()
}
