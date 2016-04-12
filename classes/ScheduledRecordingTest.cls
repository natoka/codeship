/**************************************************************************************************
 * Name: ScheduledRecordingTest
 * Purpose: 
 	1. Test run as XLC customer created new recording the completed scheduled recording been deleted.
 	1. Test run as XLC customer inserts scheduled recording
 	2. Test run as XLC customer updates scheduled recording
 	3. Test run as XLC customer deletes scheduled recording
 	5. Test run as XLC customer Bulk inserts scheduled recording
 * Author: Adv Dev Candidate
 * Create Date: 2016-02-05
 * Modify History:
 * 2016-02-05    Adv Dev Candidate    Write comments in this format
 **************************************************************************************************/
@isTest
private class ScheduledRecordingTest {

	// Test run as XLC customer created new recording the completed scheduled recording been deleted.
	static testMethod void testDeleteCompletedScheduledRecordings_Runas () {
		
		// Creates XLC customer user
		User XLCCustomer = TestDataUtil.createUser(null, 'XLC Customer');

		// Creates account and update the Customer__c to the XLCCustomer user ID.
		Account acc = TestDataUtil.createAccount();
		acc.Customer__c = XLCCustomer.Id;
		update acc;

		// Creates the recording device then share with XLCCustomer user ID.
		Recording_Device__c recordingDevice = new Recording_Device__c(Name = 'Dining Room DVR', Account__c = acc.Id);
		insert recordingDevice;

		Recording_Device__Share rds = new Recording_Device__Share(ParentId = recordingDevice.Id,
			                                                      UserOrGroupId = XLCCustomer.Id,
			                                                      AccessLevel = 'Edit');
		insert rds;

		// Creats Shows
		Show__c show = new Show__c(Name = 'Alaska Frontier');
		insert show;

    	Datetime GMTNow = DateTime.newInstance(Datetime.now().year(),
                                               Datetime.now().month(),
                                               Datetime.now().day(),
                                               Datetime.now().hour(), 00, 00);

		List<Broadcast__c> broadcasts = new List<Broadcast__c> ();
		Broadcast__c b1 = new Broadcast__c (Show__c = show.Id, Channel__c = 'CNN', Start_Time__c = GMTNow.addHours(1));
		broadcasts.add(b1);
		Broadcast__c b2 = new Broadcast__c (Show__c = show.Id, Channel__c = 'Discovery', Start_Time__c = GMTNow.addHours(-10));
		broadcasts.add(b2);
		Broadcast__c b3 = new Broadcast__c (Show__c = show.Id, Channel__c = 'Discovery', Start_Time__c = GMTNow.addHours(1));
		broadcasts.add(b3);
		insert broadcasts;

		System.runAs(XLCCustomer) {

			// Start Test
            Test.startTest();

            // Because of the validation rule, creates a normal schedule recording
        	Recording__c rec1 = new Recording__c (Broadcast__c = b1.Id, Recording_Device__c = recordingDevice.ID);
        	insert rec1;

        	// Updates the recording start time to 10 hours before now.
        	rec1.Broadcast__c = b2.Id;
        	update rec1;

        	// Creates a normal recording in the same device again
        	Recording__c rec2 = new Recording__c (Broadcast__c = b3.Id, Recording_Device__c = recordingDevice.ID);
    		insert rec2;

    		// Verifies the rec1 record should be deleted.
    		List<Recording__c> verifyRecordings = [SELECT Name, Conflict_Warning__c
    			                                   FROM Recording__c
    			                                   WHERE Id =: rec1.Id];

    		System.assertEquals(verifyRecordings.size(), 0);
            Test.stopTest();
		}
	}

