Feature: Test that unauthenticated users get the correct response

  Background: Setup
    * def INTEROP = 'http://www.w3.org/ns/solid/interop#'

  Scenario: Discover Authorization Agent
    * text statement =
    """
      PREFIX interop: <http://www.w3.org/ns/solid/interop#>

      <https://alice.pod.docker/profile/card#me>
          interop:hasAuthorizationAgent <https://sai.docker/agents/aHR0cHM6Ly9hbGljZS5wb2QuZG9ja2VyL3Byb2ZpbGUvY2FyZCNtZQ==> .
    """
    * def expected = parse(statement, 'text/turtle')
    * def webId = webIds.alice
    When def result = call read('utils/get-webid.feature') { webId: "#(webId)"}
    Then assert parse(result.response, 'text/turtle').contains(expected)

  Scenario: Discover Social Agent Registration
    * def webId = webIds.alice
    * def rel = INTEROP + 'registeredAgent'
    * def webIdResult = call read('utils/get-webid.feature') { webId: "#(webId)"}
    * def aliceAgent = parse(webIdResult.response, 'text/turtle').objects(iri(webId), iri(INTEROP, 'hasAuthorizationAgent'))[0]
    Given url aliceAgent
    # IMPORTANT: Bob is making the request
    And headers clients.bob.getAuthHeaders('HEAD', aliceAgent)
    When method HEAD
    Then status 200
    * def links = parseLinkHeaders(responseHeaders)
    And match links contains [{ rel: "#(rel)", uri: "#(webIds.bob)" }]

  @ignore
  Scenario: Discover Application Registration
    * def webId = webIds.alice
    * def rel = INTEROP + 'registeredAgent'
    * def webIdResult = call read('utils/get-webid.feature') { webId: "#(webId)"}
    * def aliceAgent = parse(webIdResult.response, 'text/turtle').objects(iri(webId), iri(INTEROP, 'hasAuthorizationAgent'))[0]
    Given url aliceAgent
    # IMPORTANT: Alice is making the request
    And headers clients.alice.getAuthHeaders('HEAD', aliceAgent)
    When method HEAD
    Then status 200
    * def links = parseLinkHeaders(responseHeaders)
    And match links contains [{ rel: "#(rel)", uri: "specification-tests_4488019d-2798-4e61-8b9e-bdcb8d8efd5a" }]

  # TODO: use shape instead
  Scenario: Registry Set
    * def webId = webIds.alice
    * def webIdResult = call read('utils/get-webid.feature') { webId: "#(webId)"}
    * def registrySet = parse(webIdResult.response, 'text/turtle').objects(iri(webId), iri(INTEROP, 'hasRegistrySet'))[0]
    Given url registrySet
    And headers clients.alice.getAuthHeaders('GET', registrySet)
    And header Accept = 'text/turtle'
    When method GET
    Then status 200
    * def dataset = parse(response, 'text/turtle', registrySet)
    And match dataset.objects(iri(registrySet), iri(INTEROP, 'hasAuthorizationRegistry')) == '#[1]'
    And match dataset.objects(iri(registrySet), iri(INTEROP, 'hasAgentRegistry')) == '#[1]'
    And match dataset.objects(iri(registrySet), iri(INTEROP, 'hasDataRegistry')) != '#[0]'

  Scenario: Data Grant Issuance Discovery
    * def webId = webIds.alice
    * def webIdResult = call read('utils/get-webid.feature') { webId: "#(webId)"}
    * def aliceAgent = parse(webIdResult.response, 'text/turtle').objects(iri(webId), iri(INTEROP, 'hasAuthorizationAgent'))[0]
    Given url aliceAgent
    And header Accept = 'text/turtle'
    And headers clients.alice.getAuthHeaders('GET', aliceAgent)
    When method GET
    Then status 200
    * def dataset = parse(response, 'text/turtle', aliceAgent)
    And match dataset.objects(iri(aliceAgent), iri(INTEROP, 'hasDelegationIssuanceEndpoint')) == '#[1]'

    * def issuanceEndpoint = dataset.objects(iri(aliceAgent), iri(INTEROP, 'hasDelegationIssuanceEndpoint'))[0]
    Given url issuanceEndpoint
    An headers clients.alice.getAuthHeaders('POST', issuanceEndpoint)
    When method POST
    Then status 200

