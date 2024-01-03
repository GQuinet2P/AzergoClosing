@IsTest
private class TestFactoryTest {
  @IsTest
  static void when_objectIsCreated_expect_defaultFieldsArePopulated() {
    //when
    Account a = (Account) TestFactory.createSObject(new Account());
    //then
    System.assertEquals(
      'Test Account',
      a.Name,
      'Expecting Default field value is set to specific value'
    );
  }

  @IsTest
  static void when_objectIsInserted_expect_defaultFieldsArePopulated() {
    User testuser = TestDataFactory.createUser('testuser' + System.currentTimeMillis(), true);

    System.runAs(testuser) {
      //when
      Account a = (Account) TestFactory.createSObject(new Account(), true);
      //then
      a = [SELECT Name FROM Account WHERE Id = :a.Id];
      System.assertEquals(
        'TEST ACCOUNT',
        a.Name.toUpperCase(),
        'Expecting Default field value is set to specific value'
      );
    }
  }

  @IsTest
  static void when_objectIsCreatedWithSpecificDefaultsSet_expect_defaultFieldsArePopulated() {
    //when
    Account a = (Account) TestFactory.createSObject(
      new Account(),
      'TestFactoryDefaults.AccountDefaults'
    );
    //then
    System.assertEquals(
      'Test Account',
      a.Name,
      'Expecting Default field value is set to specific value'
    );
  }

  @IsTest
  static void when_objectIsInsertedWithSpecificDefaultsSet_expect_defaultFieldsArePopulated() {
    User testuser = TestDataFactory.createUser('testuser' + System.currentTimeMillis(), true);

    System.runAs(testuser) {
      //when
      Account a = (Account) TestFactory.createSObject(
        new Account(),
        'TestFactoryDefaults.AccountDefaults',
        true
      );
      //then
      System.assertEquals(
        'Test Account',
        a.Name,
        'Expecting Default field value is set to specific value'
      );
    }
  }

  @IsTest
  static void when_ListOfObjectsIsCreated_expect_defaultFieldsArePopulated() {
    //when
    Account[] aList = (Account[]) TestFactory.createSObjectList(
      new Account(),
      200
    );
    //then
    for (Account a : aList) {
      System.assert(
        a.Name.startsWithIgnoreCase('Test Account'),
        'Expecting Default field value is set to specific value'
      );
    }
  }

  @IsTest
  static void when_ListOfObjectIsInserted_expect_defaultFieldsArePopulated() {
    User testuser = TestDataFactory.createUser('testuser' + System.currentTimeMillis(), true);

    System.runAs(testuser) {
      //when
      Account[] aList = (Account[]) TestFactory.createSObjectList(
        new Account(),  
        200,
        true
      );
      //then
      aList = [SELECT Name FROM Account WHERE Id IN :aList ORDER BY Name];
      for (Account a : aList) {
        System.assert(
          a.Name.startsWithIgnoreCase('TEST ACCOUNT'),
          'Expecting Default field value is set to specific value'
        );
      }
    }
  }

  @IsTest
  static void when_ListOfObjectsIsCreatedWithSpecificDefaultsSet_expect_defaultFieldsArePopulated() {
    User testuser = TestDataFactory.createUser('testuser' + System.currentTimeMillis(), true);

    System.runAs(testuser) {
      //when
      Account[] aList = (Account[]) TestFactory.createSObjectList(
        new Account(),
        200,
        'TestFactoryDefaults.AccountDefaults'
      );
      //then
      for (Account a : aList) {
        System.assert(
          a.Name.startsWithIgnoreCase('Test Account'),
          'Expecting Default field value is set to specific value'
        );
      }
    }
  }

  @IsTest
  static void when_ListOfObjectsIsInsertedWithSpecificDefaultsSet_expect_defaultFieldsArePopulated() {
    User testuser = TestDataFactory.createUser('testuser' + System.currentTimeMillis(), true);

    System.runAs(testuser) {
      //when
      Account[] aList = (Account[]) TestFactory.createSObjectList(
        new Account(),
        200,
        'TestFactoryDefaults.AccountDefaults',
        true
      );
      //then
      aList = [SELECT Name FROM Account WHERE Id IN :aList ORDER BY Name];
      for (Account a : aList) {
        System.assert(
          a.Name.startsWithIgnoreCase('TEST ACCOUNT'),
          'Expecting Default field value is set to specific value'
        );
      }
    }
  }
}