	// Test run as XLC customer inserts scheduled recording
	static testMethod void testScheduledRecordingInsertTrigger_Runas () {

		// Creates XLC customer user
		User XLCCustomer = TestDataUtil.createUser(null, 'XLC Customer');

		// Creates account and update the Customer__c to the XLCCustomer user ID.
		Account acc = TestDataUtil.createAccount();
		acc.Customer__c = XLCCustomer.Id;
		update acc;

		// Creates the recording device then share with XLCCustomer user ID.
		Recording_Device__c recordingDevice = new Recording_Device__c(Name = 'Dining Room DVR', Account__c = acc.Id);
		insert recordingDevice;

		Recording_Device__Share rds = new Recording_Device__Share(ParentId = recordingDevice.Id,
			                                                      UserOrGroupId = XLCCustomer.Id,
			                                                      AccessLevel = 'Edit');
		insert rds;

		// Creats Shows
		Show__c show = new Show__c(Name = 'Alaska Frontier');
		insert show;

    	Datetime GMTNow = DateTime.newInstance(Datetime.now().year(),
                                               Datetime.now().month(),
                                               Datetime.now().day(),
                                               Datetime.now().hour(), 00, 00);

		List<Broadcast__c> broadcasts = new List<Broadcast__c> ();
		Broadcast__c b1 = new Broadcast__c (Show__c = show.Id, Channel__c = 'CNN', Start_Time__c = GMTNow.addHours(1));
		broadcasts.add(b1);
		Broadcast__c b2 = new Broadcast__c (Show__c = show.Id, Channel__c = 'Discovery', Start_Time__c = GMTNow.addHours(1));
		broadcasts.add(b2);
		insert broadcasts;

		System.runAs(XLCCustomer) {

			// Start Test
            Test.startTest();
            List<Recording__c> recordings = new List<Recording__c> ();
        	Recording__c rec1 = new Recording__c (Broadcast__c = b1.Id, Recording_Device__c = recordingDevice.ID);
        	recordings.add(rec1);
        	Recording__c rec2 = new Recording__c (Broadcast__c = b2.Id, Recording_Device__c = recordingDevice.ID);
        	recordings.add(rec2);
    		insert recordings;

    		// Conflict_Warning__c checkbox in the both recording records should be checked.
    		List<Recording__c> verifyRecordings = [SELECT Name, Conflict_Warning__c
    			                                   FROM Recording__c
    			                                   WHERE Conflict_Warning__c = TRUE
    			                                   AND Recording_Device__c =: recordingDevice.ID];
    		System.assertEquals(verifyRecordings.size(), 2);
            Test.stopTest();
		}
	}

	// Test run as XLC customer updates scheduled recording
	static testMethod void testScheduledRecordingUpdateTrigger_Runas () {

		// Creates XLC customer user
		User XLCCustomer = TestDataUtil.createUser(null, 'XLC Customer');

		// Creates account and update the Customer__c to the XLCCustomer user ID.
		Account acc = TestDataUtil.createAccount();
		acc.Customer__c = XLCCustomer.Id;
		update acc;

		// Creates the recording device then share with XLCCustomer user ID.
		Recording_Device__c recordingDevice = new Recording_Device__c(Name = 'Dining Room DVR', Account__c = acc.Id);
		insert recordingDevice;

		Recording_Device__Share rds = new Recording_Device__Share(ParentId = recordingDevice.Id,
			                                                      UserOrGroupId = XLCCustomer.Id,
			                                                      AccessLevel = 'Edit');
		insert rds;

		// Creats Shows
		Show__c show = new Show__c(Name = 'Alaska Frontier');
		insert show;

    	Datetime GMTNow = DateTime.newInstance(Datetime.now().year(),
                                               Datetime.now().month(),
                                               Datetime.now().day(),
                                               Datetime.now().hour(), 00, 00);

		List<Broadcast__c> broadcasts = new List<Broadcast__c> ();
		Broadcast__c b1 = new Broadcast__c (Show__c = show.Id, Channel__c = 'CNN', Start_Time__c = GMTNow.addHours(1));
		broadcasts.add(b1);
		Broadcast__c b2 = new Broadcast__c (Show__c = show.Id, Channel__c = 'Discovery', Start_Time__c = GMTNow.addHours(1));
		broadcasts.add(b2);
		Broadcast__c b3 = new Broadcast__c (Show__c = show.Id, Channel__c = 'Discovery', Start_Time__c = GMTNow.addHours(2));
		broadcasts.add(b3);
		insert broadcasts;

		System.runAs(XLCCustomer) {

			// Start Test
            Test.startTest();

            List<Recording__c> recordings = new List<Recording__c> ();
        	Recording__c rec1 = new Recording__c (Broadcast__c = b1.Id, Recording_Device__c = recordingDevice.ID);
        	recordings.add(rec1);
        	Recording__c rec2 = new Recording__c (Broadcast__c = b2.Id, Recording_Device__c = recordingDevice.ID);
        	recordings.add(rec2);

    		insert recordings;

    		rec2.Broadcast__c = b3.Id;
    		update rec2;

    		// Conflict_Warning__c checkbox in the both recording record should be unchecked.
    		List<Recording__c> verifyRecordings = [SELECT Name, Conflict_Warning__c
    			                                   FROM Recording__c
    			                                   WHERE Conflict_Warning__c = TRUE
    			                                   AND Recording_Device__c =: recordingDevice.ID];
    		System.assertEquals(verifyRecordings.size(), 0);
            Test.stopTest();
		}
	}

