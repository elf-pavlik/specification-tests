Feature: Get WebID

  Scenario: Discover Authorization Agent
    Given url webId
    And header Accept = 'text/turtle'
    When method GET
    Then status 200
    And match header Content-Type contains 'text/turtle'
    # TODO: * def dataset = parse(response, 'text/turtle')
