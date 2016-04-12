/**************************************************************************************************
 * Name: TestDataUtil
 * Purpose: This class is the data util class for testing
 * Author: Adv Dev Candidate
 * Create Date: 2016-02-04
 * Modify History:
 * 2016-02-04    Adv Dev Candidate    Write comments in this format
 **************************************************************************************************/
@isTest
public class TestDataUtil {

    // Initiates roleMap
    private static Map<String, Id> roleMap;
    private static Map<String, Id> getUserRoleMapInstance () {
        if (roleMap == null) {
            roleMap = new Map<String, Id>(); 
            for (UserRole role : [SELECT Name FROM UserRole LIMIT 1000]) {
                roleMap.put(role.Name, role.Id);
            }
        }
        return roleMap;
    }

    // Initiates profileMap
    private static Map<String, Id> profileMap;
    private static Map<String, Id> getProfileMapInstance () {
        if (profileMap == null) {
            profileMap = new Map<String, Id> ();
            for (Profile prof : [SELECT Name FROM Profile LIMIT 1000]) {
                profileMap.put(prof.Name, prof.Id);
            }
        }
        return profileMap;
    }

    // Gets UserRoleId by Role Name
    private static Id getUserRoleId(String roleName) {
        return getUserRoleMapInstance().get(roleName);
    }
    
    // Gets ProfileId by Profile Name
    private static Id getProfileId(String profileName) {
        return getProfileMapInstance().get(profileName);
    }

    // Creates Test User
    public static User createUser (Id userRoleId, Id profileId) {
        User usr = new User();
        usr.UserName = 'test' + Math.rint(Math.random() * 100000) + '@candidate.com';
        usr.UserRoleId = userRoleId;
        usr.ProfileId = profileId;
        usr.LastName = 'Test User';
        usr.Email = 'test001@candidate.com';
        usr.Alias = 'test';
        usr.TimeZoneSidKey = 'Asia/Shanghai';
        usr.EmailEncodingKey = 'UTF-8';
        usr.LanguageLocaleKey = 'en_US';
        usr.localesidkey='en_US';
        insert usr;

        return usr;
    }

    // Creates Test User by Role Name and Profile Name
    public static User createUser (String roleName, String profileName) {
        return createUser(roleName == null ? null : getUserRoleId(roleName), getProfileId(profileName));
    }

    // Creates account
    public static Account createAccount () {

    	Account acc = new Account(Name = 'XLC Customer', Subscribed_Channels__c = 'Discovery;EPIC;Science;SYFY');
    	insert acc;

    	return acc;
    }
}