	// Test run as XLC customer deletes scheduled recording
	static testMethod void testScheduledRecordingDeleteTrigger_Runas () {

		// Creates XLC customer user
		User XLCCustomer = TestDataUtil.createUser(null, 'XLC Customer');

		// Creates account and update the Customer__c to the XLCCustomer user ID.
		Account acc = TestDataUtil.createAccount();
		acc.Customer__c = XLCCustomer.Id;
		update acc;

		// Creates the recording device then share with XLCCustomer user ID.
		Recording_Device__c recordingDevice = new Recording_Device__c(Name = 'Dining Room DVR', Account__c = acc.Id);
		insert recordingDevice;

		Recording_Device__Share rds = new Recording_Device__Share(ParentId = recordingDevice.Id,
			                                                      UserOrGroupId = XLCCustomer.Id,
			                                                      AccessLevel = 'Edit');
		insert rds;

		// Creats Shows
		Show__c show = new Show__c(Name = 'Alaska Frontier');
		insert show;

    	Datetime GMTNow = DateTime.newInstance(Datetime.now().year(),
                                               Datetime.now().month(),
                                               Datetime.now().day(),
                                               Datetime.now().hour(), 00, 00);

		List<Broadcast__c> broadcasts = new List<Broadcast__c> ();
		Broadcast__c b1 = new Broadcast__c (Show__c = show.Id, Channel__c = 'CNN', Start_Time__c = GMTNow.addHours(1));
		broadcasts.add(b1);
		Broadcast__c b2 = new Broadcast__c (Show__c = show.Id, Channel__c = 'Discovery', Start_Time__c = GMTNow.addHours(1));
		broadcasts.add(b2);
		insert broadcasts;

		System.runAs(XLCCustomer) {

			// Start Test
            Test.startTest();

            List<Recording__c> recordings = new List<Recording__c> ();
            for (Broadcast__c b : broadcasts) {

            	Recording__c rec = new Recording__c (Broadcast__c = b.Id, Recording_Device__c = recordingDevice.ID);
            	recordings.add(rec);
            }

    		insert recordings;
    		delete recordings[0];

    		// Conflict_Warning__c checkbox in the only recording record should be unchecked.
    		List<Recording__c> verifyRecordings = [SELECT Name, Conflict_Warning__c
    			                                   FROM Recording__c
    			                                   WHERE Conflict_Warning__c = TRUE
    			                                   AND Recording_Device__c =: recordingDevice.ID];
    		System.assertEquals(verifyRecordings.size(), 0);
            Test.stopTest();
		}
	}

	// Test run as XLC customer Bulk inserts scheduled recording
	static testMethod void testScheduledRecordingBulkInsertTrigger_Runas () {

		// Creates XLC customer user
		User XLCCustomer = TestDataUtil.createUser(null, 'XLC Customer');

		// Creates account and update the Customer__c to the XLCCustomer user ID.
		Account acc = TestDataUtil.createAccount();
		acc.Customer__c = XLCCustomer.Id;
		update acc;

		// Creates the recording device then share with XLCCustomer user ID.
		Recording_Device__c recordingDevice = new Recording_Device__c(Name = 'Dining Room DVR', Account__c = acc.Id);
		insert recordingDevice;

		Recording_Device__Share rds = new Recording_Device__Share(ParentId = recordingDevice.Id,
			                                                      UserOrGroupId = XLCCustomer.Id,
			                                                      AccessLevel = 'Edit');
		insert rds;

		// Creats Shows
		Show__c show = new Show__c(Name = 'Alaska Frontier');
		insert show;

    	Datetime GMTNow = DateTime.newInstance(Datetime.now().year(),
                                               Datetime.now().month(),
                                               Datetime.now().day(),
                                               Datetime.now().hour(), 00, 00);

		List<Broadcast__c> broadcasts = new List<Broadcast__c> ();
		Broadcast__c b1 = new Broadcast__c (Show__c = show.Id, Channel__c = 'CNN', Start_Time__c = GMTNow.addHours(1));
		broadcasts.add(b1);
		Broadcast__c b2 = new Broadcast__c (Show__c = show.Id, Channel__c = 'Discovery', Start_Time__c = GMTNow.addHours(1));
		broadcasts.add(b2);
		insert broadcasts;

		System.runAs(XLCCustomer) {

			// Start Test
            Test.startTest();
            List<Recording__c> recordings = new List<Recording__c> ();
            for (Integer i = 0; i < 1000; i++) {

	        	Recording__c rec = new Recording__c (Broadcast__c = broadcasts[Math.mod(i, 2)].Id,
	        		                                 Recording_Device__c = recordingDevice.ID);
	        	recordings.add(rec);
            }
            insert recordings;

    		// Conflict_Warning__c checkbox in the both recording record should be checked.
    		List<Recording__c> verifyRecordings = [SELECT Name, Conflict_Warning__c
    			                                   FROM Recording__c
    			                                   WHERE Conflict_Warning__c = TRUE
    			                                   AND Recording_Device__c =: recordingDevice.ID];
    		System.assertEquals(verifyRecordings.size(), 1000);
    		System.assertEquals(true, Limits.getDMLRows() < Limits.getLimitDMLRows());
    		System.assertEquals(true, Limits.getDMLStatements() < Limits.getLimitDMLStatements());
            Test.stopTest();
		}
	}

	// Test run as XLC customer created new recording with start time in the past time to violate the validation rule.
	static testMethod void testScheduledRecordingInsertTrigger_Negative () {

		// Creates XLC customer user
		User XLCCustomer = TestDataUtil.createUser(null, 'XLC Customer');

		// Creates account and update the Customer__c to the XLCCustomer user ID.
		Account acc = TestDataUtil.createAccount();
		acc.Customer__c = XLCCustomer.Id;
		update acc;

		// Creates the recording device then share with XLCCustomer user ID.
		Recording_Device__c recordingDevice = new Recording_Device__c(Name = 'Dining Room DVR', Account__c = acc.Id);
		insert recordingDevice;

		Recording_Device__Share rds = new Recording_Device__Share(ParentId = recordingDevice.Id,
			                                                      UserOrGroupId = XLCCustomer.Id,
			                                                      AccessLevel = 'Edit');
		insert rds;

		// Creats Shows
		Show__c show = new Show__c(Name = 'Alaska Frontier');
		insert show;

    	Datetime GMTNow = DateTime.newInstance(Datetime.now().year(),
                                               Datetime.now().month(),
                                               Datetime.now().day(),
                                               Datetime.now().hour(), 00, 00);

		List<Broadcast__c> broadcasts = new List<Broadcast__c> ();
		Broadcast__c b1 = new Broadcast__c (Show__c = show.Id, Channel__c = 'CNN', Start_Time__c = GMTNow);
		insert b1;

		System.runAs(XLCCustomer) {

			// Start Test
            Test.startTest();
            List<Recording__c> recordings = new List<Recording__c> ();

            // Because of the validation rule, creates a normal schedule recording
        	Recording__c rec1 = new Recording__c (Broadcast__c = b1.Id, Recording_Device__c = recordingDevice.ID);

        	try {

        		insert rec1;
            } catch (DMLException e) {
                System.assert(e.getDMLMessage(0) == 'No new Scheduled Recordings may be created in the past.');
            }

            Test.stopTest();
		}
	}
}